import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import '../admin/resource_upload_screen.dart';

class StudyMaterialsScreen extends StatefulWidget {
  final String department;
  final bool isAdmin;

  const StudyMaterialsScreen({
    Key? key,
    required this.department,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _resourceService = ResourceService();
  String _selectedCategory = 'notes';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showUploadDialog,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      appBar: AppBar(
        title: Text(
          '${widget.department} Resources',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[700],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search notes, question papers...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Category Toggle
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryButton('Lecture Notes', 'notes'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCategoryButton('Question Bank', 'question_bank'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildMaterialsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String displayName, String category) {
    final isSelected = _selectedCategory == category;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedCategory = category),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.white24,
        foregroundColor: isSelected ? Colors.blue[700] : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(displayName),
    );
  }

  void _showUploadDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceUploadScreen(
          category: _selectedCategory,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _deleteResource(Resource resource) async {
    try {
      await _resourceService.deleteResource(resource.id, resource.fileUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting resource: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<List<Resource>>(
      stream: _resourceService.getResources(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final resources = snapshot.data!;
        if (resources.isEmpty) {
          return const Center(
            child: Text('No materials available'),
          );
        }

        final searchQuery = _searchController.text.toLowerCase();
        final filteredResources = resources.where((resource) {
          return resource.title.toLowerCase().contains(searchQuery) ||
              resource.subject.toLowerCase().contains(searchQuery) ||
              resource.description.toLowerCase().contains(searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: filteredResources.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final resource = filteredResources[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  resource.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Subject: ${resource.subject}'),
                    Text('Semester: ${resource.semester}'),
                    Text('Type: ${resource.fileType.toUpperCase()}'),
                    if (resource.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Description: ${resource.description}'),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _resourceService.downloadFile(
                        resource.fileUrl,
                        '${resource.title}.${resource.fileType}',
                      ),
                    ),
                    if (widget.isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteResource(resource),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
