class CallLog {
  final String title;
  final String subtitle;
  final DateTime time;
  final bool success;

  const CallLog({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.success,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      success: json['success'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'time': time.toIso8601String(),
      'success': success,
    };
  }
}


