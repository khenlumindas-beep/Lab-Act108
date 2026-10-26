import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  late ApiService _apiService;
  
  // Dashboard data
  Map<String, dynamic> _dashboardStats = {
    'total_travels': 48,
    'total_users': 25,
    'compliance_rate': 95,
    'announcements': 5,
    'colleges': 3,
  };
  
  Map<String, dynamic> _collegeData = {};
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = context.read<AuthProvider>();
      _apiService = ApiService(auth.prefs);
      
      // Fetch dashboard stats
      final stats = await _apiService.getAdminDashboardStats();
      
      // Fetch recent activities
      final activities = await _apiService.getRecentActivities(limit: 5);
      
      setState(() {
        _dashboardStats = stats;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      // Use mock data on error
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CommonAppBar(title: 'Admin Dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero banner
                    _buildHeroBanner(context),
                    const SizedBox(height: 24),
                    
                    // Stats row
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    
                    // Charts row
                    _buildChartsRow(),
                    const SizedBox(height: 24),
                    
                    // Activities and summary
                    _buildActivitiesAndSummary(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentRoute: '/admin-dashboard',
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.logoGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning,',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${authProvider.fullName}!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Oversee. Manage. Empower.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to SmartTrack Admin — your command center for global travel oversight, compliance monitoring, and institutional management.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Feature pills
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFeaturePill('User Management'),
              _buildFeaturePill('Global Travel Data'),
              _buildFeaturePill('Compliance Reports'),
              _buildFeaturePill('AI Analysis'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.flight,
            label: 'Total Travel Records',
            value: _dashboardStats['total_travels']?.toString() ?? '48',
            trend: '↑ 12% vs. last month',
            color: const Color(0xFF06B6D4),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.people,
            label: 'Total Users',
            value: _dashboardStats['total_users']?.toString() ?? '25',
            trend: '↑ 3 new this month',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.security,
            label: 'Compliance Rate',
            value: '${_dashboardStats['compliance_rate'] ?? 95}%',
            trend: '↑ 5% vs. last month',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.notifications,
            label: 'Announcements',
            value: _dashboardStats['announcements']?.toString() ?? '5',
            trend: '↑ 1 new',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.domain,
            label: 'Total Colleges',
            value: _dashboardStats['colleges']?.toString() ?? '3',
            trend: '— no change',
            color: const Color(0xFF14B8A6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Travel Records by College',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: [
                        _makeGroupData(0, 8, 5, 3),
                        _makeGroupData(1, 6, 4, 2),
                        _makeGroupData(2, 5, 3, 1),
                      ],
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const titles = ['CEIT', 'CTHM', 'CBA'];
                              return Text(
                                titles[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 11),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Compliance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF10B981),
                          value: 98,
                          title: 'Passport',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF3B82F6),
                          value: 94,
                          title: 'Visa',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFF59E0B),
                          value: 92,
                          title: 'COE',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF8B5CF6),
                          value: 88,
                          title: 'Other',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double approved, double pending, double rejected) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: approved,
          color: const Color(0xFF10B981),
          width: 6,
        ),
        BarChartRodData(
          toY: pending,
          color: const Color(0xFFF59E0B),
          width: 6,
        ),
        BarChartRodData(
          toY: rejected,
          color: const Color(0xFFEF4444),
          width: 6,
        ),
      ],
      groupVertically: true,
      barsSpace: 4,
    );
  }

  Widget _buildActivitiesAndSummary() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildActivitiesCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildSystemSummary(),
        ),
      ],
    );
  }

  Widget _buildActivitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No activities yet'),
            )
          else
            ..._activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getActivityColor(activity['type']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getActivityIcon(activity['type']),
                        color: _getActivityColor(activity['type']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] ?? 'Activity',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            activity['description'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time'] ?? '1h ago',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'user':
        return Icons.person_add;
      case 'travel':
        return Icons.flight;
      case 'document':
        return Icons.check_circle;
      case 'ai':
        return Icons.smart_toy;
      case 'report':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'user':
        return const Color(0xFF3B82F6);
      case 'travel':
        return const Color(0xFF06B6D4);
      case 'document':
        return const Color(0xFF10B981);
      case 'ai':
        return const Color(0xFF8B5CF6);
      case 'report':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  Widget _buildSystemSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem('Pending Approvals', '8', const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildSummaryItem('Pending Documents', '14', const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildSummaryItem('Active Faculty', '22', const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          _buildSummaryItem('AI Processed', '156', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
