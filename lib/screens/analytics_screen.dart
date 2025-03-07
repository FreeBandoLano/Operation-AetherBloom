import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _medicationService = MedicationService();
  late List<Medication> _medications;
  bool _isLoading = true;
  int _selectedPeriod = 7; // Default to 7 days

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      _medications = _medicationService.medications;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (days) {
              setState(() => _selectedPeriod = days);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 7,
                child: Text('Last 7 Days'),
              ),
              const PopupMenuItem(
                value: 30,
                child: Text('Last 30 Days'),
              ),
              const PopupMenuItem(
                value: 90,
                child: Text('Last 90 Days'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 64.0,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'No medications to analyze',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to add medication screen
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Medication'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMedications,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Adherence',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16.0),
                              SizedBox(
                                height: 200,
                                child: _buildAdherenceChart(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medication Adherence',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16.0),
                              ..._medications.map((medication) {
                                final adherenceRate =
                                    medication.getAdherenceRate(
                                  start: DateTime.now().subtract(
                                    Duration(days: _selectedPeriod),
                                  ),
                                  end: DateTime.now(),
                                );
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(medication.name),
                                      subtitle: Text(
                                        '${(adherenceRate * 100).toStringAsFixed(1)}% adherence',
                                      ),
                                      trailing: SizedBox(
                                        width: 100,
                                        child: LinearProgressIndicator(
                                          value: adherenceRate,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            adherenceRate >= 0.8
                                                ? Colors.green
                                                : adherenceRate >= 0.6
                                                    ? Colors.orange
                                                    : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (medication != _medications.last)
                                      const Divider(),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAdherenceChart() {
    final now = DateTime.now();
    final data = List.generate(_selectedPeriod, (index) {
      final date = now.subtract(Duration(days: _selectedPeriod - 1 - index));
      var totalAdherence = 0.0;
      var count = 0;

      for (final medication in _medications) {
        final adherenceRate = medication.getAdherenceRate(
          start: date,
          end: date.add(const Duration(days: 1)),
        );
        if (adherenceRate >= 0) {
          totalAdherence += adherenceRate;
          count++;
        }
      }

      return FlSpot(
        index.toDouble(),
        count > 0 ? (totalAdherence / count) : 0,
      );
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${(value * 100).toInt()}%');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % (_selectedPeriod ~/ 7) != 0) {
                  return const SizedBox.shrink();
                }
                final date = now.subtract(
                  Duration(days: _selectedPeriod - 1 - value.toInt()),
                );
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_selectedPeriod - 1).toDouble(),
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
} 