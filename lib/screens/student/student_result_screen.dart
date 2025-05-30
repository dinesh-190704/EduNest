import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/result_model.dart';
import '../../providers/result_provider.dart';

class StudentResultScreen extends StatefulWidget {
  final String regNo;
  final String department;
  final String year;
  final String className;

  const StudentResultScreen({
    super.key,
    required this.regNo,
    required this.department,
    required this.year,
    required this.className,
  });

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch result when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching result with:');
      print('RegNo: ${widget.regNo}');
      print('Department: ${widget.department}');
      print('Year: ${widget.year}');
      print('Class: ${widget.className}');
      context.read<ResultProvider>().getStudentResult(
        regNo: widget.regNo,
        department: widget.department,
        year: widget.year,
        className: widget.className,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Result'),
      ),
      body: Consumer<ResultProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final result = provider.currentResult;
          if (result == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No result found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(result),
                const SizedBox(height: 16),
                _buildMarksCard(result),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(StudentResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.exam,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('dd MMM yyyy').format(result.uploadedAt)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalMarks(StudentResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Marks',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.total,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassFailChip(double marks) {
    bool isPassed = marks >= 40; // Pass mark is 40
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Text(
        isPassed ? 'Pass' : 'Fail',
        style: TextStyle(
          color: isPassed ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMarksCard(StudentResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...result.subjects.entries.where((entry) => entry.key != 'subjects').map((entry) {
              double marks = double.tryParse(entry.value) ?? 0;
              bool isPassed = marks >= 40;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPassed ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPassed ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            isPassed ? 'Pass' : 'Fail',
                            style: TextStyle(
                              color: isPassed ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(StudentResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Chart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.round().toString(),
                          const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= result.marks.length) {
                            return const Text('');
                          }
                          return RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              result.marks.keys.elementAt(value.toInt()),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 20,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(
                    result.marks.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: result.marks.values.elementAt(index),
                          color: Colors.blue,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
