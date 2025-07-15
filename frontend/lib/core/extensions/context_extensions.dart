import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frames_app/core/cubits/loading_cubit.dart';
import 'package:frames_app/core/cubits/message_cubit.dart';

extension ContextExtensions on BuildContext {
  MessageCubit get messageCubit => read<MessageCubit>();
  LoadingCubit get loadingCubit => read<LoadingCubit>();

  // Message methods
  void showError(String message) => messageCubit.setError(message);
  void showSuccess(String message) => messageCubit.setSuccess(message);
  void showInfo(String message) => messageCubit.setInfo(message);
  void clearMessages() => messageCubit.clearAll();

  // Loading methods
  void setLoading(bool isLoading) => loadingCubit.setLoading(isLoading);
  void startLoading() => loadingCubit.startLoading();
  void stopLoading() => loadingCubit.stopLoading();
  bool get isLoading => loadingCubit.state.isLoading;
}
