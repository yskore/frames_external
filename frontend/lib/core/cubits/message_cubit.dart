import 'package:flutter_bloc/flutter_bloc.dart';

enum MessageType {
  info,
  success,
  error,
}

class AppMessage {
  final String text;
  final MessageType type;

  AppMessage({required this.text, required this.type});
}

class MessageState {
  final AppMessage? message;
  final String? error;

  const MessageState({this.message, this.error});

  MessageState copyWith({
    AppMessage? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return MessageState(
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MessageCubit extends Cubit<MessageState> {
  static MessageCubit? _instance;

  MessageCubit._() : super(const MessageState());

  static MessageCubit get instance {
    _instance ??= MessageCubit._();
    return _instance!;
  }

  void setInfo(String infoMessage) {
    emit(state.copyWith(
      message: AppMessage(text: infoMessage, type: MessageType.info),
    ));
  }

  void setSuccess(String successMessage) {
    emit(state.copyWith(
      message: AppMessage(text: successMessage, type: MessageType.success),
    ));
  }

  void setError(String? errorMessage) {
    if (errorMessage != null) {
      print(errorMessage);
    }
    emit(state.copyWith(error: errorMessage));
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true, clearError: true));
  }

  void clearError() {
    emit(state.copyWith(clearError: true, clearMessage: true));
  }

  void clearAll() {
    emit(state.copyWith(clearMessage: true, clearError: true));
  }
}
