import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_application_model.dart';

class LeaveApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _leaveApplicationsCollection = 'leave_applications';

  LeaveApplicationService();

  // Submit new leave application (Student)
  Future<void> submitApplication(LeaveApplication application) async {
    try {
      await _firestore
          .collection(_leaveApplicationsCollection)
          .doc(application.id)
          .set(application.toJson());
    } catch (e) {
      print('Error submitting leave application: $e');
      throw e;
    }
  }

  // Get all leave applications (Admin)
  Stream<List<LeaveApplication>> getApplications() {
    return _firestore
        .collection(_leaveApplicationsCollection)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LeaveApplication.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // Get student's leave applications
  Stream<List<LeaveApplication>> getStudentApplications(String regNo) {
    return _firestore
        .collection(_leaveApplicationsCollection)
        .where('regNo', isEqualTo: regNo)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map((doc) => LeaveApplication.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory instead of using orderBy
          applications.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
          return applications;
        });
  }

  // Get count of approved leaves for a student in current month
  Future<int> getApprovedLeavesCount(String regNo) async {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    
    final snapshot = await _firestore
        .collection(_leaveApplicationsCollection)
        .where('regNo', isEqualTo: regNo)
        .where('status', isEqualTo: 'approved')
        .get();

    return snapshot.docs.where((doc) {
      final leaveApp = LeaveApplication.fromJson({...doc.data(), 'id': doc.id});
      return leaveApp.fromDate.isAfter(currentMonthStart.subtract(const Duration(seconds: 1))) &&
             leaveApp.fromDate.isBefore(nextMonthStart);
    }).length;
  }

  // Update leave application status (Admin)
  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
    String? remarks,
  ) async {
    try {
      await _firestore
          .collection(_leaveApplicationsCollection)
          .doc(applicationId)
          .update({
        'status': status,
        'adminRemarks': remarks,
      });
    } catch (e) {
      print('Error updating leave application status: $e');
      throw e;
    }
  }
}
