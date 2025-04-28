import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

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

  Future<ApiResponse> postMultipart(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, File>? files,
  }) async {
    try {
      final formData = FormData();

      // Add regular data fields
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // Add files
      if (files != null) {
        await Future.forEach(files.entries, (entry) async {
          final file = entry.value;
          final fileName = file.path.split('/').last;

          // Detect MIME type based on file extension
          String mimeType = _getMimeType(fileName);

          formData.files.add(
            MapEntry(
              entry.key,
              await MultipartFile.fromFile(
                file.path,
                filename: fileName,
                contentType:
                    mimeType.isNotEmpty ? MediaType.parse(mimeType) : null,
              ),
            ),
          );
        });
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
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

  // Helper method to determine MIME type from file extension
  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return ''; // Let Dio determine the content type
    }
  }
}
