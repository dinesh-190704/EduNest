import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';
import '../services/result_service.dart';

class ResultProvider with ChangeNotifier {
  final ResultService _resultService = ResultService();
  StudentResult? _currentResult;
  ResultMetadata? _currentMetadata;
  PassStats? _passStats;
  bool _isLoading = false;
  String? _error;

  // Current class details
  String? _currentDepartment;
  String? _currentYear;
  String? _currentClass;

  StudentResult? get currentResult => _currentResult;
  ResultMetadata? get currentMetadata => _currentMetadata;
  PassStats? get passStats => _passStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters for current class details
  String? get currentDepartment => _currentDepartment;
  String? get currentYear => _currentYear;
  String? get currentClass => _currentClass;

  // Clear current result
  void clearResult() {
    _currentResult = null;
    _currentMetadata = null;
    _passStats = null;
    _error = null;
    _currentDepartment = null;
    _currentYear = null;
    _currentClass = null;
    notifyListeners();
  }

  // Upload result from Excel
  Future<void> uploadResult({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _resultService.uploadResultFromExcel(
        department: department,
        year: year,
        className: className,
      );

      // Store current class details
      _currentDepartment = department;
      _currentYear = year;
      _currentClass = className;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get student result
  Future<void> getStudentResult({
    required String regNo,
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      print('ResultProvider: Fetching result for $regNo');
      _isLoading = true;
      _error = null;
      _currentResult = null;
      notifyListeners();

      final result = await _resultService.getStudentResult(
        regNo: regNo,
        department: department,
        year: year,
        className: className,
      );

      if (result == null) {
        print('ResultProvider: No result found');
        _error = 'No result found for registration number: $regNo';
      } else {
        print('ResultProvider: Result found for ${result.name}');
        _currentResult = result;
      }
    } catch (e) {
      print('ResultProvider: Error - $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add result
  Future<void> addResult(StudentResult result) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _resultService.addResult(result);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get result metadata
  Future<void> getResultMetadata({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final metadata = await _resultService.getResultMetadata(
        department: department,
        year: year,
        className: className,
      );

      _currentMetadata = metadata;
      if (metadata == null) {
        _error = 'No results found for this class';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete result
  Future<void> deleteResult({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _resultService.deleteResult(
        department: department,
        year: year,
        className: className,
      );

      _currentMetadata = null;
      _passStats = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate pass stats
  Future<void> calculatePassStats({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final results = await _resultService.getClassResults(
        department: department,
        year: year,
        className: className,
      );

      if (results.isEmpty) {
        _error = 'No results found for this class';
        _passStats = null;
        return;
      }

      // Initialize variables
      final totalStudents = results.length;
      var passedStudents = 0;
      var failedStudents = 0;
      final subjectWisePassPercent = <String, double>{};
      final subjectMarks = <String, List<double>>{};
      
      // Calculate subject-wise pass percentage first
      print('\nCalculating subject-wise pass percentage:');
      
      // First collect all marks for each subject
      for (var result in results) {
        for (var entry in result.subjects.entries) {
          if (!subjectMarks.containsKey(entry.key)) {
            subjectMarks[entry.key] = [];
          }
          double mark = double.tryParse(entry.value) ?? 0;
          subjectMarks[entry.key]!.add(mark);
        }
      }

      // Then calculate pass percentage for each subject
      for (var subject in subjectMarks.keys) {
        print('\nSubject: $subject');
        var marks = subjectMarks[subject]!;
        int passedCount = marks.where((mark) => mark >= 35).length;
        double passPercent = (passedCount / totalStudents) * 100;
        print('Passed: $passedCount out of $totalStudents (${passPercent.toStringAsFixed(1)}%)');
        subjectWisePassPercent[subject] = passPercent;
      }

      // Now update student status based on subject pass percentages
      print('\nCalculating overall pass/fail:');
      for (var result in results) {
        bool hasFailed = false;
        print('\nStudent ${result.regNo}:');
        
        for (var entry in result.subjects.entries) {
          double markValue = double.tryParse(entry.value) ?? 0;
          print('${entry.key}: $markValue');
          if (markValue < 40) { // Changed to 40 for consistency
            hasFailed = true;
            print('Failed in ${entry.key}');
          }
        }
        
        result.status = hasFailed ? 'Failed' : 'Pass';
        print('Overall status: ${result.status}');
      }

      // Update passed/failed counts
      passedStudents = results.where((r) => r.status == 'Pass').length;
      failedStudents = totalStudents - passedStudents;

      _passStats = PassStats(
        totalStudents: totalStudents,
        passedStudents: passedStudents,
        failedStudents: failedStudents,
        subjectWisePassPercent: subjectWisePassPercent,
      );
    } catch (e) {
      _error = e.toString();
      _passStats = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
