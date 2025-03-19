import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/profile_repository.dart';
import 'package:frames_app/core/services/email_service.dart';
import 'package:frames_app/core/services/storage_service.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/models/user_profile_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';

import '../core/repositories/user_repository.dart';
import '../models/user_model.dart';

const kBucketName = 'x-fabric-419423.appspot.com';
const kFolderName = 'profile_pictures';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final userRepository = ref.read(userRepositoryProvider);
  final profileRepository = ref.read(profileRepositoryProvider);
  final loadingNotifier = ref.read(loadingProvider.notifier);
  final errorNotifier = ref.read(errorProvider.notifier);

  return UserNotifier(
      userRepository, profileRepository, loadingNotifier, errorNotifier);
});

final userProfileProvider = Provider<UserProfileModel?>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  return ref.read(userNotifierProvider).cachedUserProfile;
});

final userNotifierProvider = Provider<UserNotifier>((ref) {
  return ref.watch(userProvider.notifier);
});

class UserNotifier extends StateNotifier<UserModel?> {
  final UserRepository _userRepository;
  final ProfileRepository _profileRepository;
  final LoadingNotifier _loadingNotifier;
  final ErrorNotifier _errorNotifier;

  // User profile related data
  UserProfileModel? cachedUserProfile;

  UserNotifier(this._userRepository, this._profileRepository,
      this._loadingNotifier, this._errorNotifier)
      : super(null);

  Future<bool> login(String username, String password) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      final response = await _userRepository.login(username, password);

      if (response.isSuccess) {
        return await getUserProfile(username);
      }
      _errorNotifier.setError(response.message);
      return false;
    } catch (e) {
      _errorNotifier.setError('Failed to login: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> getUserProfile(String username) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      final response = await _userRepository.getUserProfile(username);

      if (response.isSuccess && response.data != null) {
        final userData = response.data!['user'];
        if (userData != null) {
          state = UserModel.fromJson(userData);

          return await _fetchProfileDetails(username);
        } else {
          _errorNotifier.setError('User data not found in response');
          return false;
        }
      }
      _errorNotifier.setError(response.message);
      return false;
    } catch (e) {
      _errorNotifier.setError('Failed to get user profile: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> _fetchProfileDetails(String username,
      {bool showLoading = true}) async {
    try {
      if (showLoading) {
        _loadingNotifier.setLoading(true);
      }

      final response = await _profileRepository.getUserProfile(username);

      if (response.isSuccess && response.data != null) {
        try {
          cachedUserProfile =
              UserProfileModel.fromJson(response.data!['profile']);

          await Future.wait([
            _loadFollowerCount(username),
            _loadFollowingCount(username),
            _loadPieceCount(username),
            _loadPieces(username),
            _loadAnchors(username),
          ]);
          return true;
        } catch (e) {
          _errorNotifier.setError(e.toString());
          return false;
        }
      }

      _errorNotifier.setError(response.message);
      return false;
    } catch (e) {
      _errorNotifier.setError('Failed to load profile details: $e');
      return false;
    } finally {
      if (showLoading) {
        _loadingNotifier.setLoading(false);
      }
    }
  }

  Future<void> _loadFollowerCount(String username) async {
    try {
      final response = await _profileRepository.getFollowerCount(username);
      if (response.isSuccess && response.data != null) {
        final count = response.data!['followerCount'] ?? 0;
        if (cachedUserProfile != null) {
          cachedUserProfile = cachedUserProfile!.copyWith(followerCount: count);
        }
        return;
      }
      throw response.message ?? 'Failed to load follower count';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadFollowingCount(String username) async {
    try {
      final response = await _profileRepository.getFollowingCount(username);
      if (response.isSuccess && response.data != null) {
        final count = response.data!['followingCount'] ?? 0;
        if (cachedUserProfile != null) {
          cachedUserProfile =
              cachedUserProfile!.copyWith(followingCount: count);
        }
        return;
      }
      throw response.message ?? 'Failed to load following count';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadPieceCount(String username) async {
    try {
      final response = await _profileRepository.getPieceCount(username);
      if (response.isSuccess && response.data != null) {
        final count = response.data!['pieceCount'] ?? 0;
        if (cachedUserProfile != null) {
          cachedUserProfile = cachedUserProfile!.copyWith(pieceCount: count);
        }
        return;
      }
      throw response.message ?? 'Failed to load piece count';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadPieces(String username) async {
    try {
      final response = await _profileRepository.getPiecesByOwner(username);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> piecesData = response.data!['pieces'] ?? [];
        final pieces = piecesData.map((json) => Piece.fromJson(json)).toList();
        if (cachedUserProfile != null) {
          cachedUserProfile = cachedUserProfile!.copyWith(pieces: pieces);
        }
        return;
      }
      throw response.message ?? 'Failed to fetch pieces';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadAnchors(String username) async {
    try {
      final response = await _profileRepository.getAnchorsByOwner(username);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> anchorsData = response.data!['anchors'] ?? [];
        final anchors =
            anchorsData.map((json) => AnchorModel.fromJson(json)).toList();
        if (cachedUserProfile != null) {
          cachedUserProfile = cachedUserProfile!.copyWith(anchors: anchors);
        }
        return;
      }
      throw response.message ?? 'Failed to load anchors';
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signup(Map<String, dynamic> userData) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      final response = await _userRepository.signup(userData);

      if (response.isSuccess) {
        if (await login(userData['username'], userData['password'])) {
          return createUserProfile(userData['username']);
        }
      }
      _errorNotifier.setError(response.message);
      return false;
    } catch (e) {
      _errorNotifier.setError('Failed to sign up: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> createUserProfile(String username) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _profileRepository.createUserProfile(username);

      if (response.isSuccess) {
        return true;
      }

      _errorNotifier.setError(response.message ?? 'Failed to create profile');
      return false;
    } catch (e) {
      _errorNotifier.setError('Failed to create user profile: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> updateUserProfile(
      String username, String bio, File? profileImage) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      String? imageUrl;

      if (profileImage != null) {
        imageUrl = await StorageService()
            .uploadImage(profileImage, kBucketName, kFolderName);
      }

      final response = await _profileRepository.updateUserProfile(
          username, bio, imageUrl ?? "");

      if (response.isSuccess) {
        await refreshUserData();
        return true;
      }

      _errorNotifier.setError(response.message ?? 'Failed to update profile');
      return false;
    } catch (e) {
      _errorNotifier.setError('Failed to update profile: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<String?> checkUserExistSendOTp(String username, String email) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _userRepository.userExists(username, email);

      if (!response.isSuccess) {
        _errorNotifier.setError(response.message);
        return null;
      }

      return sendVerificationCode(email.toLowerCase());
    } catch (e) {
      _errorNotifier.setError('Error: $e');
      return null;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<String?> sendVerificationCode(String email) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      final OTP = EmailService().generateOTP;
      final sendOTPRes =
          await EmailService().sendVerificationCode(email.toLowerCase(), OTP);

      if (!sendOTPRes.isSuccess) {
        _errorNotifier.setError(sendOTPRes.message);
        return null;
      }

      return OTP;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  // Helper method to refresh all user data
  Future<void> refreshUserData({bool showLoading = true}) async {
    if (state == null) return;
    await _fetchProfileDetails(state!.username, showLoading: showLoading);
  }

  Future<void> refreshUserPieces() async {
    if (state == null) return;
    await _fetchProfileDetails(state!.username, showLoading: false);
  }

  Future<void> logout() async {
    await _userRepository.logout();
    cachedUserProfile = null;
    state = null;
  }
}
