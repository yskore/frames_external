import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/subscription_repository.dart';
import 'package:frames_app/models/subscription_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';

// Provider for subscription repository
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

// Provider to check subscription status to a specific user
final isSubscribedProvider =
    FutureProvider.family<bool, String>((ref, username) async {
  final repository = ref.read(subscriptionRepositoryProvider);
  final response = await repository.isSubscribedToUser(username);

  if (response.isSuccess && response.data != null) {
    return response.data!['isSubscribed'] as bool;
  }
  return false;
});

// Provider for user's subscriptions (people they follow)
final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, List<UserSubscriptionModel>>(
        (ref) {
  final repository = ref.read(subscriptionRepositoryProvider);
  final loadingNotifier = ref.read(loadingProvider.notifier);
  final errorNotifier = ref.read(errorProvider.notifier);

  return SubscriptionsNotifier(repository, loadingNotifier, errorNotifier);
});

// Provider for user's subscribers (people who follow them)
final subscribersProvider =
    StateNotifierProvider<SubscribersNotifier, List<UserSubscriptionModel>>(
        (ref) {
  final repository = ref.read(subscriptionRepositoryProvider);
  final loadingNotifier = ref.read(loadingProvider.notifier);
  final errorNotifier = ref.read(errorProvider.notifier);

  return SubscribersNotifier(repository, loadingNotifier, errorNotifier);
});

class SubscriptionsNotifier extends StateNotifier<List<UserSubscriptionModel>> {
  final SubscriptionRepository _repository;
  final LoadingNotifier _loadingNotifier;
  final ErrorNotifier _errorNotifier;

  SubscriptionsNotifier(
      this._repository, this._loadingNotifier, this._errorNotifier)
      : super([]);

  Future<void> loadSubscriptions() async {
    try {
      _loadingNotifier.setLoading(true);

      _errorNotifier.clearError();

      final response = await _repository.getMySubscriptions();

      if (response.isSuccess && response.data != null) {
        final subscriptionsData =
            response.data!['subscriptions'] as List<dynamic>;
        state = subscriptionsData
            .map((json) => UserSubscriptionModel.fromJson(json))
            .toList();
      } else {
        _errorNotifier
            .setError(response.message ?? 'Failed to load subscriptions');
      }
    } catch (e) {
      _errorNotifier.setError('Error loading subscriptions: $e');
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> subscribeToUser(String username) async {
    try {
      // _loadingNotifier.setLoading(true);

      final response = await _repository.subscribeToUser(username);

      if (response.isSuccess) {
        // await loadSubscriptions();
        return true;
      } else {
        _errorNotifier.setError(response.message ?? 'Failed to follow user');
        return false;
      }
    } catch (e) {
      _errorNotifier.setError('Error following user: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> unsubscribeFromUser(String username) async {
    try {
      // _loadingNotifier.setLoading(true);

      final response = await _repository.unsubscribeFromUser(username);

      if (response.isSuccess) {
        state = state.where((user) => user.username != username).toList();
        return true;
      } else {
        _errorNotifier.setError(response.message ?? 'Failed to unfollow user');
        return false;
      }
    } catch (e) {
      _errorNotifier.setError('Error unfollowing user: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }
}

class SubscribersNotifier extends StateNotifier<List<UserSubscriptionModel>> {
  final SubscriptionRepository _repository;
  final LoadingNotifier _loadingNotifier;
  final ErrorNotifier _errorNotifier;

  SubscribersNotifier(
      this._repository, this._loadingNotifier, this._errorNotifier)
      : super([]);

  Future<void> loadSubscribers() async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _repository.getMySubscribers();

      if (response.isSuccess && response.data != null) {
        final subscribersData = response.data!['subscribers'] as List<dynamic>;
        state = subscribersData
            .map((json) => UserSubscriptionModel.fromJson(json))
            .toList();
      } else {
        _errorNotifier
            .setError(response.message ?? 'Failed to load subscribers');
      }
    } catch (e) {
      _errorNotifier.setError('Error loading subscribers: $e');
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }
}
