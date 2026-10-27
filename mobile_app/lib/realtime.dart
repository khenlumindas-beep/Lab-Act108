import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';
import 'brand.dart';

/// Connection state of the realtime channel.
enum RealtimeState { connecting, live, polling, offline }

/// One change notification pushed by the backend, or synthesised by the
/// polling fallback (`topic == 'all'`).
class RealtimeEvent {
  const RealtimeEvent({
    required this.topic,
    required this.action,
    this.seq = 0,
    this.data = const <String, dynamic>{},
  });

  /// `documents` | `travels` | `users` | `compliance` | `requirements` | `all`
  final String topic;
  final String action;
  final int seq;
  final Map<String, dynamic> data;

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json)
      ..remove('type')
      ..remove('topic')
      ..remove('action')
      ..remove('seq')
      ..remove('ts');
    return RealtimeEvent(
      topic: (json['topic'] ?? 'all').toString(),
      action: (json['action'] ?? 'changed').toString(),
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      data: data,
    );
  }
}

/// Single realtime connection for the whole app.
///
/// * WebSocket push (`/api/realtime/ws`) for instant updates.
/// * Polling fallback (`/api/realtime/version` every 8s) whenever the socket
///   is down, so monitoring screens never go stale.
///
/// Screens never talk to this class directly — they mix in [RealtimeAware].
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  /// How often the fallback checks the change token.
  static const Duration pollEvery = Duration(seconds: 8);
  static const Duration _minRetry = Duration(seconds: 2);
  static const Duration _maxRetry = Duration(seconds: 30);

  final ValueNotifier<RealtimeState> status =
      ValueNotifier<RealtimeState>(RealtimeState.offline);

  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _events.stream;
  RealtimeState get state => status.value;
  DateTime? get lastSync => _lastSync;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pollTimer;
  Timer? _retryTimer;
  DateTime? _lastSync;
  String? _fingerprint;
  bool _running = false;
  bool _socketOpen = false;
  int _attempt = 0;

  /// Start listening. Safe to call repeatedly (e.g. from every Home screen).
  void start() {
    if (_running) return;
    _running = true;
    _attempt = 0;
    _fingerprint = null;
    _open();
    _startPolling();
  }

  /// Stop and drop the socket (logout).
  void stop() {
    _running = false;
    _socketOpen = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _closeSocket();
    _set(RealtimeState.offline);
  }

  /// Force an immediate resync (app resumed, manual pull-to-refresh, ...).
  void refreshNow() {
    if (!_running) start();
    _pollOnce();
  }

  void _set(RealtimeState next) {
    if (status.value != next) status.value = next;
  }

  // ---------------------------------------------------------------- socket

  void _open() {
    if (!_running) return;
    final token = Session.instance.token;
    if (token == null || token.isEmpty) {
      _set(RealtimeState.offline);
      return;
    }
    _closeSocket();
    if (status.value != RealtimeState.live) {
      _set(RealtimeState.connecting);
    }
    try {
      final channel = WebSocketChannel.connect(_wsUri(token));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onError: (_) => _onSocketDown(),
        onDone: _onSocketDown,
        cancelOnError: true,
      );
      channel.ready.then((_) {
        if (!_running || _channel != channel) return;
        _socketOpen = true;
        _attempt = 0;
        _set(RealtimeState.live);
        _pollOnce(); // baseline fingerprint for the fallback
      }).catchError((_) => _onSocketDown());
    } catch (_) {
      _onSocketDown();
    }
  }

  void _closeSocket() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {
      // already closed
    }
    _channel = null;
    _socketOpen = false;
  }

  void _onSocketDown() {
    _socketOpen = false;
    _closeSocket();
    if (!_running) return;
    _set(RealtimeState.polling);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_running) return;
    _retryTimer?.cancel();
    _attempt = (_attempt + 1).clamp(1, 8);
    var delay = _minRetry * (1 << (_attempt - 1));
    if (delay > _maxRetry) delay = _maxRetry;
    _retryTimer = Timer(delay, _open);
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = json['type'];
    if (type == 'hello') {
      _socketOpen = true;
      _attempt = 0;
      _set(RealtimeState.live);
      _pollOnce();
      return;
    }
    if (type == 'ping') {
      if (status.value != RealtimeState.live) _set(RealtimeState.live);
      return;
    }
    if (type != 'event') return;
    _lastSync = DateTime.now();
    _events.add(RealtimeEvent.fromJson(json));
  }

  Uri _wsUri(String token) {
    var base = kApiBase;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    final parsed = Uri.parse(base);
    return parsed.replace(
      scheme: parsed.scheme == 'https' ? 'wss' : 'ws',
      path: '${parsed.path}/realtime/ws',
      queryParameters: <String, String>{'token': token},
    );
  }

  // --------------------------------------------------------------- polling

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollEvery, (_) {
      if (!_socketOpen) _pollOnce();
    });
  }

  Future<void> _pollOnce() async {
    if (!_running) return;
    final token = Session.instance.token;
    if (token == null || token.isEmpty) return;
    try {
      final res = await http
          .get(
            Uri.parse('$kApiBase/realtime/version'),
            headers: <String, String>{'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (!_running) return;
      if (res.statusCode != 200) {
        if (!_socketOpen) _set(RealtimeState.offline);
        return;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final fp = body['fingerprint']?.toString();
      _lastSync = DateTime.now();
      if (_fingerprint == null) {
        _fingerprint = fp; // baseline — no refresh on first tick
        if (!_socketOpen && status.value == RealtimeState.offline) {
          _set(RealtimeState.polling);
        }
        return;
      }
      if (fp != null && fp != _fingerprint) {
        _fingerprint = fp;
        _events.add(RealtimeEvent(
          topic: 'all',
          action: 'poll',
          seq: (body['seq'] as num?)?.toInt() ?? 0,
          data: body,
        ));
      }
      if (!_socketOpen) _set(RealtimeState.polling);
    } catch (_) {
      if (!_socketOpen) _set(RealtimeState.offline);
    }
  }
}

/// Mix into a monitoring screen's [State] to refresh it on realtime events.
///
/// ```dart
/// class _FooState extends State<Foo> with RealtimeAware {
///   @override
///   Set<String> get realtimeTopics => const {'documents', 'travels'};
///   @override
///   Future<void> onRealtimeRefresh() => _load(silent: true);
/// }
/// ```
///
/// An empty [realtimeTopics] means "refresh on everything".
mixin RealtimeAware<T extends StatefulWidget> on State<T> {
  Set<String> get realtimeTopics => const <String>{};
  Future<void> onRealtimeRefresh() async {}

  StreamSubscription<RealtimeEvent>? _rtSub;
  Timer? _rtDebounce;

  @override
  void initState() {
    super.initState();
    _rtSub = RealtimeService.instance.events.listen(_rtHandle);
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    _rtDebounce?.cancel();
    super.dispose();
  }

  void _rtHandle(RealtimeEvent event) {
    final topics = realtimeTopics;
    if (topics.isNotEmpty && event.topic != 'all' && !topics.contains(event.topic)) {
      return;
    }
    _rtDebounce?.cancel();
    _rtDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      onRealtimeRefresh();
    });
  }
}

/// "● Live" indicator shown in monitoring headers.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RealtimeState>(
      valueListenable: RealtimeService.instance.status,
      builder: (context, state, _) {
        final (label, color, icon) = switch (state) {
          RealtimeState.live => ('Live', Brand.green, Icons.bolt_rounded),
          RealtimeState.connecting =>
            ('Connecting', Brand.orange, Icons.sync_rounded),
          RealtimeState.polling => ('Syncing', Brand.orange, Icons.sync_rounded),
          RealtimeState.offline =>
            ('Offline', const Color(0xFFB91C1C), Icons.cloud_off_rounded),
        };
        return Tooltip(
          message: state == RealtimeState.live
              ? 'Realtime updates are streaming'
              : 'Updates refresh every ${RealtimeService.pollEvery.inSeconds}s',
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: compact ? 12 : 14, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Colour used for a submission status string from the API.
Color submissionColor(String? status) {
  switch (status) {
    case 'Complete':
      return Brand.green;
    case 'Verified':
      return const Color(0xFF0D9488);
    case 'Partially Verified':
      return const Color(0xFF2563EB);
    case 'Submitted':
      return Brand.orange;
    case 'Not Yet Submitted':
    default:
      return Brand.textMuted;
  }
}

/// "Not Yet Submitted" / "Submitted" / "Partially Verified" / "Complete" chip.
///
/// The status is computed live on the server from the documents table, so a
/// faculty member who has not uploaded anything is always marked
/// **Not Yet Submitted**.
class SubmissionStatusChip extends StatelessWidget {
  const SubmissionStatusChip({
    super.key,
    required this.status,
    this.files,
    this.verified,
    this.compact = false,
  });

  final String? status;
  final int? files;
  final int? verified;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = (status == null || status!.isEmpty) ? 'Not Yet Submitted' : status!;
    final color = submissionColor(label);
    final showCounts = (files ?? 0) > 0 && !compact;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Not Yet Submitted'
                ? Icons.inbox_outlined
                : Icons.check_circle_outline_rounded,
            size: compact ? 11 : 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (showCounts) ...[
            const SizedBox(width: 6),
            Text(
              verified != null && verified! > 0
                  ? '${files ?? 0} file(s) · ${verified!} verified'
                  : '${files ?? 0} file(s)',
              style: TextStyle(
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
