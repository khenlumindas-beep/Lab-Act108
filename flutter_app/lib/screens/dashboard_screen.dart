import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../widgets/index.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().getTravels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final travelProvider = context.watch<TravelProvider>();
    final currentUser = authProvider.currentUser;
    final userName = currentUser?['full_name'] ?? 'Faculty Member';

    return Scaffold(
      appBar: CommonAppBar(
        title: 'SmartTrack Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/announcements'),
          ),
        ],
      ),
      body: SafeArea(
        child: travelProvider.isLoading
            ? const LoadingIndicator(message: 'Loading dashboard...')
            : RefreshIndicator(
                onRefresh: () => travelProvider.getTravels(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(context, userName),
                      const SizedBox(height: 24),

                      // Statistics Cards
                      _buildStatsSection(context, travelProvider),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActionsSection(context),
                      const SizedBox(height: 24),

                      // Recent Travels
                      _buildRecentTravelsSection(context, travelProvider),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(currentRoute: '/'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTravelDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back, $userName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your travels and stay compliant',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
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
          'Your Statistics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Total Travels',
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
              title: 'Total Funding',
              value: '\$${totalFunding.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              color: AppTheme.secondaryColor,
            ),
            StatCard(
              title: 'Pending',
              value: ((totalTravels as int) - (completedTravels as int))
                  .toString(),
              icon: Icons.hourglass_empty,
              color: AppTheme.warningColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionButton(
                context,
                icon: Icons.flight_takeoff,
                label: 'New Travel',
                onPressed: () => _showAddTravelDialog(context),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: Icons.description,
                label: 'Documents',
                onPressed: () => context.go('/documents'),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: Icons.list,
                label: 'All Travels',
                onPressed: () => context.go('/travels'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildRecentTravelsSection(
    BuildContext context,
    TravelProvider travelProvider,
  ) {
    final recentTravels = travelProvider.travels.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Travels',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/travels'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentTravels.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 48,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No travels yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddTravelDialog(context),
                    child: const Text('Create First Travel'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTravels.length,
            itemBuilder: (context, index) {
              final travel = recentTravels[index];
              return TravelCard(
                travel: travel,
                onTap: () {
                  context.go('/travels');
                },
              );
            },
          ),
      ],
    );
  }

  void _showAddTravelDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AddTravelSheet(),
    );
  }
}

class _AddTravelSheet extends StatefulWidget {
  const _AddTravelSheet({Key? key}) : super(key: key);

  @override
  State<_AddTravelSheet> createState() => _AddTravelSheetState();
}

class _AddTravelSheetState extends State<_AddTravelSheet> {
  late TextEditingController _destinationController;
  late TextEditingController _purposeController;
  late TextEditingController _startDateController;
  late TextEditingController _fundingController;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController();
    _purposeController = TextEditingController();
    _startDateController = TextEditingController();
    _fundingController = TextEditingController();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _purposeController.dispose();
    _startDateController.dispose();
    _fundingController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateTravel(BuildContext context) async {
    final travelProvider = context.read<TravelProvider>();

    if (_destinationController.text.isEmpty ||
        _purposeController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _fundingController.text.isEmpty) {
      ErrorDialog.show(
        context,
        title: 'Validation Error',
        message: 'Please fill in all fields.',
      );
      return;
    }

    final travelData = {
      'destination': _destinationController.text,
      'purpose': _purposeController.text,
      'start_date': _startDateController.text,
      'funding_amount': double.tryParse(_fundingController.text) ?? 0,
      'status': 'pending',
    };

    final success = await travelProvider.createTravel(travelData);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Travel created successfully!')),
        );
      } else {
        ErrorDialog.show(
          context,
          title: 'Error',
          message: travelProvider.errorMessage ?? 'Failed to create travel',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'Create New Travel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'e.g., Japan, Philippines',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose',
                hintText: 'e.g., Research, Conference',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fundingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Funding Amount',
                hintText: 'e.g., 10000',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleCreateTravel(context),
              child: const Text('Create Travel'),
            ),
          ],
        ),
      ),
    );
  }
}
