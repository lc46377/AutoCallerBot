class IntakeStartResponse {
  String sessionId;
  List<String> nextFields;
  String question;
  String? callId;

  IntakeStartResponse({
    required this.sessionId,
    required this.nextFields,
    required this.question,
    this.callId,
  });

  factory IntakeStartResponse.fromJson(Map<String, dynamic> json) {
    return IntakeStartResponse(
      sessionId: json['sessionId'] as String? ?? '',
      nextFields: (json['nextFields'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      question: json['question'] as String? ?? '',
      callId: json['callId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'nextFields': nextFields,
      'question': question,
      'callId': callId,
    };
  }
}

class IntakeReplyResponse {
  bool done;
  String? message;
  String? callId;
  List<String> nextFields;
  String question;

  IntakeReplyResponse({
    required this.done,
    this.message,
    this.callId,
    required this.nextFields,
    required this.question,
  });

  factory IntakeReplyResponse.fromJson(Map<String, dynamic> json) {
    return IntakeReplyResponse(
      done: json['done'] as bool? ?? false,
      message: json['message'] as String?,
      callId: json['callId'] as String?,
      nextFields: (json['nextFields'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      question: json['question'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'done': done,
      'message': message,
      'callId': callId,
      'nextFields': nextFields,
      'question': question,
    };
  }
}


