import 'package:riverpod/riverpod.dart';

final unitySceneProvider = StateNotifierProvider<UnitySceneNotifier, String>((ref) {
  return UnitySceneNotifier();
});

class UnitySceneNotifier extends StateNotifier<String> {
  UnitySceneNotifier() : super('frames_ar');

  void setScene(String sceneName) {
    state = sceneName;
  }
}