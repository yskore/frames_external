import 'package:flutter_riverpod/flutter_riverpod.dart';

//TODO: merge MessageProvider and ErrorProvider into one
enum MessageType {
  info,
  success,
}

class AppMessage {
  final String text;
  final MessageType type;

  AppMessage({required this.text, required this.type});
}

final messageProvider =
    StateNotifierProvider<MessageNotifier, AppMessage?>((ref) {
  return MessageNotifier();
});

class MessageNotifier extends StateNotifier<AppMessage?> {
  MessageNotifier() : super(null);

  void setInfo(String infoMessage) {
    state = AppMessage(text: infoMessage, type: MessageType.info);
  }

  void setSuccess(String successMessage) {
    state = AppMessage(text: successMessage, type: MessageType.success);
  }

  void clearMessage() {
    state = null;
  }
}

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
