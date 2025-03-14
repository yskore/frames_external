import 'dart:convert';

class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final int? httpStatus;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.httpStatus,
  });

  bool get isSuccess => success;
  bool get isError => !success;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: _extractData(json),
      httpStatus: json['httpStatus'],
    );
  }

  static Map<String, dynamic>? _extractData(Map<String, dynamic> json) {
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return null;
  }

  factory ApiResponse.fromDioResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return ApiResponse.fromJson(responseData);
    } else if (responseData is String) {
      try {
        final jsonData = json.decode(responseData);
        if (jsonData is Map<String, dynamic>) {
          return ApiResponse.fromJson(jsonData);
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    // Default error response if we couldn't parse the data
    return ApiResponse.error('Invalid response format');
  }

  factory ApiResponse.error(String message, {int? httpStatus}) {
    return ApiResponse(
      success: false,
      message: message,
      httpStatus: httpStatus,
    );
  }

  factory ApiResponse.success({Map<String, dynamic>? data, String? message}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, data: $data, httpStatus: $httpStatus}';
  }
}
