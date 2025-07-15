import 'package:frames_app/core/cubits/message_cubit.dart';

mixin MessageMixin {
  MessageCubit get messageCubit => MessageCubit.instance;

  void showError(String? message) => messageCubit.setError(message);
  void showSuccess(String message) => messageCubit.setSuccess(message);
  void showInfo(String message) => messageCubit.setInfo(message);
  void clearMessages() => messageCubit.clearAll();
  void clearError() => messageCubit.clearError();
}
