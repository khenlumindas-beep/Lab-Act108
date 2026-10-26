import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../widgets/index.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ApiService _apiService;
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
    await _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _apiService.getUserAnalytics();
      setState(() => _analytics = analytics);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final travelProvider = context.watch<TravelProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: CommonAppBar(title: 'Profile'),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading profile...')
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      _buildProfileHeader(context, currentUser),
                      const SizedBox(height: 32),

                      // User Information
                      _buildUserInformation(context, currentUser),
                      const SizedBox(height: 32),

                      // Travel Statistics
                      _buildTravelStatistics(context, travelProvider),
                      const SizedBox(height: 32),

                      // Analytics
                      if (_analytics != null)
                        _buildAnalyticsSection(context, _analytics!),
                      const SizedBox(height: 32),

                      // Settings Section
                      _buildSettingsSection(context),
                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _handleLogout(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(currentRoute: '/profile'),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic>? user,
  ) {
    final initials = (user?['full_name'] as String?)
            ?.split(' ')
            .take(2)
            .map((n) => n[0])
            .join('')
            .toUpperCase() ??
        'FM';

    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?['full_name'] ?? 'Faculty Member',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user?['email'] ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInformation(
    BuildContext context,
    Map<String, dynamic>? user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          icon: Icons.person,
          label: 'Full Name',
          value: user?['full_name'] ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          icon: Icons.email,
          label: 'Email',
          value: user?['email'] ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          icon: Icons.business,
          label: 'College',
          value: user?['college'] ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          icon: Icons.school,
          label: 'Department',
          value: user?['department'] ?? 'N/A',
        ),
        _buildInfoRow(
          context,
          icon: Icons.badge,
          label: 'Faculty ID',
          value: user?['faculty_id'] ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTravelStatistics(
    BuildContext context,
    TravelProvider travelProvider,
  ) {
    final stats = travelProvider.stats ?? {};
    final totalTravels = stats['total_travels'] ?? 0;
    final completedTravels = stats['completed_travels'] ?? 0;
    final totalFunding = stats['total_funding'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Summary',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Total',
              value: totalTravels.toString(),
              icon: Icons.flight_takeoff,
              color: AppTheme.primaryColor,
            ),
            StatCard(
              title: 'Completed',
              value: completedTravels.toString(),
              icon: Icons.check_circle,
              color: AppTheme.successColor,
            ),
            StatCard(
              title: 'Funding',
              value: '\$${totalFunding.toString()}',
              icon: Icons.attach_money,
              color: AppTheme.secondaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAnalyticsRow(
                  context,
                  'Average Funding per Travel',
                  '\$${(analytics['avg_funding'] ?? 0).toStringAsFixed(2)}',
                ),
                const Divider(),
                _buildAnalyticsRow(
                  context,
                  'Total Compliance Score',
                  '${(analytics['compliance_score'] ?? 0).toStringAsFixed(0)}%',
                ),
                const Divider(),
                _buildAnalyticsRow(
                  context,
                  'Average Risk Level',
                  analytics['avg_risk'] ?? 'N/A',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications settings coming soon'),
              ),
            );
          },
        ),
        _buildSettingTile(
          context,
          icon: Icons.security,
          title: 'Security',
          subtitle: 'Change password and 2FA',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Security settings coming soon'),
              ),
            );
          },
        ),
        _buildSettingTile(
          context,
          icon: Icons.language,
          title: 'Language & Theme',
          subtitle: 'Customize app appearance',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Language & Theme settings coming soon'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
