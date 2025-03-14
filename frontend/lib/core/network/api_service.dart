import 'package:dio/dio.dart';

import 'api_response.dart';
import 'dio_client.dart';

class ApiService {
  final Dio _dio = DioClient().dio;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return ApiResponse.fromDioResponse(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          return ApiResponse.fromDioResponse(e.response?.data);
        }
        return ApiResponse.error(
          ApiErrorHandler.handleError(e),
          httpStatus: e.response?.statusCode,
        );
      }
      return ApiResponse.error('Unknown error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return ApiResponse.fromDioResponse(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          return ApiResponse.fromDioResponse(e.response?.data);
        }
        return ApiResponse.error(
          ApiErrorHandler.handleError(e),
          httpStatus: e.response?.statusCode,
        );
      }
      return ApiResponse.error('Unknown error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return ApiResponse.fromDioResponse(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          return ApiResponse.fromDioResponse(e.response?.data);
        }
        return ApiResponse.error(
          ApiErrorHandler.handleError(e),
          httpStatus: e.response?.statusCode,
        );
      }
      return ApiResponse.error('Unknown error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse.fromDioResponse(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          return ApiResponse.fromDioResponse(e.response?.data);
        }
        return ApiResponse.error(
          ApiErrorHandler.handleError(e),
          httpStatus: e.response?.statusCode,
        );
      }
      return ApiResponse.error('Unknown error occurred: ${e.toString()}');
    }
  }
}
