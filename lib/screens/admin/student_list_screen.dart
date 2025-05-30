import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late AttendanceService _attendanceService;
  List<Student> _students = [];
  String _selectedDepartment = '';
  String _selectedYear = '';
  String _selectedSection = '';
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _attendanceService = AttendanceService();
    _selectedDepartment = 'Information Technology';
    _selectedYear = '1st Year';
    _selectedSection = 'A';
    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _attendanceService.getStudentsByClass(
        department: _selectedDepartment,
        year: _selectedYear,
        section: _selectedSection,
      );
      setState(() => _students = students);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Student',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _regNoController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter registration number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (Optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final student = Student(
                  id: const Uuid().v4(),
                  name: _nameController.text,
                  regNo: _regNoController.text,
                  department: _selectedDepartment,
                  year: _selectedYear,
                  section: _selectedSection,
                  imageUrl: _imageUrlController.text,
                );

                await _attendanceService.addStudent(student);
                _nameController.clear();
                _regNoController.clear();
                _imageUrlController.clear();
                if (mounted) {
                  Navigator.pop(context);
                  _loadStudents();
                }
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student List',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: _attendanceService
                        .getDepartments()
                        .map((dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDepartment = value);
                        _loadStudents();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: _attendanceService
                        .getYears()
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                        _loadStudents();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                    ),
                    items: _attendanceService
                        .getSections()
                        .map((section) => DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSection = value);
                        _loadStudents();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Text(
                          'No students found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: student.imageUrl.isNotEmpty
                                    ? NetworkImage(student.imageUrl)
                                    : null,
                                child: student.imageUrl.isEmpty
                                    ? Text(
                                        student.name[0],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                student.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                student.regNo,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Student'),
                                      content: Text(
                                        'Are you sure you want to delete ${student.name}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await _attendanceService
                                        .deleteStudent(student.id);
                                    _loadStudents();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
