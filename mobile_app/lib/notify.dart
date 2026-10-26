import 'package:flutter/material.dart';

import 'brand.dart';

/// Global transaction notifiers for SmartTrack.
///
/// Every API transaction funnels through here so the app has one consistent
/// feedback language:
///   * [Notify.success] — green toast after a completed transaction
///   * [Notify.error]   — red toast for failures
///   * [Notify.warning] — amber toast for client-side validation nudges
///   * [Notify.info]    — brand-green toast for neutral notices
///   * [Notify.offline] — deep-red toast when the server is unreachable
///   * [BusyOverlay]    — blocking spinner card shown during in-flight
///                        mutations (see [Notify.busyShow]/[Notify.busyHide])
///
/// All methods are safe to call before the first frame — they no-op when the
/// root [ScaffoldMessenger] is not mounted yet (e.g. during startup restore).
class Notify {
  Notify._();

  /// Attached as `MaterialApp.scaffoldMessengerKey` so toasts work from any
  /// screen without a BuildContext.
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  /// Current busy label; `null` = idle. Rendered by [BusyOverlay].
  static final ValueNotifier<String?> busy = ValueNotifier<String?>(null);
  static int _busyCount = 0;

  static void success(String msg) =>
      _show(msg, Icons.check_circle_rounded, const Color(0xFF16A34A));

  static void error(String msg) => _show(
      msg, Icons.error_rounded, const Color(0xFFDC2626),
      duration: const Duration(milliseconds: 5000));

  static void warning(String msg) => _show(
      msg, Icons.warning_amber_rounded, const Color(0xFFD97706));

  static void info(String msg) =>
      _show(msg, Icons.info_rounded, const Color(0xFF0A5C36));

  /// Server unreachable / no connection. Deeper red + longer duration so it
  /// is clearly distinguishable from a normal transaction error.
  static void offline(String msg) => _show(
      msg, Icons.wifi_off_rounded, const Color(0xFFB91C1C),
      duration: const Duration(milliseconds: 6000));

  /// Show the blocking busy overlay (ref-counted — safe for overlapping
  /// transactions; the overlay hides only when every caller released it).
  static void busyShow(String label) {
    _busyCount++;
    busy.value = label;
  }

  static void busyHide() {
    if (_busyCount > 0) _busyCount--;
    if (_busyCount == 0) busy.value = null;
  }

  static void _show(String msg, IconData icon, Color color,
      {Duration duration = const Duration(milliseconds: 3500)}) {
    final sm = key.currentState;
    if (sm == null) return;
    // Latest feedback wins — never queue stale toasts behind each other.
    sm.hideCurrentSnackBar();
    sm.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 21),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Root-level overlay rendered by `MaterialApp.builder` on top of the app.
/// Blocks input while a transaction is in flight.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Notify.busy,
      builder: (context, msg, _) {
        if (msg == null) return const SizedBox.shrink();
        return Container(
          color: Colors.black.withValues(alpha: 0.32),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      strokeWidth: 3.5, color: Brand.deep),
                ),
                const SizedBox(height: 16),
                Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Brand.dark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please wait…',
                  style: TextStyle(fontSize: 12.5, color: Brand.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
