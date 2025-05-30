import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/result_provider.dart';

class ResultUploadScreen extends StatefulWidget {
  const ResultUploadScreen({Key? key}) : super(key: key);

  @override
  _ResultUploadScreenState createState() => _ResultUploadScreenState();
}

class _ResultUploadScreenState extends State<ResultUploadScreen> {
  bool get _isUploading => context.watch<ResultProvider>().isLoading;
  String? get _error => context.watch<ResultProvider>().error;

  String _selectedDepartment = 'CSE';
  String _selectedYear = '1';
  String _selectedClass = 'A';

  final List<String> _departments = ['CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> _years = ['1', '2', '3', '4'];
  final List<String> _classes = ['A', 'B', 'C'];

  Future<void> _uploadResult() async {
    final provider = context.read<ResultProvider>();
    
    await provider.uploadResult(
      department: _selectedDepartment,
      year: _selectedYear,
      className: _selectedClass,
    );

    if (mounted) {
      if (provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results uploaded successfully!')),
        );
        
        // Calculate pass stats
        await provider.calculatePassStats(
          department: _selectedDepartment,
          year: _selectedYear,
          className: _selectedClass,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResultProvider>();
    final stats = provider.passStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Class Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      items: _departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDepartment = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: _years.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedYear = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      items: _classes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClass = value!);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadResult,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Result Excel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Excel File Format',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Required columns in order:\n'
                      '1. Register Number\n'
                      '2. Student Name\n'
                      '3. Subject 1\n'
                      '4. Subject 2\n'
                      '5. Subject 3...\n'
                      'Last Column: Total',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            if (stats != null) ...[  // Show stats if available
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Result Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total Students', stats.totalStudents.toString()),
                          _buildStatItem('Passed', stats.passedStudents.toString()),
                          _buildStatItem('Failed', stats.failedStudents.toString()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Subject-wise Pass Percentage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...stats.subjectWisePassPercent.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: entry.value / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  entry.value >= 75 ? Colors.green
                                    : entry.value >= 50 ? Colors.orange
                                    : Colors.red,
                                ),
                              ),
                              Text('${entry.value.toStringAsFixed(1)}%'),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}
