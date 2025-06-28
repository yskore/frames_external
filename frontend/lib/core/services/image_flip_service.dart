import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageFlipService {
  static Future<String> flipHorizontal(String imageUrl) async {
    try {
      // Download image
      final imageBytes = await _downloadImage(imageUrl);
      
      // Decode image
      final ui.Image image = await _decodeImage(imageBytes);
      
      // Flip horizontally
      final flippedImage = await _flipImageHorizontally(image);
      
      // Save to temporary file
      final tempPath = await _saveImageToTemp(flippedImage, 'horizontal');
      
      return tempPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error flipping image horizontally: $e');
      }
      rethrow;
    }
  }

  static Future<String> flipVertical(String imageUrl) async {
    try {
      // Download image
      final imageBytes = await _downloadImage(imageUrl);
      
      // Decode image
      final ui.Image image = await _decodeImage(imageBytes);
      
      // Flip vertically
      final flippedImage = await _flipImageVertically(image);
      
      // Save to temporary file
      final tempPath = await _saveImageToTemp(flippedImage, 'vertical');
      
      return tempPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error flipping image vertically: $e');
      }
      rethrow;
    }
  }

  static Future<String> flipBoth(String imageUrl) async {
    try {
      // Download image
      final imageBytes = await _downloadImage(imageUrl);
      
      // Decode image
      final ui.Image image = await _decodeImage(imageBytes);
      
      // Flip both ways
      final flippedImage = await _flipImageBoth(image);
      
      // Save to temporary file
      final tempPath = await _saveImageToTemp(flippedImage, 'both');
      
      return tempPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error flipping image both ways: $e');
      }
      rethrow;
    }
  }

  static Future<Uint8List> _downloadImage(String imageUrl) async {
    if (imageUrl.startsWith('file://')) {
      // Local file - read directly
      final filePath = imageUrl.substring(7);
      final file = File(filePath);
      return await file.readAsBytes();
    } else {
      // Remote URL - download via HTTP
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    }
  }

  static Future<ui.Image> _decodeImage(Uint8List imageBytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  static Future<ui.Image> _flipImageHorizontally(ui.Image image) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Scale horizontally by -1 to flip
    canvas.scale(-1.0, 1.0);
    canvas.translate(-image.width.toDouble(), 0);
    
    // Draw the flipped image
    canvas.drawImage(image, Offset.zero, Paint());
    
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(image.width, image.height);
  }

  static Future<ui.Image> _flipImageVertically(ui.Image image) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Scale vertically by -1 to flip
    canvas.scale(1.0, -1.0);
    canvas.translate(0, -image.height.toDouble());
    
    // Draw the flipped image
    canvas.drawImage(image, Offset.zero, Paint());
    
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(image.width, image.height);
  }

  static Future<ui.Image> _flipImageBoth(ui.Image image) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Scale both directions by -1 to flip both ways
    canvas.scale(-1.0, -1.0);
    canvas.translate(-image.width.toDouble(), -image.height.toDouble());
    
    // Draw the flipped image
    canvas.drawImage(image, Offset.zero, Paint());
    
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(image.width, image.height);
  }

  static Future<String> _saveImageToTemp(ui.Image image, String flipType) async {
    // Convert image to bytes
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }
    
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    
    // Get temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = 'flipped_${flipType}_$timestamp.png';
    final String filePath = path.join(tempDir.path, fileName);
    
    // Save file
    final File file = File(filePath);
    await file.writeAsBytes(pngBytes);
    
    if (kDebugMode) {
      print('Flipped image saved to: $filePath');
    }
    
    // Return file:// URI for Unity
    return 'file://$filePath';
  }

  // Clean up temporary files (call this when no longer needed)
  static Future<void> cleanupTempFiles() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();
      
      for (final file in files) {
        if (file.path.contains('flipped_') && file.path.endsWith('.png')) {
          await file.delete();
        }
      }
      
      if (kDebugMode) {
        print('Temporary flip files cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up temp files: $e');
      }
    }
  }
}