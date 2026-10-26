import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../widgets/index.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;
  int? _selectedTravelId;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
  }

  Future<void> _loadDocuments(int travelId) async {
    setState(() => _isLoading = true);
    try {
      final docs = await _apiService.getDocuments(travelId);
      setState(() {
        _documents = docs;
        _selectedTravelId = travelId;
      });
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Error',
          message: 'Failed to load documents: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(int travelId, String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final file = result.files.first;
      await _apiService.uploadDocument(
        travelId: travelId,
        docType: docType,
        filePath: file.path!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
        await _loadDocuments(travelId);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Upload Error',
          message: 'Failed to upload document: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travelProvider = context.watch<TravelProvider>();

    return Scaffold(
      appBar: CommonAppBar(title: 'Documents'),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading...')
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Travel Selection
                    _buildTravelSelection(context, travelProvider),

                    if (_selectedTravelId != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Upload Buttons
                            _buildDocumentUploadButtons(context),
                            const SizedBox(height: 24),

                            // Documents List
                            _buildDocumentsList(context),
                          ],
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.document_scanner,
                                size: 64,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select a travel to manage documents',
                                style:
                                    Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(currentRoute: '/documents'),
    );
  }

  Widget _buildTravelSelection(
    BuildContext context,
    TravelProvider travelProvider,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Travel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (travelProvider.travels.isEmpty)
            Text(
              'No travels available',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: travelProvider.travels
                    .map((travel) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(travel['destination'] ?? 'Unknown'),
                            selected: _selectedTravelId == travel['travel_id'],
                            onSelected: (selected) {
                              if (selected) {
                                _loadDocuments(travel['travel_id']);
                              }
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedTravelId == travel['travel_id']
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Documents',
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
            _buildUploadButton(
              context,
              icon: Icons.description,
              label: 'Passport',
              docType: 'passport',
            ),
            _buildUploadButton(
              context,
              icon: Icons.receipt,
              label: 'Visa',
              docType: 'visa',
            ),
            _buildUploadButton(
              context,
              icon: Icons.card_travel,
              label: 'Travel Plan',
              docType: 'travel_plan',
            ),
            _buildUploadButton(
              context,
              icon: Icons.assignment,
              label: 'Budget',
              docType: 'budget',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String docType,
  }) {
    return InkWell(
      onTap: () {
        if (_selectedTravelId != null) {
          _uploadDocument(_selectedTravelId!, docType);
        }
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Documents',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (_documents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents uploaded yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              final doc = _documents[index];
              return _buildDocumentTile(context, doc);
            },
          ),
      ],
    );
  }

  Widget _buildDocumentTile(
    BuildContext context,
    Map<String, dynamic> document,
  ) {
    final docType = document['doc_type'] ?? 'Document';
    final fileName = document['file_name'] ?? 'Unknown';
    final uploadedAt = document['uploaded_at'] ?? 'N/A';
    final status = document['verification_status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.description,
          color: AppTheme.primaryColor,
        ),
        title: Text(docType.toUpperCase()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Uploaded: $uploadedAt', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: _buildStatusBadge(status),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'pending': Colors.orange,
      'verified': Colors.green,
      'rejected': Colors.red,
    };

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colors[status] ?? Colors.grey,
    );
  }
}
