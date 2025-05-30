import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/result_model.dart';

class ResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _resultCollection = 'results';

  // Upload result from Excel file
  Future<void> uploadResultFromExcel({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,  // Required for web
        allowMultiple: false,
      );

      if (result != null) {
        // Read Excel file
        var bytes = result.files.single.bytes!;  // Use bytes directly for web
        var excel = Excel.decodeBytes(bytes);

        // Get the first sheet
        var table = excel.tables[excel.tables.keys.first]!;
        var rows = table.rows;

        // Get headers from first row
        print('\nReading Excel file headers:');
        var headers = rows[0].map((cell) => cell?.value.toString() ?? '').toList();
        print('Found headers: $headers');
        
        // Map Excel headers to proper subject names
        Map<String, String> subjectNameMap = {
          'HVE': 'HVE',
          'an': 'Urban Agriculture',
          'IT': 'IT in Agri',
          'TGM': 'TQM'
        };

        // Get subject columns (all columns except first two and last one)
        // First two columns are RegNo and Name, last column is Total
        var subjectColumns = headers.sublist(2, headers.length - 1);
        print('\nSubject columns: $subjectColumns');

        // Create batch write
        var batch = _firestore.batch();
        // Convert department name to uppercase and remove 'Science' if present
        var deptCode = department.toUpperCase().replaceAll(' SCIENCE', '').replaceAll(' ENGINEERING', '');
        var docId = '${deptCode}_${year}_${className}';
        print('Creating result with docId: $docId');
        var resultRef = _firestore.collection(_resultCollection).doc(docId);
        var count = 0;

        // Process each row (skip header)
        for (var row in rows.skip(1)) {
          var regNo = row[0]?.value.toString() ?? '';
          if (regNo.isEmpty) continue;

          var studentData = {
            'regNo': regNo,
            'name': row[1]?.value.toString() ?? '',
            'department': department,
            'year': year,
            'className': className,
            'total': row[headers.length - 1]?.value.toString() ?? '0',
            'uploadedAt': FieldValue.serverTimestamp(),
          };

          // Add subject marks
          print('\nProcessing marks for student $regNo:');
          for (var i = 0; i < subjectColumns.length; i++) {
            var subjectColumn = subjectColumns[i];
            var columnIndex = headers.indexOf(subjectColumn);
            var cellValue = row[columnIndex]?.value;
            
            String markValue;
            if (cellValue is double || cellValue is int) {
              markValue = cellValue.toString();
            } else {
              markValue = cellValue?.toString() ?? '0';
            }
            
            var subjectName = subjectNameMap[subjectColumn] ?? subjectColumn;
            print('${subjectName}: $markValue');
            studentData[subjectName] = markValue;
          }

          batch.set(resultRef.collection('results').doc(regNo), studentData);
          count++;
        }

        // Add metadata with proper subject names
        var mappedSubjects = subjectColumns.map((col) => subjectNameMap[col] ?? col).toList();
        batch.set(resultRef, ResultMetadata(
          department: department,
          year: year,
          className: className,
          totalStudents: count,
          uploadedAt: DateTime.now(),
          subjects: mappedSubjects,
        ).toMap());

        // Commit batch
        await batch.commit();
      }
    } catch (e) {
      print('Error uploading results: $e');
      throw 'Failed to upload results: $e';
    }
  }

  // Calculate pass/fail statistics
  Future<PassStats> calculatePassStats(List<StudentResult> results) async {
    int passedStudents = 0;
    int failedStudents = 0;
    Map<String, int> subjectPassCount = {};
    Map<String, int> subjectTotalCount = {};

    // Initialize subject counts
    if (results.isNotEmpty) {
      for (var subject in results[0].subjects.keys) {
        subjectPassCount[subject] = 0;
        subjectTotalCount[subject] = 0;
      }
    }

    // Calculate statistics
    for (var result in results) {
      bool studentPassed = true;

      // Check each subject
      result.subjects.forEach((subject, mark) {
        double markValue = double.tryParse(mark) ?? 0;
        subjectTotalCount[subject] = (subjectTotalCount[subject] ?? 0) + 1;
        
        if (markValue >= 40) { // Pass mark is 40
          subjectPassCount[subject] = (subjectPassCount[subject] ?? 0) + 1;
        } else {
          studentPassed = false;
        }
      });

      if (studentPassed) {
        passedStudents++;
      } else {
        failedStudents++;
      }
    }

    // Calculate pass percentage for each subject
    Map<String, double> subjectWisePassPercent = {};
    subjectPassCount.forEach((subject, passCount) {
      int totalCount = subjectTotalCount[subject] ?? 0;
      double passPercent = totalCount > 0 ? (passCount / totalCount) * 100 : 0;
      subjectWisePassPercent[subject] = passPercent;
    });

    return PassStats(
      totalStudents: results.length,
      passedStudents: passedStudents,
      failedStudents: failedStudents,
      subjectWisePassPercent: subjectWisePassPercent,
    );
  }

  // Get all results for a class
  Future<List<StudentResult>> getClassResults({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      // Convert department name to uppercase and remove 'Science' if present
      var deptCode = department.toUpperCase().replaceAll(' SCIENCE', '').replaceAll(' ENGINEERING', '');
      var docId = '${deptCode}_${year}_${className}';
      print('Fetching results for class: $docId');

      // Get metadata first
      var metadataDoc = await _firestore.collection(_resultCollection).doc(docId).get();
      if (!metadataDoc.exists) {
        print('No metadata found for class: $docId');
        return [];
      }

      var metadata = ResultMetadata.fromMap(metadataDoc.data()!);
      print('Found metadata with ${metadata.subjects.length} subjects');

      // Get all results
      var resultsSnapshot = await _firestore
          .collection(_resultCollection)
          .doc(docId)
          .collection('results')
          .get();

      var results = <StudentResult>[];
      for (var doc in resultsSnapshot.docs) {
        var data = doc.data();
        var subjects = <String, String>{};

        // Get subject marks directly using subject names
        for (var subjectName in metadata.subjects) {
          if (data.containsKey(subjectName)) {
            subjects[subjectName] = data[subjectName].toString();
          }
        }

        results.add(StudentResult(
          regNo: data['regNo'] ?? '',
          name: data['name'] ?? '',
          department: data['department'] ?? '',
          year: data['year'] ?? '',
          className: data['className'] ?? '',
          subjects: subjects,
          total: data['total']?.toString() ?? '0',
          uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'Pending'
        ));
      }

      print('Found ${results.length} results');
      return results;
    } catch (e) {
      print('Error getting class results: $e');
      throw 'Failed to get class results: $e';
    }
  }

  // Get student result
  Future<StudentResult?> getStudentResult({
    required String regNo,
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      print('Fetching result for:');
      print('RegNo: $regNo');
      print('Department: $department');
      print('Year: $year');
      print('Class: $className');

      // Convert department name to uppercase and remove 'Science' if present
      var deptCode = department.toUpperCase().replaceAll(' SCIENCE', '').replaceAll(' ENGINEERING', '');
      var docId = '${deptCode}_${year}_${className}';
      print('Generated docId: $docId');
      
      // First get the metadata to get subject list
      var metadataDoc = await _firestore
          .collection(_resultCollection)
          .doc(docId)
          .get();

      print('Metadata exists: ${metadataDoc.exists}');
      if (!metadataDoc.exists) {
        print('No metadata found for class: $docId');
        return null;
      }

      var metadata = ResultMetadata.fromMap(metadataDoc.data()!);
      
      // Then get student result
      var doc = await _firestore
          .collection(_resultCollection)
          .doc(docId)
          .collection('results')
          .doc(regNo)
          .get();

      print('Student result exists: ${doc.exists}');
      if (!doc.exists) {
        print('No result found for student: $regNo');
        return null;
      }

      var data = doc.data()!;
      var subjects = <String, String>{};
      
      print('Converting subject marks to named subjects');
      // Convert subject1, subject2, etc. to actual subject names
      for (var i = 0; i < metadata.subjects.length; i++) {
        var subjectKey = 'subject${i + 1}';
        var mark = data[subjectKey]?.toString() ?? '0';
        subjects[metadata.subjects[i]] = mark;
        print('${metadata.subjects[i]}: $mark');
      }
      
      // Add subjects to the data map
      data['subjects'] = subjects;
      
      print('Creating StudentResult object');
      var result = StudentResult.fromMap(data);
      print('Successfully created StudentResult for ${result.name}');
      return result;
    } catch (e) {
      print('Error fetching result: $e');
      throw 'Failed to fetch result: $e';
    }
  }

  // Add result
  Future<void> addResult(StudentResult result) async {
    try {
      final docRef = _firestore
          .collection('results')
          .doc('${result.department}_${result.year}_${result.className}')
          .collection('results')
          .doc(result.regNo);

      await docRef.set(result.toMap());
    } catch (e) {
      throw 'Failed to add result: $e';
    }
  }

  // Get result metadata
  Future<ResultMetadata?> getResultMetadata({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      // Convert department name to uppercase and remove 'Science' if present
      var deptCode = department.toUpperCase().replaceAll(' SCIENCE', '').replaceAll(' ENGINEERING', '');
      var docId = '${deptCode}_${year}_${className}';
      print('Fetching result with docId: $docId');
      var doc = await _firestore
          .collection(_resultCollection)
          .doc(docId)
          .get();

      print('Student result exists: ${doc.exists}');
      if (doc.exists) {
        return ResultMetadata.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch result metadata: $e';
    }
  }

  // Delete result
  Future<void> deleteResult({
    required String department,
    required String year,
    required String className,
  }) async {
    try {
      // Convert department name to uppercase and remove 'Science' if present
      var deptCode = department.toUpperCase().replaceAll(' SCIENCE', '').replaceAll(' ENGINEERING', '');
      var docId = '${deptCode}_${year}_${className}';
      print('Fetching result with docId: $docId');
      var resultRef = _firestore.collection(_resultCollection).doc(docId);
      
      // Get all student results
      var results = await resultRef.collection('results').get();
      
      // Create batch
      var batch = _firestore.batch();
      
      // Delete all student results
      for (var doc in results.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete metadata
      batch.delete(resultRef);
      
      // Commit batch
      await batch.commit();
    } catch (e) {
      throw 'Failed to delete results: $e';
    }
  }
}
