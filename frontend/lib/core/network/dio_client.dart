import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/token_manager.dart';
import '../config/app_config.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final StreamController<bool> _tokenExpiredController;
  late final Dio dio;
  final TokenManager _tokenManager = TokenManager();

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio();
    _tokenExpiredController = StreamController.broadcast();
    _configureClient();
  }

  Stream<bool> get onTokenExpired => _tokenExpiredController.stream;

  void _configureClient() {
    try {
      final appConfig = AppConfig();
      final apiConfig = appConfig.apiConfig;

      final baseUrl = apiConfig['base_url'] as String;
      final apiKey = apiConfig['key'] as String;
      final apiHeader = apiConfig['header'] as String;

      dio.options = BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          apiHeader: apiKey,
          'Content-Type': 'application/json',
        },
      );

      dio.interceptors
          .add(AuthInterceptor(_tokenManager, _tokenExpiredController));
      dio.interceptors.add(RequestInterceptor());
      dio.interceptors.add(ResponseInterceptor());
    } catch (e) {
      log('Failed to configure Dio client: $e', name: 'DioClient');
      throw Exception('Failed to configure HTTP client: $e');
    }
  }
}

class AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final StreamController<bool> _tokenExpiredController;

  AuthInterceptor(this._tokenManager, this._tokenExpiredController);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_tokenManager.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_tokenManager.accessToken}';
      if (kDebugMode) {
        log('Added auth token to request', name: 'AuthInterceptor');
      }
    }

    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 errors (token expired or invalid)
    if (err.response?.statusCode == 401) {
      log('Authentication error: Unauthorized access', name: 'AuthInterceptor');
      _tokenExpiredController.add(true);
      _tokenManager.clearToken();
    }

    return super.onError(err, handler);
  }
}

class RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      log('REQUEST[${options.method}] => PATH: ${options.path}',
          name: 'DioClient');
      // log('REQUEST HEADERS: ${options.headers}', name: 'DioClient');
      // log('REQUEST BODY: ${options.data}', name: 'DioClient');
    }
    return super.onRequest(options, handler);
  }
}

class ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      log('RESPONSE DATA: ${response.data.toString().replaceAll('\n', ' ')}',
          name:
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    }

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;

      // If success field is not present, add it based on the status code
      if (!data.containsKey('success')) {
        final isSuccessStatusCode = response.statusCode != null &&
            (response.statusCode! >= 200 && response.statusCode! < 300);
        response.data = {
          'success': isSuccessStatusCode,
          'message':
              data['message'] ?? (isSuccessStatusCode ? 'Success' : 'Error'),
          'data': data['data'] ?? data,
          'httpStatus': response.statusCode,
        };
      }

      // Add HTTP status to the response if not present
      if (response.data['httpStatus'] == null) {
        response.data['httpStatus'] = response.statusCode;
      }
    }

    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (kDebugMode) {
      log('RESPONSE DATA: ${response?.data}',
          name:
              'RESPONSE[${response?.statusCode}] => PATH: ${err.requestOptions.path}');
    }

    if (response?.data is Map<String, dynamic>) {
      handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: {
            'success': false,
            'message': (response?.data as Map)['message'] ??
                ApiErrorHandler.handleError(err),
            'httpStatus': response?.statusCode,
          },
        ),
      );
    } else {
      handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: {
            'success': false,
            'message': ApiErrorHandler.handleError(err),
            'httpStatus': response?.statusCode,
          },
        ),
      );
    }
  }
}

class ApiErrorHandler {
  static String handleError(DioException error) {
    if (error.response?.data != null) {
      try {
        final Map<String, dynamic> errorData = error.response?.data;
        if (errorData.containsKey('message')) {
          return errorData['message'];
        }
      } catch (_) {}
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Request timeout';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout';
      case DioExceptionType.badResponse:
        return _handleErrorResponse(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return 'An unexpected error occurred';
    }
  }

  static String _handleErrorResponse(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Resource not found';
      case 500:
        return 'Internal server error';
      default:
        return 'Something went wrong';
    }
  }
}
