import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentResourceScreen extends StatefulWidget {
  final String category;

  const StudentResourceScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<StudentResourceScreen> createState() => _StudentResourceScreenState();
}

class _StudentResourceScreenState extends State<StudentResourceScreen> {
  final _resourceService = ResourceService();
  int _selectedSemester = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == 'notes' ? 'Lecture Notes' : 'Question Papers',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(
                  'Semester:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedSemester,
                    isExpanded: true,
                    items: List.generate(8, (index) => index + 1)
                        .map((semester) => DropdownMenuItem(
                              value: semester,
                              child: Text(
                                'Semester $semester',
                                style: GoogleFonts.poppins(),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSemester = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Resource>>(
              stream: _resourceService.getResources(widget.category),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading resources',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final resources = snapshot.data!
                    .where((r) => r.semester == _selectedSemester)
                    .toList();

                if (resources.isEmpty) {
                  return Center(
                    child: Text(
                      widget.category == 'notes'
                          ? 'No lecture notes available for this semester'
                          : 'No question papers available for this semester',
                      style: GoogleFonts.poppins(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final resource = resources[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          resource.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              resource.description,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Subject: ${resource.subject}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Uploaded on: ${DateTime.parse(resource.uploadDate).toString().split(' ')[0]}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            try {
                              await _resourceService.downloadFile(
                                resource.fileUrl,
                                '${resource.title}.${resource.fileType}',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('File downloaded successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to download: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
