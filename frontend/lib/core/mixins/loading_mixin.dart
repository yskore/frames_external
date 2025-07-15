import 'package:frames_app/core/cubits/loading_cubit.dart';

mixin LoadingMixin {
  LoadingCubit get loadingCubit => LoadingCubit.instance;

  void setLoading(bool isLoading) => loadingCubit.setLoading(isLoading);
  void startLoading() => loadingCubit.startLoading();
  void stopLoading() => loadingCubit.stopLoading();
  bool get isLoading => loadingCubit.state.isLoading;
}
