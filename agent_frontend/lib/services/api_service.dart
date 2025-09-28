import 'package:dio/dio.dart';

import 'package:agent_frontend/models/call_log.dart';
import 'package:agent_frontend/models/intake.dart';

// Configure at build time: pass --dart-define=BASE_URL=http://<your-mac-ip>:8000 for real iPhone
const kBaseUrl = String.fromEnvironment('BASE_URL',
    defaultValue: 'http://10.200.61.198:8000');

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: kBaseUrl,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[DIO] $obj'),
    ));
    print('[ApiService] Base URL: ${_dio.options.baseUrl}');
  }

  // Mocked locally; not part of FastAPI spec but used by homepage
  Future<List<CallLog>> fetchCallLogs() async {
    return [
      CallLog(
        title: 'Walmart: Replacement started',
        subtitle: 'Headphones • Ticket #RMA-2311',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        success: true,
      ),
      CallLog(
        title: 'Enterprise: Refund requested',
        subtitle: 'Rental ID 88-1211 • escalated',
        time: DateTime.now().subtract(const Duration(days: 1)),
        success: false,
      ),
    ];
  }

  Future<IntakeStartResponse> intakeStart(String utterance) async {
    try {
      final r =
          await _dio.post('/intake/start', data: {'utterance': utterance});
      return IntakeStartResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['detail']?.toString() ??
              e.message ??
              'Start failed')
          : e.message ?? 'Start failed';
      throw ApiException(msg, status: e.response?.statusCode);
    }
  }

  Future<IntakeReplyResponse> intakeReply(
      String sessionId, String answer) async {
    try {
      final r = await _dio.post('/intake/reply', data: {
        'session_id': sessionId,
        'answer': answer,
      });
      return IntakeReplyResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['detail']?.toString() ??
              e.message ??
              'Reply failed')
          : e.message ?? 'Reply failed';
      throw ApiException(msg, status: e.response?.statusCode);
    }
  }

  Future<bool> hangupBySession(String sessionId) async {
    try {
      final r =
          await _dio.post('/call/hangup', data: {'session_id': sessionId});
      return (r.statusCode ?? 500) < 300;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Hangup failed',
          status: e.response?.statusCode);
    }
  }
}
