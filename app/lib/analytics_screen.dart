import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'usage_data.dart';
import 'usage_data_source.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Method channel for Python integration
const MethodChannel _channel = MethodChannel('com.example.project_aetherbloom/data_channel');

/// A screen that displays analytics and insights about inhaler usage patterns.
/// Features:
/// - Weekly usage overview
/// - Daily patterns
/// - Monthly trends
/// - Usage insights and recommendations
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final UsageDataSource _dataSource = UsageDataSource();
  List<UsageData> _usageData = [];
  bool _isLoading = true;
  String _selectedTimeFrame = 'Week'; // 'Week', 'Month', 'Year'

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    setState(() => _isLoading = true);
    final data = await _dataSource.getUsageData();
    setState(() {
      _usageData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: const Color(0xFFF4A7B9),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsageData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeFrameSelector(),
                    const SizedBox(height: 20),
                    _buildUsageOverview(),
                    const SizedBox(height: 30),
                    _buildUsageChart(),
                    const SizedBox(height: 30),
                    _buildUsagePatterns(),
                    const SizedBox(height: 30),
                    _buildInsights(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['Week', 'Month', 'Year'].map((timeFrame) {
          final isSelected = timeFrame == _selectedTimeFrame;
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeFrame = timeFrame),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF4A7B9) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timeFrame,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsageOverview() {
    final stats = _calculateStats();
    
    return Row(
      children: [
        _buildStatCard(
          'Total Uses',
          stats.totalUses.toString(),
          Icons.medication,
          const Color(0xFFF4A7B9),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Daily Average',
          stats.dailyAverage.toStringAsFixed(1),
          Icons.calendar_today,
          const Color(0xFF81D4FA),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    final chartData = _getChartData();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Pattern',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartData.maxValue * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < chartData.labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              chartData.labels[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData.data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: const Color(0xFFF4A7B9),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePatterns() {
    final patterns = _analyzePatterns();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Patterns',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...patterns.map((pattern) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  pattern.icon,
                  color: const Color(0xFFF4A7B9),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(pattern.description),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final insights = _generateInsights();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Card(
            elevation: 0,
            color: insight.color.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(insight.icon, color: insight.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight.message,
                      style: TextStyle(color: insight.color.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  // Data analysis methods
  _UsageStats _calculateStats() {
    if (_usageData.isEmpty) {
      return _UsageStats(totalUses: 0, dailyAverage: 0);
    }

    final periodData = _getFilteredData();
    final totalUses = periodData.fold<int>(
      0,
      (sum, usage) => sum + usage.inhalerUseCount,
    );

    final firstDate = periodData.first.timestamp;
    final lastDate = periodData.last.timestamp;
    final daysDifference = lastDate.difference(firstDate).inDays + 1;

    return _UsageStats(
      totalUses: totalUses,
      dailyAverage: totalUses / daysDifference,
    );
  }

  _ChartData _getChartData() {
    if (_usageData.isEmpty) {
      return _ChartData(data: [], labels: [], maxValue: 0);
    }

    final now = DateTime.now();
    List<double> data = [];
    List<String> labels = [];
    
    switch (_selectedTimeFrame) {
      case 'Week':
        // Last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayUsage = _getDayUsage(date);
          data.add(dayUsage.toDouble());
          labels.add(DateFormat('E').format(date));
        }
        break;
      case 'Month':
        // Last 4 weeks
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: i * 7 + 6));
          final weekUsage = _getWeekUsage(weekStart);
          data.add(weekUsage.toDouble());
          labels.add('Week ${4 - i}');
        }
        break;
      case 'Year':
        // Last 6 months
        for (int i = 5; i >= 0; i--) {
          final month = now.month - i;
          final year = now.year + (month <= 0 ? -1 : 0);
          final adjustedMonth = month <= 0 ? month + 12 : month;
          final monthUsage = _getMonthUsage(year, adjustedMonth);
          data.add(monthUsage.toDouble());
          labels.add(DateFormat('MMM').format(DateTime(year, adjustedMonth)));
        }
        break;
    }

    return _ChartData(
      data: data,
      labels: labels,
      maxValue: data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b),
    );
  }

  int _getDayUsage(DateTime date) {
    return _usageData
        .where((usage) =>
            usage.timestamp.year == date.year &&
            usage.timestamp.month == date.month &&
            usage.timestamp.day == date.day)
        .fold<int>(0, (sum, usage) => sum + usage.inhalerUseCount);
  }

  int _getWeekUsage(DateTime weekStart) {
    return _usageData
        .where((usage) =>
            usage.timestamp.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            usage.timestamp.isBefore(weekStart.add(const Duration(days: 7))))
        .fold<int>(0, (sum, usage) => sum + usage.inhalerUseCount);
  }

  int _getMonthUsage(int year, int month) {
    return _usageData
        .where((usage) =>
            usage.timestamp.year == year && usage.timestamp.month == month)
        .fold<int>(0, (sum, usage) => sum + usage.inhalerUseCount);
  }

  List<_UsagePattern> _analyzePatterns() {
    if (_usageData.isEmpty) {
      return [
        _UsagePattern(
          icon: Icons.info_outline,
          description: 'Not enough data to analyze patterns yet.',
        ),
      ];
    }

    final patterns = <_UsagePattern>[];
    final periodData = _getFilteredData();
    
    // Analyze time of day patterns
    final timeOfDayUsage = _analyzeTimeOfDay(periodData);
    patterns.add(_UsagePattern(
      icon: Icons.access_time,
      description: 'Most frequent usage: $timeOfDayUsage',
    ));

    // Analyze day of week patterns
    final dayOfWeekPattern = _analyzeDayOfWeek(periodData);
    if (dayOfWeekPattern.isNotEmpty) {
      patterns.add(_UsagePattern(
        icon: Icons.calendar_view_week,
        description: 'Highest usage on: $dayOfWeekPattern',
      ));
    }

    return patterns;
  }

  String _analyzeTimeOfDay(List<UsageData> data) {
    final morning = data.where((usage) =>
        usage.timestamp.hour >= 5 && usage.timestamp.hour < 12).length;
    final afternoon = data.where((usage) =>
        usage.timestamp.hour >= 12 && usage.timestamp.hour < 17).length;
    final evening = data.where((usage) =>
        usage.timestamp.hour >= 17 && usage.timestamp.hour < 22).length;
    final night = data.where((usage) =>
        usage.timestamp.hour >= 22 || usage.timestamp.hour < 5).length;

    final max = [morning, afternoon, evening, night].reduce((a, b) => a > b ? a : b);
    if (max == morning) return 'Morning (5 AM - 12 PM)';
    if (max == afternoon) return 'Afternoon (12 PM - 5 PM)';
    if (max == evening) return 'Evening (5 PM - 10 PM)';
    return 'Night (10 PM - 5 AM)';
  }

  String _analyzeDayOfWeek(List<UsageData> data) {
    final dayCount = List<int>.filled(7, 0);
    for (var usage in data) {
      dayCount[usage.timestamp.weekday - 1] += usage.inhalerUseCount;
    }

    final maxUsage = dayCount.reduce((a, b) => a > b ? a : b);
    final maxDayIndex = dayCount.indexOf(maxUsage);
    
    return DateFormat('EEEE').format(
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - (maxDayIndex + 1))),
    );
  }

  List<_Insight> _generateInsights() {
    if (_usageData.isEmpty) {
      return [
        _Insight(
          icon: Icons.info_outline,
          message: 'Start tracking your inhaler usage to see insights.',
          color: Colors.grey,
        ),
      ];
    }

    final insights = <_Insight>[];
    final stats = _calculateStats();
    
    // Usage frequency insights
    if (stats.dailyAverage > 3) {
      insights.add(_Insight(
        icon: Icons.warning_amber_rounded,
        message: 'Your inhaler usage is above average. Consider consulting your doctor.',
        color: Colors.orange,
      ));
    } else if (stats.dailyAverage < 0.5) {
      insights.add(_Insight(
        icon: Icons.check_circle_outline,
        message: 'Your asthma appears to be well-controlled with minimal inhaler use.',
        color: Colors.green,
      ));
    }

    // Pattern insights
    final patterns = _analyzePatterns();
    if (patterns.isNotEmpty) {
      insights.add(_Insight(
        icon: Icons.timeline,
        message: 'Consider preventive measures during ${patterns.first.description.toLowerCase()}',
        color: const Color(0xFF81D4FA),
      ));
    }

    return insights;
  }

  List<UsageData> _getFilteredData() {
    final now = DateTime.now();
    switch (_selectedTimeFrame) {
      case 'Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _usageData.where((usage) => usage.timestamp.isAfter(weekAgo)).toList();
      case 'Month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _usageData.where((usage) => usage.timestamp.isAfter(monthAgo)).toList();
      case 'Year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return _usageData.where((usage) => usage.timestamp.isAfter(yearAgo)).toList();
      default:
        return _usageData;
    }
  }
}

// Helper classes
class _UsageStats {
  final int totalUses;
  final double dailyAverage;

  _UsageStats({required this.totalUses, required this.dailyAverage});
}

class _ChartData {
  final List<double> data;
  final List<String> labels;
  final double maxValue;

  _ChartData({required this.data, required this.labels, required this.maxValue});
}

class _UsagePattern {
  final IconData icon;
  final String description;

  _UsagePattern({required this.icon, required this.description});
}

class _Insight {
  final IconData icon;
  final String message;
  final Color color;

  _Insight({required this.icon, required this.message, required this.color});
}
