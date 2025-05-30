import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/college_leave_model.dart';

class CollegeLeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'college_leaves';

  // Add a college leave day
  Future<void> addCollegeLeave(DateTime date, String reason) async {
    final leaveId = const Uuid().v4();
    final leave = CollegeLeave(
      id: leaveId,
      date: DateTime(date.year, date.month, date.day),
      reason: reason,
    );

    await _firestore.collection(collectionName).doc(leaveId).set(leave.toJson());
  }

  // Remove a college leave day
  Future<void> removeCollegeLeave(String leaveId) async {
    await _firestore.collection(collectionName).doc(leaveId).delete();
  }

  // Check if a specific date is a college leave day
  Future<bool> isCollegeLeaveDay(DateTime date) async {
    final queryDate = DateTime(date.year, date.month, date.day);
    final snapshot = await _firestore
        .collection(collectionName)
        .where('date', isEqualTo: Timestamp.fromDate(queryDate))
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get all college leave days
  Stream<List<CollegeLeave>> getCollegeLeaves() {
    return _firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollegeLeave.fromJson(doc.data()))
            .toList());
  }
}
