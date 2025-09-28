import 'dart:convert';

class IntakeStartResponse {
  final String sessionId;
  final List<String> nextFields;
  final String question;
  final String? callId;

  IntakeStartResponse({
    required this.sessionId,
    required this.nextFields,
    required this.question,
    this.callId,
  });

  factory IntakeStartResponse.fromJson(Map<String, dynamic> j) {
    return IntakeStartResponse(
      sessionId: j['session_id'] ?? '',
      nextFields:
          (j['next_fields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      question: j['question']?.toString() ?? '',
      callId: j['call_id']?.toString(),
    );
  }
}

class IntakeReplyResponse {
  final bool done;
  final String? message;
  final String? callId;
  final List<String> nextFields;
  final String? question;

  IntakeReplyResponse({
    required this.done,
    this.message,
    this.callId,
    this.nextFields = const [],
    this.question,
  });

  factory IntakeReplyResponse.fromJson(Map<String, dynamic> j) {
    return IntakeReplyResponse(
      done: j['done'] == true,
      message: j['message']?.toString(),
      callId: j['call_id']?.toString(),
      nextFields:
          (j['next_fields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      question: j['question']?.toString(),
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, {this.status});
  @override
  String toString() => 'ApiException($status): $message';
}


