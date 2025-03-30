import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

import '../auth/token_manager.dart';
import '../config/app_config.dart';
import '../network/api_response.dart';

class StorageRepository {
  final TokenManager _tokenManager = TokenManager();

  Future<ApiResponse> uploadImage({
  required File imageFile,
  required String folderName,
  String? resourceId,
  String? resourceType,
}) async {
  try {
    final token = _tokenManager.accessToken;
    final appConfig = AppConfig();
    final baseUrl = appConfig.getConfig(['api', 'base_url']);
    final apiKey = appConfig.getConfig(['api', 'key']);
    final apiHeader = appConfig.getConfig(['api', 'header']);

    final url = Uri.parse('$baseUrl/upload-image');

    // Create a multipart request
    final request = http.MultipartRequest('POST', url);
    print('[LOGS] request: $request');

    // Add headers
    request.headers[apiHeader] = apiKey;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add file
    final fileExtension = path.extension(imageFile.path).replaceAll('.', '');
    print('[LOGS] fileExtension: $fileExtension');
    final contentType = _getContentType(fileExtension);
    print('[LOGS] contentType: $contentType');

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: contentType,
      ),
    );

    // Add other fields
    request.fields['folderName'] = folderName;
    if (resourceId != null) {
      request.fields['resourceId'] = resourceId;
    }
    if (resourceType != null) {
      request.fields['resourceType'] = resourceType;
    }

    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Parse response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final parsedBody = jsonDecode(response.body);
        
        // Extract the image URL from the response
        if (parsedBody is Map) {
          // If response has the expected structure with data.imageUrl
          if (parsedBody.containsKey('data') && 
              parsedBody['data'] is Map && 
              parsedBody['data'].containsKey('imageUrl')) {
            final imageUrl = parsedBody['data']['imageUrl'];
            return ApiResponse.success(
              data: {'imageUrl': imageUrl},
              message: 'Image uploaded successfully'
            );
          }
          
          // If response has a direct imageUrl field
          else if (parsedBody.containsKey('imageUrl')) {
            final imageUrl = parsedBody['imageUrl'];
            return ApiResponse.success(
              data: {'imageUrl': imageUrl},
              message: 'Image uploaded successfully'
            );
          }
        }
        
        // If we couldn't find the imageUrl in the expected places, return the whole parsed body
        return ApiResponse.success(
            data: parsedBody is Map ? parsedBody as Map<String, dynamic> : {'response': parsedBody},
          message: 'Response received successfully'
        );
        
      } catch (e) {
        // The response wasn't valid JSON
        if (kDebugMode) {
          print('Error parsing response: $e');
          print('Response body: ${response.body}');
        }
        
        // Check if the response might be a direct URL
        if (response.body.trim().startsWith('http')) {
          return ApiResponse.success(
            data: {'imageUrl': response.body.trim()},
            message: 'Image URL received'
          );
        } else {
          return ApiResponse.error('Invalid response format: ${response.body}');
        }
      }
    } else {
      if (kDebugMode) {
        print('Error uploading image: ${response.body}');
      }
      return ApiResponse.error('Failed to upload image: ${response.body}',
          httpStatus: response.statusCode);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error uploading image: $e');
    }
    return ApiResponse.error('Failed to upload image: $e');
  }
}
  MediaType _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
