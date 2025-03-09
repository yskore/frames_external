import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImagePickerNotifier extends StateNotifier<File?> {
  ImagePickerNotifier() : super(null);

  void pickImage(File image) {
    state = image;
  }
}

final imagePickerProvider = StateNotifierProvider<ImagePickerNotifier, File?>((ref) {
  return ImagePickerNotifier();
});