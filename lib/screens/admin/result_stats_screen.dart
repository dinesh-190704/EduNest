import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/result_model.dart';
import '../../providers/result_provider.dart';

class ResultStatsScreen extends StatelessWidget {
  const ResultStatsScreen({super.key});

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
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

  Widget _buildOverallStats(PassStats stats) {
    final failedStudents = stats.totalStudents - stats.passedStudents;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Students', stats.totalStudents.toString()),
                _buildStatItem('Passed', stats.passedStudents.toString()),
                _buildStatItem('Failed', failedStudents.toString()),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Overall Pass Rate: ${stats.passPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectWiseStats(PassStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject-wise Pass Percentage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                        _getColorForPercentage(entry.value),
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
    );
  }

  Widget _buildBarChart(PassStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= stats.subjectWisePassPercent.length) {
                            return const Text('');
                          }
                          return Text(
                            stats.subjectWisePassPercent.keys.elementAt(value.toInt()),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: stats.subjectWisePassPercent.entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: stats.subjectWisePassPercent.keys.toList().indexOf(entry.key),
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: _getColorForPercentage(entry.value),
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResultProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            body: Center(child: Text(provider.error!)),
          );
        }

        final stats = provider.passStats;
        if (stats == null) {
          return const Scaffold(
            body: Center(child: Text('No statistics available')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Result Statistics'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.center,
                child: Text(
                  '${provider.currentDepartment ?? ''} - Year ${provider.currentYear ?? ''} - Section ${provider.currentClass ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallStats(stats),
                const SizedBox(height: 16),
                _buildSubjectWiseStats(stats),
                const SizedBox(height: 16),
                _buildBarChart(stats),
              ],
            ),
          ),
        );
      },
    );
  }
}
