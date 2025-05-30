import 'package:flutter/material.dart';
import '../../models/result_model.dart';
import '../../services/result_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ResultStatisticsScreen extends StatefulWidget {
  final String department;
  final String year;
  final String className;

  const ResultStatisticsScreen({
    Key? key,
    required this.department,
    required this.year,
    required this.className,
  }) : super(key: key);

  @override
  State<ResultStatisticsScreen> createState() => _ResultStatisticsScreenState();
}

class _ResultStatisticsScreenState extends State<ResultStatisticsScreen> {
  final ResultService _resultService = ResultService();
  bool _isLoading = true;
  PassStats? _passStats;
  List<StudentResult>? _results;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all results
      _results = await _resultService.getClassResults(
        department: widget.department,
        year: widget.year,
        className: widget.className,
      );

      // Calculate statistics
      if (_results != null && _results!.isNotEmpty) {
        _passStats = await _resultService.calculatePassStats(_results!);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildOverallStatistics() {
    if (_passStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total Students',
                  _passStats!.totalStudents.toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Passed',
                  _passStats!.passedStudents.toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  'Failed',
                  _passStats!.failedStudents.toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Overall Pass Rate: ${_passStats!.passPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectWiseStats() {
    if (_passStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject-wise Pass Percentage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._passStats!.subjectWisePassPercent.entries.map((entry) {
              var subject = entry.key;
              var percentage = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: percentage >= 40 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: percentage >= 40 ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: percentage >= 40 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 40 ? Colors.green : Colors.red,
                        ),
                        minHeight: 8,
                      ),
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

  Widget _buildPerformanceDistribution() {
    if (_results == null || _results!.isEmpty) return const SizedBox.shrink();

    // Calculate mark ranges for each subject
    Map<String, Map<String, int>> subjectRanges = {};
    
    // Initialize ranges for each subject
    if (_results!.isNotEmpty) {
      for (var subject in _results![0].subjects.keys) {
        subjectRanges[subject] = {
          '0-20': 0,
          '21-40': 0,
          '41-60': 0,
          '61-80': 0,
          '81-100': 0,
        };
      }
    }

    // Calculate distribution for each subject
    for (var result in _results!) {
      result.subjects.forEach((subject, mark) {
        double marks = double.tryParse(mark) ?? 0;
        var ranges = subjectRanges[subject]!;
        
        if (marks <= 20) ranges['0-20'] = (ranges['0-20'] ?? 0) + 1;
        else if (marks <= 40) ranges['21-40'] = (ranges['21-40'] ?? 0) + 1;
        else if (marks <= 60) ranges['41-60'] = (ranges['41-60'] ?? 0) + 1;
        else if (marks <= 80) ranges['61-80'] = (ranges['61-80'] ?? 0) + 1;
        else ranges['81-100'] = (ranges['81-100'] ?? 0) + 1;
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...subjectRanges.entries.map((entry) {
              var subject = entry.key;
              var ranges = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _results!.length.toDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.round()} students',
                                const TextStyle(color: Colors.white),
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
                                if (value < 0 || value >= ranges.length) {
                                  return const Text('');
                                }
                                return Text(
                                  ranges.keys.elementAt(value.toInt()),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 5,
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          ranges.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: ranges.values.elementAt(index).toDouble(),
                                color: Colors.blue.withOpacity(0.8),
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
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.department} - Year ${widget.year} - ${widget.className}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverallStatistics(),
                  const SizedBox(height: 16),
                  _buildSubjectWiseStats(),
                  const SizedBox(height: 16),
                  _buildPerformanceDistribution(),
                ],
              ),
            ),
    );
  }
}
