import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/subscription_model.dart';
import 'package:frames_app/providers/loading_provider.dart';
import 'package:frames_app/providers/subscription_provider.dart';
import 'package:frames_app/ui/Screens/other_user_profile_screen.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionsProvider.notifier).loadSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Subscriptions'),
      ),
      body: isLoading
          ? const SizedBox.shrink()
          : subscriptions.isEmpty
              ? _buildEmptyState()
              : _buildSubscriptionsList(subscriptions),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "You aren't subscribed to anyone yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "When you subscribe to people, they'll appear here.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              //TODO: navigae to the sereach screen
            },
            child: const Text('Find People to Subscribe'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList(List<UserSubscriptionModel> subscriptions) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(subscriptionsProvider.notifier).loadSubscriptions();
      },
      child: ListView.builder(
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final user = subscriptions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePhoto != null
                  ? NetworkImage(user.profilePhoto!)
                  : null,
              child: user.profilePhoto == null
                  ? Text(user.firstName[0] + user.lastName[0])
                  : null,
            ),
            title: Text(user.fullName),
            subtitle: Text('@${user.username}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OtherUserProfileScreen(
                    username: user.username,
                  ),
                ),
              );
            },
            trailing: TextButton(
              onPressed: () async {
                await ref
                    .read(subscriptionsProvider.notifier)
                    .unsubscribeFromUser(user.username);
              },
              child: const Text('Unfollow'),
            ),
          );
        },
      ),
    );
  }
}
