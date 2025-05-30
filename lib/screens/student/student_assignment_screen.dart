import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';

class StudentAssignmentScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentAssignmentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentAssignmentScreen> createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  final AssignmentService _assignmentService = AssignmentService();

  Future<void> _uploadAssignment(Assignment assignment) async {
    try {
      // Check if assignment is overdue
      if (DateTime.now().isAfter(assignment.dueDate)) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Submission Closed',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sorry, this assignment is past its due date. The submission window is now closed.',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Due Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(assignment.dueDate)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // TODO: Implement actual file upload to server
        // For now, simulate upload with a success dialog
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Success',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File uploaded successfully:',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        file.extension == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.description,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Add submission to the assignment
                  final submission = AssignmentSubmission(
                    id: const Uuid().v4(),
                    assignmentId: assignment.id,
                    studentId: widget.studentId,
                    studentName: widget.studentName,
                    fileUrl: 'https://example.com/${file.name}', // TODO: Replace with actual file upload URL
                    submittedAt: DateTime.now(),
                  );
                  
                  await _assignmentService.submitAssignment(submission);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Assignment submitted successfully!',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green[600],
                      ),
                    );
                  }
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error uploading file: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assignments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: _assignmentService.getAssignments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = snapshot.data!;

          if (assignments.isEmpty) {
            return Center(
              child: Text(
                'No assignments yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return FutureBuilder<AssignmentSubmission?>(
                future: _assignmentService.getStudentSubmission(
                  assignment.id,
                  widget.studentId,
                ),
                builder: (context, submissionSnapshot) {
                  final submission = submissionSnapshot.data;
                  final hasSubmitted = submission != null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigate to assignment details
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    assignment.subject,
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasSubmitted
                                        ? Colors.green[50]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasSubmitted
                                            ? Icons.check_circle_outline
                                            : Icons.pending_outlined,
                                        size: 16,
                                        color: hasSubmitted
                                            ? Colors.green[700]
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasSubmitted ? 'Submitted' : 'Pending',
                                        style: GoogleFonts.poppins(
                                          color: hasSubmitted
                                              ? Colors.green[700]
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              assignment.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              assignment.description,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: assignment.isOverdue
                                      ? Colors.red[400]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Due ${DateFormat('MMM dd, yyyy hh:mm a').format(assignment.dueDate)}',
                                  style: GoogleFonts.poppins(
                                    color: assignment.isOverdue
                                        ? Colors.red[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (!assignment.isOverdue && !hasSubmitted) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _uploadAssignment(assignment),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Assignment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (hasSubmitted) ...[                              
                              // Show marks if available
                              if (submission!.marks != null) ...[                                
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.grade,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Marks: ${submission.marks!.toStringAsFixed(1)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Submitted on ${DateFormat('MMM dd, yyyy hh:mm a').format(submission!.submittedAt)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
