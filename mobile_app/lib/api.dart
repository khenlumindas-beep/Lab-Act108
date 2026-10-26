import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'net/discovery.dart';
import 'notify.dart';

/// API base URL.
/// - Build-time override: --dart-define=API_BASE=...
/// - Otherwise auto-resolved at startup (see [resolveApiBase]):
///   web derives host from the page URL; native scans the LAN for :5000.
String kApiBase =
    const String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:5000/api');

bool _apiBaseLocked = const bool.fromEnvironment('API_BASE');

/// Default per-request timeout so the busy overlay can never hang forever
/// when the server accepts a connection but never answers.
const Duration kRequestTimeout = Duration(seconds: 30);

/// Resolve the best API base once at app startup. Safe to call repeatedly.
Future<void> resolveApiBase() async {
  if (_apiBaseLocked) return;
  try {
    final resolved = await discoverApiBase(
        current: kApiBase, overridden: _apiBaseLocked);
    if (resolved != null && resolved.isNotEmpty) {
      kApiBase = resolved;
    }
  } catch (_) {
    // Never block startup on discovery — keep current base.
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  /// Set once the offline notice for this failure has already been shown,
  /// so `showApiError` never reports the same connection problem twice.
  bool notified = false;

  @override
  String toString() => message;
}

class Session {
  static final Session instance = Session._();
  Session._();

  String? token;
  String? role;
  String? fullName;
  int? userId;
  int? collegeId;

  bool get isAdmin => role == 'super_admin';

  Future<void> save(String token, String role, String fullName, int userId,
      int? collegeId) async {
    this.token = token;
    this.role = role;
    this.fullName = fullName;
    this.userId = userId;
    this.collegeId = collegeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('full_name', fullName);
    await prefs.setInt('user_id', userId);
    if (collegeId != null) await prefs.setInt('college_id', collegeId);
  }

  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    role = prefs.getString('role');
    fullName = prefs.getString('full_name');
    userId = prefs.getInt('user_id');
    collegeId = prefs.getInt('college_id');
    if (token == null) return false;
    try {
      await ApiClient.instance.get('/auth/me', feedback: false);
      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  Future<void> clear() async {
    token = null;
    role = null;
    fullName = null;
    userId = null;
    collegeId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('full_name');
    await prefs.remove('user_id');
    await prefs.remove('college_id');
  }

  Future<void> updateDisplayName(String name) async {
    fullName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', name);
  }
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (Session.instance.token != null)
          'Authorization': 'Bearer ${Session.instance.token}',
      };

  dynamic _decode(http.Response res) {
    final text = res.body;
    final body = text.isEmpty ? null : jsonDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    var detail = 'HTTP ${res.statusCode}';
    if (body is Map && body['detail'] != null) {
      final d = body['detail'];
      detail = d is String ? d : jsonEncode(d);
    }
    throw ApiException(res.statusCode, detail);
  }

  static const String connErrorMessage =
      'Cannot reach the SmartTrack server. Please check that the server is '
      'running and this device is connected to the same Wi-Fi network.';

  bool _isConnError(Object e) {
    if (e is ApiException) return false;
    final s = e.toString().toLowerCase();
    return s.contains('clientexception') ||
        s.contains('socketexception') ||
        s.contains('failed to fetch') ||
        s.contains('connection') ||
        s.contains('timed out') ||
        s.contains('timeoutexception') ||
        s.contains('failed host lookup');
  }

  /// Send once; on connection failure (mobile only) re-discover the backend
  /// and retry once with the new base; otherwise throw a friendly [ApiException].
  Future<dynamic> _attempt(Future<http.Response> Function() op) async {
    try {
      return _decode(await op());
    } catch (e) {
      if (!_isConnError(e)) rethrow;
      if (!_apiBaseLocked && !kIsWeb) {
        final prev = kApiBase;
        String? resolved;
        try {
          resolved = await discoverApiBase(current: prev, overridden: false);
        } catch (_) {}
        if (resolved != null && resolved.isNotEmpty && resolved != prev) {
          kApiBase = resolved;
          try {
            return _decode(await op());
          } catch (e2) {
            if (!_isConnError(e2)) rethrow;
          }
        }
      }
      throw ApiException(0, connErrorMessage);
    }
  }

  /// Verb defaults for the busy overlay and the success toast.
  String _busyDefault(String verb) {
    switch (verb) {
      case 'POST':
        return 'Saving…';
      case 'PUT':
      case 'PATCH':
        return 'Updating…';
      case 'DELETE':
        return 'Deleting…';
      case 'UPLOAD':
        return 'Uploading…';
    }
    return 'Please wait…';
  }

  String _defaultOk(String verb) {
    switch (verb) {
      case 'POST':
        return 'Saved successfully';
      case 'PUT':
      case 'PATCH':
        return 'Updated successfully';
      case 'DELETE':
        return 'Deleted successfully';
      case 'UPLOAD':
        return 'Upload complete';
    }
    return 'Done';
  }

  /// Backend responses shaped `{"message": …}` use that text as the toast.
  String? _serverMsg(dynamic body) {
    if (body is Map) {
      final m = body['message'];
      if (m is String && m.trim().isNotEmpty) return m;
    }
    return null;
  }

  /// Runs [op] with the transaction notifiers attached:
  ///   * mutations show the blocking [BusyOverlay] while in flight
  ///   * mutations end with a green success toast (server `message`, [okMsg]
  ///     override, or a verb default)
  ///   * connection failures end with the deep-red offline toast
  ///   * HTTP errors are left to the caller (they surface through
  ///     `showApiError` as red toasts, or a dedicated dialog for the
  ///     pre-travel gate) — never both.
  Future<dynamic> _send(
    Future<http.Response> Function() op, {
    required String verb,
    bool feedback = true,
    String? okMsg,
    String? busyMsg,
  }) async {
    final mutate = verb != 'GET';
    final showBusy = feedback && mutate;
    var hidden = false;
    void hideBusy() {
      if (showBusy && !hidden) {
        hidden = true;
        Notify.busyHide();
      }
    }

    if (showBusy) Notify.busyShow(busyMsg ?? _busyDefault(verb));
    try {
      final dynamic body = await _attempt(op);
      hideBusy();
      if (feedback && mutate) {
        Notify.success(okMsg ?? _serverMsg(body) ?? _defaultOk(verb));
      }
      return body;
    } catch (e) {
      hideBusy();
      if (e is ApiException && e.status == 0 && feedback) {
        e.notified = true;
        Notify.offline(e.message);
      }
      rethrow;
    } finally {
      hideBusy();
    }
  }

  Future<dynamic> get(String path, {bool feedback = true}) => _send(
      () => http
          .get(Uri.parse('$kApiBase$path'), headers: _headers)
          .timeout(kRequestTimeout),
      verb: 'GET',
      feedback: feedback);

  Future<dynamic> post(String path, Map<String, dynamic> body,
          {bool feedback = true, String? okMsg, String? busyMsg}) =>
      _send(
          () => http
              .post(Uri.parse('$kApiBase$path'),
                  headers: _headers, body: jsonEncode(body))
              .timeout(kRequestTimeout),
          verb: 'POST',
          feedback: feedback,
          okMsg: okMsg,
          busyMsg: busyMsg);

  Future<dynamic> put(String path, Map<String, dynamic> body,
          {bool feedback = true, String? okMsg, String? busyMsg}) =>
      _send(
          () => http
              .put(Uri.parse('$kApiBase$path'),
                  headers: _headers, body: jsonEncode(body))
              .timeout(kRequestTimeout),
          verb: 'PUT',
          feedback: feedback,
          okMsg: okMsg,
          busyMsg: busyMsg);

  Future<dynamic> patch(String path, Map<String, dynamic> body,
          {bool feedback = true, String? okMsg, String? busyMsg}) =>
      _send(
          () => http
              .patch(Uri.parse('$kApiBase$path'),
                  headers: _headers, body: jsonEncode(body))
              .timeout(kRequestTimeout),
          verb: 'PATCH',
          feedback: feedback,
          okMsg: okMsg,
          busyMsg: busyMsg);

  Future<dynamic> delete(String path,
          {bool feedback = true, String? okMsg, String? busyMsg}) =>
      _send(
          () => http
              .delete(Uri.parse('$kApiBase$path'), headers: _headers)
              .timeout(kRequestTimeout),
          verb: 'DELETE',
          feedback: feedback,
          okMsg: okMsg,
          busyMsg: busyMsg);

  /// Multipart file upload (e.g. document upload).
  Future<dynamic> upload(
    String path, {
    required Map<String, String> fields,
    required String fileName,
    required List<int> bytes,
    String fileField = 'file',
    bool feedback = true,
    String? okMsg,
    String? busyMsg,
  }) {
    final uri = Uri.parse('$kApiBase$path');
    return _send(() async {
      final req = http.MultipartRequest('POST', uri);
      if (Session.instance.token != null) {
        req.headers['Authorization'] = 'Bearer ${Session.instance.token}';
      }
      req.fields.addAll(fields);
      req.files.add(http.MultipartFile.fromBytes(fileField, bytes,
          filename: fileName));
      final streamed = await req.send().timeout(const Duration(seconds: 120));
      return http.Response.fromStream(streamed);
    },
        verb: 'UPLOAD',
        feedback: feedback,
        okMsg: okMsg,
        busyMsg: busyMsg);
  }

  /// URL that authenticates via `?token=` — for direct browser file downloads
  /// (the endpoint serves files as attachments, so opening the URL downloads).
  String authedFileUrl(String path) {
    final sep = path.contains('?') ? '&' : '?';
    return '$kApiBase$path${sep}token=${Uri.encodeComponent(Session.instance.token ?? '')}';
  }

  /// Login and persist the session. Returns the user profile.
  /// The sign-in screen renders its own inline error box + button spinner,
  /// so this flow opts out of the global toasts/loading overlay.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final tokenRes = await post('/auth/login', {
      'email': email,
      'password': password,
    }, feedback: false);
    Session.instance.token = tokenRes['access_token'];
    final me = Map<String, dynamic>.from(
        await get('/auth/me', feedback: false));
    await Session.instance.save(
      Session.instance.token!,
      (me['role'] ?? 'faculty') as String,
      (me['full_name'] ?? '') as String,
      (me['user_id'] ?? 0) as int,
      me['college_id'] as int?,
    );
    return me;
  }
}
