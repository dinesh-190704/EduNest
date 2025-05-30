import 'package:flutter/material.dart';
import '../../models/leave_application_model.dart';
import '../../services/leave_application_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _leaveService = LeaveApplicationService();
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final regNo = ModalRoute.of(context)?.settings.arguments as String?;
    if (regNo != null) {
      _regNoController.text = regNo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    _sectionController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (_formKey.currentState!.validate() && _fromDate != null && _toDate != null) {
      setState(() => _isLoading = true);

      try {
        final leaveApplication = LeaveApplication(
          id: const Uuid().v4(),
          studentName: _nameController.text,
          regNo: _regNoController.text,
          department: _departmentController.text,
          year: _yearController.text,
          section: _sectionController.text,
          reason: _reasonController.text,
          description: _descriptionController.text,
          fromDate: _fromDate!,
          toDate: _toDate!,
          appliedDate: DateTime.now(),
        );

        await _leaveService.submitApplication(leaveApplication);
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to My Leave Applications
        Navigator.pushReplacementNamed(
          context,
          '/my-leave-applications',
          arguments: _regNoController.text,
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Application'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
              TextFormField(
                controller: _nameController,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _regNoController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter registration number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter section';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _fromDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_fromDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _toDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_toDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Leave',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reason for leave';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitLeaveApplication,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Application'),
              ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
