import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/travel_provider.dart';
import '../widgets/index.dart';
import '../theme/app_theme.dart';

class TravelsScreen extends StatefulWidget {
  const TravelsScreen({Key? key}) : super(key: key);

  @override
  State<TravelsScreen> createState() => _TravelsScreenState();
}

class _TravelsScreenState extends State<TravelsScreen> {
  String _selectedStatus = 'all';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().getTravels();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterTravels(
    List<Map<String, dynamic>> travels,
  ) {
    var filtered = travels;

    if (_selectedStatus != 'all') {
      filtered = filtered
          .where((t) => t['status']?.toString() == _selectedStatus)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((t) =>
              t['destination']?.toString().toLowerCase().contains(query) ??
              false)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final travelProvider = context.watch<TravelProvider>();
    final filteredTravels = _filterTravels(travelProvider.travels);

    return Scaffold(
      appBar: CommonAppBar(title: 'Travels'),
      body: SafeArea(
        child: travelProvider.isLoading
            ? const LoadingIndicator(message: 'Loading travels...')
            : RefreshIndicator(
                onRefresh: () => travelProvider.getTravels(),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Search and Filter
                      _buildSearchAndFilter(context),

                      // Travels List
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: filteredTravels.isEmpty
                            ? _buildEmptyState(context)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredTravels.length,
                                itemBuilder: (context, index) {
                                  final travel = filteredTravels[index];
                                  return TravelCard(
                                    travel: travel,
                                    onTap: () => _showTravelDetails(
                                      context,
                                      travel,
                                    ),
                                    onEdit: () => _showEditTravelDialog(
                                      context,
                                      travel,
                                    ),
                                    onDelete: () =>
                                        _showDeleteConfirmation(context, travel),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(currentRoute: '/travels'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTravelDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search destination...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('approved', 'Approved'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : 'all';
        });
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No travels found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Create your first travel to get started'
                  : 'No travels match your search',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Travel'),
              onPressed: () => _showAddTravelDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showTravelDetails(
    BuildContext context,
    Map<String, dynamic> travel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TravelDetailsSheet(travel: travel),
    );
  }

  void _showAddTravelDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddEditTravelSheet(),
    );
  }

  void _showEditTravelDialog(
    BuildContext context,
    Map<String, dynamic> travel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddEditTravelSheet(travel: travel),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> travel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Travel'),
        content: Text(
          'Are you sure you want to delete the travel to ${travel['destination']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final travelProvider = context.read<TravelProvider>();
              final success =
                  await travelProvider.deleteTravel(travel['travel_id']);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Travel deleted successfully!'),
                    ),
                  );
                } else {
                  ErrorDialog.show(
                    context,
                    title: 'Error',
                    message: travelProvider.errorMessage ??
                        'Failed to delete travel',
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> travel;

  const _TravelDetailsSheet({
    Key? key,
    required this.travel,
  }) : super(key: key);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Travel Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              context,
              'Destination',
              travel['destination'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              'Purpose',
              travel['purpose'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              'Start Date',
              travel['start_date'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              'End Date',
              travel['end_date'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              'Funding Amount',
              '\$${(travel['funding_amount'] ?? 0).toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              context,
              'Status',
              travel['status'] ?? 'N/A',
              isStatus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('View Documents'),
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/documents');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          if (isStatus)
            Chip(
              label: Text(value.toUpperCase()),
              backgroundColor: _getStatusColor(value),
              labelStyle: const TextStyle(color: Colors.white),
            )
          else
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _AddEditTravelSheet extends StatefulWidget {
  final Map<String, dynamic>? travel;

  const _AddEditTravelSheet({
    Key? key,
    this.travel,
  }) : super(key: key);

  @override
  State<_AddEditTravelSheet> createState() => _AddEditTravelSheetState();
}

class _AddEditTravelSheetState extends State<_AddEditTravelSheet> {
  late TextEditingController _destinationController;
  late TextEditingController _purposeController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _fundingController;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _destinationController =
        TextEditingController(text: widget.travel?['destination'] ?? '');
    _purposeController =
        TextEditingController(text: widget.travel?['purpose'] ?? '');
    _startDateController =
        TextEditingController(text: widget.travel?['start_date'] ?? '');
    _endDateController =
        TextEditingController(text: widget.travel?['end_date'] ?? '');
    _fundingController = TextEditingController(
      text: (widget.travel?['funding_amount'] ?? '').toString(),
    );
    _selectedStatus = widget.travel?['status'] ?? 'pending';
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _purposeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _fundingController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveTravel(BuildContext context) async {
    if (_destinationController.text.isEmpty ||
        _purposeController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _fundingController.text.isEmpty) {
      ErrorDialog.show(
        context,
        title: 'Validation Error',
        message: 'Please fill in all required fields.',
      );
      return;
    }

    final travelProvider = context.read<TravelProvider>();
    final travelData = {
      'destination': _destinationController.text,
      'purpose': _purposeController.text,
      'start_date': _startDateController.text,
      'end_date': _endDateController.text,
      'funding_amount': double.tryParse(_fundingController.text) ?? 0,
      'status': _selectedStatus,
    };

    late final bool success;
    if (widget.travel != null) {
      success =
          await travelProvider.updateTravel(widget.travel!['travel_id'], travelData);
    } else {
      success = await travelProvider.createTravel(travelData);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.travel != null
                ? 'Travel updated successfully!'
                : 'Travel created successfully!'),
          ),
        );
      } else {
        ErrorDialog.show(
          context,
          title: 'Error',
          message: travelProvider.errorMessage ?? 'Failed to save travel',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.travel != null;

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
                isEditing ? 'Edit Travel' : 'Create New Travel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination *',
                hintText: 'e.g., Japan',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose *',
                hintText: 'e.g., Research',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date *',
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'End Date',
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fundingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Funding Amount *',
                hintText: 'e.g., 10000',
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing) ...[
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: ['pending', 'approved', 'rejected', 'in_progress', 'completed']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => _handleSaveTravel(context),
              child: Text(isEditing ? 'Update Travel' : 'Create Travel'),
            ),
          ],
        ),
      ),
    );
  }
}
