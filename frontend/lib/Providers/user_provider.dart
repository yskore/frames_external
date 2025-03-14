import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';

import '../core/repositories/user_repository.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final userRepository = ref.read(userRepositoryProvider);
  final loadingNotifier = ref.read(loadingProvider.notifier);
  final errorNotifier = ref.read(errorProvider.notifier);

  return UserNotifier(userRepository, loadingNotifier, errorNotifier);
});

class UserNotifier extends StateNotifier<UserModel?> {
  final UserRepository _userRepository;
  final LoadingNotifier _loadingNotifier;
  final ErrorNotifier _errorNotifier;

  UserNotifier(this._userRepository, this._loadingNotifier, this._errorNotifier)
      : super(null);

  Future<bool> login(String username, String password) async {
    try {
      print('Starting login process for user: $username');
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      final response = await _userRepository.login(username, password);
      print(
          'Login response: ${response.isSuccess}, message: ${response.message}');

      if (response.isSuccess) {
        return await getUserProfile(username);
      }
      _errorNotifier.setError(response.message);
      print('Login failed: ${response.message}');
      return false;
    } catch (e) {
      print('Login exception: $e');
      _errorNotifier.setError('Failed to login: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> getUserProfile(String username) async {
    try {
      print('Fetching user profile for: $username');
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      final response = await _userRepository.getUserProfile(username);
      print('Profile response: ${response.isSuccess}, data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final userData = response.data!;
        state = UserModel.fromJson(userData);
        print('Profile successfully loaded');
        return true;
      }
      print('Failed to load profile: no data or unsuccessful response');
      return false;
    } catch (e) {
      print('Profile fetch exception: $e');
      _errorNotifier.setError('Failed to get user profile: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<void> logout() async {
    await _userRepository.logout();
    state = null;
  }
}
