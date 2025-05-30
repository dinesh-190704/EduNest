import 'package:flutter/material.dart';
import '../../models/leave_application_model.dart';
import '../../services/leave_application_service.dart';
import 'package:intl/intl.dart';

class LeaveApplicationsDashboard extends StatefulWidget {
  const LeaveApplicationsDashboard({super.key});

  @override
  State<LeaveApplicationsDashboard> createState() =>
      _LeaveApplicationsDashboardState();
}

class _LeaveApplicationsDashboardState extends State<LeaveApplicationsDashboard> {
  final LeaveApplicationService _service = LeaveApplicationService();

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
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

  Future<void> _updateApplicationStatus(
      LeaveApplication application, String status) async {
    // Show dialog for remarks
    final remarks = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status.capitalize()} Leave Application'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Remarks (Optional)',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'No remarks'),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status.capitalize()),
          ),
        ],
      ),
    );

    if (remarks != null) {
      try {
        await _service.updateApplicationStatus(
          application.id,
          status,
          remarks,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.capitalize()}'),
            backgroundColor:
                status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating application: $e'),
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
        title: const Text('Leave Applications'),
      ),
      body: StreamBuilder<List<LeaveApplication>>(
        stream: _service.getApplications(),
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
            return const Center(
              child: Text('No leave applications found'),
            );
          }

          return ListView.builder(
            itemCount: applications.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final application = applications[index];
              final isStatusPending = application.status == 'pending';

              return FutureBuilder<int>(
                future: _service.getApprovedLeavesCount(application.regNo),
                builder: (context, leaveCountSnapshot) {
                  final leaveCount = leaveCountSnapshot.data ?? 0;
                  
                  return Card(
                    child: ExpansionTile(
                      title: const Text(
                        'Leave Application',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${application.department} - ${application.year} Year',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Approved Leaves This Month: $leaveCount',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: application.status == 'approved'
                              ? Colors.green
                              : application.status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          application.status.capitalize(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildInfoRow('Student Name', application.studentName),
                              buildInfoRow('Reg No', application.regNo),
                              buildInfoRow('Section', application.section),
                              buildInfoRow(
                                'Duration',
                                '${DateFormat('dd/MM/yyyy').format(application.fromDate)} - ${DateFormat('dd/MM/yyyy').format(application.toDate)}',
                              ),
                              buildInfoRow('Reason', application.reason),
                              buildInfoRow('Description', application.description),
                              if (application.status != 'pending')
                                buildInfoRow(
                                  'Admin Remarks',
                                  application.adminRemarks ?? 'No remarks',
                                ),
                              if (isStatusPending)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _updateApplicationStatus(
                                            application, 'rejected'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () => _updateApplicationStatus(
                                            application, 'approved'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ],
                                  ),
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
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
