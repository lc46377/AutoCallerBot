// lib/models/intake.dart
class IntakeStartResponse {
  final String sessionId;
  final List<String>
      nextFields; // e.g., ["order_id","date_of_purchase","bill_amount"]
  final String question; // single compact prompt to show in UI
  final String? callId; // present if a call already started

  IntakeStartResponse({
    required this.sessionId,
    required this.nextFields,
    required this.question,
    this.callId,
  });

  factory IntakeStartResponse.fromJson(Map<String, dynamic> j) {
    return IntakeStartResponse(
      sessionId: j['session_id'] as String,
      nextFields: (j['next_fields'] as List<dynamic>? ?? []).cast<String>(),
      question: (j['question'] ?? '') as String,
      callId: j['call_id'] as String?,
    );
  }
}

class IntakeReplyResponse {
  final bool done; // true => call is being placed
  final List<String> nextFields; // empty when done
  final String? question; // next compact prompt, when done == false
  final String? message; // e.g. "Calling the company now."
  final String? callId;

  IntakeReplyResponse({
    required this.done,
    required this.nextFields,
    this.question,
    this.message,
    this.callId,
  });

  factory IntakeReplyResponse.fromJson(Map<String, dynamic> j) {
    return IntakeReplyResponse(
      done: (j['done'] ?? false) as bool,
      nextFields: (j['next_fields'] as List<dynamic>? ?? []).cast<String>(),
      question: j['question'] as String?,
      message: j['message'] as String?,
      callId: j['call_id'] as String?,
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
