import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import 'assignment_details_screen.dart';

class AdminAssignmentScreen extends StatefulWidget {
  const AdminAssignmentScreen({super.key});

  @override
  State<AdminAssignmentScreen> createState() => _AdminAssignmentScreenState();
}

class _AdminAssignmentScreenState extends State<AdminAssignmentScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _showCreateForm = false;

  void _toggleCreateForm() {
    setState(() {
      _showCreateForm = !_showCreateForm;
      if (!_showCreateForm) {
        // Clear form when hiding
        _titleController.clear();
        _descriptionController.clear();
        _subjectController.clear();
        _dueDate = DateTime.now().add(const Duration(days: 7));
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _createAssignment() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all fields',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    final assignment = Assignment(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      subject: _subjectController.text,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
    );

    try {
      await _assignmentService.createAssignment(assignment);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assignment created successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green[600],
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      _subjectController.clear();
      setState(() {
        _dueDate = DateTime.now().add(const Duration(days: 7));
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error creating assignment: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showCreateForm ? 'Create Assignment' : 'Manage Assignments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCreateForm,
        child: Icon(_showCreateForm ? Icons.close : Icons.add),
        backgroundColor: _showCreateForm ? Colors.red : Colors.blue,
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: _assignmentService.getAssignments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showCreateForm) ...[
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(
                      'Due Date',
                      style: GoogleFonts.poppins(),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy hh:mm a').format(_dueDate),
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDueDate,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _createAssignment();
                        if (mounted) {
                          _toggleCreateForm(); // Hide form after successful creation
                        }
                      },
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
                      child: Text(
                        'Create Assignment',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'All Assignments',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (assignments.isEmpty)
                  Center(
                    child: Text(
                      'No assignments yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        final assignment = assignments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssignmentDetailsScreen(
                                    assignment: assignment,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: StreamBuilder<List<AssignmentSubmission>>(
                                          stream: _assignmentService.getAssignmentSubmissions(assignment.id),
                                          builder: (context, submissionSnapshot) {
                                            final submissionCount = submissionSnapshot.data?.length ?? 0;
                                            final hasSubmissions = submissionCount > 0;

                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  hasSubmissions
                                                      ? Icons.check_circle_outline
                                                      : Icons.pending_outlined,
                                                  size: 16,
                                                  color: hasSubmissions
                                                      ? Colors.green[700]
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$submissionCount submissions',
                                                  style: GoogleFonts.poppins(
                                                    color: hasSubmissions
                                                        ? Colors.green[700]
                                                        : Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.red[400],
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        final confirmed = await showDialog<bool>(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: Text(
                                                              'Delete Assignment',
                                                              style: GoogleFonts.poppins(
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            content: Text(
                                                              'Are you sure you want to delete this assignment? This action cannot be undone.',
                                                              style: GoogleFonts.poppins(),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context, false),
                                                                child: Text(
                                                                  'Cancel',
                                                                  style: GoogleFonts.poppins(),
                                                                ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context, true),
                                                                child: Text(
                                                                  'Delete',
                                                                  style: GoogleFonts.poppins(
                                                                    color: Colors.red[400],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );

                                                        if (confirmed == true) {
                                                          try {
                                                            await _assignmentService.deleteAssignment(assignment.id);
                                                            if (!mounted) return;
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Assignment deleted successfully',
                                                                  style: GoogleFonts.poppins(),
                                                                ),
                                                                backgroundColor: Colors.green[600],
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            if (!mounted) return;
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Error deleting assignment: $e',
                                                                  style: GoogleFonts.poppins(),
                                                                ),
                                                                backgroundColor: Colors.red[600],
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
