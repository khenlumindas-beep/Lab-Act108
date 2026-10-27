import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../brand.dart';
import '../models.dart';
import '../notify.dart';
import '../realtime.dart';
import '../widgets.dart';

const _templateLabels = {
  'faculty_pre_checklist': 'Pre-Foreign Travel Checklist (PDF)',
  'faculty_post_checklist': 'Post-Foreign Travel Checklist (PDF)',
  'student_post_checklist': 'Student Post-Travel Checklist (PDF)',
  'reentry_plan': 'CSU Re-Entry Action Plan Template (PDF)',
};

// Official Faculty Post-Travel checklist document (verbatim from the HR&OIGE PDF).
const _postDocTitle = 'POST-FOREIGN TRAVEL REQUIREMENTS';
const _postDocIntro =
    'For the Office of Internationalization and Global Engagement (OIGE) to '
    'complete its documentation and monitoring requirements, kindly submit the '
    'following pertinent documents:';

// Official Faculty Pre-Foreign Travel checklist (verbatim from the HR&OIGE PDF).
const _preDocTitle =
    'FACULTY CHECKLIST OF REQUIREMENTS FOR FOREIGN TRAVEL REQUEST '
    '(HRM & OIGE REQUIREMENTS)';
const _preDocSubtitle = 'Pre-Foreign Travel';

/// The official HR&OIGE letterhead (CSU-Cabadbaran + CHED/IAB logos) image.
const _docFont = 'Outfit';

Color _reqStatusColor(String s) => statusColor(s);

IconData _reqStatusIcon(String s) {
  switch (s) {
    case 'Verified':
      return Icons.check_circle;
    case 'Submitted':
    case 'Under Verification':
      return Icons.schedule;
    case 'Rejected':
    case 'Resubmission Required':
      return Icons.cancel;
    default:
      return Icons.radio_button_unchecked;
  }
}

/// Checklist checkbox: live status for faculty, blank box for the admin master.
class _DocCheck extends StatelessWidget {
  const _DocCheck({this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    var border = const Color(0xFF94A3B8);
    var bg = Colors.white;
    Widget inner = const SizedBox.shrink();
    switch (status) {
      case 'Verified':
        border = const Color(0xFF059669);
        bg = const Color(0xFFECFDF5);
        inner = const Icon(Icons.check, size: 14, color: Color(0xFF059669));
        break;
      case 'Submitted':
      case 'Under Verification':
        border = const Color(0xFFF59E0B);
        bg = const Color(0xFFFFFBEB);
        inner = const Icon(Icons.schedule, size: 13, color: Color(0xFFF59E0B));
        break;
      case 'Rejected':
      case 'Resubmission Required':
      case 'Incomplete':
        border = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        inner = const Icon(Icons.close, size: 14, color: Color(0xFFDC2626));
        break;
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: inner,
    );
  }
}

/// Official Faculty Post-Travel checklist rendered in the HR&OIGE PDF format:
/// CSU seal header, Name/Designation/Office fields, verbatim numbered items
/// (1-23 with CHED IAS a-j), per-item checkbox + status actions, PDF download.
class OfficialPostTravelDoc extends StatelessWidget {
  const OfficialPostTravelDoc({
    super.key,
    required this.items,
    required this.readOnly,
    this.phase = 'Post-Travel',
    this.profile,
    this.onUpload,
    this.onViewDoc,
    this.onDownloadPdf,
    this.onOpenTemplate,
    this.aiCheck,
    this.aiRunning = false,
    this.onRunAiCheck,
    this.travelSelected = false,
  });

  /// All requirement items for one travel (parents + children of the phase).
  final List<ReqItem> items;

  /// Checklist phase — 'Pre-Travel' renders the official Pre-Foreign Travel
  /// form (title + ANNEX A + condition lines), 'Post-Travel' the post form.
  final String phase;

  /// true = admin master (blank form, Required/Optional chips, no actions).
  final bool readOnly;
  final Profile? profile;
  final Future<void> Function(ReqItem)? onUpload;
  final void Function(ReqItem)? onViewDoc;
  final VoidCallback? onDownloadPdf;
  final void Function(String templateKey)? onOpenTemplate;

  /// Heuristic AI check result (null = not run yet). When present the doc
  /// shows a verdict banner and per-item AI badges.
  final ReqAiCheck? aiCheck;
  final bool aiRunning;
  final VoidCallback? onRunAiCheck;

  /// admin master with a travel picked → show that travel's live statuses.
  final bool travelSelected;

  Widget _field(String label, String? value) {
    final empty = value == null || value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Brand.textPrimary,
                  fontFamily: _docFont)),
          Expanded(
            child: Text(
              empty ? '________________________________' : value,
              style: TextStyle(
                  fontSize: 12,
                  color: empty ? Brand.textMuted : Brand.textPrimary,
                  fontFamily: _docFont),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(ReqItem it) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onUpload != null)
          IconButton(
            tooltip: 'Upload scan',
            onPressed: () => onUpload!(it),
            icon: const Icon(Icons.cloud_upload_outlined, size: 19),
            color: const Color(0xFF0D8353),
            visualDensity: VisualDensity.compact,
          ),
        if (onViewDoc != null && it.documentId != null)
          IconButton(
            tooltip: 'View uploaded file',
            onPressed: () => onViewDoc!(it),
            icon: const Icon(Icons.visibility_outlined, size: 19),
            color: const Color(0xFF2563EB),
            visualDensity: VisualDensity.compact,
          ),
        if (it.hasTemplate && it.templateKey != null && onOpenTemplate != null)
          IconButton(
            tooltip: 'Download template',
            onPressed: () => onOpenTemplate!(it.templateKey!),
            icon: const Icon(Icons.description_outlined, size: 19),
            color: const Color(0xFF7C3AED),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  /// AI verdict badge for a row (ai_ok / needs_review only — the new signal;
  /// verified/missing already read from the checkbox + status chip).
  Widget? _aiBadge(ReqItem it) {
    final ai = aiCheck?.byRequirementId[it.requirementId];
    if (ai == null) return null;
    final Color c;
    final String label;
    switch (ai.verdict) {
      case 'ai_ok':
        c = const Color(0xFF059669);
        label = 'AI: OK';
      case 'needs_review':
        c = const Color(0xFFF59E0B);
        label = 'AI: Check';
      case 'missing':
      case 'optional_missing':
        c = const Color(0xFF64748B);
        label = 'AI: Not submitted';
      case 'rejected':
        c = const Color(0xFFDC2626);
        label = 'AI: Rejected';
      default:
        return null;
    }
    final tip = ai.reasons.isNotEmpty ? ai.reasons.join('\n') : ai.notes.join('\n');
    return Tooltip(
      message: tip.isEmpty ? label : tip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withValues(alpha: 0.45)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: c)),
      ),
    );
  }

  /// AI check button (before first run) / verdict banner (after run).
  Widget _aiPanel() {
    if (aiCheck == null) {
      return Row(
        children: [
          OutlinedButton.icon(
            onPressed: aiRunning ? null : onRunAiCheck,
            icon: const Icon(Icons.smart_toy_outlined, size: 16),
            label: Text(
                aiRunning ? 'AI checking…' : 'Run AI Check (complete & correct?)',
                style: const TextStyle(fontSize: 12)),
          ),
          if (aiRunning) ...[
            const SizedBox(width: 10),
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ],
      );
    }
    final s = aiCheck!.summary;
    final Color vc = switch (s.verdict) {
      'COMPLETE' => const Color(0xFF059669),
      'NEEDS REVIEW' => const Color(0xFFF59E0B),
      _ => const Color(0xFFDC2626),
    };
    final IconData vi = switch (s.verdict) {
      'COMPLETE' => Icons.check_circle,
      'NEEDS REVIEW' => Icons.warning_amber,
      _ => Icons.cancel,
    };
    final problems = aiCheck!.items
        .where((i) =>
            (i.isRequired &&
                (i.verdict == 'missing' || i.verdict == 'rejected')) ||
            i.verdict == 'needs_review')
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vc.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: vc.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(vi, size: 18, color: vc),
              const SizedBox(width: 6),
              Expanded(
                child: Text('AI Check: ${s.verdict}',
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800, color: vc)),
              ),
              if (onRunAiCheck != null)
                TextButton(
                  onPressed: aiRunning ? null : onRunAiCheck,
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  child: Text(aiRunning ? 'Checking…' : 'Re-run',
                      style: const TextStyle(fontSize: 11.5)),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${s.passed} of ${s.requiredTotal} required passed (${s.percent}%)'
            ' · Verified ${s.verified} · AI OK ${s.aiOk}'
            ' · Review ${s.needsReview} · Missing ${s.missing}'
            '${s.rejected > 0 ? ' · Rejected ${s.rejected}' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          if (problems.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in problems.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '${p.verdict == 'needs_review' ? '⚠' : '🔴'} ',
                      style: const TextStyle(fontSize: 12)),
                  TextSpan(
                      text: p.displayText,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Brand.textPrimary)),
                  if (p.reasons.isNotEmpty)
                    TextSpan(
                        text: ' — ${p.reasons.first}',
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFFB45309))),
                ])),
              ),
            if (problems.length > 10)
              Text('+ ${problems.length - 10} more…',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          if (s.verdict == 'COMPLETE') ...[
            const SizedBox(height: 6),
            const Text(
                '✔ All required requirements passed the AI check.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF059669))),
          ],
          const SizedBox(height: 6),
          const Text(
              'Heuristic check only (file name, file type, size, phase/category) — '
              'no OCR; final verification remains with OIGE.',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  /// One checklist line. Sub-items (CHED IAS a-j) keep the ☐ box before the
  /// letter like the official form; parent rows are plain numbered text.
  Widget _row(ReqItem it, String leading,
      {double indent = 0, bool child = false}) {
    final st = it.status;
    final text = (it.displayText != null && it.displayText!.isNotEmpty)
        ? it.displayText!
        : it.name;
    final badge = _aiBadge(it);
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (child) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _DocCheck(
                  status: readOnly && !travelSelected ? null : st),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '$leading ',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Brand.textPrimary)),
                    TextSpan(
                        text: text,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Brand.textSecondary)),
                  ]),
                  style: const TextStyle(fontFamily: _docFont),
                ),
                if (phase == 'Pre-Travel' &&
                    !child &&
                    it.conditionText != null &&
                    it.conditionText!.trim().isNotEmpty)
                  Text(it.conditionText!.trim(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                          fontFamily: _docFont)),
                if (!readOnly && it.fileName != null)
                  Text('File: ${it.fileName}',
                      style: const TextStyle(
                          fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (readOnly) ...[
            if (travelSelected) ...[
              StatusChip(label: st ?? 'Not Submitted'),
              const SizedBox(width: 4),
            ],
            StatusChip(label: it.isRequired ? 'Required' : 'Optional'),
          ] else ...[
            StatusChip(label: st ?? 'Not Submitted'),
            const SizedBox(width: 4),
            _actions(it),
          ],
          if (badge != null) ...[
            const SizedBox(width: 4),
            badge,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parents = items.where((i) => i.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final childrenOf = <int, List<ReqItem>>{};
    for (final i in items) {
      if (i.parentId != null) {
        childrenOf.putIfAbsent(i.parentId!, () => []).add(i);
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E5DC)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(Brand.header, height: 60, fit: BoxFit.contain),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          _field('Name',
              readOnly ? null : profile?.fullName),
          _field('Designation',
              readOnly ? null : (profile?.designation ?? profile?.academicRank)),
          _field('Office', readOnly ? null : profile?.collegeName),
          const SizedBox(height: 10),
          if (phase == 'Pre-Travel')
            Center(
              child: Column(
                children: [
                  Text(_preDocTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Color(0xFF0D8353),
                          fontFamily: _docFont)),
                  const SizedBox(height: 2),
                  Text(_preDocSubtitle,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Brand.textSecondary,
                          fontFamily: _docFont)),
                ],
              ),
            )
          else
            Center(
              child: Text(_postDocTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Color(0xFF0D8353),
                      fontFamily: _docFont)),
            ),
          const SizedBox(height: 8),
          if (phase != 'Pre-Travel') ...[
            Text(_postDocIntro,
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Brand.textSecondary,
                    fontFamily: _docFont)),
            const SizedBox(height: 10),
          ],
          if (onDownloadPdf != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onDownloadPdf,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Download Official PDF (with logo)',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          if (onRunAiCheck != null || aiCheck != null) ...[
            const SizedBox(height: 8),
            _aiPanel(),
          ],
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 6),
          if (phase == 'Pre-Travel') ...[
            Center(
              child: Text('ANNEX A',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Brand.textPrimary,
                      fontFamily: _docFont)),
            ),
            const SizedBox(height: 6),
          ],
          for (var idx = 0; idx < parents.length; idx++) ...[
            _row(parents[idx], '${idx + 1}.'),
            for (var c = 0;
                c < (childrenOf[parents[idx].requirementId] ?? const <ReqItem>[]).length;
                c++)
              _row(childrenOf[parents[idx].requirementId]![c],
                  '${String.fromCharCode(97 + c)}.',
                  indent: 14, child: true),
          ],
        ],
      ),
    );
  }
}

/// ==================== FACULTY: REQUIREMENTS CHECKLIST ====================
class RequirementsTab extends StatefulWidget {
  const RequirementsTab({super.key});

  @override
  State<RequirementsTab> createState() => _RequirementsTabState();
}

class _RequirementsTabState extends State<RequirementsTab> with RealtimeAware {
  List<Travel> _travels = [];
  int? _sel;
  ReqStatus? _status;
  ReqAiCheck? _aiCheck;
  bool _aiBusy = false;
  Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  Set<String> get realtimeTopics => const {'documents', 'travels'};

  @override
  Future<void> onRealtimeRefresh() => _loadTravels(silent: true);

  @override
  void initState() {
    super.initState();
    _loadTravels();
  }

  Future<void> _loadTravels({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final r = await ApiClient.instance.get('/travels/');
      _travels = (r as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      try {
        final p = Map<String, dynamic>.from(
            await ApiClient.instance.get('/users/profile'));
        _profile = Profile.fromJson(p);
      } catch (_) {
        _profile = null;
      }
      if (_travels.isEmpty) {
        _status = null;
      } else {
        _sel ??= _travels.first.travelId;
        await _loadStatus();
        await _runAiCheck(); // auto-run — no button click needed
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStatus() async {
    if (_sel == null) return;
    try {
      final r =
          await ApiClient.instance.get('/requirements/travel/$_sel');
      _status =
          ReqStatus.fromJson(Map<String, dynamic>.from(r as Map));
    } catch (e) {
      _error = e.toString();
      _status = null;
    } finally {
      if (mounted) setState(() {});
    }
  }

  String _travelLabel(Travel t) => '${t.eventTitle} (${t.startDate})';

  Future<void> _runAiCheck() async {
    if (_sel == null || _aiBusy) return;
    setState(() => _aiBusy = true);
    try {
      final r = await ApiClient.instance.get('/requirements/ai-check/$_sel');
      _aiCheck = ReqAiCheck.fromJson(Map<String, dynamic>.from(r as Map));
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _open(String path) async {
    final url = ApiClient.instance.authedFileUrl(path);
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      await showApiError(context, 'Could not open the file');
    }
  }

  Future<void> _upload(ReqItem item) async {
    if (_sel == null) return;
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
          'travel_id=$_sel&doc_type=${Uri.encodeComponent(item.name)}'
          '&doc_category=${Uri.encodeComponent(item.phase)}';
      await ApiClient.instance.upload(
        '/documents/upload?$query',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: '${item.name} uploaded — awaiting verification',
      );
      await _loadStatus();
      // auto report — re-run the AI check so the summary reflects the upload
      await _runAiCheck();
      if (mounted && _aiCheck != null) {
        final sm = _aiCheck!.summary;
        Notify.info(
            'Auto report: ${sm.verdict} — ${sm.passed} of ${sm.requiredTotal} required passed');
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Widget _templateRow() {
    final keys = _status?.checklistFiles ?? const <String>[];
    if (keys.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in keys)
          if (_templateLabels.containsKey(k))
            OutlinedButton.icon(
              onPressed: () => _open('/requirements/templates/$k'),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(_templateLabels[k]!,
                  style: const TextStyle(fontSize: 12)),
            ),
      ],
    );
  }

  Widget _summaryCard(ReqStatus s) {
    final pct = s.percent / 100.0;
    final color = s.complete
        ? const Color(0xFF059669)
        : s.percent >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);
    return SectionCard(
      title: 'Requirements Completeness',
      trailing: StatusChip(
          label: s.complete ? 'Complete' : 'Incomplete', color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${s.percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${s.verifiedRequired} of ${s.requiredTotal} required requirements verified'
            ' (${s.participantType})',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          _templateRow(),
        ],
      ),
    );
  }

  Widget _itemTile(ReqItem it, {bool child = false}) {
    final st = it.status ?? 'Not Submitted';
    return Padding(
      padding: EdgeInsets.only(left: child ? 22 : 0, bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: child ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_reqStatusIcon(st),
                size: 18, color: _reqStatusColor(st)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.name,
                      style: TextStyle(
                          fontSize: child ? 12.5 : 13,
                          fontWeight: FontWeight.w600)),
                  if (it.conditionText != null &&
                      it.conditionText!.isNotEmpty)
                    Text(it.conditionText!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  if (it.fileName != null)
                    Text('File: ${it.fileName}',
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
            StatusChip(label: st),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Upload scan',
              onPressed: () => _upload(it),
              icon: const Icon(Icons.cloud_upload_outlined, size: 19),
              color: const Color(0xFF0D8353),
              visualDensity: VisualDensity.compact,
            ),
            if (it.documentId != null)
              IconButton(
                tooltip: 'View uploaded file',
                onPressed: () => _open('/documents/${it.documentId}/file'),
                icon: const Icon(Icons.visibility_outlined, size: 19),
                color: const Color(0xFF2563EB),
                visualDensity: VisualDensity.compact,
              ),
            if (it.hasTemplate && it.templateKey != null)
              IconButton(
                tooltip: 'Download template',
                onPressed: () =>
                    _open('/requirements/templates/${it.templateKey}'),
                icon: const Icon(Icons.description_outlined, size: 19),
                color: const Color(0xFF7C3AED),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _phaseSection(ReqStatus s, String phase) {
    final all =
        s.items.where((i) => i.phase == phase).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (all.isEmpty) return const SizedBox.shrink();
    final parents = all.where((i) => i.parentId == null).toList();
    final childrenOf = <int, List<ReqItem>>{};
    for (final i in all) {
      if (i.parentId != null) {
        childrenOf.putIfAbsent(i.parentId!, () => []).add(i);
      }
    }
    return SectionCard(
      title: '$phase Requirements',
      trailing: Text('${parents.length} items',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in parents) ...[
            _itemTile(p),
            for (final c in (childrenOf[p.requirementId] ?? const <ReqItem>[]))
              _itemTile(c, child: true),
          ],
        ],
      ),
    );
  }

  /// Post-Travel rendered as the official HR&OIGE document (logo + numbering).
  Widget _postDocSection(ReqStatus s) {
    final post =
        s.items.where((i) => i.phase == 'Post-Travel').toList();
    if (post.isEmpty) return const SizedBox.shrink();
    final count = post.where((i) => i.parentId == null).length;
    return SectionCard(
      title: 'Post-Travel Requirements',
      trailing: Text('$count items',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      child: OfficialPostTravelDoc(
        items: post,
        readOnly: false,
        profile: _profile,
        onUpload: _upload,
        onViewDoc: (it) => _open('/documents/${it.documentId}/file'),
        onDownloadPdf: () => _open('/requirements/templates/faculty_post_checklist'),
        onOpenTemplate: (key) => _open('/requirements/templates/$key'),
        aiCheck: _aiCheck,
        aiRunning: _aiBusy,
        onRunAiCheck: _runAiCheck,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    if (_travels.isEmpty) {
      return const EmptyState(
          message: 'Create a travel record first to track requirements.');
    }
    final s = _status;
    return RefreshIndicator(
      onRefresh: () async {
        if (_sel == null) {
          await _loadTravels();
        } else {
          await _loadStatus();
          await _runAiCheck();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          SectionCard(
            title: 'Select Travel',
            child: DropdownButton<int>(
              isExpanded: true,
              value: _sel,
              items: [
                for (final t in _travels)
                  DropdownMenuItem(
                      value: t.travelId, child: Text(_travelLabel(t))),
              ],
              onChanged: (v) {
                setState(() {
                  _sel = v;
                  _aiCheck = null;
                });
                _loadStatus().then((_) => _runAiCheck());
              },
            ),
          ),
          if (s == null) const EmptyState(message: 'Loading checklist…'),
          if (s != null) ...[
            _summaryCard(s),
            _phaseSection(s, 'Pre-Travel'),
            _postDocSection(s),
          ],
        ],
      ),
    );
  }
}

/// ==================== ADMIN: OFFICIAL CHECKLISTS (read-only master) ====================
class AdminChecklistsTab extends StatefulWidget {
  const AdminChecklistsTab({super.key});

  @override
  State<AdminChecklistsTab> createState() => _AdminChecklistsTabState();
}

class _AdminChecklistsTabState extends State<AdminChecklistsTab> with RealtimeAware {
  List<ReqItem> _items = [];
  List<Travel> _travels = [];
  int? _postSel;
  ReqStatus? _postStatus;
  ReqAiCheck? _postAi;
  bool _postBusy = false;
  bool _loading = true;
  String? _error;

  @override
  Set<String> get realtimeTopics => const {'documents', 'travels'};

  @override
  Future<void> onRealtimeRefresh() => _load(silent: true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/requirements/'),
        ApiClient.instance.get('/travels/?limit=100'),
      ]);
      _items = (results[0] as List)
          .map((e) => ReqItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _travels = (results[1] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      // Keep the open travel's live checklist in sync too.
      if (silent && _postSel != null) {
        try {
          final r = await ApiClient.instance.get('/requirements/travel/$_postSel');
          _postStatus = ReqStatus.fromJson(Map<String, dynamic>.from(r as Map));
        } catch (_) {
          // keep the previous checklist on transient errors
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Master template (null) or a specific travel's live checklist + AI state.
  Future<void> _selectPostTravel(int? tid) async {
    setState(() {
      _postSel = tid;
      _postStatus = null;
      _postAi = null;
    });
    if (tid == null) return;
    try {
      final r = await ApiClient.instance.get('/requirements/travel/$tid');
      final st = ReqStatus.fromJson(Map<String, dynamic>.from(r as Map));
      if (mounted) setState(() => _postStatus = st);
      await _runPostAi(); // auto-run AI check when a travel is picked
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _runPostAi() async {
    if (_postSel == null || _postBusy) return;
    setState(() => _postBusy = true);
    try {
      final r =
          await ApiClient.instance.get('/requirements/ai-check/$_postSel');
      _postAi = ReqAiCheck.fromJson(Map<String, dynamic>.from(r as Map));
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _postBusy = false);
    }
  }

  Future<void> _open(String path) async {
    final url = ApiClient.instance.authedFileUrl(path);
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      await showApiError(context, 'Could not open the file');
    }
  }

  Widget _downloads() => SectionCard(
        title: 'Official Checklists & Templates (PDF)',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _templateLabels.entries)
              OutlinedButton.icon(
                onPressed: () => _open('/requirements/templates/${e.key}'),
                icon: const Icon(Icons.download_outlined, size: 16),
                label:
                    Text(e.value, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );

  Widget _group(String appliesTo, String phase) {
    final all = _items
        .where((i) => i.appliesTo == appliesTo && i.phase == phase)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (all.isEmpty) return const SizedBox.shrink();
    final parents = all.where((i) => i.parentId == null).toList();
    final childrenOf = <int, List<ReqItem>>{};
    for (final i in all) {
      if (i.parentId != null) {
        childrenOf.putIfAbsent(i.parentId!, () => []).add(i);
      }
    }
    final reqCount = parents.where((i) => i.isRequired).length;
    return SectionCard(
      title: '$appliesTo — $phase ($reqCount required of ${parents.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in parents) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        if (p.conditionText != null &&
                            p.conditionText!.isNotEmpty)
                          Text(p.conditionText!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  StatusChip(
                      label: p.isRequired ? 'Required' : 'Optional'),
                ],
              ),
            ),
            for (final c in (childrenOf[p.requirementId] ?? const <ReqItem>[]))
              Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(c.name,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF475569))),
                    ),
                    const Text('sub-item',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Faculty Post-Travel rendered as the official HR&OIGE document.
  /// Master template by default; pick a travel to see live statuses + AI check.
  Widget _adminPostDoc() {
    final master = _items
        .where((i) => i.appliesTo == 'Faculty' && i.phase == 'Post-Travel')
        .toList();
    if (master.isEmpty) return const SizedBox.shrink();
    final post = _postStatus?.items
            .where((i) => i.phase == 'Post-Travel')
            .toList() ??
        master;
    final parents = post.where((i) => i.parentId == null);
    final reqCount = parents.where((i) => i.isRequired).length;
    final travelLive = _postStatus != null;
    return SectionCard(
      title: 'Faculty — Post-Travel ($reqCount required of ${parents.length})',
      trailing: SizedBox(
        width: 280,
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _postSel,
          items: [
            const DropdownMenuItem<int?>(
                value: null, child: Text('Master template', style: TextStyle(fontSize: 12.5))),
            for (final t in _travels)
              DropdownMenuItem<int?>(
                value: t.travelId,
                child: Text('${t.eventTitle} (${t.startDate})',
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != _postSel) _selectPostTravel(v);
          },
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_postSel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(builder: (_) {
                final sel = _travels
                    .where((t) => t.travelId == _postSel)
                    .toList();
                if (sel.isEmpty) return const SizedBox.shrink();
                return SubmissionStatusChip(
                    status: sel.first.submissionStatus,
                    files: sel.first.submittedFiles,
                    verified: sel.first.verifiedFiles);
              }),
            ),
          OfficialPostTravelDoc(
            items: post,
            readOnly: true,
            travelSelected: travelLive,
            aiCheck: _postAi,
            aiRunning: _postBusy,
            onRunAiCheck: travelLive ? _runPostAi : null,
            onDownloadPdf: () =>
                _open('/requirements/templates/faculty_post_checklist'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _downloads(),
          _group('Faculty', 'Pre-Travel'),
          _adminPostDoc(),
          _group('Student', 'Post-Travel'),
        ],
      ),
    );
  }
}
