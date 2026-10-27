import 'package:flutter/material.dart';

import '../account.dart';
import '../api.dart';
import '../brand.dart';
import '../models.dart';
import '../notify.dart';
import '../realtime.dart';
import '../widgets.dart';
import 'faculty_sections.dart';
import 'login_screen.dart';
import 'requirements_sections.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.start();
  }

  @override
  void dispose() {
    RealtimeService.instance.stop();
    super.dispose();
  }

  static const _titles = [
    'Dashboard',
    'Travel Records',
    'Documents',
    'Mobility Plan',
    'Announcements',
    'Reports',
    'Colleges',
    'Analytics',
    'Profile',
    'Settings',
    'More',
    'Post-Travel',
    'Re-Entry',
    'Compliance',
    'My Remarks',
    'Requirements',
  ];

  static const _sidebarItems = [
    SidebarItem(0, 'Dashboard', Icons.home_outlined),
    SidebarItem(1, 'Travel Records', Icons.flight_takeoff_outlined),
    SidebarItem(2, 'Documents', Icons.description_outlined),
    SidebarItem(3, 'Mobility Plan', Icons.language),
    SidebarItem(4, 'Announcements', Icons.volume_up_outlined),
    SidebarItem(5, 'Reports', Icons.bar_chart_outlined),
    SidebarItem(6, 'College Records', Icons.account_balance_outlined),
    SidebarItem(7, 'Analytics', Icons.schedule_outlined),
    SidebarItem(8, 'Profile', Icons.person_outline),
    SidebarItem(9, 'Settings', Icons.settings_outlined),
    SidebarItem(10, 'More', Icons.grid_view_outlined),
  ];

  void _go(int i) => setState(() => _index = i);

  int get _bottomSelected => switch (_index) {
        0 => 0,
        1 => 1,
        2 => 2,
        _ => 3,
      };

  int get _sidebarActive =>
      _sidebarItems.any((i) => i.index == _index) ? _index : 10;

  List<Widget> _pages() => [
        _FacultyDashboard(onGo: _go),
        const _TravelRecords(),
        const FacultyDocumentsTab(),
        const _MobilityPlanTab(),
        const FacultyAnnouncementsTab(),
        const FacultyReportsTab(),
        const FacultyCollegesTab(),
        const FacultyAnalyticsTab(),
        ListView(
          padding: const EdgeInsets.all(16),
          children: const [ProfileForm()],
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          children: const [ChangePasswordForm()],
        ),
        MoreGrid(
          onSelect: _go,
          items: const [
            MoreItem(4, 'Announcements', Icons.campaign_outlined),
            MoreItem(5, 'Reports', Icons.summarize_outlined),
            MoreItem(6, 'Colleges', Icons.account_balance_outlined),
            MoreItem(7, 'Analytics', Icons.insights_outlined),
            MoreItem(8, 'Profile', Icons.person_outline),
            MoreItem(9, 'Settings', Icons.settings_outlined),
            MoreItem(11, 'Post-Travel', Icons.flight_land_outlined),
            MoreItem(12, 'Re-Entry', Icons.replay_outlined),
            MoreItem(13, 'Compliance', Icons.verified_user_outlined),
            MoreItem(14, 'My Remarks', Icons.forum_outlined),
            MoreItem(15, 'Requirements', Icons.checklist_outlined),
          ],
        ),
        const FacultyLifecycleTab(),
        const FacultyLifecycleTab(),
        const FacultyLifecycleTab(),
        const FacultyMyRemarksTab(),
        const RequirementsTab(),
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
          actions: [const LiveBadge(), const NotificationBell(), _logoutBtn(context)],
        ),
        body: Row(
          children: [
            AppSidebar(
              items: _sidebarItems,
              activeIndex: _sidebarActive,
              onSelected: (it) => _go(it.index),
              portalTag: 'Faculty Portal (Dashboard)',
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
        actions: [const LiveBadge(compact: true), const NotificationBell(), _logoutBtn(context)],
      ),
      body: AppBackground(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomSelected,
        onDestinationSelected: (i) => setState(() => _index =
            switch (i) {
              3 => 10,
              _ => i,
            }),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.flight_takeoff_outlined),
              selectedIcon: Icon(Icons.flight_takeoff),
              label: 'Travels'),
          NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Documents'),
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
    RealtimeService.instance.stop();
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

class _FacultyDashboard extends StatefulWidget {
  const _FacultyDashboard({required this.onGo});
  final void Function(int) onGo;

  @override
  State<_FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<_FacultyDashboard> with RealtimeAware {
  List<Travel> _travels = [];
  int _pendingDocs = 0;
  int _verifiedDocs = 0;
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
      final userId = Session.instance.userId;
      final results = await Future.wait([
        ApiClient.instance.get('/travels/user/$userId'),
        ApiClient.instance.get('/documents/user/all'),
      ]);
      _travels = (results[0] as List)
          .map((e) => Travel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final docs = (results[1] as List)
          .map((e) => DocumentRec.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _pendingDocs = docs
          .where((d) => const [
                'Pending',
                'Uploaded',
                'Submitted',
                'Under Verification'
              ].contains(d.status))
          .length;
      _verifiedDocs = docs.where((d) => d.status == 'Verified').length;
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
    final completed =
        _travels.where((t) => t.timelineStatus == 'Completed').length;
    final upcoming =
        _travels.where((t) => t.timelineStatus == 'Upcoming').length;

    final hero = DashboardHero(
      name: Session.instance.fullName ?? 'Faculty',
      tagline: 'Track. Manage. Advance.',
      subtext: 'Welcome to SmartTrack, your centralized platform for '
          'international travel monitoring and compliance.',
      pills: const [
        (Icons.flight_takeoff, 'Travel Records Monitoring'),
        (Icons.description, 'Document Management'),
        (Icons.insights, 'AI-Powered Insights'),
        (Icons.public, 'Global Opportunities'),
      ],
    );

    final stats = <Widget>[
      StatCard(
          label: 'Total Travel Records',
          value: '${_travels.length}',
          color: const Color(0xFF2563EB),
          icon: Icons.flight_takeoff),
      StatCard(
          label: 'Completed',
          value: '$completed',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_outline),
      StatCard(
          label: 'Upcoming',
          value: '$upcoming',
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule),
      StatCard(
          label: 'Pending Documents',
          value: '$_pendingDocs',
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top),
      StatCard(
          label: 'Verified Documents',
          value: '$_verifiedDocs',
          color: const Color(0xFF10B981),
          icon: Icons.verified_outlined),
    ];

    final recentPanel = SectionCard(
      title: 'Recent Travel Records',
      child: _travels.isEmpty
          ? const EmptyState(message: 'No travel records yet.')
          : Column(
              children: [
                for (var i = 0;
                    i < _travels.length && i < 5;
                    i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _TravelTile(travel: _travels[i]),
                ],
              ],
            ),
    );

    final quickActions = SectionCard(
      title: 'Quick Actions',
      child: Column(
        children: [
          TintedActionButton(
            icon: Icons.flight_takeoff,
            label: 'Add Travel Record',
            tint: const Color(0xFF059669),
            onTap: () => widget.onGo(1),
          ),
          const SizedBox(height: 8),
          TintedActionButton(
            icon: Icons.upload_file,
            label: 'Upload Document',
            tint: const Color(0xFF2563EB),
            onTap: () => widget.onGo(2),
          ),
          const SizedBox(height: 8),
          TintedActionButton(
            icon: Icons.summarize_outlined,
            label: 'View Reports',
            tint: const Color(0xFF7C3AED),
            onTap: () => widget.onGo(5),
          ),
        ],
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
      quickActions,
      const PortalDateCard(portal: 'CSUCC OIGE Faculty Portal'),
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
}

class _TravelTile extends StatelessWidget {
  const _TravelTile({required this.travel});
  final Travel travel;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      travel.mobilityType,
      if (travel.country != null && travel.country!.isNotEmpty) travel.country!,
      '${travel.startDate} → ${travel.endDate}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(travel.eventTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
              label: travel.workflowStatus ??
                  travel.timelineStatus ??
                  'Upcoming'),
        ],
      ),
    );
  }
}

// ==================== TRAVEL RECORDS ====================

class _TravelRecords extends StatefulWidget {
  const _TravelRecords();

  @override
  State<_TravelRecords> createState() => _TravelRecordsState();
}

class _TravelRecordsState extends State<_TravelRecords> with RealtimeAware {
  List<Travel> _travels = [];
  bool _loading = true;
  String? _error;

  @override
  Set<String> get realtimeTopics => const {'travels', 'documents'};

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
      final userId = Session.instance.userId;
      final data = await ApiClient.instance.get('/travels/user/$userId');
      _travels = (data as List)
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
    Widget body;
    if (_loading) {
      body = const LoadingBox();
    } else if (_error != null) {
      body = EmptyState(message: 'Error: $_error');
    } else if (_travels.isEmpty) {
      body = const EmptyState(
          message: 'No travel records yet.\nTap + to add one.');
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _travels.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _TravelDetailTile(travel: _travels[i], onChanged: _load),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showAddTravelDialog(context);
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Travel'),
      ),
    );
  }
}

class _TravelDetailTile extends StatefulWidget {
  const _TravelDetailTile({required this.travel, this.onChanged});
  final Travel travel;
  final VoidCallback? onChanged;

  @override
  State<_TravelDetailTile> createState() => _TravelDetailTileState();
}

class _TravelDetailTileState extends State<_TravelDetailTile> {
  bool _submitting = false;

  Future<void> _submitForApproval() async {
    setState(() => _submitting = true);
    try {
      await ApiClient.instance
          .post('/travels/${widget.travel.travelId}/submit-for-approval', {},
              okMsg: 'Submitted for approval — wait for the OIGE admin '
                  'to review your travel request.');
      if (!mounted) return;
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      final missing = missingListFromApiError(e);
      if (missing != null) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Checklist still incomplete'),
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
                          Expanded(
                              child: Text(m,
                                  style: const TextStyle(fontSize: 13))),
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
      } else {
        await showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travel = widget.travel;
    final wf = travel.workflowStatus ?? '';
    final pendingGate = wf == 'Pending Requirements' || wf == 'Draft';
    final forTravel = kForTravelStatuses.contains(wf);
    // Old travels can be Approved/Completed without a complete pre-travel
    // checklist (grandfathered) — never show "For Travel" while incomplete.
    final preComplete = travel.preTravelStatus == 'Complete Documents';
    final rows = <String>[
      if (travel.participantType == 'Student' && travel.participantName != null)
        'Student: ${travel.participantName}',
      '${travel.startDate} → ${travel.endDate}',
      if (travel.mobilityDuration != null)
        'Duration: ${travel.mobilityDuration}',
      if (travel.followUp != null) 'Follow Up: ${travel.followUp}',
      if (travel.preTravelStatus != null)
        'Pre-Travel: ${travel.preTravelStatus}',
      if (travel.postTravelStatus != null)
        'Post-Travel: ${travel.postTravelStatus}',
      if (travel.movs != null && travel.movs!.isNotEmpty)
        'MOVs: ${travel.movs}',
    ];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(travel.eventTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (forTravel && preComplete)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: StatusChip(label: 'For Travel'),
                  ),
                if (forTravel && !preComplete)
                  const StatusChip(
                      label: 'Pre-Travel Incomplete',
                      color: Color(0xFFDC2626))
                else
                  StatusChip(
                      label: wf.isNotEmpty
                          ? wf
                          : (travel.timelineStatus ?? 'Upcoming')),
              ],
            ),
            const SizedBox(height: 4),
            Text('${travel.mobilityType}'
                '${travel.country == null || travel.country!.isEmpty ? '' : ' · ${travel.country}'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            SubmissionStatusChip(
                status: travel.submissionStatus,
                files: travel.submittedFiles,
                verified: travel.verifiedFiles,
                compact: true),
            const SizedBox(height: 6),
            ...rows.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(s, style: const TextStyle(fontSize: 12)))),
          ],
        ),
        children: [
          PreTravelDocPanel(travelId: travel.travelId, editable: true),
          if (pendingGate) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submitting ? null : _submitForApproval,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              icon: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, size: 16),
              label: Text(_submitting
                  ? 'Submitting…'
                  : 'Submit for Approval (complete the checklist above)'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool?> showAddTravelDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _AddTravelDialog(),
  );
}

class _AddTravelDialog extends StatelessWidget {
  const _AddTravelDialog();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth >= 900;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 24 : 16,
        vertical: isLandscape ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLandscape ? 1060 : 680,
          ),
          child: const _AddTravelCard(),
        ),
      ),
    );
  }
}

class _ReqItem {
  final String title;
  final bool isRequired;
  const _ReqItem(this.title, this.isRequired);
}

const List<String> _kPopularCountries = [
  'Japan',
  'Taiwan',
  'Thailand',
  'Vietnam',
  'South Korea',
  'Singapore',
  'Malaysia',
  'Indonesia',
  'Australia',
  'United States',
  'United Kingdom',
  'Canada',
  'Germany',
  'France',
  'China',
  'New Zealand',
  'Philippines',
  'Other (Enter Custom)',
];

const List<String> _kPopularLocations = [
  'University of Aizu',
  'Tatung University, Taipei',
  'Vietnamese-German University',
  'Bangkok and Pattaya',
  'Seoul National University',
  'National University of Singapore',
  'University of Tokyo',
  'Taipei Tech',
  'Chulalongkorn University',
  'Universiti Malaya',
  'Other (Enter Custom)',
];

class _AddTravelCard extends StatefulWidget {
  const _AddTravelCard();

  @override
  State<_AddTravelCard> createState() => _AddTravelCardState();
}

class _AddTravelCardState extends State<_AddTravelCard> {
  final _formKey = GlobalKey<FormState>();
  final _eventTitle = TextEditingController();
  final _country = TextEditingController();
  final _location = TextEditingController();
  final _remarks = TextEditingController();
  final _participantName = TextEditingController();
  final _studentId = TextEditingController();
  final _program = TextEditingController();

  String? _mobilityType;
  String _participantType = 'Faculty';
  String? _selectedCountry;
  String? _selectedLocation;
  bool _customCountry = false;
  bool _customLocation = false;
  DateTime? _start;
  DateTime? _end;
  String _durationChoice = 'Auto';
  String _fundingType = 'To Be Determined';
  bool _saving = false;

  // Step 2: pre-travel checklist gate.
  int? _travelId;
  String _eventTitleSaved = '';
  ReqAiCheck? _ai;
  bool _submitting = false;

  // Step 1 preview: master Pre-Travel checklist (what they'll need to upload).
  List<Map<String, dynamic>> _previewItems = [];

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _eventTitle.dispose();
    _country.dispose();
    _location.dispose();
    _remarks.dispose();
    _participantName.dispose();
    _studentId.dispose();
    _program.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    try {
      final r = await ApiClient.instance
          .get('/requirements/?phase=Pre-Travel');
      if (mounted) {
        setState(() {
          _previewItems = (r as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? (_start ?? DateTime.now()) : (_end ?? _start ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF15803D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (d == null) return;
    setState(() {
      if (isStart) {
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  String _fmtDisplay(DateTime? d) {
    if (d == null) return 'MM / DD / YYYY';
    return '${d.month.toString().padLeft(2, '0')} / ${d.day.toString().padLeft(2, '0')} / ${d.year}';
  }

  Future<void> _save() async {
    final title = _eventTitle.text.trim();
    final country = _country.text.trim();
    final location = _location.text.trim();

    if (title.isEmpty) {
      Notify.warning('Please enter an Event Title.');
      return;
    }
    if (_mobilityType == null || _mobilityType!.isEmpty) {
      Notify.warning('Please select a Type of Mobility.');
      return;
    }
    if (country.isEmpty) {
      Notify.warning('Please select or enter a Country.');
      return;
    }
    if (location.isEmpty) {
      Notify.warning('Please select or enter a Location.');
      return;
    }
    if (_start == null || _end == null) {
      Notify.warning('Please select both Start Date and End Date.');
      return;
    }
    if (_end!.isBefore(_start!)) {
      Notify.warning('End Date cannot be before Start Date.');
      return;
    }
    if (_participantType == 'Student' && _participantName.text.trim().isEmpty) {
      Notify.warning('Student Name is required for student participants.');
      return;
    }

    setState(() => _saving = true);
    try {
      int? collegeId = Session.instance.collegeId;
      if (collegeId == null) {
        final colleges = await ApiClient.instance.get('/colleges/');
        collegeId = (colleges as List).isNotEmpty
            ? (colleges.first as Map)['college_id'] as int?
            : null;
      }
      final res = await ApiClient.instance.post('/travels/', {
        'event_title': title,
        'mobility_type': _mobilityType,
        'participant_type': _participantType,
        if (_participantType == 'Student') ...{
          'participant_name': _participantName.text.trim(),
          'student_id_no': _studentId.text.trim().isEmpty
              ? null
              : _studentId.text.trim(),
          'program':
              _program.text.trim().isEmpty ? null : _program.text.trim(),
        },
        'college_id': collegeId,
        'start_date': _fmt(_start!),
        'end_date': _fmt(_end!),
        'country': country,
        'location': location,
        'remarks': _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
        'funding_type': _fundingType,
        if (_durationChoice != 'Auto') 'mobility_duration': _durationChoice,
      }, okMsg: 'Travel saved — please complete the Pre-Travel Checklist.');
      final id = (res as Map)['travel_id'] as int?;
      if (mounted && id != null) {
        setState(() {
          _travelId = id;
          _eventTitleSaved = title;
          _ai = null;
        });
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitForApproval() async {
    final id = _travelId;
    if (id == null) return;
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.post('/travels/$id/submit-for-approval', {},
          okMsg: 'Submitted for approval — wait for the OIGE admin '
              'to review your travel request.');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final missing = missingListFromApiError(e);
      if (missing != null) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Checklist still incomplete'),
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
                          Expanded(
                              child: Text(m,
                                  style: const TextStyle(fontSize: 13))),
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
      } else {
        await showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth >= 900;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image: bg.png (spans entire modal)
          Positioned.fill(
            child: Image.asset(
              Brand.bg,
              fit: BoxFit.cover,
            ),
          ),
          // Clean white wash overlay so text, inputs & badges stay 100% crisp and readable
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              isLandscape ? 24 : 20,
              isLandscape ? 16 : 18,
              isLandscape ? 24 : 20,
              isLandscape ? 16 : 20,
            ),
            child: _travelId == null
                ? (isLandscape ? _buildLandscapeStep1() : _buildPortraitStep1())
                : _buildStep2(),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: CHECKLIST + SUBMIT ====================

  Widget _buildStep2() {
    final sm = _ai?.summary;
    final ready = sm != null && sm.missing == 0 && !_submitting;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4.5,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pre-Travel Checklist',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2E1E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _eventTitleSaved.isNotEmpty ? _eventTitleSaved : 'Upload required documents before travel approval.',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context, true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(Icons.close_rounded, size: 17, color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_rounded, size: 16, color: Color(0xFF15803D)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please complete ALL Pre-Travel checklist requirements before the admin can approve your travel.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (sm != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (sm.missing == 0
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626))
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: (sm.missing == 0
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626))
                        .withValues(alpha: 0.3)),
              ),
              child: Text(
                sm.missing == 0
                    ? 'Checklist complete (${sm.passed} of ${sm.requiredTotal} '
                        'required passed) — ready to submit for approval.'
                    : '${sm.missing} required document(s) still missing — '
                        'upload them below, then submit.',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Checking checklist…',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          const SizedBox(height: 14),
          PreTravelDocPanel(
            travelId: _travelId!,
            editable: true,
            onAiCheck: (ai) {
              if (mounted) setState(() => _ai = ai);
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: ready ? _submitForApproval : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF145E36),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          sm == null
                              ? 'Submit for Approval'
                              : sm.missing == 0
                                  ? 'Submit for Approval'
                                  : 'Submit for Approval (${sm.missing} missing)',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Do this later — keep as Pending',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 1: LANDSCAPE (NO SCROLLING) ====================

  Widget _buildLandscapeStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4.5,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add Travel Record',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2E1E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Log a new travel event for monitoring and record keeping.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(Icons.close_rounded, size: 17, color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Main 2-Column Body (Left: Form Inputs | Right: Funding, Remarks, Button, Checklist)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== LEFT COLUMN ====================
              Expanded(
                flex: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event Title *
                    _buildFieldHeader(
                      icon: Icons.calendar_month_rounded,
                      label: 'Event Title',
                      isRequired: true,
                      compact: true,
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _eventTitle,
                      decoration: _fieldDecoration(hintText: 'e.g. Training, Conference, Site Visit'),
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5),
                    ),
                    _buildRequiredSubtext(),

                    const SizedBox(height: 8),

                    // Type of Mobility *
                    _buildFieldHeader(
                      icon: Icons.people_alt_rounded,
                      label: 'Type of Mobility',
                      isRequired: true,
                      compact: true,
                    ),
                    const SizedBox(height: 5),
                    _buildDropdown<String>(
                      value: _mobilityType,
                      hint: 'Select type of mobility',
                      height: 38,
                      items: kMobilityTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12.5))))
                          .toList(),
                      onChanged: (v) => setState(() => _mobilityType = v),
                    ),
                    _buildRequiredSubtext(),

                    const SizedBox(height: 8),

                    // Participant Type
                    _buildFieldHeader(
                      icon: Icons.school_rounded,
                      label: 'Participant Type',
                      compact: true,
                    ),
                    const SizedBox(height: 5),
                    _buildDropdown<String>(
                      value: _participantType,
                      hint: 'Select participant type',
                      height: 38,
                      items: const [
                        DropdownMenuItem(value: 'Faculty', child: Text('Faculty', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'Student', child: Text('Student', style: TextStyle(fontSize: 12.5))),
                      ],
                      onChanged: (v) => setState(() => _participantType = v ?? 'Faculty'),
                    ),

                    if (_participantType == 'Student') ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _participantName,
                              decoration: _fieldDecoration(hintText: 'Student Name *'),
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _studentId,
                              decoration: _fieldDecoration(hintText: 'Student ID No.'),
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _program,
                              decoration: _fieldDecoration(hintText: 'Program'),
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Country * & Location * (2 Columns in Left)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldHeader(
                                icon: Icons.public_rounded,
                                label: 'Country',
                                isRequired: true,
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _buildDropdown<String>(
                                value: _selectedCountry,
                                hint: 'Select country',
                                height: 38,
                                items: _kPopularCountries
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedCountry = v;
                                    if (v == 'Other (Enter Custom)') {
                                      _customCountry = true;
                                      _country.text = '';
                                    } else {
                                      _customCountry = false;
                                      _country.text = v ?? '';
                                    }
                                  });
                                },
                              ),
                              if (_customCountry) ...[
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _country,
                                  decoration: _fieldDecoration(hintText: 'Type country'),
                                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
                                ),
                              ],
                              _buildRequiredSubtext(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldHeader(
                                icon: Icons.location_on_rounded,
                                label: 'Location',
                                isRequired: true,
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _buildDropdown<String>(
                                value: _selectedLocation,
                                hint: 'Select location',
                                height: 38,
                                items: _kPopularLocations
                                    .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12.5))))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedLocation = v;
                                    if (v == 'Other (Enter Custom)') {
                                      _customLocation = true;
                                      _location.text = '';
                                    } else {
                                      _customLocation = false;
                                      _location.text = v ?? '';
                                    }
                                  });
                                },
                              ),
                              if (_customLocation) ...[
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _location,
                                  decoration: _fieldDecoration(hintText: 'Type location'),
                                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12),
                                ),
                              ],
                              _buildRequiredSubtext(),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Start Date * & End Date * (2 Columns in Left)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldHeader(
                                icon: Icons.calendar_today_rounded,
                                label: 'Start Date',
                                isRequired: true,
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _buildDatePickerBox(
                                value: _start,
                                onTap: () => _pickDate(true),
                                height: 38,
                              ),
                              _buildRequiredSubtext(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldHeader(
                                icon: Icons.calendar_today_rounded,
                                label: 'End Date',
                                isRequired: true,
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _buildDatePickerBox(
                                value: _end,
                                onTap: () => _pickDate(false),
                                height: 38,
                              ),
                              _buildRequiredSubtext(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // ==================== RIGHT COLUMN ====================
              Expanded(
                flex: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mobility Duration & Funding Support (Side-by-side row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldHeader(
                                icon: Icons.access_time_rounded,
                                label: 'Mobility Duration',
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _buildDropdown<String>(
                                value: _durationChoice,
                                hint: 'Auto',
                                height: 38,
                                items: const [
                                  DropdownMenuItem(value: 'Auto', child: Text('Auto (dates)', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Short-Term', child: Text('Short-Term', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Medium-Term', child: Text('Medium-Term', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Long-Term', child: Text('Long-Term', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'One Academic Term/Semester',
                                      child: Text('One Academic Term', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'One Academic Year',
                                      child: Text('One Academic Year', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (v) => setState(() => _durationChoice = v ?? 'Auto'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldHeader(
                                icon: Icons.eco_rounded,
                                label: 'Funding Support',
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _buildDropdown<String>(
                                value: _fundingType,
                                hint: 'To Be Determined',
                                height: 38,
                                items: kFundingTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (v) => setState(() => _fundingType = v ?? 'To Be Determined'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Remarks
                    _buildFieldHeader(
                      icon: Icons.article_rounded,
                      label: 'Remarks',
                      compact: true,
                    ),
                    const SizedBox(height: 5),
                    Stack(
                      children: [
                        TextFormField(
                          controller: _remarks,
                          maxLines: 2,
                          maxLength: 500,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          decoration: _fieldDecoration(
                            hintText: 'Additional notes (optional)',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: Color(0xFF0F172A),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 5,
                          child: Text(
                            '${_remarks.text.length}/500',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action Button: Save & Open Pre-Travel Checklist ->
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF145E36),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(21),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.description_outlined, size: 17, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save & Open Pre-Travel Checklist',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 17, color: Colors.white),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Info Notice Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF15803D),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.info_rounded, size: 11, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Note: Please complete ALL Pre-Travel checklist requirements before admin approval.',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF166534),
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 9),

                    // Pre-Travel requirements checklist card
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAF7).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 17,
                                height: 17,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pre-Travel requirements you will need:',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          _buildChecklistGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STEP 1: PORTRAIT (SCROLLABLE ON MOBILE) ====================

  Widget _buildPortraitStep1() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4.5,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Travel Record',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F2E1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Log a new travel event for monitoring and record keeping.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF334155)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFieldHeader(
              icon: Icons.calendar_month_rounded,
              label: 'Event Title',
              isRequired: true,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _eventTitle,
              decoration: _fieldDecoration(hintText: 'e.g. Training, Conference, Site Visit'),
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
            ),
            _buildRequiredSubtext(),
            const SizedBox(height: 12),
            _buildFieldHeader(
              icon: Icons.people_alt_rounded,
              label: 'Type of Mobility',
              isRequired: true,
            ),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              value: _mobilityType,
              hint: 'Select type of mobility',
              items: kMobilityTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _mobilityType = v),
            ),
            _buildRequiredSubtext(),
            const SizedBox(height: 12),
            _buildFieldHeader(
              icon: Icons.school_rounded,
              label: 'Participant Type',
            ),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              value: _participantType,
              hint: 'Select participant type',
              items: const [
                DropdownMenuItem(value: 'Faculty', child: Text('Faculty', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'Student', child: Text('Student', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (v) => setState(() => _participantType = v ?? 'Faculty'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldHeader(
                        icon: Icons.public_rounded,
                        label: 'Country',
                        isRequired: true,
                      ),
                      const SizedBox(height: 6),
                      _buildDropdown<String>(
                        value: _selectedCountry,
                        hint: 'Select country',
                        items: _kPopularCountries
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedCountry = v;
                            if (v == 'Other (Enter Custom)') {
                              _customCountry = true;
                              _country.text = '';
                            } else {
                              _customCountry = false;
                              _country.text = v ?? '';
                            }
                          });
                        },
                      ),
                      _buildRequiredSubtext(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldHeader(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        isRequired: true,
                      ),
                      const SizedBox(height: 6),
                      _buildDropdown<String>(
                        value: _selectedLocation,
                        hint: 'Select location',
                        items: _kPopularLocations
                            .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedLocation = v;
                            if (v == 'Other (Enter Custom)') {
                              _customLocation = true;
                              _location.text = '';
                            } else {
                              _customLocation = false;
                              _location.text = v ?? '';
                            }
                          });
                        },
                      ),
                      _buildRequiredSubtext(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldHeader(
                        icon: Icons.calendar_today_rounded,
                        label: 'Start Date',
                        isRequired: true,
                      ),
                      const SizedBox(height: 6),
                      _buildDatePickerBox(value: _start, onTap: () => _pickDate(true)),
                      _buildRequiredSubtext(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldHeader(
                        icon: Icons.calendar_today_rounded,
                        label: 'End Date',
                        isRequired: true,
                      ),
                      const SizedBox(height: 6),
                      _buildDatePickerBox(value: _end, onTap: () => _pickDate(false)),
                      _buildRequiredSubtext(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFieldHeader(
              icon: Icons.access_time_rounded,
              label: 'Mobility Duration',
            ),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              value: _durationChoice,
              hint: 'Auto (based on dates)',
              items: const [
                DropdownMenuItem(value: 'Auto', child: Text('Auto (based on dates)')),
                DropdownMenuItem(value: 'Short-Term', child: Text('Short-Term')),
                DropdownMenuItem(value: 'Medium-Term', child: Text('Medium-Term')),
                DropdownMenuItem(value: 'Long-Term', child: Text('Long-Term')),
                DropdownMenuItem(value: 'One Academic Term/Semester', child: Text('One Academic Term/Semester')),
                DropdownMenuItem(value: 'One Academic Year', child: Text('One Academic Year')),
              ],
              onChanged: (v) => setState(() => _durationChoice = v ?? 'Auto'),
            ),
            const SizedBox(height: 12),
            _buildFieldHeader(
              icon: Icons.eco_rounded,
              label: 'Type of Funding Support',
            ),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              value: _fundingType,
              hint: 'To Be Determined',
              items: kFundingTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _fundingType = v ?? 'To Be Determined'),
            ),
            const SizedBox(height: 12),
            _buildFieldHeader(
              icon: Icons.article_rounded,
              label: 'Remarks',
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _remarks,
              maxLines: 2,
              maxLength: 500,
              decoration: _fieldDecoration(hintText: 'Additional notes (optional)'),
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145E36),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                ),
                child: const Text('Save & Open Pre-Travel Checklist', style: TextStyle(fontFamily: 'Outfit', fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'Note: Please complete ALL Pre-Travel checklist requirements before admin approval.',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FAF7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pre-Travel requirements you will need:', style: TextStyle(fontFamily: 'Outfit', fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildChecklistGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistGrid() {
    final List<_ReqItem> items = _previewItems.isNotEmpty
        ? _previewItems
            .where((x) => (x['applies_to'] ?? '') == _participantType)
            .map((x) => _ReqItem(x['name'] ?? '', x['is_required'] == true))
            .toList()
        : const [
            _ReqItem('Letter of Intent', true),
            _ReqItem('Endorsement Letter (Immediate Supervisor)', true),
            _ReqItem('Invitation Letter', true),
            _ReqItem('Proof of Acceptance', false),
            _ReqItem('CHED IAS Assesment', true),
            _ReqItem('Itinerary of Travel', true),
            _ReqItem('Travel Order', true),
            _ReqItem('Re-Entry Action Plan', true),
          ];

    final half = (items.length / 2).ceil();
    final col1 = items.sublist(0, half);
    final col2 = items.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: col1
                .map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildChecklistRow(it),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: col2
                .map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildChecklistRow(it),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldHeader({
    required IconData icon,
    required String label,
    bool isRequired = false,
    bool compact = false,
    double? height,
  }) {
    return Row(
      children: [
        Container(
          width: compact ? 26 : 32,
          height: compact ? 26 : (height ?? 32),
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: compact ? 14 : 17,
              color: const Color(0xFF15803D),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredSubtext() {
    return const Padding(
      padding: EdgeInsets.only(top: 4, left: 2),
      child: Text(
        'Required',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Outfit',
        color: Color(0xFF94A3B8),
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF10B981),
          width: 1.8,
        ),
      ),
      isDense: true,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double height = 44,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF334155),
            size: 20,
          ),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePickerBox({
    required DateTime? value,
    required VoidCallback onTap,
    double height = 44,
  }) {
    final hasValue = value != null;
    final text = _fmtDisplay(value);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                color: hasValue ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(_ReqItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Color(0xFF15803D),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: item.title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
              children: [
                if (item.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== MOBILITY PLAN ====================

class _MobilityPlanTab extends StatefulWidget {
  const _MobilityPlanTab();

  @override
  State<_MobilityPlanTab> createState() => _MobilityPlanTabState();
}

class _MobilityPlanTabState extends State<_MobilityPlanTab> {
  final _country = TextEditingController();
  final _period = TextEditingController();
  final _notes = TextEditingController();
  Set<String> _types = {};
  bool _fundingNeeded = true;
  String? _fundingType;
  String _readiness = 'Interested';

  bool _loading = true;
  bool _saving = false;
  int? _planId;
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
      final plan = await ApiClient.instance.get('/mobility-plans/my-plan');
      if (plan != null) {
        final p = MobilityPlan.fromJson(Map<String, dynamic>.from(plan));
        _planId = p.planId;
        _types = (p.preferredMobilityTypes ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        _country.text = p.targetCountry ?? '';
        _period.text = p.preferredPeriod ?? '';
        _fundingNeeded = p.fundingNeeded;
        _fundingType = p.fundingType;
        _readiness = p.readinessStatus;
        _notes.text = p.notes ?? '';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await ApiClient.instance.post('/mobility-plans/', {
        'preferred_mobility_types':
            _types.isEmpty ? null : _types.join(', '),
        'target_country': _country.text.trim().isEmpty
            ? null
            : _country.text.trim(),
        'preferred_period':
            _period.text.trim().isEmpty ? null : _period.text.trim(),
        'funding_needed': _fundingNeeded,
        'funding_type': _fundingType,
        'readiness_status': _readiness,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }, okMsg: 'Mobility plan saved');
      setState(() => _planId = saved['plan_id'] as int? ?? _planId);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_planId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete plan?'),
        content: const Text('Your mobility plan will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/mobility-plans/$_planId');
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FacultyHome()));
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('International Faculty Mobility Plan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            if (_planId != null)
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Declare your interest in future international mobility opportunities. One plan per faculty member.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        const Text('Preferred Type(s) of Mobility',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kMobilityTypes
              .map((t) => FilterChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: _types.contains(t),
                    onSelected: (sel) => setState(
                        () => sel ? _types.add(t) : _types.remove(t)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
            controller: _country,
            decoration: const InputDecoration(
                labelText: 'Target Country / Region',
                hintText: 'e.g. Japan, Taiwan, Germany')),
        const SizedBox(height: 12),
        TextField(
            controller: _period,
            decoration: const InputDecoration(
                labelText: 'Preferred Period',
                hintText: 'e.g. Summer 2026 / SY 2026-2027')),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Funding support needed?',
              style: TextStyle(fontSize: 14)),
          value: _fundingNeeded,
          onChanged: (v) => setState(() => _fundingNeeded = v),
        ),
        DropdownButtonFormField<String>(
          value: _fundingType,
          decoration:
              const InputDecoration(labelText: 'Type of Funding Support'),
          items: [
            const DropdownMenuItem<String>(
                value: null, child: Text('Select funding type')),
            ...kFundingTypes
                .map((f) => DropdownMenuItem(value: f, child: Text(f))),
          ],
          onChanged: (v) => setState(() => _fundingType = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _readiness,
          decoration: const InputDecoration(labelText: 'Readiness Status'),
          items: kReadinessStatuses
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _readiness = v ?? 'Interested'),
        ),
        const SizedBox(height: 12),
        TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Notes / Remarks',
                hintText: 'Requirements, scheduling constraints, etc.')),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15)),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_planId == null ? 'Save Mobility Plan' : 'Update Mobility Plan'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
