import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../models.dart';
import '../notify.dart';
import '../realtime.dart';
import '../widgets.dart';

/// ==================== DOCUMENTS ====================
class FacultyDocumentsTab extends StatefulWidget {
  const FacultyDocumentsTab({super.key});

  @override
  State<FacultyDocumentsTab> createState() => _FacultyDocumentsTabState();
}

class _FacultyDocumentsTabState extends State<FacultyDocumentsTab> with RealtimeAware {
  List<DocumentRec> _docs = [];
  List<Travel> _travels = [];
  List<DocType> _types = [];
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
        ApiClient.instance.get('/documents/user/all'),
        ApiClient.instance.get('/travels/'),
        ApiClient.instance.get('/document-types/'),
      ]);
      _docs = (results[0] as List)
          .map((e) => DocumentRec.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => (b.uploadedAt ?? '').compareTo(a.uploadedAt ?? ''));
      _travels = (results[1] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _types = (results[2] as List)
          .map((e) => DocType.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _travelLabel(int id) {
    final t = _travels.where((x) => x.travelId == id);
    if (t.isEmpty) return 'Travel $id';
    final tr = t.first;
    return '${tr.eventTitle} (${tr.startDate})';
  }

  Future<void> _download(DocumentRec d) async {
    final url = ApiClient.instance.authedFileUrl('/documents/${d.documentId}/file');
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      await showApiError(context, 'Could not open download link');
    }
  }

  Future<void> _delete(DocumentRec d) async {
    final ok = await confirmAction(
        context, 'Delete document?', '${d.fileName ?? d.docType} will be removed.',
        confirmLabel: 'Delete');
    if (!ok) return;
    try {
      await ApiClient.instance.delete('/documents/${d.documentId}');
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  static const _resubmittable = {
    'Rejected',
    'Resubmission Required',
    'Incomplete',
    'Missing',
  };

  Future<void> _resubmit(DocumentRec d) async {
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
      await ApiClient.instance.upload(
        '/documents/${d.documentId}/resubmit',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: 'Document resubmitted for verification',
      );
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _upload() async {
    if (_travels.isEmpty) {
      Notify.warning('Create a travel record before uploading documents');
      return;
    }
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UploadDocSheet(travels: _travels, types: _types),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const LoadingBox();
    } else if (_error != null) {
      body = EmptyState(message: 'Error: $_error');
    } else if (_docs.isEmpty) {
      body = const EmptyState(
          message:
              'No documents uploaded yet.\nTap + Upload Document to add one.');
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = _docs[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(d.fileName ?? 'Document ${d.documentId}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        StatusChip(label: d.status ?? 'Pending'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                            label: Text(d.docType,
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact),
                        if (d.docCategory != null && d.docCategory!.isNotEmpty)
                          Chip(
                              label: Text(d.docCategory!,
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Travel: ${_travelLabel(d.travelId)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Uploaded: ${d.uploadedAt ?? '—'}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (d.remarks != null && d.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Remarks: ${d.remarks}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade900)),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_resubmittable.contains(d.status)) ...[
                          TextButton.icon(
                            onPressed: () => _resubmit(d),
                            icon: const Icon(Icons.replay, size: 16),
                            label: const Text('Resubmit',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        TextButton.icon(
                          onPressed: () => _download(d),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download',
                              style: TextStyle(fontSize: 12)),
                        ),
                        TextButton.icon(
                          onPressed: () => _delete(d),
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.redAccent),
                          label: const Text('Delete',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (!_loading && _error == null && _travels.isNotEmpty)
            _submissionBanner(),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      ),
    );
  }

  /// Live per-travel submission summary — "Not Yet Submitted" until the
  /// faculty member actually uploads a file.
  Widget _submissionBanner() {
    final pending = _travels.where((t) => !t.hasSubmitted).length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inbox_outlined,
                size: 16, color: Color(0xFF059669)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pending == 0
                    ? 'All travels have submitted documents'
                    : '$pending travel(s) not yet submitted',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46)),
              ),
            ),
            const LiveBadge(compact: true),
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in _travels)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tooltip(
                      message: t.eventTitle,
                      child: SubmissionStatusChip(
                          status: t.submissionStatus,
                          files: t.submittedFiles,
                          verified: t.verifiedFiles,
                          compact: true),
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

class _UploadDocSheet extends StatefulWidget {
  const _UploadDocSheet({required this.travels, required this.types});
  final List<Travel> travels;
  final List<DocType> types;

  @override
  State<_UploadDocSheet> createState() => _UploadDocSheetState();
}

class _UploadDocSheetState extends State<_UploadDocSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _travelId;
  String? _docType;
  PlatformFile? _file;
  bool _saving = false;

  Future<void> _pickFile() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    setState(() => _file = res.files.first);
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    final f = _file;
    if (f == null) {
      Notify.warning('Please choose a file to upload');
      return;
    }
    final bytes = f.bytes;
    if (bytes == null) {
      Notify.error('Could not read file');
      return;
    }
    setState(() => _saving = true);
    try {
      final typeMatches = widget.types.where((t) => t.name == _docType);
      final category = typeMatches.isEmpty ? null : typeMatches.first.category;
      final query = 'travel_id=$_travelId'
          '&doc_type=${Uri.encodeQueryComponent(_docType!)}'
          '${category == null ? '' : '&doc_category=${Uri.encodeQueryComponent(category)}'}';
      final resp = await ApiClient.instance.upload('/documents/upload?$query',
          fields: const {},
          fileName: f.name,
          bytes: bytes,
          okMsg: 'Document uploaded successfully');
      DocAnalysis? analysis;
      try {
        final docId = (resp is Map) ? resp['document_id'] as int? : null;
        if (docId != null) {
          final a = await ApiClient.instance.post('/ai/document-analysis',
              {'document_id': docId},
              feedback: false);
          analysis = DocAnalysis.fromJson(Map<String, dynamic>.from(a as Map));
        }
      } catch (_) {
        // analysis is advisory — upload already succeeded
      }
      if (mounted) {
        if (analysis != null) await _showAnalysis(analysis);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAnalysis(DocAnalysis a) async {
    final pct = ((a.confidence ?? 0) * 100).round();
    final flags = a.flags;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7C3AED)),
          SizedBox(width: 8),
          Text('AI Document Analysis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Suggested type', a.suggestedType ?? '—'),
              _row('Confidence', '$pct%'),
              _row('Status', a.status ?? '—'),
              if (a.extractedText != null && a.extractedText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Extracted fields',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(a.extractedText!,
                    style: const TextStyle(fontSize: 12.5, height: 1.4)),
              ],
              const SizedBox(height: 10),
              const Text('Issues detected',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              flags.isEmpty
                  ? const Row(children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 6),
                      Text('No issues detected',
                          style: TextStyle(fontSize: 13))
                    ])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (a.issues ?? '')
                          .split('|')
                          .where((s) => s.trim().isNotEmpty)
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 16, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(s.trim(),
                                            style:
                                                const TextStyle(fontSize: 12.5))),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 105,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B)))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('Upload Document',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _travelId,
                decoration:
                    const InputDecoration(labelText: 'Travel Record *'),
                items: widget.travels
                    .map((t) => DropdownMenuItem(
                        value: t.travelId,
                        child: Text('${t.eventTitle} (${t.startDate})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _travelId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _docType,
                decoration:
                    const InputDecoration(labelText: 'Document Type *'),
                items: widget.types
                    .map((t) => DropdownMenuItem(
                        value: t.name,
                        child: Text(
                            t.category.isEmpty ? t.name : '${t.name} — ${t.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _docType = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(
                    _file == null ? 'Choose file (PDF/JPG/PNG)' : _file!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _upload,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==================== ANNOUNCEMENTS ====================
class FacultyAnnouncementsTab extends StatefulWidget {
  const FacultyAnnouncementsTab({super.key});

  @override
  State<FacultyAnnouncementsTab> createState() =>
      _FacultyAnnouncementsTabState();
}

class _FacultyAnnouncementsTabState extends State<FacultyAnnouncementsTab> {
  List<Announcement> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/announcements/');
      _items = (data as List)
          .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    if (_items.isEmpty) {
      return const EmptyState(message: 'No announcements yet.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final a = _items[i];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      Text(timeAgo(a.createdAt),
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(a.content,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF475569))),
                  if (!a.isActive)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: StatusChip(label: 'Inactive'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ==================== REPORTS ====================
class FacultyReportsTab extends StatefulWidget {
  const FacultyReportsTab({super.key});

  @override
  State<FacultyReportsTab> createState() => _FacultyReportsTabState();
}

class _FacultyReportsTabState extends State<FacultyReportsTab> {
  List<Travel> _all = [];
  ReqReport? _reqReport;
  String? _year;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/travels/'),
        ApiClient.instance
            .get('/requirements/report?applies_to=Faculty&phase=Post-Travel'),
      ]);
      _all = (results[0] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _reqReport = ReqReport.fromJson(
          Map<String, dynamic>.from(results[1] as Map));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Travel> get _rows => _year == null
      ? _all
      : _all.where((t) => t.startDate.startsWith(_year!)).toList();

  Map<String, int> _group(String Function(Travel) key) {
    final m = <String, int>{};
    for (final t in _rows) {
      final k = key(t);
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    final years = _all
        .map((t) => t.startDate.substring(0, 4))
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final rows = _rows;
    final completed = rows.where((t) => t.timelineStatus == 'Completed').length;
    final ongoing = rows.where((t) => t.timelineStatus == 'Ongoing').length;
    final upcoming =
        rows.where((t) => (t.timelineStatus ?? 'Upcoming') == 'Upcoming').length;
    final rate =
        rows.isEmpty ? '—' : '${(completed / rows.length * 100).round()}%';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_reqReport != null) ...[
            RequirementsReportCard(
                report: _reqReport!, onRefresh: _load, editable: true),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Expanded(
                child: Text('Mobility Reports',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _year,
                hint: const Text('All Years', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('All Years')),
                  ...years.map(
                      (y) => DropdownMenuItem(value: y, child: Text(y))),
                ],
                onChanged: (v) => setState(() => _year = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Total Records',
                    value: '${rows.length}',
                    color: const Color(0xFF1D4ED8),
                    icon: Icons.flight_takeoff)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Completed',
                    value: '$completed',
                    color: const Color(0xFF059669),
                    icon: Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Ongoing',
                    value: '$ongoing',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.downloading)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Upcoming',
                    value: '$upcoming',
                    color: const Color(0xFF0891B2),
                    icon: Icons.schedule)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Completion Rate',
                    value: rate,
                    color: const Color(0xFF7C3AED),
                    icon: Icons.percent)),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 14),
          _groupCard('By Mobility Type', _group((t) => t.mobilityType)),
          _groupCard('By Country', _group((t) =>
              (t.country == null || t.country!.isEmpty) ? '—' : t.country!)),
          _groupCard('By Funding Support',
              _group((t) => t.fundingType ?? '—')),
        ],
      ),
    );
  }

  Widget _groupCard(String title, Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SectionCard(
      title: title,
      child: entries.isEmpty
          ? Text('No records.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
          : Column(
              children: entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(e.key,
                                    style: const TextStyle(fontSize: 13))),
                            StatusChip(
                                label: '${e.value}',
                                color: const Color(0xFF1D4ED8)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

/// ==================== COLLEGE RECORDS ====================
class FacultyCollegesTab extends StatefulWidget {
  const FacultyCollegesTab({super.key});

  @override
  State<FacultyCollegesTab> createState() => _FacultyCollegesTabState();
}

class _FacultyCollegesTabState extends State<FacultyCollegesTab> {
  List<College> _colleges = [];
  final Map<int, List<Department>> _depts = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/colleges/');
      _colleges = (data as List)
          .map((e) => College.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final deptResults = await Future.wait(_colleges
          .map((c) => ApiClient.instance.get('/colleges/${c.collegeId}/departments')));
      for (var i = 0; i < _colleges.length; i++) {
        _depts[_colleges[i].collegeId] = (deptResults[i] as List)
            .map((e) => Department.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    if (_colleges.isEmpty) {
      return const EmptyState(message: 'No colleges found.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent:
              MediaQuery.of(context).size.width >= 900 ? 340 : 480,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
        ),
        itemCount: _colleges.length,
        itemBuilder: (_, i) {
          final c = _colleges[i];
          final depts = _depts[c.collegeId] ?? [];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.code,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF0D3818))),
                  const SizedBox(height: 2),
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      depts.isEmpty
                          ? 'No departments listed.'
                          : depts.map((d) => d.name).join('\n'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ==================== ANALYTICS ====================
class FacultyAnalyticsTab extends StatefulWidget {
  const FacultyAnalyticsTab({super.key});

  @override
  State<FacultyAnalyticsTab> createState() => _FacultyAnalyticsTabState();
}

class _FacultyAnalyticsTabState extends State<FacultyAnalyticsTab> {
  Map<String, dynamic>? _summary;
  List<Travel> _travels = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/analytics/user/summary'),
        ApiClient.instance.get('/travels/'),
      ]);
      _summary = Map<String, dynamic>.from(results[0] as Map);
      _travels = (results[1] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, int> _group(String Function(Travel) key, {int? take}) {
    final m = <String, int>{};
    for (final t in _travels) {
      final k = key(t);
      m[k] = (m[k] ?? 0) + 1;
    }
    if (take != null) {
      final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return {for (final e in sorted.take(take)) e.key: e.value};
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    final s = _summary ?? {};
    final rate = s['compliance_rate'] ?? s['average_compliance_score'] ?? 0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Mobility Intelligence & Analytics',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Total Travels',
                    value: '${s['total_travels'] ?? 0}',
                    color: const Color(0xFF1D4ED8),
                    icon: Icons.flight_takeoff)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Completed',
                    value: '${s['completed_travels'] ?? 0}',
                    color: const Color(0xFF059669),
                    icon: Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Ongoing',
                    value: '${s['ongoing_travels'] ?? 0}',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.downloading)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Upcoming',
                    value: '${s['upcoming_travels'] ?? 0}',
                    color: const Color(0xFF0891B2),
                    icon: Icons.schedule)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Compliance',
                    value: '${(num.tryParse('$rate') ?? 0).round()}%',
                    color: const Color(0xFF7C3AED),
                    icon: Icons.verified_outlined)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'High Risk',
                    value: '${s['high_risk_travels'] ?? 0}',
                    color: const Color(0xFFDC2626),
                    icon: Icons.warning_amber)),
          ]),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Summary',
            child: Text(
              (s['compliance_status'] ?? 'Analysis based on your travel records.')
                  .toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SectionCard(
            title: 'Travels by Year',
            child: MiniBars(
              data: _group((t) =>
                  t.startDate.isEmpty ? '—' : t.startDate.substring(0, 4)),
              color: const Color(0xFF059669),
            ),
          ),
          SectionCard(
            title: 'Travels by Mobility Type',
            child: MiniBars(
                data: _group((t) => t.mobilityType),
                color: const Color(0xFF1D4ED8)),
          ),
          SectionCard(
            title: 'Top Countries',
            child: MiniBars(
              data: _group(
                  (t) =>
                      (t.country == null || t.country!.isEmpty) ? '�?"' : t.country!,
                  take: 5),
              color: const Color(0xFF0D3818),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==================== PHASE 4: FACULTY LIFECYCLE ====================
/// Post-travel requirements (FR-F07), re-entry activities (FR-F08) and
/// calculated compliance (FR-F09) for a faculty member's own travel.
class FacultyLifecycleTab extends StatefulWidget {
  const FacultyLifecycleTab({super.key});

  @override
  State<FacultyLifecycleTab> createState() => _FacultyLifecycleTabState();
}

class _FacultyLifecycleTabState extends State<FacultyLifecycleTab> {
  List<Travel> _travels = [];
  Travel? _selected;
  List<PostTravelReq> _postTravel = [];
  List<ReentryActivity> _reentry = [];
  ComplianceRec? _compliance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTravels();
  }

  Future<void> _loadTravels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = Session.instance.userId;
      final data = await ApiClient.instance.get('/travels/user/$userId');
      _travels = (data as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => (b.startDate).compareTo(a.startDate));
      if (_travels.isNotEmpty) {
        _selected ??= _travels.first;
        await _loadDetail();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDetail() async {
    final t = _selected;
    if (t == null) return;
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/travels/${t.travelId}/post-travel/'),
        ApiClient.instance.get('/travels/${t.travelId}/re-entry/'),
        ApiClient.instance.get('/travels/${t.travelId}/compliance'),
      ]);
      _postTravel = (results[0] as List)
          .map((e) => PostTravelReq.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _reentry = (results[1] as List)
          .map((e) => ReentryActivity.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _compliance = results[2] is Map
          ? ComplianceRec.fromJson(Map<String, dynamic>.from(results[2] as Map))
          : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _selectTravel(Travel t) async {
    setState(() {
      _selected = t;
      _postTravel = [];
      _reentry = [];
      _compliance = null;
    });
    await _loadDetail();
  }

  // ---------- Post-Travel actions (FR-F07) ----------

  Future<void> _addPostTravel() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add post-travel requirement'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Requirement',
            hintText: 'e.g. Travel Report',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await ApiClient.instance
          .post('/travels/${_selected!.travelId}/post-travel/', {
        'requirement': ctrl.text.trim(),
      });
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _uploadPostTravelEvidence(PostTravelReq r) async {
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
      await ApiClient.instance.upload(
        '/travels/${_selected!.travelId}/post-travel/${r.requirementId}/evidence',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: 'Evidence submitted for verification',
      );
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  // ---------- Re-Entry actions (FR-F08) ----------

  Future<void> _addReentry() async {
    final ctrl = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add re-entry activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Activity',
                hintText: 'e.g. Share insights at faculty seminar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await ApiClient.instance.post('/travels/${_selected!.travelId}/re-entry/', {
        'activity': ctrl.text.trim(),
        if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
      }, okMsg: 'Re-entry activity added');
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _uploadReentryEvidence(ReentryActivity a) async {
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
      await ApiClient.instance.upload(
        '/travels/${_selected!.travelId}/re-entry/${a.activityId}/evidence',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: 'Re-entry evidence recorded',
      );
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _setReentryStatus(ReentryActivity a, String status) async {
    try {
      await ApiClient.instance.patch(
          '/travels/${_selected!.travelId}/re-entry/${a.activityId}',
          {'status': status});
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  void _showReentryStatusSheet(ReentryActivity a) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Update "${a.activity}"',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final s in kReentryStatuses)
              ListTile(
                leading: Icon(
                  s == 'Completed'
                      ? Icons.check_circle_outline
                      : s == 'Not Complied'
                          ? Icons.cancel_outlined
                          : Icons.schedule,
                  color: statusColor(s),
                ),
                title: Text(s),
                trailing: a.status == s
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (a.status != s) _setReentryStatus(a, s);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    if (_travels.isEmpty) {
      return const EmptyState(
          message: 'No travel records yet.\nCreate a travel first, then add post-travel and re-entry items here.');
    }

    return RefreshIndicator(
      onRefresh: _loadTravels,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _travelPicker(),
          const SizedBox(height: 14),
          _complianceSection(),
          const SizedBox(height: 14),
          _postTravelSection(),
          const SizedBox(height: 14),
          _reentrySection(),
        ],
      ),
    );
  }

  Widget _travelPicker() {
    return SectionCard(
      title: 'Select travel',
      child: DropdownButtonFormField<Travel>(
        value: _selected,
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: _travels
            .map((t) => DropdownMenuItem<Travel>(
                  value: t,
                  child: Text(
                    '${t.eventTitle}  ·  ${t.startDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
            .toList(),
        onChanged: (t) {
          if (t != null) _selectTravel(t);
        },
      ),
    );
  }

  Widget _complianceSection() {
    final c = _compliance;
    return SectionCard(
      title: 'Compliance',
      trailing: c == null
          ? null
          : StatusChip(label: c.status, color: statusColor(c.status)),
      child: c == null
          ? Text('No compliance record yet.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.docPercent / 100,
                          minHeight: 8,
                          backgroundColor:
                              statusColor(c.status).withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(statusColor(c.status)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${c.docPercent}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Score ${c.score.toStringAsFixed(1)}%  ·  '
                    '${c.verifiedDocs}/${c.requiredDocs} documents verified',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                _okRow('Pre-travel', c.preTravelOk),
                _okRow('Post-travel', c.postTravelOk),
                _okRow('Re-entry', c.reentryOk),
                if (c.computedAt != null && c.computedAt!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Last computed ${timeAgo(c.computedAt)}',
                        style:
                            TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                  ),
              ],
            ),
    );
  }

  Widget _okRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: ok ? const Color(0xFF059669) : const Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _postTravelSection() {
    return SectionCard(
      title: 'Post-Travel Requirements',
      trailing: IconButton(
        tooltip: 'Add requirement',
        icon: const Icon(Icons.add, size: 20),
        onPressed: _addPostTravel,
      ),
      child: _postTravel.isEmpty
          ? Text('No post-travel requirements yet.\nTap + to add one.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))
          : Column(
              children: _postTravel.map(_postTravelTile).toList(),
            ),
    );
  }

  Widget _postTravelTile(PostTravelReq r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r.requirement,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  StatusChip(label: r.status),
                ],
              ),
              if (r.dueDate != null && r.dueDate!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Due ${r.dueDate}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ),
              if (r.hasEvidence)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(r.evidencePath!.split(RegExp(r'[\\/]')).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(
                      r.hasEvidence ? Icons.upload_file : Icons.cloud_upload,
                      size: 16),
                  label: Text(r.hasEvidence ? 'Replace' : 'Upload evidence'),
                  onPressed: () => _uploadPostTravelEvidence(r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reentrySection() {
    return SectionCard(
      title: 'Re-Entry Activities',
      trailing: IconButton(
        tooltip: 'Add activity',
        icon: const Icon(Icons.add, size: 20),
        onPressed: _addReentry,
      ),
      child: _reentry.isEmpty
          ? Text('No re-entry activities yet.\nTap + to plan one.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))
          : Column(children: _reentry.map(_reentryTile).toList()),
    );
  }

  Widget _reentryTile(ReentryActivity a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(a.activity,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  StatusChip(label: a.status),
                  IconButton(
                    tooltip: 'Change status',
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    onPressed: () => _showReentryStatusSheet(a),
                  ),
                ],
              ),
              if (a.description != null && a.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(a.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                ),
              if (a.targetDate != null && a.targetDate!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Target ${a.targetDate}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ),
              if (a.hasEvidence)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(a.evidencePath!.split(RegExp(r'[\\/]')).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(
                      a.hasEvidence ? Icons.upload_file : Icons.cloud_upload,
                      size: 16),
                  label: Text(a.hasEvidence ? 'Replace' : 'Upload evidence'),
                  onPressed: () => _uploadReentryEvidence(a),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==================== MY REMARKS (FR-F09) ====================
class FacultyMyRemarksTab extends StatefulWidget {
  const FacultyMyRemarksTab({super.key});

  @override
  State<FacultyMyRemarksTab> createState() => _FacultyMyRemarksTabState();
}

class _FacultyMyRemarksTabState extends State<FacultyMyRemarksTab> {
  List<RemarkRow> _rows = [];
  Map<int, Travel> _travelById = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = Session.instance.userId;
      final results = await Future.wait([
        ApiClient.instance.get('/remarks/mine?limit=200'),
        ApiClient.instance.get('/travels/user/$userId'),
      ]);
      _rows = (results[0] as List)
          .map((e) => RemarkRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _travelById = {
        for (final t in (results[1] as List).map(
            (e) => Travel.fromJson(Map<String, dynamic>.from(e))))
          t.travelId: t,
      };
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    if (_rows.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton.filledTonal(
                  onPressed: _load, icon: const Icon(Icons.refresh)),
            ),
          ),
          const Expanded(
              child: EmptyState(
                  message: 'No remarks on your travels yet.\n'
                      'Admin notes and status transitions will appear here.')),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('${_rows.length} remarks on your travels',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ),
              IconButton.filledTonal(
                  onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = _rows[i];
                final travel = _travelById[r.travelId ?? -1];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  r.affectedRequirement ??
                                      r.remarkType ??
                                      'Remark',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                            if (r.previousStatus != null &&
                                r.newStatus != null)
                              StatusChip(
                                  label: r.newStatus!,
                                  color: statusColor(r.newStatus)),
                          ],
                        ),
                        if (r.remarkText != null && r.remarkText!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(r.remarkText!,
                                style: const TextStyle(fontSize: 12.5)),
                          ),
                        if (travel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(travel.eventTitle,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                          ),
                        if (r.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(timeAgo(r.createdAt),
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade500)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
