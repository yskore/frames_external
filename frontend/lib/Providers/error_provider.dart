import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorProvider = StateNotifierProvider<ErrorNotifier, String?>((ref) {
  return ErrorNotifier();
});

class ErrorNotifier extends StateNotifier<String?> {
  ErrorNotifier() : super(null);

  void setError(String? errorMessage) {
    state = errorMessage;
  }

  void clearError() {
    state = null;
  }
}
