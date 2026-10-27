import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'brand.dart';
import 'models.dart';
import 'notify.dart';
import 'screens/requirements_sections.dart';

/// White top header matching the original CSUCC dashboard design:
/// seal + institution (left), SMARTTRACK brand + tagline (center),
/// avatar/name/role + actions (right).
class BrandedHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandedHeader({super.key, this.title, this.actions = const []});
  final String? title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(66);

  String get _initials {
    final name = Session.instance.fullName ?? '';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final role = Session.instance.isAdmin ? 'OIGE' : 'Faculty';
    final name = Session.instance.fullName ?? 'SmartTrack User';
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Image.asset(Brand.seal, width: 42, height: 42),
          const SizedBox(width: 12),
          const Flexible(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARAGA STATE UNIVERSITY \u2013 CABADBARAN CAMPUS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Brand.deep,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Office of Internationalization and Global Engagement (OIGE)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B6B5D),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Flexible(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'SMART',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          letterSpacing: 0.5,
                          color: Brand.deep,
                        ),
                      ),
                      TextSpan(
                        text: 'TRACK',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          letterSpacing: 0.5,
                          color: Brand.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'AI-Based International Travel Monitoring System',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10, color: Brand.textMuted, height: 1.2),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(width: 1, height: 26, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: Brand.deep,
            child: Text(
              _initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Brand.textPrimary),
                ),
                Text(
                  role,
                  style: const TextStyle(
                      fontSize: 11, color: Brand.textMuted, height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ...actions,
        ],
      ),
    );
  }
}

/// Pastel stat card matching the legacy `.stat-card` design:
/// icon chip on top, muted label, big dark value, optional trend line.
class StatCard extends StatelessWidget {
  const StatCard(
      {super.key,
      required this.label,
      required this.value,
      required this.color,
      required this.icon,
      this.sub,
      this.subColor});
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? sub;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.3)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.1)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: subColor ?? Brand.active)),
          ],
        ],
      ),
    );
  }
}

Color statusColor(String? s) {
  switch (s) {
    case 'Completed':
    case 'Done':
    case 'Ready':
    case 'Verified':
    case 'Approved':
    case 'Fully Compliant':
    case 'Waived':
      return const Color(0xFF059669);
    case 'Cancelled':
    case 'High':
    case 'Rejected':
    case 'Incomplete':
    case 'Not Compliant':
    case 'Not Complied':
    case 'Needs Action':
    case 'Resubmission Required':
      return const Color(0xFFDC2626);
    case 'Ongoing':
    case 'For Implementation':
    case 'Preparing':
    case 'Medium':
    case 'Under Review':
    case 'Under Verification':
    case 'Pending Requirements':
    case 'Draft':
      return const Color(0xFFF59E0B);
    case 'Submitted':
    case 'Partially Compliant':
      return const Color(0xFF2563EB);
    case 'Not Submitted':
    case 'Not Started':
      return const Color(0xFF64748B);
    default:
      return const Color(0xFF64748B);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

/// Reusable background wrapper: bg.png (map + plane deco) behind [child].
/// Used across admin & faculty pages for a consistent branded canvas.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Brand.bg, fit: BoxFit.cover),
        child,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
}

/// Show an API failure as a global red toast (the transaction layer already
/// surfaced connection/offline failures, so those are skipped here to avoid
/// showing the same problem twice). Kept with the same signature so the ~60
/// existing call sites keep working unchanged.
Future<void> showApiError(BuildContext context, Object e) async {
  if (e is ApiException) {
    if (e.status == 0) {
      // Connection failure: show it unless ApiClient already did.
      if (!e.notified) Notify.offline(e.message);
      return;
    }
    Notify.error(_friendlyDetail(e.message));
    return;
  }
  Notify.error(e.toString());
}

/// Backend errors shaped `{message, missing:[…]}` display their human
/// message instead of the raw JSON payload.
String _friendlyDetail(String raw) {
  if (raw.startsWith('{') || raw.startsWith('[')) {
    try {
      final d = jsonDecode(raw);
      if (d is Map && d['message'] is String) return d['message'] as String;
    } catch (_) {}
  }
  return raw;
}

Future<bool> confirmAction(BuildContext context, String title, String message,
    {String confirmLabel = 'Confirm'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}

/// Admin dialog to advance a travel's workflow status (with optional remarks).
Future<void> showWorkflowDialog(BuildContext context, Travel travel,
    VoidCallback onChanged) async {
  final current = travel.workflowStatus ?? 'Submitted';
  final nextOptions = kWorkflowTransitions[current] ?? const <String>[];
  if (nextOptions.isEmpty) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Workflow'),
        content: Text("'$current' is a terminal status — no further changes."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
    return;
  }
  final selected = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Move "${travel.eventTitle}" from "$current" to…',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          for (final next in nextOptions)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(next),
              onTap: () => Navigator.pop(context, next),
            ),
        ],
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  final remarksCtrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Set status: $selected'),
      content: TextField(
        controller: remarksCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
            labelText: 'Remarks (optional)', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update')),
      ],
    ),
  );
  if (confirmed != true) return;
    try {
      await ApiClient.instance.patch('/travels/${travel.travelId}/workflow', {
        'workflow_status': selected,
        if (remarksCtrl.text.trim().isNotEmpty) 'remarks': remarksCtrl.text.trim(),
      }, okMsg: 'Workflow updated: $selected');
      onChanged();
  } catch (e) {
    // The pre-travel gate returns {message, missing:[…]} — show it nicely.
    final missing = missingListFromApiError(e);
    if (missing != null && context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(selected == 'Approved'
              ? 'Cannot approve yet'
              : 'Pre-Travel requirements incomplete'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text('Upload these documents first:'),
                const SizedBox(height: 8),
                for (final m in missing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(m, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
    } else if (context.mounted) {
      await showApiError(context, e);
    }
  }
}

/// Parse the `{message, missing:[…]}` 422 detail the requirements gate returns.
List<String>? missingListFromApiError(Object e) {
  if (e is! ApiException) return null;
  try {
    final decoded = jsonDecode(e.message);
    if (decoded is Map && decoded['missing'] is List) {
      return (decoded['missing'] as List).map((x) => '$x').toList();
    }
  } catch (_) {}
  return null;
}

String timeAgo(String? ts) {
  if (ts == null || ts.isEmpty) return '';
  var s = ts;
  final hasTz = RegExp(r'Z$|[+-]\d{2}:?\d{2}$').hasMatch(s);
  if (!hasTz) s = '${s}Z';
  final d = DateTime.tryParse(s)?.toLocal();
  if (d == null) return ts.length >= 10 ? ts.substring(0, 10) : ts;
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Panel card with a heading — mirrors the HTML `.panel-card` sections.
class SectionCard extends StatelessWidget {
  const SectionCard(
      {super.key,
      required this.title,
      required this.child,
      this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Simple horizontal bar chart — no external chart dependency.
class MiniBars extends StatelessWidget {
  const MiniBars(
      {super.key,
      required this.data,
      this.title,
      this.color = const Color(0xFF1D4ED8),
      this.emptyText = 'No data yet.'});
  final Map<String, int> data;
  final String? title;
  final Color color;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV =
        entries.isEmpty ? 1 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
        ],
        if (entries.isEmpty)
          Text(emptyText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
        else
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxV == 0 ? 0 : e.value / maxV,
                          minHeight: 10,
                          backgroundColor: color.withValues(alpha: 0.10),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 34,
                      child: Text('${e.value}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

/// Grid of "More" section shortcuts used at the end of the navigation.
class MoreItem {
  const MoreItem(this.index, this.label, this.icon);
  final int index;
  final String label;
  final IconData icon;
}

class MoreGrid extends StatelessWidget {
  const MoreGrid(
      {super.key, required this.items, required this.onSelect, this.title = 'More'});
  final List<MoreItem> items;
  final void Function(int) onSelect;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: items
              .map((it) => Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelect(it.index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(it.icon, color: const Color(0xFF1D4ED8)),
                          const SizedBox(height: 8),
                          Text(it.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// AppBar notification bell with unread badge and dropdown panel.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final c = await ApiClient.instance.get('/notifications/unread/count');
      final n = (c is Map ? c['unread_count'] : 0) ?? 0;
      if (mounted) setState(() => _unread = n as int);
    } catch (_) {}
  }

  Future<void> _open() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NotificationPanel(onChanged: null),
    );
    _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: _open,
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text('$_unread', style: const TextStyle(fontSize: 10)),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _NotificationPanel extends StatefulWidget {
  const _NotificationPanel({required this.onChanged});
  final VoidCallback? onChanged;

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  List<NotifItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/notifications/?limit=12');
      _items = (data as List)
          .map((e) => NotifItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(NotifItem n) async {
    if (n.isRead) return;
    try {
      await ApiClient.instance
          .patch('/notifications/${n.notificationId}/read', {});
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _markAll() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all', {});
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16))),
                TextButton(onPressed: _markAll, child: const Text('Mark all read')),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()))
            else if (_items.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: Text('No notifications yet.',
                          style: TextStyle(color: Colors.grey))))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = _items[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _markRead(n),
                      leading: Icon(
                        n.isRead
                            ? Icons.mail_outline
                            : Icons.mark_email_unread_outlined,
                        color: n.isRead ? Colors.grey : const Color(0xFF1D4ED8),
                        size: 20,
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w700)),
                      subtitle: Text(
                        '${n.message.length > 90 ? '${n.message.substring(0, 90)}…' : n.message}\n${timeAgo(n.createdAt)}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// One navigation entry of the legacy-style sidebar.
class SidebarItem {
  const SidebarItem(this.index, this.label, this.icon);
  final int index;
  final String label;
  final IconData icon;
}

/// Legacy CSUCC sidebar: 220px dark-green gradient column, monochrome
/// outline icons, emerald pill active state, logout footer + portal tag.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onSelected,
    required this.portalTag,
    required this.onLogout,
  });

  final List<SidebarItem> items;
  final int activeIndex;
  final ValueChanged<SidebarItem> onSelected;
  final String portalTag;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF064531), Color(0xFF043626)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -70,
            bottom: 40,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x1A10B981),
                  Color(0x0010B981),
                ]),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                    children: [
                      for (final it in items)
                        _SidebarTile(
                          item: it,
                          active: it.index == activeIndex,
                          onTap: () => onSelected(it),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          height: 1, color: Colors.white.withValues(alpha: 0.08)),
                      const SizedBox(height: 4),
                      _SidebarTile(
                        item: const SidebarItem(-1, 'Log Out', Icons.logout),
                        active: false,
                        danger: true,
                        onTap: onLogout,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Brand.active.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Brand.active.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          portalTag,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6EE7B7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  final SidebarItem item;
  final bool active;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = active ? const Color(0xFF064531) : const Color(0xFFB5D5C8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          hoverColor: danger
              ? const Color(0x26EF4444)
              : Colors.white.withValues(alpha: 0.08),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: active ? Brand.active : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? const [
                      BoxShadow(
                          color: Color(0x5910B981),
                          blurRadius: 10,
                          offset: Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard hero card: greeting + name + tagline + feature pills over a
/// soft blue/green gradient with the campus photo faded in on the right.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.name,
    required this.tagline,
    required this.subtext,
    required this.pills,
  });

  final String name;
  final String tagline;
  final String subtext;
  final List<(IconData, String)> pills;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6F6F9),
            Color(0xFFE0F2FE),
            Color(0xFFEBF8F4),
            Color(0xFFF0FDF4),
          ],
        ),
        border: Border.all(color: const Color(0xFFD0E7F7)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 340,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  Brand.campus,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.85),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFEBF8F4),
                          const Color(0xFFEBF8F4).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A2F),
                      height: 1.2),
                ),
                const SizedBox(height: 3),
                Text(
                  '$name!',
                  style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B4532),
                      height: 1.15,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  tagline,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D8353)),
                ),
                const SizedBox(height: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                    subtext,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in pills) _HeroPill(icon: p.$1, label: p.$2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: Brand.active.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF059669)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46)),
          ),
        ],
      ),
    );
  }
}

/// Date widget for the dashboard right column (legacy `.widget-datetime`).
class PortalDateCard extends StatelessWidget {
  const PortalDateCard({super.key, required this.portal});
  final String portal;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${_months[now.month - 1]} ${now.day}, ${now.year}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF0A5C36)),
              const SizedBox(width: 8),
              Text(date,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 6),
          Text(portal,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

/// Full-width pastel action button (legacy faculty Quick Actions).
class TintedActionButton extends StatelessWidget {
  const TintedActionButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap,
      required this.tint});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.10),
            border: Border.all(color: tint.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: tint)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==================== REQUIREMENTS COMPLIANCE REPORT CARD ====================
/// Post-Travel requirements compliance summary + per-travel rows. Expanding a
/// row shows the official HR&OIGE document (letterhead + AI check + upload) —
/// the faculty's post-travel workspace, reflected system-wide for the admin.
/// Shared: admin Reports tab (read-only) and faculty Reports tab (editable).
class RequirementsReportCard extends StatefulWidget {
  const RequirementsReportCard(
      {super.key, required this.report, this.onRefresh, this.editable = false});

  final ReqReport report;
  final Future<void> Function()? onRefresh;

  /// true = faculty (upload/view actions + prefilled Name fields).
  final bool editable;

  @override
  State<RequirementsReportCard> createState() => _RequirementsReportCardState();
}

class _RequirementsReportCardState extends State<RequirementsReportCard> {
  String _filter = 'All';

  // Per-travel official document state (lazily loaded when a row expands).
  final Map<int, ReqStatus> _statuses = {};
  final Map<int, ReqAiCheck> _ais = {};
  final Set<int> _loadingDoc = {};
  final Set<int> _aiBusy = {};
  Profile? _profile;
  bool _profileLoaded = false;

  ReqReport get rep => widget.report;

  void _export(String fmt) {
    final url = ApiClient.instance.authedFileUrl(
        '/requirements/report/export?format=$fmt&applies_to=Faculty'
        '&phase=Post-Travel');
    launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
  }

  Future<void> _open(String path) async {
    final url = ApiClient.instance.authedFileUrl(path);
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      await showApiError(context, 'Could not open the file');
    }
  }

  /// Loads a travel's checklist (+ auto AI check) the first time its row opens.
  Future<void> _ensureDoc(int tid) async {
    if (_statuses.containsKey(tid) || _loadingDoc.contains(tid)) return;
    setState(() => _loadingDoc.add(tid));
    if (widget.editable && !_profileLoaded) {
      _profileLoaded = true;
      try {
        _profile = Profile.fromJson(Map<String, dynamic>.from(
            await ApiClient.instance.get('/users/profile')));
      } catch (_) {
        _profile = null;
      }
    }
    await _loadStatus(tid);
    if (mounted) setState(() => _loadingDoc.remove(tid));
    await _runAi(tid); // auto — no button click
  }

  Future<void> _loadStatus(int tid) async {
    try {
      final r = await ApiClient.instance.get('/requirements/travel/$tid');
      final st = ReqStatus.fromJson(Map<String, dynamic>.from(r as Map));
      if (mounted) setState(() => _statuses[tid] = st);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _runAi(int tid) async {
    if (_aiBusy.contains(tid)) return;
    setState(() => _aiBusy.add(tid));
    try {
      final r = await ApiClient.instance.get('/requirements/ai-check/$tid');
      final ai = ReqAiCheck.fromJson(Map<String, dynamic>.from(r as Map));
      if (mounted) setState(() => _ais[tid] = ai);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _aiBusy.remove(tid));
    }
  }

  Future<void> _upload(int tid, ReqItem item) async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      if (mounted) await showApiError(context, 'Could not read the selected file');
      return;
    }
    try {
      final query =
          'travel_id=$tid&doc_type=${Uri.encodeComponent(item.name)}'
          '&doc_category=${Uri.encodeComponent(item.phase)}';
      await ApiClient.instance.upload(
        '/documents/upload?$query',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: '${item.name} uploaded — awaiting verification',
      );
      await _loadStatus(tid);
      await _runAi(tid); // auto report after upload
      if (mounted && _ais[tid] != null) {
        final sm = _ais[tid]!.summary;
        Notify.info('Auto report: ${sm.verdict} — '
            '${sm.passed} of ${sm.requiredTotal} required passed');
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  /// Official HR&OIGE document for an expanded report row.
  Widget _docSection(int tid) {
    if (_loadingDoc.contains(tid)) {
      return Row(
        children: [
          const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('Loading official requirements…',
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      );
    }
    final st = _statuses[tid];
    if (st == null) {
      return const Text('Could not load requirements for this travel.',
          style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)));
    }
    final post =
        st.items.where((i) => i.phase == 'Post-Travel').toList();
    return OfficialPostTravelDoc(
      items: post,
      readOnly: !widget.editable,
      travelSelected: true,
      profile: widget.editable ? _profile : null,
      onUpload: widget.editable ? (it) => _upload(tid, it) : null,
      onViewDoc: widget.editable
          ? (it) => _open('/documents/${it.documentId}/file')
          : null,
      onDownloadPdf: () =>
          _open('/requirements/templates/faculty_post_checklist'),
      onOpenTemplate: widget.editable
          ? (key) => _open('/requirements/templates/$key')
          : null,
      aiCheck: _ais[tid],
      aiRunning: _aiBusy.contains(tid),
      onRunAiCheck: () => _runAi(tid),
    );
  }

  Widget _statBox(String label, String value, Color color) => Container(
        width: 108,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );

  Widget _reportRow(ReqReportRow r) {
    final pctColor = r.complete
        ? const Color(0xFF059669)
        : r.percent > 0
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onExpansionChanged: (open) {
          if (open) _ensureDoc(r.travelId);
        },
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.facultyName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(
                      '${r.college ?? '—'} · ${r.eventTitle}'
                      '${r.startDate != null ? ' · ${r.startDate}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${r.percent}%',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: pctColor)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                        value: r.percent / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(pctColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(label: r.complete ? 'Complete' : 'Incomplete'),
          ],
        ),
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _docSection(r.travelId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = rep.rows
        .where((r) =>
            _filter == 'All' ||
            (_filter == 'Complete' && r.complete) ||
            (_filter == 'Incomplete' && !r.complete))
        .toList();
    return SectionCard(
      title: 'Post-Travel Requirements Compliance',
      trailing: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          OutlinedButton.icon(
            onPressed: () => _export('csv'),
            icon: const Icon(Icons.download_outlined, size: 15),
            label: const Text('CSV', style: TextStyle(fontSize: 11.5)),
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10)),
          ),
          OutlinedButton.icon(
            onPressed: () => _export('html'),
            icon: const Icon(Icons.print_outlined, size: 15),
            label: const Text('Print / PDF', style: TextStyle(fontSize: 11.5)),
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statBox('Total Travels', '${rep.total}', const Color(0xFF2563EB)),
              _statBox('Complete', '${rep.complete}', const Color(0xFF059669)),
              _statBox('Incomplete', '${rep.incomplete}', const Color(0xFFDC2626)),
              _statBox(
                  'Avg Complete', '${rep.avgPercent}%', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: ['All', 'Complete', 'Incomplete'].map((f) {
              final sel = _filter == f;
              return ChoiceChip(
                label: Text(f,
                    style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
                selected: sel,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: const Color(0xFF0D8353),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No travels match this filter.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            ),
          for (final r in rows) _reportRow(r),
          if (widget.onRefresh != null && rows.isEmpty)
            TextButton(onPressed: widget.onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

/// Official Pre-Travel document embedded in a travel-records row
/// (faculty Travel Records = editable with upload; admin Global Travel Data =
/// read-only). Loads the checklist + auto-runs the heuristic AI check the
/// first time the row expands — no button click needed.
class PreTravelDocPanel extends StatefulWidget {
  const PreTravelDocPanel(
      {super.key,
      required this.travelId,
      this.editable = false,
      this.onAiCheck});

  final int travelId;
  final bool editable;

  /// Called after every AI check with the fresh result — lets a parent
  /// (e.g. Add Travel step 2) enable "Submit for Approval" when complete.
  final void Function(ReqAiCheck ai)? onAiCheck;

  @override
  State<PreTravelDocPanel> createState() => _PreTravelDocPanelState();
}

class _PreTravelDocPanelState extends State<PreTravelDocPanel> {
  ReqStatus? _status;
  ReqAiCheck? _ai;
  bool _loading = true;
  bool _aiBusy = false;
  String? _error;
  Profile? _profile;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.editable && !_profileLoaded) {
      _profileLoaded = true;
      try {
        _profile = Profile.fromJson(Map<String, dynamic>.from(
            await ApiClient.instance.get('/users/profile')));
      } catch (_) {
        _profile = null;
      }
    }
    await _load();
    await _runAi(); // auto — no button click
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance
          .get('/requirements/travel/${widget.travelId}');
      final st = ReqStatus.fromJson(Map<String, dynamic>.from(r as Map));
      if (mounted) setState(() => _status = st);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAi() async {
    if (_aiBusy) return;
    setState(() => _aiBusy = true);
    try {
      final r = await ApiClient.instance
          .get('/requirements/ai-check/${widget.travelId}?phase=Pre-Travel');
      final ai = ReqAiCheck.fromJson(Map<String, dynamic>.from(r as Map));
      if (mounted) setState(() => _ai = ai);
      widget.onAiCheck?.call(ai);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _open(String path) async {
    final url = ApiClient.instance.authedFileUrl(path);
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    if (!ok && mounted) await showApiError(context, 'Could not open the file');
  }

  Future<void> _upload(ReqItem item) async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      if (mounted) {
        await showApiError(context, 'Could not read the selected file');
      }
      return;
    }
    try {
      final query =
          'travel_id=${widget.travelId}&doc_type=${Uri.encodeComponent(item.name)}'
          '&doc_category=${Uri.encodeComponent(item.phase)}';
      await ApiClient.instance.upload(
        '/documents/upload?$query',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: '${item.name} uploaded — awaiting verification',
      );
      await _load();
      await _runAi(); // auto report after upload
      if (mounted && _ai != null) {
        final sm = _ai!.summary;
        Notify.info('Auto report: ${sm.verdict} — '
            '${sm.passed} of ${sm.requiredTotal} required passed');
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Row(
        children: [
          SizedBox(
              width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Loading pre-travel requirements…',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      );
    }
    if (_error != null) {
      return Text('Could not load pre-travel requirements: $_error',
          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)));
    }
    final st = _status;
    if (st == null) {
      return const Text('Could not load requirements for this travel.',
          style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)));
    }
    final pre = st.items.where((i) => i.phase == 'Pre-Travel').toList();
    if (pre.isEmpty) {
      return const Text('No pre-travel requirements for this participant type.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)));
    }
    return OfficialPostTravelDoc(
      items: pre,
      phase: 'Pre-Travel',
      readOnly: !widget.editable,
      travelSelected: true,
      profile: widget.editable ? _profile : null,
      onUpload: widget.editable ? _upload : null,
      onViewDoc: widget.editable
          ? (it) => _open('/documents/${it.documentId}/file')
          : null,
      onDownloadPdf: () => _open('/requirements/templates/faculty_pre_checklist'),
      onOpenTemplate: widget.editable
          ? (key) => _open('/requirements/templates/$key')
          : null,
      aiCheck: _ai,
      aiRunning: _aiBusy,
      onRunAiCheck: _runAi,
    );
  }
}
