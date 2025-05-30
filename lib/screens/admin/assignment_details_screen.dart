import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailsScreen extends StatelessWidget {
  final Assignment assignment;
  final AssignmentService _assignmentService = AssignmentService();

  AssignmentDetailsScreen({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assignment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      assignment.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assignment.description,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
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
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Submissions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<AssignmentSubmission>>(
              stream: _assignmentService.getAssignmentSubmissions(assignment.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final submissions = snapshot.data!;

                if (submissions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No submissions yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              submission.studentName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Marks input field
                            Row(
                              children: [
                                Icon(
                                  Icons.grade,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    initialValue: submission.marks?.toString() ?? '',
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Enter marks',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onFieldSubmitted: (value) async {
                                      if (value.isNotEmpty) {
                                        try {
                                          final marks = double.parse(value);
                                          await _assignmentService.updateSubmissionMarks(
                                            assignment.id,
                                            submission.id,
                                            marks,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Marks updated successfully'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Invalid marks value'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.attachment,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'View Submission',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue[700],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Submitted on ${DateFormat('MMM dd, yyyy hh:mm a').format(submission.submittedAt)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (submission.marks != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Marks: ${submission.marks!.toStringAsFixed(1)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Open submission file
                          launchUrl(Uri.parse(submission.fileUrl));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
