import 'package:flutter/material.dart';
import '../../models/leave_application_model.dart';
import '../../services/leave_application_service.dart';
import 'package:intl/intl.dart';

class MyLeaveApplications extends StatefulWidget {
  final String? studentRegNo;

  const MyLeaveApplications({
    super.key,
    this.studentRegNo,
  });

  @override
  State<MyLeaveApplications> createState() => _MyLeaveApplicationsState();
}

class _MyLeaveApplicationsState extends State<MyLeaveApplications> {
  final LeaveApplicationService _service = LeaveApplicationService();
  late String _studentRegNo;

  @override
  void initState() {
    super.initState();
    // Initialize with a default value, will be updated in didChangeDependencies
    _studentRegNo = 'STUDENT123';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the registration number from widget property or route arguments
    final routeRegNo = ModalRoute.of(context)?.settings.arguments as String?;
    setState(() {
      _studentRegNo = widget.studentRegNo ?? routeRegNo ?? _studentRegNo;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave Applications'),
      ),
      body: StreamBuilder<List<LeaveApplication>>(
        stream: _service.getStudentApplications(_studentRegNo),
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

          final applications = snapshot.data!;

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No leave applications found',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/leave-application'),
                    icon: const Icon(Icons.add),
                    label: const Text('Apply for Leave'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: applications.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final application = applications[index];
              return Card(
                child: ExpansionTile(
                  title: Text(
                    application.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(application.fromDate),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      application.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildInfoRow(
                            'Duration',
                            '${DateFormat('dd/MM/yyyy').format(application.fromDate)} - ${DateFormat('dd/MM/yyyy').format(application.toDate)}',
                          ),
                          buildInfoRow('Reason', application.reason),
                          buildInfoRow(
                            'Description',
                            application.description,
                          ),
                          if (application.adminRemarks != null)
                            buildInfoRow(
                              'Admin Remarks',
                              application.adminRemarks!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/leave-application'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
