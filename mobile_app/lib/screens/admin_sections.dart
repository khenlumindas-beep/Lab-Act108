import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../models.dart';
import '../notify.dart';
import '../widgets.dart';

/// ==================== STUDENT RECORDS ====================
class AdminStudentsTab extends StatefulWidget {
  const AdminStudentsTab({super.key});

  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  List<Travel> _rows = [];
  List<College> _colleges = [];
  bool _loading = true;
  String? _error;

  String? _year;
  int? _collegeId;
  String? _mobility;

  static const _years = ['2026', '2025', '2024'];

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
      final params = StringBuffer('participant_type=Student&limit=100');
      if (_year != null) params.write('&year=$_year');
      if (_collegeId != null) params.write('&college_id=$_collegeId');
      if (_mobility != null) {
        params.write('&mobility_type=${Uri.encodeComponent(_mobility!)}');
      }
      final results = await Future.wait([
        ApiClient.instance.get('/travels/?$params'),
        ApiClient.instance.get('/colleges/'),
      ]);
      _rows = (results[0] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _colleges = (results[1] as List)
          .map((e) => College.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _collegeLabel(int? id) {
    if (id == null) return '—';
    final c = _colleges.where((x) => x.collegeId == id);
    return c.isEmpty ? 'College #$id' : c.first.code;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _dropdown<String>(
                  value: _year,
                  hint: 'Year',
                  items: _years,
                  onChanged: (v) {
                    setState(() => _year = v);
                    _load();
                  }),
              const SizedBox(width: 8),
              _dropdown<int>(
                  value: _collegeId,
                  hint: 'College',
                  items: _colleges.map((c) => c.collegeId).toList(),
                  labelOf: (id) => _colleges
                      .firstWhere((c) => c.collegeId == id)
                      .code,
                  onChanged: (v) {
                    setState(() => _collegeId = v);
                    _load();
                  }),
              const SizedBox(width: 8),
              _dropdown<String>(
                  value: _mobility,
                  hint: 'Mobility',
                  items: kMobilityTypes,
                  onChanged: (v) {
                    setState(() => _mobility = v);
                    _load();
                  }),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  onPressed: _load, icon: const Icon(Icons.refresh)),
            ]),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBox()
              : _error != null
                  ? EmptyState(message: 'Error: $_error')
                  : _rows.isEmpty
                      ? const EmptyState(message: 'No student records found.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _rows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = _rows[i];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey.shade200)),
                                child: ListTile(
                                  title: Text(
                                      t.participantName ?? 'Student',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  subtitle: Text(
                                    '${t.eventTitle}\n'
                                    '${t.mobilityType} · ${t.country ?? ''} · ${t.startDate} → ${t.endDate}\n'
                                    '${_collegeLabel(t.collegeId)}'
                                    '${t.mobilityDuration == null ? '' : ' · ${t.mobilityDuration}'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusChip(
                                          label:
                                              t.workflowStatus ?? 'Submitted'),
                                      IconButton(
                                        tooltip: 'Workflow',
                                        icon: const Icon(Icons.swap_horiz,
                                            size: 20),
                                        onPressed: () =>
                                            showWorkflowDialog(context, t, _load),
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

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? labelOf,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i, child: Text(labelOf?.call(i) ?? '$i')))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// ==================== 3-YEAR BACKTRACKING REPORT ====================
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  List<Travel> _rows = [];
  Map<int, String> _userNames = {};
  Map<int, String> _collegeCodes = {};
  ReqReport? _reqReport;
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
      final now = DateTime.now().year;
      final results = await Future.wait([
        ApiClient.instance.get('/travels/?limit=100&year=$now'),
        ApiClient.instance.get('/travels/?limit=100&year=${now - 1}'),
        ApiClient.instance.get('/travels/?limit=100&year=${now - 2}'),
        ApiClient.instance.get('/users/'),
        ApiClient.instance.get('/colleges/'),
        ApiClient.instance
            .get('/requirements/report?applies_to=Faculty&phase=Post-Travel'),
      ]);
      _rows = [
        for (var i = 0; i < 3; i++)
          ...(results[i] as List)
              .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
      ];
      _userNames = {
        for (final u in (results[3] as List))
          (u['user_id'] as int? ?? 0): (u['full_name'] as String? ?? ''),
      };
      _collegeCodes = {
        for (final c in (results[4] as List))
          (c['college_id'] as int? ?? 0): (c['code'] as String? ?? ''),
      };
      _reqReport = ReqReport.fromJson(
          Map<String, dynamic>.from(results[5] as Map));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _name(Travel t) => t.participantType == 'Student'
      ? (t.participantName ?? 'Student')
      : (_userNames[t.userId] ?? 'User #${t.userId}');

  Widget _travelCard(Travel t) {
    final year = t.startDate.isEmpty ? '—' : t.startDate.substring(0, 4);
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
                  child: Text(_name(t),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                StatusChip(label: t.riskFlag ?? '—'),
              ],
            ),
            const SizedBox(height: 2),
            Text(
                '${_collegeCodes[t.collegeId] ?? t.collegeId ?? '—'} · $year · ${t.eventTitle}',
                style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 6),
            Text(
                'Pre-Travel: ${t.preTravelStatus ?? '—'}   ·   Post-Travel: ${t.postTravelStatus ?? '—'}',
                style: const TextStyle(fontSize: 12)),
            Text(
                'MOVs: ${t.movs ?? '—'}   ·   Follow-up: ${t.followUp ?? '—'}',
                style: const TextStyle(fontSize: 12)),
            Text('Doc Completeness: ${t.docCompleteness ?? '—'}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
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
        padding: const EdgeInsets.all(16),
        children: [
          if (_reqReport != null) ...[
            RequirementsReportCard(report: _reqReport!, onRefresh: _load),
            const SizedBox(height: 8),
          ],
          if (_rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: EmptyState(
                  message: 'No travel records in the last 3 years.'),
            ),
          for (final t in _rows) ...[
            _travelCard(t),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// ==================== DOCUMENT TYPES (CRUD) ====================
class AdminDocTypesTab extends StatefulWidget {
  const AdminDocTypesTab({super.key});

  @override
  State<AdminDocTypesTab> createState() => _AdminDocTypesTabState();
}

class _AdminDocTypesTabState extends State<AdminDocTypesTab> {
  List<DocType> _all = [];
  String _cat = 'All';
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
      final data = await ApiClient.instance.get('/document-types/');
      _all = (data as List)
          .map((e) => DocType.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _form({DocType? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final sort = TextEditingController(text: '${existing?.sortOrder ?? 0}');
    String category = existing?.category ?? 'Pre-Travel';
    bool required_ = existing?.isRequired ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(existing == null ? 'Add Document Type' : 'Edit Document Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: const [
                    DropdownMenuItem(value: 'Pre-Travel', child: Text('Pre-Travel')),
                    DropdownMenuItem(value: 'Post-Travel', child: Text('Post-Travel')),
                  ],
                  onChanged: (v) => setD(() => category = v ?? 'Pre-Travel'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Required', style: TextStyle(fontSize: 14)),
                  value: required_,
                  onChanged: (v) => setD(() => required_ = v),
                ),
                const SizedBox(height: 6),
                TextField(
                    controller: sort,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sort order')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(existing == null ? 'Create' : 'Update')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (name.text.trim().isEmpty) return;
    try {
      final payload = {
        'name': name.text.trim(),
        'category': category,
        'is_required': required_,
        'sort_order': int.tryParse(sort.text) ?? 0,
      };
      if (existing == null) {
        await ApiClient.instance.post('/document-types/', payload,
            okMsg: 'Document type created');
      } else {
        await ApiClient.instance
            .put('/document-types/${existing.docTypeId}', payload,
                okMsg: 'Document type updated');
      }
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _delete(DocType d) async {
    final ok = await confirmAction(context, 'Delete document type?',
        '${d.name} will be removed.',
        confirmLabel: 'Delete');
    if (!ok) return;
    try {
      await ApiClient.instance.delete('/document-types/${d.docTypeId}');
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const LoadingBox();
    } else if (_error != null) {
      body = EmptyState(message: 'Error: $_error');
    } else {
      final rows = _cat == 'All'
          ? _all
          : _all.where((d) => d.category == _cat).toList();
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: ['All', 'Pre-Travel', 'Post-Travel']
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c, style: const TextStyle(fontSize: 12)),
                          selected: _cat == c,
                          onSelected: (_) => setState(() => _cat = c),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const EmptyState(message: 'No document types found.')
            else
              ...rows.map((d) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(d.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                          '${d.category} · ${d.isRequired ? 'Required' : 'Optional'} · sort ${d.sortOrder}',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _form(existing: d)),
                          IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () => _delete(d)),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Add Type'),
      ),
    );
  }
}

/// ==================== AI ANALYSIS ====================
class AdminAiAnalysisTab extends StatefulWidget {
  const AdminAiAnalysisTab({super.key});

  @override
  State<AdminAiAnalysisTab> createState() => _AdminAiAnalysisTabState();
}

class _AdminAiAnalysisTabState extends State<AdminAiAnalysisTab> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _mobility;
  List<AiInsight> _insights = [];
  String? _priorityFilter;
  bool _recomputing = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final q = _priorityFilter == null
          ? '/ai/insights?limit=100'
          : '/ai/insights?limit=100&priority=$_priorityFilter';
      final results = await Future.wait([
        ApiClient.instance.get('/analytics/system/summary'),
        ApiClient.instance.get('/analytics/trends/mobility-types'),
        ApiClient.instance.get(q),
      ]);
      _summary = Map<String, dynamic>.from(results[0] as Map);
      _mobility = Map<String, dynamic>.from(results[1] as Map);
      _insights = (results[2] as List)
          .map((e) => AiInsight.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recompute() async {
    setState(() => _recomputing = true);
    try {
      // feedback:false — the toast below carries the regenerated count.
      final res = await ApiClient.instance.post('/ai/insights/recompute', {},
          feedback: false);
      final n = res is Map ? (res['written'] ?? 0) : 0;
      Notify.success('Regenerated $n insight(s)');
      await _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _recomputing = false);
    }
  }

  Future<void> _accept(AiInsight ins) async {
    try {
      await ApiClient.instance.post('/ai/insights/${ins.insightId}/accept',
          {'accepted': true},
          okMsg: 'Insight acknowledged');
      await _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Color _priorityColor(String? p) => switch (p) {
        'high' => const Color(0xFFDC2626),
        'medium' => const Color(0xFFF59E0B),
        'low' => const Color(0xFF059669),
        _ => const Color(0xFF64748B),
      };

  Widget _insightCard(AiInsight ins) {
    final color = _priorityColor(ins.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4),
            top: BorderSide(color: Colors.grey.shade200),
            right: BorderSide(color: Colors.grey.shade200),
            bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                  '${ins.insightType ?? 'insight'} · ${ins.priority ?? '—'}'
                      .toUpperCase(),
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: color)),
            ),
            if (ins.isAccepted == true)
              const Icon(Icons.check_circle,
                  size: 15, color: Color(0xFF059669)),
          ]),
          const SizedBox(height: 5),
          Text(ins.summary ?? '', style: const TextStyle(fontSize: 12.5, height: 1.4)),
          if (ins.eventTitle != null && ins.eventTitle!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(ins.eventTitle!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          if (ins.suggestedRemark != null && ins.suggestedRemark!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Suggested remark: ${ins.suggestedRemark}',
                  style: const TextStyle(fontSize: 11.5, height: 1.35)),
            ),
          ],
          if (ins.isAccepted != true)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _accept(ins),
                icon: const Icon(Icons.how_to_reg, size: 15),
                label: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    final s = _summary ?? {};
    final risk = Map<String, dynamic>.from(s['risk_analysis'] as Map? ?? {});
    final types = Map<String, dynamic>.from(
        _mobility?['mobility_types'] as Map? ?? {});
    final typeEntries = types.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('AI Analysis',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Rule-based insights generated from actual system data.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          SectionCard(
            title: 'System Summary',
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: _tile('Total Travels', '${s['total_travels'] ?? 0}',
                        const Color(0xFF059669))),
                const SizedBox(width: 10),
                Expanded(
                    child: _tile('Compliance Rate',
                        '${s['compliance_rate'] ?? 0}%', const Color(0xFF1D4ED8))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _tile('High Risk', '${risk['high_risk'] ?? 0}',
                        const Color(0xFFDC2626))),
                const SizedBox(width: 10),
                Expanded(
                    child: _tile('Medium Risk', '${risk['medium_risk'] ?? 0}',
                        const Color(0xFFF59E0B))),
                const SizedBox(width: 10),
                Expanded(
                    child: _tile('Low Risk', '${risk['low_risk'] ?? 0}',
                        const Color(0xFF059669))),
              ]),
            ]),
          ),
          SectionCard(
            title: 'Risk Levels',
            child: Column(
              children: ['High', 'Medium', 'Low'].map((level) {
                final count = level == 'High'
                    ? risk['high_risk']
                    : level == 'Medium'
                        ? risk['medium_risk']
                        : risk['low_risk'];
                final color = level == 'High'
                    ? const Color(0xFFDC2626)
                    : level == 'Medium'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF059669);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: color, width: 4),
                      top: BorderSide(color: Colors.grey.shade200),
                      right: BorderSide(color: Colors.grey.shade200),
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('$level Risk',
                              style: const TextStyle(fontSize: 13))),
                      Text('${count ?? 0}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: 'Mobility Type Distribution',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: typeEntries.isEmpty
                  ? [const Text('No data yet.', style: TextStyle(fontSize: 13))]
                  : typeEntries
                      .map((e) => Chip(
                            label: Text('${e.key}: ${e.value}',
                                style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
            ),
          ),
          SectionCard(
            title: 'Compliance Insights (AI-assisted)',
            trailing: _recomputing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    tooltip: 'Regenerate insights',
                    onPressed: _recompute,
                    icon: const Icon(Icons.refresh, size: 18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Priority recommendations and suggested remarks generated from actual record data. Advisory only — decisions remain with your office.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final f in const [
                      null,
                      'high',
                      'medium',
                      'low'
                    ])
                      ChoiceChip(
                        label: Text(f ?? 'All',
                            style: const TextStyle(fontSize: 12)),
                        selected: _priorityFilter == f,
                        onSelected: (_) {
                          setState(() {
                            _priorityFilter = f;
                            _loading = true;
                          });
                          _load();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_insights.isEmpty)
                  const Text('No insights yet — tap refresh to generate.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)))
                else
                  ..._insights.take(40).map(_insightCard),
                if (_insights.length > 40)
                  Text('Showing 40 of ${_insights.length} — use priority filters to narrow.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ==================== ANNOUNCEMENTS (with edit / deactivate) ====================
class AdminAnnouncementsTab extends StatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab> {
  List<Announcement> _items = [];
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

  Future<void> _compose({Announcement? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final content = TextEditingController(text: existing?.content ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'New Announcement' : 'Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 10),
              TextField(
                  controller: content,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Content *')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(existing == null ? 'Publish' : 'Update')),
        ],
      ),
    );
    if (ok != true) return;
    if (title.text.trim().isEmpty || content.text.trim().isEmpty) return;
    try {
      if (existing == null) {
        // Server replies with "Announcement created and notified N users".
        await ApiClient.instance.post('/announcements/', {
          'title': title.text.trim(),
          'content': content.text.trim(),
        });
      } else {
        await ApiClient.instance.put(
            '/announcements/${existing.announcementId}', {
          'title': title.text.trim(),
          'content': content.text.trim(),
        }, okMsg: 'Announcement updated');
      }
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _deactivate(Announcement a) async {
    final ok = await confirmAction(
        context,
        'Deactivate announcement?',
        'It will be hidden from all users.',
        confirmLabel: 'Deactivate');
    if (!ok) return;
    try {
      await ApiClient.instance.patch('/announcements/${a.announcementId}/deactivate', {},
          okMsg: 'Announcement deactivated');
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _items.isEmpty
          ? const EmptyState(message: 'No announcements yet.')
          : RefreshIndicator(
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
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(a.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                              IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit, size: 17),
                                  onPressed: () => _compose(existing: a)),
                              IconButton(
                                  tooltip: 'Deactivate',
                                  icon: const Icon(Icons.toggle_off,
                                      size: 20, color: Colors.redAccent),
                                  onPressed: () => _deactivate(a)),
                            ],
                          ),
                          Text(a.content,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(timeAgo(a.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              if (!a.isActive) ...[
                                const SizedBox(width: 8),
                                const StatusChip(label: 'Inactive'),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _compose(),
        icon: const Icon(Icons.edit),
        label: const Text('Announce'),
      ),
    );
  }
}

/// ==================== DOCUMENT VERIFICATION QUEUE ====================
class AdminVerificationTab extends StatefulWidget {
  const AdminVerificationTab({super.key});

  @override
  State<AdminVerificationTab> createState() => _AdminVerificationTabState();
}

class _AdminVerificationTabState extends State<AdminVerificationTab> {
  List<DocumentRec> _docs = [];
  List<Travel> _travels = [];
  Map<int, String> _userNames = {};
  bool _loading = true;
  String? _error;
  String _filter = 'Awaiting';

  static const _filters = ['Awaiting', 'Rejected', 'Verified', 'All'];
  static const _awaiting = {
    'Pending',
    'Uploaded',
    'Submitted',
    'Under Verification',
  };
  static const _rejected = {'Rejected', 'Resubmission Required', 'Incomplete'};

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
      final results = await Future.wait([
        ApiClient.instance.get('/documents/?limit=300'),
        ApiClient.instance.get('/travels/?limit=100'),
        ApiClient.instance.get('/users/'),
      ]);
      _docs = (results[0] as List)
          .map((e) => DocumentRec.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _travels = (results[1] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _userNames = {
        for (final u in (results[2] as List))
          (u['user_id'] as int? ?? 0): (u['full_name'] as String? ?? ''),
      };
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DocumentRec> get _visible {
    switch (_filter) {
      case 'Awaiting':
        return _docs.where((d) => _awaiting.contains(d.status)).toList();
      case 'Rejected':
        return _docs.where((d) => _rejected.contains(d.status)).toList();
      case 'Verified':
        return _docs.where((d) => d.status == 'Verified').toList();
      default:
        return _docs;
    }
  }

  String _travelLabel(int id) {
    final t = _travels.where((x) => x.travelId == id);
    if (t.isEmpty) return 'Travel $id';
    final tr = t.first;
    final owner = tr.participantType == 'Student'
        ? (tr.participantName ?? 'Student')
        : (_userNames[tr.userId] ?? 'User #${tr.userId}');
    return '$owner — ${tr.eventTitle}';
  }

  Future<void> _viewScan(DocumentRec d) async {
    final url =
        ApiClient.instance.authedFileUrl('/documents/${d.documentId}/file');
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      await showApiError(context, 'Could not open the uploaded file');
    }
  }

  Future<void> _verify(DocumentRec d) async {
    try {
      await ApiClient.instance.patch('/documents/${d.documentId}/verify',
          <String, dynamic>{},
          okMsg: 'Document verified');
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _aiCheck(DocumentRec d) async {
    try {
      // Phase 8: pull document findings and a suggested remark together.
      final results = await Future.wait([
        ApiClient.instance.get('/ai/document-analysis/${d.documentId}'),
        ApiClient.instance
            .post('/ai/suggest-remark', {'document_id': d.documentId}),
      ]);
      final a =
          DocAnalysis.fromJson(Map<String, dynamic>.from(results[0] as Map));
      final rem = Map<String, dynamic>.from(results[1] as Map);
      if (!mounted) return;
      final pct = ((a.confidence ?? 0) * 100).round();
      final remark = rem['remark'] as String?;
      final issues = (rem['issues'] as List?) ?? const [];
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('AI Document Findings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _aiRow('Suggested type', a.suggestedType ?? '—'),
                _aiRow('Confidence', '$pct%'),
                _aiRow('Declared type', d.docType),
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
                (a.issues == null || a.issues!.isEmpty)
                    ? const Row(children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Color(0xFF059669)),
                        SizedBox(width: 6),
                        Text('No issues detected', style: TextStyle(fontSize: 13))
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
                                              style: const TextStyle(
                                                  fontSize: 12.5))),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Compliance issues',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  ...issues.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('• $s',
                            style: const TextStyle(fontSize: 12.5, height: 1.35)),
                      )),
                ],
                if (remark != null && remark.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Suggested remark: $remark',
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Widget _aiRow(String label, String value) => Padding(
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

  Future<void> _reject(DocumentRec d) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject document'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (required)',
            hintText: 'e.g. Signature not visible',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (ok != true) return;
    final reason = ctrl.text.trim();
    if (reason.isEmpty) {
      Notify.warning('A rejection reason is required');
      return;
    }
    try {
      await ApiClient.instance.patch('/documents/${d.documentId}/reject',
          {'remarks': reason},
          okMsg: 'Document rejected');
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const LoadingBox();
    } else if (_error != null) {
      body = EmptyState(message: 'Error: $_error');
    } else if (_visible.isEmpty) {
      body = EmptyState(message: 'No documents in "$_filter".');
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: _visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = _visible[i];
            final awaiting = _awaiting.contains(d.status);
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
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () => _viewScan(d),
                          icon: const Icon(Icons.visibility_outlined,
                              size: 16, color: Color(0xFF059669)),
                          label: const Text('View Scan',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF059669))),
                        ),
                        if (awaiting) ...[
                          TextButton.icon(
                            onPressed: () => _aiCheck(d),
                            icon: const Icon(Icons.auto_awesome,
                                size: 16, color: Color(0xFF7C3AED)),
                            label: const Text('AI Check',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF7C3AED))),
                          ),
                          TextButton.icon(
                            onPressed: () => _reject(d),
                            icon: const Icon(Icons.cancel_outlined,
                                size: 16, color: Colors.redAccent),
                            label: const Text('Reject',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.redAccent)),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _verify(d),
                            icon: const Icon(Icons.verified_outlined,
                                size: 16),
                            label: const Text('Verify',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                IconButton.filledTonal(
                    onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// ==================== COMPLIANCE DASHBOARD (FR-A05, BR-04, BR-07) ====================
class AdminComplianceTab extends StatefulWidget {
  const AdminComplianceTab({super.key});

  @override
  State<AdminComplianceTab> createState() => _AdminComplianceTabState();
}

class _AdminComplianceTabState extends State<AdminComplianceTab> {
  List<ComplianceRec> _records = [];
  Map<int, Travel> _travelById = {};
  Map<int, String> _userNames = {};
  List<Map<String, dynamic>> _limits = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  String? _priorityFilter;

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
      final params = StringBuffer('limit=100');
      if (_statusFilter != null) {
        params.write('&status=${Uri.encodeComponent(_statusFilter!)}');
      }
      if (_priorityFilter != null) params.write('&priority=$_priorityFilter');
      final results = await Future.wait([
        ApiClient.instance.get('/compliance/records?$params'),
        ApiClient.instance.get('/travels/?limit=100'),
        ApiClient.instance.get('/users/'),
        ApiClient.instance.get('/compliance/travel-limits'),
      ]);
      _records = (results[0] as List)
          .map((e) => ComplianceRec.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _travelById = {
        for (final t in (results[1] as List).map(
            (e) => Travel.fromJson(Map<String, dynamic>.from(e))))
          t.travelId: t,
      };
      _userNames = {
        for (final u in (results[2] as List))
          (u['user_id'] as int? ?? 0): (u['full_name'] as String? ?? ''),
      };
      _limits = (results[3] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recompute(int travelId) async {
    try {
      await ApiClient.instance
          .post('/travels/$travelId/compliance/recompute', {});
      await _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  String _travelLabel(int travelId) {
    final t = _travelById[travelId];
    if (t == null) return 'Travel $travelId';
    final owner = _userNames[t.userId] ?? 'User #${t.userId}';
    return '$owner — ${t.eventTitle}';
  }

  Color _priorityColor(String p) => switch (p) {
        'high' => const Color(0xFFDC2626),
        'medium' => const Color(0xFFF59E0B),
        _ => const Color(0xFF059669),
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) {
      return EmptyState(message: 'Error: $_error');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in const [
                  null,
                  'Fully Compliant',
                  'Partially Compliant',
                  'Needs Action'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s ?? 'All'),
                      selected: _statusFilter == s,
                      onSelected: (_) {
                        setState(() => _statusFilter = s);
                        _load();
                      },
                    ),
                  ),
                for (final p in const [null, 'high', 'medium', 'low'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p ?? 'Any priority'),
                      selected: _priorityFilter == p,
                      onSelected: (_) {
                        setState(() => _priorityFilter = p);
                        _load();
                      },
                    ),
                  ),
                IconButton.filledTonal(
                    onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (_limits.isNotEmpty) ...[
                  SectionCard(
                    title: 'Travel limit exceeded (BR-04)',
                    child: Column(
                      children: _limits
                          .map((l) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.warning_amber,
                                    color: Color(0xFFDC2626)),
                                title: Text(
                                    _userNames[l['faculty_user_id'] as int? ?? 0] ??
                                        'User #${l['faculty_user_id']}'),
                                subtitle: Text(
                                    '${l['travel_count']} travels in ${l['year']} (limit ${l['limit']})'),
                                trailing:
                                    StatusChip(label: 'Exceeded', color: statusColor('High')),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_records.isEmpty)
                  const EmptyState(message: 'No compliance records yet.')
                else
                  ..._records.map((c) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                        color: _priorityColor(c.priority),
                                        shape: BoxShape.circle),
                                  ),
                                  Expanded(
                                    child: Text(_travelLabel(c.travelId),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                  StatusChip(
                                      label: c.status,
                                      color: statusColor(c.status)),
                                  IconButton(
                                    tooltip: 'Recompute',
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: () => _recompute(c.travelId),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: c.docPercent / 100,
                                  minHeight: 6,
                                  backgroundColor: statusColor(c.status)
                                      .withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                      statusColor(c.status)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  'Score ${c.score.toStringAsFixed(1)}%  ·  '
                                  '${c.verifiedDocs}/${c.requiredDocs} docs  ·  '
                                  'priority ${c.priority}',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Row(children: [
                                _flag('Pre', c.preTravelOk),
                                _flag('Post', c.postTravelOk),
                                _flag('Re-entry', c.reentryOk),
                              ]),
                              if (c.computedAt != null &&
                                  c.computedAt!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                      'Computed ${timeAgo(c.computedAt)}',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.grey.shade500)),
                                ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _flag(String label, bool ok) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: ok ? const Color(0xFF059669) : const Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11.5)),
        ]),
      );
}

/// ==================== LIFECYCLE OVERSIGHT (FR-A06, FR-A07, BR-05, BR-06) ====================
class AdminLifecycleTab extends StatefulWidget {
  const AdminLifecycleTab({super.key});

  @override
  State<AdminLifecycleTab> createState() => _AdminLifecycleTabState();
}

class _AdminLifecycleTabState extends State<AdminLifecycleTab> {
  List<Travel> _travels = [];
  Map<int, String> _userNames = {};
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
      final results = await Future.wait([
        ApiClient.instance.get('/travels/?limit=100'),
        ApiClient.instance.get('/users/'),
      ]);
      _travels = (results[0] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => (b.startDate).compareTo(a.startDate));
      _userNames = {
        for (final u in (results[1] as List))
          (u['user_id'] as int? ?? 0): (u['full_name'] as String? ?? ''),
      };
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

  String _ownerLabel(Travel t) =>
      _userNames[t.userId] ?? 'User #${t.userId}';

  // ---------- Admin post-travel actions (FR-A06) ----------

  void _showPostTravelStatusSheet(PostTravelReq r) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Verify "${r.requirement}"',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final s in const [
              'Verified',
              'Incomplete',
              'Waived',
              'Submitted',
              'Not Submitted'
            ])
              ListTile(
                leading: Icon(
                  s == 'Verified' || s == 'Waived'
                      ? Icons.verified_outlined
                      : s == 'Incomplete'
                          ? Icons.cancel_outlined
                          : Icons.schedule,
                  color: statusColor(s),
                ),
                title: Text(s),
                trailing: r.status == s ? const Icon(Icons.check, size: 18) : null,
                onTap: () {
                  Navigator.pop(context);
                  if (r.status != s) _setPostTravelStatus(r, s);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPostTravelStatus(PostTravelReq r, String status) async {
    final t = _selected;
    if (t == null) return;
    try {
      await ApiClient.instance.patch(
          '/travels/${t.travelId}/post-travel/${r.requirementId}',
          {'status': status});
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _addPostTravel() async {
    final t = _selected;
    if (t == null) return;
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
      await ApiClient.instance.post('/travels/${t.travelId}/post-travel/',
          {'requirement': ctrl.text.trim()});
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _deletePostTravel(PostTravelReq r) async {
    final t = _selected;
    if (t == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete requirement?'),
        content: Text(r.requirement),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ApiClient.instance
          .delete('/travels/${t.travelId}/post-travel/${r.requirementId}');
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _uploadPostEvidence(PostTravelReq r) async {
    final t = _selected;
    if (t == null) return;
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
        '/travels/${t.travelId}/post-travel/${r.requirementId}/evidence',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: 'Evidence uploaded',
      );
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  // ---------- Admin re-entry actions (FR-A07) ----------

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
                trailing: a.status == s ? const Icon(Icons.check, size: 18) : null,
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

  Future<void> _setReentryStatus(ReentryActivity a, String status) async {
    final t = _selected;
    if (t == null) return;
    try {
      await ApiClient.instance.patch(
          '/travels/${t.travelId}/re-entry/${a.activityId}',
          {'status': status});
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _addReentry() async {
    final t = _selected;
    if (t == null) return;
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
      await ApiClient.instance.post('/travels/${t.travelId}/re-entry/', {
        'activity': ctrl.text.trim(),
        if (desc.text.trim().isNotEmpty) 'description': desc.text.trim(),
      });
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _deleteReentry(ReentryActivity a) async {
    final t = _selected;
    if (t == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text(a.activity),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ApiClient.instance
          .delete('/travels/${t.travelId}/re-entry/${a.activityId}');
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _uploadReentryEvidence(ReentryActivity a) async {
    final t = _selected;
    if (t == null) return;
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
        '/travels/${t.travelId}/re-entry/${a.activityId}/evidence',
        fields: {},
        fileName: f.name,
        bytes: bytes,
        okMsg: 'Evidence uploaded',
      );
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _recompute() async {
    final t = _selected;
    if (t == null) return;
    try {
      await ApiClient.instance.post('/travels/${t.travelId}/compliance/recompute', {},
          okMsg: 'Compliance recomputed');
      _loadDetail();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    if (_travels.isEmpty) {
      return const EmptyState(message: 'No travel records in the system.');
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
      trailing: IconButton(
        tooltip: 'Recompute compliance',
        icon: const Icon(Icons.calculate_outlined, size: 20),
        onPressed: _recompute,
      ),
      child: DropdownButtonFormField<Travel>(
        value: _selected,
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: _travels
            .map((t) => DropdownMenuItem<Travel>(
                  value: t,
                  child: Text(
                    '${_ownerLabel(t)} — ${t.eventTitle}  ·  ${t.startDate}',
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
                          valueColor:
                              AlwaysStoppedAnimation(statusColor(c.status)),
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
                    '${c.verifiedDocs}/${c.requiredDocs} documents verified  ·  '
                    'priority ${c.priority}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
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
          : Column(children: _postTravel.map(_postTravelTile).toList()),
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
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
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
                  IconButton(
                    tooltip: 'Set status',
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    onPressed: () => _showPostTravelStatusSheet(r),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _deletePostTravel(r),
                  ),
                ],
              ),
              if (r.hasEvidence)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    const Icon(Icons.attach_file, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          r.evidencePath!.split(RegExp(r'[\\/]')).last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ]),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(
                      r.hasEvidence ? Icons.upload_file : Icons.cloud_upload,
                      size: 16),
                  label: Text(r.hasEvidence ? 'Replace' : 'Upload evidence'),
                  onPressed: () => _uploadPostEvidence(r),
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
          ? Text('No re-entry activities yet.\nTap + to add one.',
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
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
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
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _deleteReentry(a),
                  ),
                ],
              ),
              if (a.description != null && a.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(a.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade700)),
                ),
              if (a.hasEvidence)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    const Icon(Icons.attach_file, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          a.evidencePath!.split(RegExp(r'[\\/]')).last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ]),
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

/// ==================== AUDIT LOG (FR-A15, BR-10) ====================
class AdminAuditTab extends StatefulWidget {
  const AdminAuditTab({super.key});

  @override
  State<AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<AdminAuditTab> {
  List<AuditLogRow> _rows = [];
  Map<int, String> _userNames = {};
  bool _loading = true;
  String? _error;
  String? _entityFilter;
  String? _actionFilter;

  static const _entityTypes = [
    null,
    'user',
    'travel',
    'document',
    'compliance',
    'post_travel',
    'reentry',
    'announcement',
    'system',
  ];
  static const _actions = [
    null,
    'create',
    'update',
    'delete',
    'login',
    'verify',
    'reject',
    'approve',
    'status_change',
    'deactivate',
  ];

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
      final params = StringBuffer('limit=200');
      if (_entityFilter != null) {
        params.write('&entity_type=${Uri.encodeComponent(_entityFilter!)}');
      }
      if (_actionFilter != null) {
        params.write('&action=${Uri.encodeComponent(_actionFilter!)}');
      }
      final results = await Future.wait([
        ApiClient.instance.get('/audit-logs?$params'),
        ApiClient.instance.get('/users/'),
      ]);
      _rows = (results[0] as List)
          .map((e) => AuditLogRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _userNames = {
        for (final u in (results[1] as List))
          (u['user_id'] as int? ?? 0): (u['full_name'] as String? ?? ''),
      };
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _actionColor(String a) => switch (a) {
        'create' || 'login' || 'verify' || 'approve' => const Color(0xFF059669),
        'delete' || 'reject' || 'deactivate' => const Color(0xFFDC2626),
        'update' || 'status_change' => const Color(0xFFF59E0B),
        _ => Colors.grey.shade600,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in _entityTypes)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(e ?? 'All entities'),
                      selected: _entityFilter == e,
                      onSelected: (_) {
                        setState(() => _entityFilter = e);
                        _load();
                      },
                    ),
                  ),
                for (final a in _actions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(a ?? 'All actions'),
                      selected: _actionFilter == a,
                      onSelected: (_) {
                        setState(() => _actionFilter = a);
                        _load();
                      },
                    ),
                  ),
                IconButton.filledTonal(
                    onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const EmptyState(message: 'No audit-log entries yet.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final r = _rows[i];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.bolt,
                              size: 18, color: _actionColor(r.action)),
                          title: Text(
                              r.description ?? '${r.entityType} #${r.entityId}',
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${_userNames[r.userId] ?? 'User #${r.userId}'}  ·  '
                              '${r.entityType}  ·  ${r.action}'
                              '${r.entityId != null ? '  ·  #${r.entityId}' : ''}'
                              '${r.createdAt != null ? '\n${timeAgo(r.createdAt)}' : ''}',
                              style: const TextStyle(fontSize: 11)),
                          isThreeLine: true,
                          trailing: StatusChip(
                              label: r.action, color: _actionColor(r.action)),
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

/// ==================== REMARKS REVIEW (FR-A15, BR-12) ====================
class AdminRemarksTab extends StatefulWidget {
  const AdminRemarksTab({super.key});

  @override
  State<AdminRemarksTab> createState() => _AdminRemarksTabState();
}

class _AdminRemarksTabState extends State<AdminRemarksTab> {
  List<RemarkRow> _rows = [];
  Map<int, String> _adminNames = {};
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
      final results = await Future.wait([
        ApiClient.instance.get('/remarks?limit=200'),
        ApiClient.instance.get('/users/'),
        ApiClient.instance.get('/travels/?limit=100'),
      ]);
      _rows = (results[0] as List)
          .map((e) => RemarkRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _adminNames = {
        for (final u in (results[1] as List))
          (u['user_id'] as int? ?? 0): (u['full_name'] as String? ?? ''),
      };
      _travelById = {
        for (final t in (results[2] as List).map(
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
              child: EmptyState(message: 'No remarks recorded yet.')),
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
                child: Text('${_rows.length} remarks',
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
                              Text('${r.previousStatus} → ${r.newStatus}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                        if (r.remarkText != null && r.remarkText!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(r.remarkText!,
                                style: const TextStyle(fontSize: 12.5)),
                          ),
                        const SizedBox(height: 4),
                        Text(
                            'Travel #${r.travelId ?? '—'}'
                            '${travel != null ? ' (${travel.eventTitle})' : ''}'
                            '  ·  by ${_adminNames[r.adminId] ?? 'Admin #${r.adminId}'}'
                            '${r.createdAt != null ? '  ·  ${timeAgo(r.createdAt)}' : ''}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
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
