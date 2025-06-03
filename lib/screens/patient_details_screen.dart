import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({
    Key? key,
    required this.patientId,
    required this.patientData,
  }) : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Stream<QuerySnapshot>? _patientUsageStream;

  @override
  void initState() {
    super.initState();
    _initializePatientData();
  }

  void _initializePatientData() {
    _patientUsageStream = FirebaseFirestore.instance
        .collection('inhaler_usage')
        .where('patientId', isEqualTo: widget.patientId)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientData['firstName'] ?? 'Unknown'} ${widget.patientData['lastName'] ?? 'Patient'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit patient screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit patient feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: Text(
                            _getPatientInitials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.patientData['firstName'] ?? 'Unknown'} ${widget.patientData['lastName'] ?? 'Patient'}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Email: ${widget.patientData['email'] ?? 'Not provided'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (widget.patientData['phone'] != null && widget.patientData['phone'].isNotEmpty)
                                Text(
                                  'Phone: ${widget.patientData['phone']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (widget.patientData['age'] != null)
                                Text(
                                  'Age: ${widget.patientData['age']} years',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (widget.patientData['medicalCondition'] != null && widget.patientData['medicalCondition'].isNotEmpty)
                                Text(
                                  'Condition: ${widget.patientData['medicalCondition']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Usage Analytics Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usage Analytics',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _patientUsageStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No usage data available',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }
                          
                          List<Map<String, dynamic>> chartData = _processUsageData(snapshot.data!.docs);
                          
                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() < chartData.length) {
                                        return Text(chartData[value.toInt()]['day']);
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chartData.asMap().entries.map((entry) {
                                    return FlSpot(entry.key.toDouble(), entry.value['count'].toDouble());
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Usage List
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Usage',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _patientUsageStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No recent usage data');
                        }
                        
                        List<QueryDocumentSnapshot> recentUsage = snapshot.data!.docs.take(10).toList();
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentUsage.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> usageData = recentUsage[index].data() as Map<String, dynamic>;
                            DateTime usageTime = (usageData['usageTime'] as Timestamp?)?.toDate() ?? 
                                                 (usageData['timestamp'] as Timestamp?)?.toDate() ?? 
                                                 DateTime.now();
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.air, color: Colors.green.shade700),
                              ),
                              title: Text('${usageData['medicationType'] ?? 'Inhaler'} Usage'),
                              subtitle: Text(
                                '${usageData['dosage'] ?? 'Unknown'} mg • ${_formatDateTime(usageTime)}',
                              ),
                              trailing: Text(
                                _formatLastUsage(usageTime),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      },
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

  String _getPatientInitials() {
    String initials = '';
    String firstName = widget.patientData['firstName'] ?? widget.patientData['name'] ?? '';
    String lastName = widget.patientData['lastName'] ?? '';
    
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isEmpty ? '??' : initials;
  }

  List<Map<String, dynamic>> _processUsageData(List<QueryDocumentSnapshot> docs) {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> chartData = [];
    
    // Process last 7 days
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      String dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(day.weekday - 1) % 7];
      
      int count = 0;
      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime usageTime = (data['usageTime'] as Timestamp?)?.toDate() ?? 
                             (data['timestamp'] as Timestamp?)?.toDate() ?? 
                             DateTime.now();
        
        if (usageTime.year == day.year &&
            usageTime.month == day.month &&
            usageTime.day == day.day) {
          count++;
        }
      }
      
      chartData.add({'day': dayName, 'count': count});
    }
    
    return chartData;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatLastUsage(DateTime lastUsage) {
    Duration difference = DateTime.now().difference(lastUsage);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 