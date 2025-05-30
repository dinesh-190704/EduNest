import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/result_model.dart';
import '../../providers/result_provider.dart';
import 'result_statistics_screen.dart';

class AdminResultUploadScreen extends StatefulWidget {
  const AdminResultUploadScreen({super.key});

  @override
  State<AdminResultUploadScreen> createState() => _AdminResultUploadScreenState();
}

class _AdminResultUploadScreenState extends State<AdminResultUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> examTypes = ['Mid Term', 'Final Term', 'Internal Test 1'];
  String? selectedExam;
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  final Map<String, TextEditingController> subjectControllers = {};
  final List<String> subjects = ['Math', 'Physics', 'Chemistry'];

  @override
  void initState() {
    super.initState();
    for (var subject in subjects) {
      subjectControllers[subject] = TextEditingController();
    }
  }

  @override
  void dispose() {
    studentIdController.dispose();
    studentNameController.dispose();
    subjectControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _submitResult() {
    if (_formKey.currentState!.validate()) {
      // Calculate total marks
      double total = 0;
      Map<String, double> marks = {};
      
      for (var subject in subjects) {
        double mark = double.parse(subjectControllers[subject]!.text);
        marks[subject] = mark;
        total += mark;
      }

      final result = StudentResult(
        regNo: studentIdController.text,
        name: studentNameController.text,
        subjects: marks.map((key, value) => MapEntry(key, value.toString())),
        total: total.toString(),
        department: 'CSE',  // These could be made dynamic
        year: '3rd Year',
        className: 'A',
        uploadedAt: DateTime.now(),
        exam: selectedExam!,
      );

      // Save result using provider
      context.read<ResultProvider>().addResult(result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result uploaded successfully')),
      );
      _resetForm();
    }
  }

  String _calculateStatus(double total) {
    // Assuming passing mark is 40% of total possible marks
    double maxPossibleMarks = subjects.length * 100.0;
    return total >= (maxPossibleMarks * 0.4) ? 'Passed' : 'Failed';
  }

  void _resetForm() {
    studentIdController.clear();
    studentNameController.clear();
    subjectControllers.values.forEach((controller) => controller.clear());
    setState(() {
      selectedExam = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Student Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'View Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultStatisticsScreen(
                    department: 'CSE',
                    year: '3rd Year',
                    className: 'A',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Exam',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedExam,
                        items: examTypes.map((String exam) {
                          return DropdownMenuItem(
                            value: exam,
                            child: Text(exam),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedExam = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an exam';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: studentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subject Marks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...subjects.map((subject) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            controller: subjectControllers[subject],
                            decoration: InputDecoration(
                              labelText: subject,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter marks for $subject';
                              }
                              final mark = int.tryParse(value);
                              if (mark == null || mark < 0 || mark > 100) {
                                return 'Enter valid marks (0-100)';
                              }
                              return null;
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitResult,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Upload Result'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
