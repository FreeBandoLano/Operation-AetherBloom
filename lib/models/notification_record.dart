/// Status of a notification
enum NotificationStatus {
  scheduled,
  sent,
  cancelled,
  failed,
  info,
}

class NotificationRecord {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationStatus status;

  const NotificationRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == (json['status'] as String? ?? NotificationStatus.sent.toString()),
        orElse: () => NotificationStatus.sent,
      ),
    );
  }
} 