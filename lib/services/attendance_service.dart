import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_leave_service.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollegeLeaveService _collegeLeaveService = CollegeLeaveService();

  AttendanceService();

  // Student Management
  Future<List<Student>> getStudents() async {
    final snapshot = await _firestore.collection('students').get();
    return snapshot.docs.map((doc) => Student.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<List<Student>> getStudentsByClass({
    required String department,
    required String year,
    required String section,
  }) async {
    final snapshot = await _firestore
        .collection('students')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();
    return snapshot.docs.map((doc) => Student.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> addStudent(Student student) async {
    await _firestore
        .collection('students')
        .doc(student.id)
        .set(student.toJson());
  }

  Future<void> updateStudent(Student student) async {
    await _firestore
        .collection('students')
        .doc(student.id)
        .update(student.toJson());
  }

  Future<void> deleteStudent(String studentId) async {
    await _firestore.collection('students').doc(studentId).delete();
  }

  // Attendance Management
  Future<List<Attendance>> getAttendance() async {
    final snapshot = await _firestore.collection('attendance').get();
    return snapshot.docs.map((doc) => Attendance.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<List<Attendance>> getAttendanceByDate(DateTime date, {String? section}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);

    Query query = _firestore.collection('attendance');

    if (section != null) {
      query = query.where('section', isEqualTo: section);
    }

    query = query.where('date', isEqualTo: Timestamp.fromDate(startOfDay));

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Attendance.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> markAttendance(List<Attendance> attendanceList) async {
    final batch = _firestore.batch();
    
    for (var attendance in attendanceList) {
      final docId = '${attendance.studentId}_${DateFormat('yyyy-MM-dd').format(attendance.date)}';
      final docRef = _firestore.collection('attendance').doc(docId);
      batch.set(docRef, attendance.toJson(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    try {
      print('Fetching attendance for student: $studentId');
      
      // Get attendance records for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      print('Querying Firestore for attendance records...');
      
      // Query using document ID pattern
      final querySnapshot = await _firestore
          .collection('attendance')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${studentId}_${DateFormat('yyyy-MM-dd').format(thirtyDaysAgo)}')
          .where(FieldPath.documentId, isLessThanOrEqualTo: '${studentId}_${DateFormat('yyyy-MM-dd').format(now)}')
          .get();

      print('Found ${querySnapshot.docs.length} attendance records');
      
      if (querySnapshot.docs.isEmpty) {
        print('No records found with studentId, trying with regNo...');
        // Try alternative query if no records found
        final snapshot = await _firestore
            .collection('attendance')
            .where('regNo', isEqualTo: studentId)
            .get();
            
        print('Found ${snapshot.docs.length} records with regNo');
        
        if (snapshot.docs.isNotEmpty) {
          final records = snapshot.docs
              .map((doc) {
                print('Document data: ${doc.data()}');
                return Attendance.fromJson(doc.data() as Map<String, dynamic>);
              })
              .where((attendance) => attendance.date.isAfter(thirtyDaysAgo))
              .toList();

          records.sort((a, b) => b.date.compareTo(a.date));
          print('Returning ${records.length} filtered records');
          return records;
        }
      }

      final records = querySnapshot.docs
          .map((doc) {
            print('Document data: ${doc.data()}');
            return Attendance.fromJson(doc.data() as Map<String, dynamic>);
          })
          .toList();

      records.sort((a, b) => b.date.compareTo(a.date));
      print('Returning ${records.length} filtered records');
      return records;
    } catch (e) {
      print('Error fetching student attendance: $e');
      print('Stack trace: ${e is Error ? e.stackTrace : ''}');
      return [];
    }
  }

  Future<double> getStudentMonthlyAttendancePercentage(String studentId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // First try to get all attendance records for the student
      final snapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .get();

      final allAttendanceRecords = snapshot.docs
          .map((doc) => Attendance.fromJson(doc.data()))
          .where((attendance) =>
              attendance.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              attendance.date.isBefore(endOfMonth.add(const Duration(days: 1))))
          .toList();

      if (allAttendanceRecords.isEmpty) return 0.0;

      int totalDays = 0;
      int presentDays = 0;

      for (var attendance in allAttendanceRecords) {
        final isCollegeLeave = await _collegeLeaveService.isCollegeLeaveDay(attendance.date);
        
        if (!isCollegeLeave) {
          totalDays++;
          if (attendance.isPresent) {
            presentDays++;
          }
        }
      }

      return totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
    } catch (e) {
      print('Error calculating monthly attendance: $e');
      return 0.0;
    }
  }

  Future<double> calculateAttendancePercentage(String regNo) async {
    try {
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('regNo', isEqualTo: regNo)
          .get();

      if (attendanceQuery.docs.isEmpty) return 0.0;

      int totalDays = 0;
      int presentDays = 0;

      for (var doc in attendanceQuery.docs) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        final isCollegeLeave = await _collegeLeaveService.isCollegeLeaveDay(date);
        
        if (!isCollegeLeave) {
          totalDays++;
          if (doc.data()['isPresent'] as bool) {
            presentDays++;
          }
        }
      }

      return totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
    } catch (e) {
      print('Error calculating attendance percentage: $e');
      return 0.0;
    }
  }

  // Analytics
  Future<AttendanceReport> getStudentReport(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final attendance = await getStudentAttendance(studentId);
    final filteredAttendance = attendance.where((a) =>
        a.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        a.date.isBefore(endDate.add(const Duration(days: 1)))).toList();

    final totalDays = filteredAttendance.length;
    final presentDays = filteredAttendance.where((a) => a.isPresent).length;
    final percentage = totalDays > 0 ? (presentDays / totalDays) * 100.0 : 0.0;

    final absentDates = filteredAttendance
        .where((a) => !a.isPresent)
        .map((a) => a.date)
        .toList();

    return AttendanceReport(
      studentId: studentId,
      studentName: filteredAttendance.first.studentName,
      regNo: filteredAttendance.first.regNo,
      totalDays: totalDays,
      presentDays: presentDays,
      percentage: percentage,
      absentDates: absentDates,
    );
  }

  Future<List<AttendanceReport>> getClassReport(
    String department,
    String year,
    String section,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final students = await getStudentsByClass(
      department: department,
      year: year,
      section: section,
    );

    List<AttendanceReport> reports = [];
    for (var student in students) {
      final report = await getStudentReport(student.id, startDate, endDate);
      reports.add(report);
    }

    return reports;
  }

  // Helper Methods
  List<String> getDepartments() {
    return [
      'Information Technology',
    ];
  }

  List<String> getYears() {
    return ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  }

  List<String> getSections() {
    return ['A', 'B', 'C'];
  }
}
