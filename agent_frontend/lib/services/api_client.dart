// api_client.dart
import 'package:agent_frontend/ui/common/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio()
      ..options.baseUrl = AppConstants.baseUrl
      ..options.receiveDataWhenStatusError = true
      ..options.connectTimeout =
          const Duration(milliseconds: AppConstants.connectionTimeout)
      ..options.receiveTimeout =
          const Duration(milliseconds: AppConstants.receiveTimeout)
      ..options.responseType = ResponseType.json
      // Add log interceptor
      ..interceptors.addAll([
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
        ),
        // Add token interceptor using the same Dio instance
      ]);
  }

  // Get:-----------------------------------------------------------------------
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Post:----------------------------------------------------------------------
  Future<Response> post(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }
}
