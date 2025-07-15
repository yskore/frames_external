import 'package:flutter_bloc/flutter_bloc.dart';

class LoadingState {
  final bool isLoading;

  const LoadingState({this.isLoading = false});

  LoadingState copyWith({bool? isLoading}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoadingCubit extends Cubit<LoadingState> {
  static LoadingCubit? _instance;

  LoadingCubit._() : super(const LoadingState());

  static LoadingCubit get instance {
    _instance ??= LoadingCubit._();
    return _instance!;
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void startLoading() {
    emit(state.copyWith(isLoading: true));
  }

  void stopLoading() {
    emit(state.copyWith(isLoading: false));
  }
}
