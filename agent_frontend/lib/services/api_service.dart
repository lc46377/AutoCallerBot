import 'package:dio/dio.dart';

import 'package:agent_frontend/models/call_log.dart';
import 'package:agent_frontend/models/intake.dart';

const kBaseUrl = "http://localhost:8000";

class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: kBaseUrl));

  final Dio _dio;

  Future<List<CallLog>> fetchCallLogs() async {
    try {
      final response = await _dio.get('/call-logs');
      final data = response.data as List<dynamic>? ?? const [];
      return data
          .map((e) => CallLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [
          CallLog(
            title: 'Welcome to Fetch',
            subtitle: 'Start your first task',
            time: DateTime.now().subtract(const Duration(minutes: 5)),
            success: true,
          ),
          CallLog(
            title: 'Example intake',
            subtitle: 'Tap to view details',
            time: DateTime.now().subtract(const Duration(hours: 2)),
            success: false,
          ),
        ];
      }
      rethrow;
    }
  }

  Future<IntakeStartResponse> intakeStart(String utterance) async {
    final response = await _dio.post('/intake/start', data: {
      'utterance': utterance,
    });
    return IntakeStartResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IntakeReplyResponse> intakeReply(String sessionId, String answer) async {
    final response = await _dio.post('/intake/reply', data: {
      'sessionId': sessionId,
      'answer': answer,
    });
    return IntakeReplyResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> hangupBySession(String sessionId) async {
    final response = await _dio.post('/call/hangup', data: {
      'sessionId': sessionId,
    });
    final data = response.data as Map<String, dynamic>?;
    return (data?['success'] as bool?) ?? false;
  }
}


