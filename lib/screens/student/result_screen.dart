import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/result_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _regNoController = TextEditingController();
  
  String _selectedDepartment = 'CSE';
  String _selectedYear = '1';
  String _selectedClass = 'A';

  bool get _isLoading => context.watch<ResultProvider>().isLoading;
  String? get _error => context.watch<ResultProvider>().error;
  get _result => context.watch<ResultProvider>().currentResult;

  final List<String> _departments = ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> _years = ['1', '2', '3', '4'];
  final List<String> _classes = ['A', 'B', 'C'];

  Future<void> _fetchResult() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ResultProvider>();
    await provider.getStudentResult(
      regNo: _regNoController.text.trim(),
      department: _selectedDepartment,
      year: _selectedYear,
      className: _selectedClass,
    );
  }

  @override
  void dispose() {
    _regNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _regNoController,
                        decoration: const InputDecoration(
                          labelText: 'Register Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your register number';
                          }
                          return null;
                        },
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
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchResult,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Fetching...' : 'Check Result'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              )
            else if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Result for ${_result!.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Register Number: ${_result!.regNo}'),
                      Text('Department: ${_result!.department}'),
                      Text('Year: ${_result!.year}'),
                      Text('Class: ${_result!.className}'),
                      const Divider(height: 32),
                      const Text(
                        'Subject Marks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_result!.subjects.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key.replaceAll('subject', 'Subject ')),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      })),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _result!.total,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
