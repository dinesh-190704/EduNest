import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _assignmentsCollection = 'assignments';
  final _submissionsCollection = 'submissions';

  // Create new assignment (Admin)
  Future<void> createAssignment(Assignment assignment) async {
    try {
      await _firestore
          .collection(_assignmentsCollection)
          .doc(assignment.id)
          .set(assignment.toMap());
    } catch (e) {
      print('Error creating assignment: $e');
      throw e;
    }
  }

  // Get all assignments
  Stream<List<Assignment>> getAssignments() {
    return _firestore
        .collection(_assignmentsCollection)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Assignment.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // Get assignment by ID
  Future<Assignment?> getAssignmentById(String assignmentId) async {
    try {
      final doc = await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .get();
      
      if (doc.exists) {
        return Assignment.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting assignment: $e');
      throw e;
    }
  }

  // Submit assignment (Student)
  Future<void> submitAssignment(AssignmentSubmission submission) async {
    try {
      await _firestore
          .collection(_assignmentsCollection)
          .doc(submission.assignmentId)
          .collection(_submissionsCollection)
          .doc(submission.id)
          .set(submission.toMap());
    } catch (e) {
      print('Error submitting assignment: $e');
      throw e;
    }
  }

  // Get submissions for an assignment (Admin)
  Stream<List<AssignmentSubmission>> getAssignmentSubmissions(String assignmentId) {
    return _firestore
        .collection(_assignmentsCollection)
        .doc(assignmentId)
        .collection(_submissionsCollection)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AssignmentSubmission.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // Get student's submission for an assignment
  Future<AssignmentSubmission?> getStudentSubmission(String assignmentId, String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .collection(_submissionsCollection)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AssignmentSubmission.fromMap({
          ...querySnapshot.docs.first.data(),
          'id': querySnapshot.docs.first.id
        });
      }
      return null;
    } catch (e) {
      print('Error getting student submission: $e');
      throw e;
    }
  }

  // Get submission count for an assignment (Admin)
  Future<int> getSubmissionCount(String assignmentId) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .collection(_submissionsCollection)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting submission count: $e');
      throw e;
    }
  }

  // Update submission marks (Admin)
  Future<void> updateSubmissionMarks(String assignmentId, String submissionId, double marks) async {
    try {
      await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .collection(_submissionsCollection)
          .doc(submissionId)
          .update({'marks': marks});
    } catch (e) {
      print('Error updating submission marks: $e');
      throw e;
    }
  }

  // Delete assignment (Admin)
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      // Delete all submissions first
      final submissions = await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .collection(_submissionsCollection)
          .get();
      
      for (var submission in submissions.docs) {
        await submission.reference.delete();
      }

      // Then delete the assignment
      await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .delete();
    } catch (e) {
      print('Error deleting assignment: $e');
      throw e;
    }
  }
}
