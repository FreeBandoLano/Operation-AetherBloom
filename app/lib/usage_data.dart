class UsageData {
  final DateTime timestamp;
  final int inhalerUseCount;
  final String notes;

  UsageData({
    required this.timestamp,
    required this.inhalerUseCount,
    this.notes = ' ',
  });

  // Example function to convert UsageData to JSON format
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'inhalerUseCount': inhalerUseCount,
      'notes': notes,
    };
  }

  // Create a UsageData object from JSON, ensuring to parse the timestamp into DateTime
  static UsageData fromJson(Map<String, dynamic> json) {
    return UsageData(
      timestamp: DateTime.parse(json['timestamp']),  // Convert string to DateTime
      inhalerUseCount: json['inhalerUseCount'],
      notes: json['notes'] ?? '',
    );
  }
}
