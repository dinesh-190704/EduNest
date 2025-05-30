import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/result_provider.dart';
import 'admin/admin_result_upload_screen.dart';
import 'admin/result_stats_screen.dart';
import 'student/student_result_screen.dart';

class ResultsPage extends StatefulWidget {
  final bool isAdmin;
  final String? studentId; // Required for student view

  const ResultsPage({
    super.key,
    required this.isAdmin,
    this.studentId,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  void initState() {
    super.initState();
    // Load student result if student ID is provided
    if (widget.studentId != null) {
      Future.microtask(() {
        context.read<ResultProvider>().getStudentResult(
          regNo: widget.studentId!,
          department: 'CSE',  // These could be passed as parameters
          year: '3rd Year',
          className: 'A',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isAdmin ? _buildAdminView() : _buildStudentView();
  }

  Widget _buildAdminView() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Results Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upload Results'),
              Tab(text: 'View Statistics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const AdminResultUploadScreen(),
            const ResultStatsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentView() {
    if (widget.studentId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Student ID not provided'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
      ),
      body: Consumer<ResultProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          final result = provider.currentResult;
          if (result == null) {
            return const Center(
              child: Text('No results available'),
            );
          }

          return StudentResultScreen(
            regNo: widget.studentId!,
            department: 'CSE',  // These could be passed as parameters
            year: '3rd Year',
            className: 'A',
          );
        },
      ),
    );
  }
}
