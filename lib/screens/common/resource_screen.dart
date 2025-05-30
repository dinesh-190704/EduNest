import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin/resource_upload_screen.dart';
import '../student/student_resource_screen.dart';
import '../../services/resource_service.dart';
import '../../models/resource_model.dart';

class ResourceScreen extends StatefulWidget {
  final bool isAdmin;

  const ResourceScreen({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Educational Resources',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Access study materials and practice resources',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildResourceCard(
                      context,
                      'Lecture Notes',
                      'Access course materials and study guides',
                      Icons.book,
                      'notes',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildResourceCard(
                      context,
                      'Question Bank',
                      'Practice with previous exam papers',
                      Icons.quiz,
                      'question_bank',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, String title,
      String description, IconData icon, String category) {
    return GestureDetector(
      onTap: () {
        if (widget.isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceUploadScreen(category: category),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentResourceScreen(category: category),
            ),
          );
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResourceListScreen extends StatefulWidget {
  final String category;
  final String title;
  final bool isAdmin;

  const ResourceListScreen({
    Key? key,
    required this.category,
    required this.title,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final ResourceService _resourceService = ResourceService();
  List<Resource> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  void _loadResources() {
    setState(() => _isLoading = true);
    _resourceService.getResources(widget.category).listen(
      (resources) {
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load resources'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _downloadResource(Resource resource) async {
    try {
      await _resourceService.downloadFile(resource.fileUrl, resource.title);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${resource.title}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: _resources.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${widget.title} available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _resources.length,
                      itemBuilder: (context, index) {
                        final resource = _resources[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              resource.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(resource.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Subject: ${resource.subject} | Semester: ${resource.semester}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => _downloadResource(resource),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResourceUploadScreen(
                      category: widget.category,
                    ),
                  ),
                );
                _loadResources();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
