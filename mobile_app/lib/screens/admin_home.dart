import 'package:flutter/material.dart';

import '../account.dart';
import '../api.dart';
import '../models.dart';
import '../notify.dart';
import '../widgets.dart';
import 'admin_sections.dart';
import 'login_screen.dart';
import 'requirements_sections.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  static const _titles = [
    'Admin Dashboard',
    'Global Travel Registry',
    'Student Records',
    'User Management',
    'Reports',
    'Document Types',
    'Announcements',
    'SIAP Internships',
    'Mobility Plan Distribution',
    'AI Analysis',
    'Settings',
    'More',
    'Document Verification',
    'Compliance',
    'Lifecycle',
    'Audit Log',
    'Remarks',
    'Requirement Checklists',
  ];

  static const _bottomMap = [0, 1, 3, 6, 11];

  static const _sidebarItems = [
    SidebarItem(0, 'Dashboard', Icons.home_outlined),
    SidebarItem(1, 'Global Travel Data', Icons.public),
    SidebarItem(2, 'Student Records', Icons.school_outlined),
    SidebarItem(3, 'User Management', Icons.people_outline),
    SidebarItem(13, 'Compliance Requirements',
        Icons.assignment_turned_in_outlined),
    SidebarItem(5, 'Document Types', Icons.description_outlined),
    SidebarItem(6, 'Announcements', Icons.volume_up_outlined),
    SidebarItem(4, 'Reports', Icons.bar_chart_outlined),
    SidebarItem(7, 'SIAP', Icons.work_outline),
    SidebarItem(8, 'Mobility Plan', Icons.language),
    SidebarItem(9, 'AI Analysis', Icons.track_changes_outlined),
    SidebarItem(10, 'Settings', Icons.settings_outlined),
    SidebarItem(11, 'More', Icons.grid_view_outlined),
  ];

  void _go(int i) => setState(() => _index = i);

  int get _bottomSelected {
    final pos = _bottomMap.indexOf(_index);
    return pos == -1 ? 4 : pos;
  }

  int get _sidebarActive => _sidebarItems.any((i) => i.index == _index)
      ? _index
      : 11; // extras (Verification/Lifecycle/Audit/Remarks) highlight "More"

  List<Widget> _pages() => [
        const _AdminDashboard(),
        const _GlobalRegistry(),
        const AdminStudentsTab(),
        const _UsersTab(),
        const AdminReportsTab(),
        const AdminDocTypesTab(),
        const AdminAnnouncementsTab(),
        const _SiapTab(),
        const _AdminPlanTab(),
        const AdminAiAnalysisTab(),
        ListView(
          padding: const EdgeInsets.all(16),
          children: const [ProfileForm(), ChangePasswordForm()],
        ),
        MoreGrid(
          onSelect: _go,
          items: const [
            MoreItem(12, 'Verification', Icons.fact_check_outlined),
            MoreItem(13, 'Compliance', Icons.verified_user_outlined),
            MoreItem(14, 'Lifecycle', Icons.flight_land_outlined),
            MoreItem(15, 'Audit Log', Icons.history_outlined),
            MoreItem(16, 'Remarks', Icons.forum_outlined),
            MoreItem(17, 'Checklists', Icons.fact_check_outlined),
            MoreItem(2, 'Students', Icons.school_outlined),
            MoreItem(4, 'Reports', Icons.summarize_outlined),
            MoreItem(5, 'Doc Types', Icons.description_outlined),
            MoreItem(7, 'SIAP', Icons.work_outline),
            MoreItem(8, 'Plans', Icons.public),
            MoreItem(9, 'AI Analysis', Icons.insights_outlined),
            MoreItem(10, 'Settings', Icons.settings_outlined),
          ],
        ),
        const AdminVerificationTab(),
        const AdminComplianceTab(),
        const AdminLifecycleTab(),
        const AdminAuditTab(),
        const AdminRemarksTab(),
        const AdminChecklistsTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final pages = _pages();
    final title = _titles[_index];
    if (isWide) {
      return Scaffold(
        appBar: BrandedHeader(
          title: title,
          actions: [const NotificationBell(), _logoutBtn(context)],
        ),
        body: Row(
          children: [
            AppSidebar(
              items: _sidebarItems,
              activeIndex: _sidebarActive,
              onSelected: (it) => _go(it.index),
              portalTag: 'Admin Portal (Dashboard)',
              onLogout: () => _logout(context),
            ),
            const VerticalDivider(width: 1),
            Expanded(
                child: AppBackground(
                    child: IndexedStack(index: _index, children: pages))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: BrandedHeader(
        title: title,
        actions: [const NotificationBell(), _logoutBtn(context)],
      ),
      body: AppBackground(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomSelected,
        onDestinationSelected: (i) => setState(() => _index = _bottomMap[i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.flight_takeoff_outlined),
              selectedIcon: Icon(Icons.flight_takeoff),
              label: 'Registry'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Notices'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'More'),
        ],
      ),
    );
  }

  Widget _logoutBtn(BuildContext context) => IconButton(
        tooltip: 'Logout',
        icon: const Icon(Icons.logout),
        onPressed: () => _logout(context),
      );

  Future<void> _logout(BuildContext context) async {
    await Session.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
    Notify.success('Signed out successfully');
  }
}

// ==================== DASHBOARD ====================

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  Map<String, dynamic>? _summary;
  int _userCount = 0;
  int _collegeCount = 0;
  Map<String, dynamic>? _docStats;
  List<Travel> _recent = [];
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
        ApiClient.instance.get('/analytics/system/summary'),
        ApiClient.instance.get('/users/'),
        ApiClient.instance.get('/colleges/'),
        ApiClient.instance.get('/documents/stats/summary'),
        ApiClient.instance.get('/travels/?limit=5'),
      ]);
      _summary = Map<String, dynamic>.from(results[0] as Map);
      _userCount = (results[1] as List).length;
      _collegeCount = (results[2] as List).length;
      _docStats = Map<String, dynamic>.from(results[3] as Map);
      _recent = (results[4] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
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
    final s = _summary!;
    final risk = Map<String, dynamic>.from(s['risk_analysis'] as Map? ?? {});

    final hero = DashboardHero(
      name: Session.instance.fullName ?? 'OIGE Admin',
      tagline: 'Oversee. Manage. Empower.',
      subtext:
          'Welcome to SmartTrack Admin \u2014 your command center for global '
          'travel oversight, compliance monitoring, and institutional management.',
      pills: const [
        (Icons.people_outline, 'User Management'),
        (Icons.public, 'Global Travel Data'),
        (Icons.shield_outlined, 'Compliance Reports'),
        (Icons.track_changes_outlined, 'AI Analysis'),
      ],
    );

    final stats = <Widget>[
      StatCard(
          label: 'Total Travel Records',
          value: '${s['total_travels'] ?? 0}',
          color: const Color(0xFF10B981),
          icon: Icons.flight_takeoff),
      StatCard(
          label: 'Total Users',
          value: '$_userCount',
          color: const Color(0xFF2563EB),
          icon: Icons.people),
      StatCard(
          label: 'Compliance Rate',
          value: '${s['compliance_rate'] ?? 0}%',
          color: const Color(0xFFF59E0B),
          icon: Icons.verified_outlined),
      StatCard(
          label: 'High Risk',
          value: '${risk['high_risk'] ?? 0}',
          color: const Color(0xFFDC2626),
          icon: Icons.warning_amber),
      StatCard(
          label: 'Medium Risk',
          value: '${risk['medium_risk'] ?? 0}',
          color: const Color(0xFFF59E0B),
          icon: Icons.error_outline),
      StatCard(
          label: 'Low Risk',
          value: '${risk['low_risk'] ?? 0}',
          color: const Color(0xFF10B981),
          icon: Icons.shield_outlined),
      StatCard(
          label: 'Total Colleges',
          value: '$_collegeCount',
          color: const Color(0xFF7C3AED),
          icon: Icons.account_balance_outlined),
      StatCard(
          label: 'Documents',
          value: '${_docStats?['total_documents'] ?? 0}',
          color: const Color(0xFF0891B2),
          icon: Icons.description_outlined),
      StatCard(
          label: 'Doc Verification',
          value: '${_docStats?['verification_rate'] ?? 0}%',
          color: const Color(0xFF10B981),
          icon: Icons.verified_outlined),
    ];

    final recentPanel = SectionCard(
      title: 'Recent Activity',
      child: _recent.isEmpty
          ? const EmptyState(message: 'No recent activity.')
          : Column(
              children: [
                for (var i = 0; i < _recent.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _recentRow(_recent[i]),
                ],
              ],
            ),
    );

    final aiPanel = SectionCard(
      title: 'AI Insights',
      child: Text(
        'Students abroad: ${s['students_abroad'] ?? 0} · '
        'Faculty mobility: ${s['faculty_mobility'] ?? 0} · '
        'Average risk score: ${s['average_risk_score'] ?? 0}',
        style: const TextStyle(fontSize: 13, height: 1.5),
      ),
    );

    final leftChildren = [
      hero,
      const SizedBox(height: 16),
      _statsGrid(stats),
      const SizedBox(height: 6),
      recentPanel,
    ];
    final rightChildren = [
      const PortalDateCard(portal: 'CSUCC OIGE Admin Portal'),
      const SizedBox(height: 16),
      aiPanel,
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(builder: (context, cons) {
        if (cons.maxWidth >= 1150) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                    padding: const EdgeInsets.all(16), children: leftChildren),
              ),
              SizedBox(
                width: 316,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    children: rightChildren),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...leftChildren,
            const SizedBox(height: 4),
            ...rightChildren,
          ],
        );
      }),
    );
  }

  Widget _statsGrid(List<Widget> cards) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cols = w >= 760 ? 5 : w >= 520 ? 3 : 2;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: cards,
          );
        },
      );

  Widget _recentRow(Travel t) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.flight_takeoff,
              size: 17, color: Color(0xFF059669)),
        ),
        title: Text(t.eventTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
            '${t.participantType} · ${t.mobilityType} · ${t.startDate}',
            style: const TextStyle(fontSize: 11.5)),
        trailing: StatusChip(label: t.timelineStatus ?? 'Upcoming'),
      );
}

// ==================== GLOBAL REGISTRY ====================

class _GlobalRegistry extends StatefulWidget {
  const _GlobalRegistry();

  @override
  State<_GlobalRegistry> createState() => _GlobalRegistryState();
}

class _GlobalRegistryState extends State<_GlobalRegistry> {
  List<Travel> _travels = [];
  List<College> _colleges = [];
  bool _loading = true;
  String? _error;

  String? _year;
  String? _mobility;
  int? _collegeId;
  String? _participant;

  static const _years = ['2026', '2025', '2024'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> get _filters => {
        if (_year != null) 'year': _year,
        if (_mobility != null) 'mobility_type': _mobility,
        if (_collegeId != null) 'college_id': '$_collegeId',
        if (_participant != null) 'participant_type': _participant,
      };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _filters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      final results = await Future.wait([
        ApiClient.instance.get('/travels/?limit=100${query.isEmpty ? '' : '&$query'}'),
        ApiClient.instance.get('/colleges/'),
      ]);
      _travels = (results[0] as List)
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

  Future<String?> _userName(int userId) async {
    try {
      final u = await ApiClient.instance.get('/users/$userId');
      return (u as Map)['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterDropdown<String>(
                  value: _year,
                  hint: 'Year',
                  items: _years,
                  onChanged: (v) {
                    setState(() => _year = v);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _filterDropdown<String>(
                  value: _mobility,
                  hint: 'Mobility',
                  items: kMobilityTypes,
                  onChanged: (v) {
                    setState(() => _mobility = v);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _filterDropdown<int>(
                  value: _collegeId,
                  hint: 'College',
                  items: _colleges.map((c) => c.collegeId).toList(),
                  labelOf: (id) => _colleges
                      .firstWhere((c) => c.collegeId == id)
                      .code,
                  onChanged: (v) {
                    setState(() => _collegeId = v);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _filterDropdown<String>(
                  value: _participant,
                  hint: 'Participant',
                  items: const ['Faculty', 'Student'],
                  onChanged: (v) {
                    setState(() => _participant = v);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                    onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBox()
              : _error != null
                  ? EmptyState(message: 'Error: $_error')
                  : _travels.isEmpty
                      ? const EmptyState(message: 'No travel records found.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _travels.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = _travels[i];
                              return FutureBuilder<String?>(
                                future: _userName(t.userId),
                                builder: (_, snap) => Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.grey.shade200)),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                    childrenPadding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    collapsedShape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  t.participantType ==
                                                          'Student'
                                                      ? (t.participantName ??
                                                          'Student')
                                                      : (snap.data ??
                                                          'Faculty'),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14)),
                                            ),
                                            StatusChip(
                                                label: t.workflowStatus ??
                                                    'Submitted'),
                                            IconButton(
                                              tooltip: 'Workflow',
                                              icon: const Icon(
                                                  Icons.swap_horiz,
                                                  size: 20),
                                              onPressed: () =>
                                                  showWorkflowDialog(
                                                      context, t, _load),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${t.eventTitle}\n${t.mobilityType} · ${t.country ?? ''} · ${t.startDate}',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      PreTravelDocPanel(
                                          travelId: t.travelId),
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

  Widget _filterDropdown<T>({
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

// ==================== USERS ====================

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<User> _users = [];
  List<College> _colleges = [];
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
        ApiClient.instance.get('/users/'),
        ApiClient.instance.get('/colleges/'),
      ]);
      _users = (results[0] as List)
          .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
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

  Future<void> _addUser() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final designation = TextEditingController();
    String role = 'faculty';
    int? collegeId;

    bool showPw = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          InputDecoration dec(IconData icon, String hint) => InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 14.5, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(icon, size: 17, color: const Color(0xFF64748B)),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 46, minHeight: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFCBD5E1), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFD4A323), width: 1.5),
                ),
              );

          Widget lbl(String text, {bool req = false}) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  if (req)
                    const Text(' *',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444))),
                ],
              );

          Widget group(String label, Widget input, {bool req = false}) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [lbl(label, req: req), const SizedBox(height: 6), input],
              );

          final nameField = group(
              'Full Name',
              TextField(
                  controller: name,
                  decoration: dec(Icons.person_outline, 'Juan Dela Cruz')),
              req: true);
          final emailField = group(
              'Email',
              TextField(
                  controller: email,
                  decoration:
                      dec(Icons.mail_outline, 'name@csucc.edu.ph')),
              req: true);
          final pwField = group(
              'Password',
              TextField(
                controller: password,
                obscureText: !showPw,
                decoration: dec(Icons.lock_outline, 'Minimum 8 characters')
                    .copyWith(
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                        showPw
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF64748B)),
                    onPressed: () => setD(() => showPw = !showPw),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 42, minHeight: 0),
                ),
              ),
              req: true);
          final roleField = group(
              'Role',
              DropdownButtonFormField<String>(
                value: role,
                icon: const SizedBox.shrink(),
                decoration: dec(Icons.group_outlined, 'Role').copyWith(
                  suffixIcon: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: Color(0xFF64748B)),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 0),
                ),
                items: const [
                  DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                  DropdownMenuItem(
                      value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (v) => setD(() => role = v ?? 'faculty'),
              ),
              req: true);
          final desigField = group(
              'Designation',
              TextField(
                  controller: designation,
                  decoration:
                      dec(Icons.badge_outlined, 'e.g. Dean, Campus Director')));
          final collegeField = group(
              'College',
              DropdownButtonFormField<int>(
                value: collegeId,
                icon: const SizedBox.shrink(),
                decoration: dec(Icons.school_outlined, 'College').copyWith(
                  suffixIcon: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: Color(0xFF64748B)),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 0),
                ),
                items: [
                  const DropdownMenuItem<int>(
                      value: null, child: Text('None')),
                  ..._colleges.map((c) => DropdownMenuItem(
                      value: c.collegeId, child: Text(c.code))),
                ],
                onChanged: (v) => setD(() => collegeId = v),
              ));

          final rows = <List<Widget>>[
            [nameField, emailField],
            [pwField, roleField],
            [desigField, collegeField],
          ];

          final formGrid = LayoutBuilder(builder: (c, constraints) {
            if (constraints.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    rows[i][0],
                    const SizedBox(height: 14),
                    rows[i][1],
                  ],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: rows[i][0]),
                      const SizedBox(width: 24),
                      Expanded(child: rows[i][1]),
                    ],
                  ),
                ],
              ],
            );
          });

          final banner = Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFFDF8E6),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 15, color: Color(0xFFA16207)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    role == 'super_admin'
                        ? 'Note: only 2 active super-admin accounts are allowed. The user will be asked to sign in again after a role change.'
                        : 'The new account can sign in with this password right away. Ask the user to change it later from Account settings.',
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF854D0E),
                        height: 1.45),
                  ),
                ),
              ],
            ),
          );

          return Dialog(
            clipBehavior: Clip.antiAlias,
            backgroundColor: Colors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFD4A323), width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    bottom: 0,
                    child: CustomPaint(
                        size: Size(280, 120), painter: _CaCornerDecor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFC48C1A),
                                        Color(0xFFAA7209)
                                      ]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Color(0x40AA7209),
                                        blurRadius: 12,
                                        offset: Offset(0, 4)),
                                  ],
                                ),
                                child: const Icon(Icons.person_add_alt_1,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Create Account',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                            height: 1.2)),
                                    SizedBox(height: 3),
                                    Text(
                                        'Fill in the required information to create a new account.',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF64748B),
                                            height: 1.3)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close,
                                      size: 20, color: Color(0xFF64748B)),
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Row(
                            children: [
                              Icon(Icons.article_outlined,
                                  size: 17, color: Color(0xFFB8860B)),
                              SizedBox(width: 8),
                              Text('Account Information',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B))),
                              SizedBox(width: 6),
                              Expanded(
                                child: SizedBox(
                                    height: 1.5,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: Color(0xFFE8D08D)))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          formGrid,
                          banner,
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: Color(0xFFB8860B), width: 1.5),
                                  foregroundColor: const Color(0xFF1E293B),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 34, vertical: 12),
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(
                                      fontSize: 14.7,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 14),
                              _GoldPillButton(
                                icon: Icons.save_outlined,
                                label: 'Create',
                                onTap: () => Navigator.pop(ctx, true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.post('/users/', {
        'full_name': name.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        'role': role,
        'designation': designation.text.trim().isEmpty
            ? null
            : designation.text.trim(),
        'college_id': collegeId,
      }, okMsg: 'User created');
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _editUser(User u) async {
    final name = TextEditingController(text: u.fullName);
    final emailRO = TextEditingController(text: u.email);
    final designation = TextEditingController(text: u.designation ?? '');
    final rank = TextEditingController(text: u.academicRank ?? '');
    String role = u.role;
    int? collegeId = u.collegeId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          InputDecoration dec(IconData icon, String hint) => InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 14.5, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(icon, size: 17, color: const Color(0xFF64748B)),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 46, minHeight: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFCBD5E1), width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFCBD5E1), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFD4A323), width: 1.5),
                ),
              );

          Widget lbl(String text, {bool req = false}) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  if (req)
                    const Text(' *',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444))),
                ],
              );

          Widget group(String label, Widget input, {bool req = false}) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [lbl(label, req: req), const SizedBox(height: 6), input],
              );

          final nameField = group(
              'Full Name',
              TextField(
                  controller: name,
                  decoration: dec(Icons.person_outline, 'Full name')),
              req: true);
          final emailField = group(
              'Email',
              TextField(
                  controller: emailRO,
                  enabled: false,
                  style: const TextStyle(
                      fontSize: 14.5, color: Color(0xFF64748B)),
                  decoration: dec(Icons.mail_outline, '')));
          final desigField = group(
              'Designation',
              TextField(
                  controller: designation,
                  decoration:
                      dec(Icons.badge_outlined, 'e.g. Dean, Campus Director')));
          final rankField = group(
              'Academic Rank',
              TextField(
                  controller: rank,
                  decoration: dec(Icons.workspace_premium_outlined,
                      'e.g. Associate Professor')));
          final roleField = group(
              'Role',
              DropdownButtonFormField<String>(
                value: role,
                icon: const SizedBox.shrink(),
                decoration: dec(Icons.group_outlined, 'Role').copyWith(
                  suffixIcon: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: Color(0xFF64748B)),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 0),
                ),
                items: const [
                  DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                  DropdownMenuItem(
                      value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (v) => setD(() => role = v ?? 'faculty'),
              ),
              req: true);
          final collegeField = group(
              'College',
              DropdownButtonFormField<int>(
                value: collegeId,
                icon: const SizedBox.shrink(),
                decoration: dec(Icons.school_outlined, 'College').copyWith(
                  suffixIcon: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: Color(0xFF64748B)),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 0),
                ),
                items: [
                  const DropdownMenuItem<int>(
                      value: null, child: Text('None')),
                  ..._colleges.map((c) => DropdownMenuItem(
                      value: c.collegeId, child: Text(c.code))),
                ],
                onChanged: (v) => setD(() => collegeId = v),
              ));

          final rows = <List<Widget>>[
            [nameField, emailField],
            [desigField, rankField],
            [roleField, collegeField],
          ];

          final formGrid = LayoutBuilder(builder: (c, constraints) {
            if (constraints.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    rows[i][0],
                    const SizedBox(height: 14),
                    rows[i][1],
                  ],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: rows[i][0]),
                      const SizedBox(width: 24),
                      Expanded(child: rows[i][1]),
                    ],
                  ),
                ],
              ],
            );
          });

          final banner = Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFFDF8E6),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 15, color: Color(0xFFA16207)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    role != u.role
                        ? 'Changing the role will block this account until it is reactivated. The user will be asked to sign in again.'
                        : 'Account details are saved immediately. A role change will require the user to sign in again.',
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF854D0E),
                        height: 1.45),
                  ),
                ),
              ],
            ),
          );

          return Dialog(
            clipBehavior: Clip.antiAlias,
            backgroundColor: Colors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFD4A323), width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    bottom: 0,
                    child: CustomPaint(
                        size: Size(280, 120), painter: _CaCornerDecor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFC48C1A),
                                        Color(0xFFAA7209)
                                      ]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Color(0x40AA7209),
                                        blurRadius: 12,
                                        offset: Offset(0, 4)),
                                  ],
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Edit Account',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                            height: 1.2)),
                                    SizedBox(height: 3),
                                    Text(
                                        'Update the account information below.',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF64748B),
                                            height: 1.3)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close,
                                      size: 20, color: Color(0xFF64748B)),
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Row(
                            children: [
                              Icon(Icons.article_outlined,
                                  size: 17, color: Color(0xFFB8860B)),
                              SizedBox(width: 8),
                              Text('Account Information',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B))),
                              SizedBox(width: 6),
                              Expanded(
                                child: SizedBox(
                                    height: 1.5,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: Color(0xFFE8D08D)))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          formGrid,
                          banner,
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: Color(0xFFB8860B), width: 1.5),
                                  foregroundColor: const Color(0xFF1E293B),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 34, vertical: 12),
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(
                                      fontSize: 14.7,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 14),
                              _GoldPillButton(
                                icon: Icons.check_rounded,
                                label: 'Save Changes',
                                onTap: () => Navigator.pop(ctx, true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.put('/users/${u.userId}', {
        'full_name': name.text.trim(),
        'designation': designation.text.trim().isEmpty
            ? null
            : designation.text.trim(),
        'academic_rank':
            rank.text.trim().isEmpty ? null : rank.text.trim(),
        'college_id': collegeId,
      }, okMsg: 'User updated');
      if (role != u.role) {
        // Role changes go through the guarded endpoint (max-2 cap;
        // the account is blocked and must be reactivated afterwards).
        // The server's confirmation message becomes the success toast.
        await ApiClient.instance
            .post('/users/${u.userId}/role', {'role': role});
      }
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _reactivate(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CaConfirmDialog(
        title: 'Reactivate user?',
        message: '${u.fullName} will be able to log in again.',
        avatarIcon: Icons.how_to_reg_outlined,
        avatarGradient: const [Color(0xFF34D399), Color(0xFF059669)],
        confirmLabel: 'Reactivate',
        confirmIcon: Icons.check_circle_outline,
        confirmGradient: const [Color(0xFF22C55E), Color(0xFF15803D)],
        confirmShadow: const Color(0x5915803D),
      ),
    );
    if (ok != true) return;
    try {
      // Server replies with its own confirmation message — used as the toast.
      await ApiClient.instance.post('/users/${u.userId}/reactivate', {});
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _deactivate(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => _CaConfirmDialog(
        title: 'Deactivate user?',
        message: '${u.fullName} will no longer be able to log in '
            'and will be logged out instantly from all devices.',
        avatarIcon: Icons.person_off_outlined,
        avatarGradient: const [Color(0xFFF87171), Color(0xFFB91C1C)],
        confirmLabel: 'Deactivate',
        confirmIcon: Icons.block_outlined,
        confirmGradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        confirmShadow: const Color(0x59B91C1C),
        notice: 'You can reactivate this account anytime from User Management.',
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/users/${u.userId}');
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final u = _users[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(u.fullName.isEmpty
                      ? '?'
                      : u.fullName[0].toUpperCase())),
                title: Text(u.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                    '${u.email}\n${u.role == 'super_admin' ? 'Admin' : 'Faculty'}'
                    ' · ${u.academicRank ?? 'N/A'}'
                    ' · ${u.designation ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editUser(u)),
                    if (u.isActive)
                      IconButton(
                          tooltip: 'Deactivate',
                          icon: const Icon(Icons.block,
                              size: 20, color: Colors.redAccent),
                          onPressed: () => _deactivate(u))
                    else
                      TextButton(
                          onPressed: () => _reactivate(u),
                          child: const Text('Reactivate',
                              style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
}

// ==================== SIAP ====================

const List<String> kSiapStatuses = [
  'Not Started',
  'Started',
  'Ongoing',
  'Completed',
];

class _SiapTab extends StatefulWidget {
  const _SiapTab();

  @override
  State<_SiapTab> createState() => _SiapTabState();
}

class _SiapTabState extends State<_SiapTab> {
  List<Siap> _rows = [];
  bool _loading = true;
  String? _error;
  List<College> _collegesCache = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _load();
    await _ensureColleges();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/siap/');
      _rows = (data as List)
          .map((e) => Siap.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final idNo = TextEditingController();
    final program = TextEditingController();
    final fhe = TextEditingController();
    final colleges = _collegesCache;
    int? collegeId =
        colleges.isNotEmpty ? colleges.first.collegeId : null;
    String status = 'Not Started';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add SIAP Internship'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Student Name *')),
                const SizedBox(height: 10),
                TextField(
                    controller: idNo,
                    decoration:
                        const InputDecoration(labelText: 'Student ID No.')),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: collegeId,
                  decoration: const InputDecoration(labelText: 'College *'),
                  items: colleges
                      .map((c) => DropdownMenuItem(
                          value: c.collegeId, child: Text(c.code)))
                      .toList(),
                  onChanged: (v) => setD(() => collegeId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: program,
                    decoration: const InputDecoration(labelText: 'Program')),
                const SizedBox(height: 10),
                TextField(
                    controller: fhe,
                    decoration: const InputDecoration(
                        labelText: 'Foreign Host Establishment')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: kSiapStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setD(() => status = v ?? 'Not Started'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.post('/siap/', {
        'student_name': name.text.trim(),
        'student_id_no':
            idNo.text.trim().isEmpty ? null : idNo.text.trim(),
        'college_id': collegeId,
        'program': program.text.trim().isEmpty ? null : program.text.trim(),
        'fhe_name': fhe.text.trim().isEmpty ? null : fhe.text.trim(),
        'status': status,
      });
      _load();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _ensureColleges() async {
    if (_collegesCache.isNotEmpty) return;
    try {
      final data = await ApiClient.instance.get('/colleges/');
      _collegesCache = (data as List)
          .map((e) => College.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
  }

  Future<void> _delete(Siap s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete SIAP record?'),
        content: Text(s.studentName),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/siap/${s.internshipId}');
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
      body: _rows.isEmpty
          ? const EmptyState(
              message: 'No SIAP internships yet.\nTap + to add one.')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = _rows[i];
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
                                child: Text(
                                    '${s.studentName}'
                                    '${s.studentIdNo == null ? '' : ' (${s.studentIdNo})'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  onPressed: () => _delete(s)),
                            ],
                          ),
                          if (s.program != null)
                            Text(s.program!,
                                style: const TextStyle(fontSize: 12)),
                          if (s.fheName != null)
                            Text('FHE: ${s.fheName}',
                                style: const TextStyle(fontSize: 12)),
                          if (s.internshipStart != null)
                            Text(
                                'Internship: ${s.internshipStart} → ${s.internshipEnd ?? ''}',
                                style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('Status: ',
                                  style: TextStyle(fontSize: 12)),
                              DropdownButton<String>(
                                value: s.status,
                                isDense: true,
                                items: kSiapStatuses
                                    .map((st) => DropdownMenuItem(
                                        value: st, child: Text(st)))
                                    .toList(),
                                onChanged: (v) async {
                                  if (v == null) return;
                                  try {
                                    await ApiClient.instance.patch(
                                        '/siap/${s.internshipId}/status',
                                        {'status': v});
                                    _load();
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    await showApiError(context, e);
                                  }
                                },
                              ),
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
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add Internship'),
      ),
    );
  }
}

// ==================== MOBILITY PLAN DISTRIBUTION ====================

class _AdminPlanTab extends StatefulWidget {
  const _AdminPlanTab();

  @override
  State<_AdminPlanTab> createState() => _AdminPlanTabState();
}

class _AdminPlanTabState extends State<_AdminPlanTab> {
  Map<String, dynamic>? _dist;
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
      final d = await ApiClient.instance.get('/mobility-plans/distribution');
      _dist = Map<String, dynamic>.from(d as Map);
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
    final d = _dist!;
    final readiness = {for (final r in (d['by_readiness'] as List? ?? []))
      (r as Map)['readiness_status'] as String: r['total_plans']};
    final byCollege = (d['by_college'] as List? ?? []).cast<Map>();
    final byRank = (d['by_academic_rank'] as List? ?? []).cast<Map>();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Equitable Distribution of Mobility Opportunities',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Total Plans',
                    value: '${d['total_plans'] ?? 0}',
                    color: const Color(0xFF059669),
                    icon: Icons.assignment_outlined)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Ready',
                    value: '${readiness['Ready'] ?? 0}',
                    color: const Color(0xFF1D4ED8),
                    icon: Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Preparing',
                    value: '${readiness['Preparing'] ?? 0}',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.hourglass_top)),
          ]),
          const SizedBox(height: 8),
          StatCard(
              label: 'Interested',
              value: '${readiness['Interested'] ?? 0}',
              color: const Color(0xFF7C3AED),
              icon: Icons.lightbulb_outline),
          const SizedBox(height: 16),
          _distTable(context, 'By College', byCollege, (m) {
            final code = m['code'] ?? '';
            final name = m['name'] ?? '';
            return '$code $name'.trim();
          }),
          const SizedBox(height: 12),
          _distTable(context, 'By Academic Rank', byRank,
              (m) => (m['academic_rank'] ?? 'N/A').toString()),
        ],
      ),
    );
  }

  Widget _distTable(BuildContext context, String title, List<Map> rows,
      String Function(Map) label) {
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
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text('No plans yet.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
            else
              ...rows.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(label(m),
                                style: const TextStyle(fontSize: 13))),
                        StatusChip(
                            label: '${m['total_plans']}',
                            color: const Color(0xFF1D4ED8)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _GoldPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color>? gradient;
  final Color? shadowColor;

  const _GoldPillButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.gradient,
      this.shadowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient ?? const [Color(0xFFC88D1D), Color(0xFFA86F0B)]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: shadowColor ?? const Color(0x59A86F0B),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14.7,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData avatarIcon;
  final List<Color> avatarGradient;
  final String confirmLabel;
  final IconData confirmIcon;
  final List<Color> confirmGradient;
  final Color confirmShadow;
  final String? notice;

  const _CaConfirmDialog({
    required this.title,
    required this.message,
    required this.avatarIcon,
    required this.avatarGradient,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.confirmGradient,
    required this.confirmShadow,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD4A323), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: avatarGradient),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 10,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Icon(avatarIcon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            height: 1.25)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close,
                          size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message,
                  style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF475569),
                      height: 1.5)),
              if (notice != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDF8E6),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 15, color: Color(0xFFA16207)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(notice!,
                            style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF854D0E),
                                height: 1.45)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                          color: Color(0xFFB8860B), width: 1.5),
                      foregroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontSize: 14.7, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  _GoldPillButton(
                    icon: confirmIcon,
                    label: confirmLabel,
                    gradient: confirmGradient,
                    shadowColor: confirmShadow,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaCornerDecor extends CustomPainter {
  const _CaCornerDecor();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 320;
    final sy = size.height / 140;

    final p1 = Path()
      ..moveTo(0, 140 * sy)
      ..cubicTo(100 * sx, 140 * sy, 180 * sx, 110 * sy, 280 * sx, 140 * sy)
      ..lineTo(0, 140 * sy)
      ..close();
    final p2 = Path()
      ..moveTo(0, 82 * sy)
      ..cubicTo(75 * sx, 76 * sy, 150 * sx, 96 * sy, 250 * sx, 140 * sy)
      ..lineTo(0, 140 * sy)
      ..close();
    final p3 = Path()
      ..moveTo(0, 108 * sy)
      ..cubicTo(55 * sx, 102 * sy, 120 * sx, 118 * sy, 185 * sx, 140 * sy)
      ..lineTo(0, 140 * sy)
      ..close();

    canvas.drawPath(p1, Paint()..color = const Color(0x59D49B28));
    canvas.drawPath(
        p2,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xD9E0A92E), Color(0xF2B87D14)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(
        p3,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB87D14), Color(0xFF9A640A)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant _CaCornerDecor oldDelegate) => false;
}
