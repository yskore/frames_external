import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/mixins/loading_mixin.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/subscription_repository.dart';
import 'package:frames_app/models/subscription_model.dart';

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

  return SubscriptionsNotifier(repository);
});

// Provider for user's subscribers (people who follow them)
final subscribersProvider =
    StateNotifierProvider<SubscribersNotifier, List<UserSubscriptionModel>>(
        (ref) {
  final repository = ref.read(subscriptionRepositoryProvider);

  return SubscribersNotifier(repository);
});

class SubscriptionsNotifier extends StateNotifier<List<UserSubscriptionModel>>
    with LoadingMixin, MessageMixin {
  final SubscriptionRepository _repository;

  SubscriptionsNotifier(this._repository) : super([]);

  Future<void> loadSubscriptions() async {
    try {
      setLoading(true);
      clearError();

      final response = await _repository.getMySubscriptions();

      if (response.isSuccess && response.data != null) {
        final subscriptionsData =
            response.data!['subscriptions'] as List<dynamic>;
        state = subscriptionsData
            .map((json) => UserSubscriptionModel.fromJson(json))
            .toList();
      } else {
        showError(response.message ?? 'Failed to load subscriptions');
      }
    } catch (e) {
      showError('Error loading subscriptions: $e');
    } finally {
      setLoading(false);
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
        showError(response.message ?? 'Failed to follow user');
        return false;
      }
    } catch (e) {
      showError('Error following user: $e');
      return false;
    } finally {
      setLoading(false);
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
        showError(response.message ?? 'Failed to unfollow user');
        return false;
      }
    } catch (e) {
      showError('Error unfollowing user: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}

class SubscribersNotifier extends StateNotifier<List<UserSubscriptionModel>>
    with LoadingMixin, MessageMixin {
  final SubscriptionRepository _repository;

  SubscribersNotifier(this._repository) : super([]);

  Future<void> loadSubscribers() async {
    try {
      setLoading(true);
      clearError();

      final response = await _repository.getMySubscribers();

      if (response.isSuccess && response.data != null) {
        final subscribersData = response.data!['subscribers'] as List<dynamic>;
        state = subscribersData
            .map((json) => UserSubscriptionModel.fromJson(json))
            .toList();
      } else {
        showError(response.message ?? 'Failed to load subscribers');
      }
    } catch (e) {
      showError('Error loading subscribers: $e');
    } finally {
      setLoading(false);
    }
  }
}
