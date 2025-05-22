import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/subscription_model.dart';
import 'package:frames_app/providers/loading_provider.dart';
import 'package:frames_app/providers/subscription_provider.dart';
import 'package:frames_app/ui/Screens/other_user_profile_screen.dart';

class SubscribersScreen extends ConsumerStatefulWidget {
  const SubscribersScreen({super.key});

  @override
  ConsumerState<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends ConsumerState<SubscribersScreen> {
  @override
  void initState() {
    super.initState();

    // Load subscribers when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscribersProvider.notifier).loadSubscribers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscribers = ref.watch(subscribersProvider);
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People Following You'),
      ),
      body: isLoading
          ? const SizedBox.shrink()
          : subscribers.isEmpty
              ? _buildEmptyState()
              : _buildSubscribersList(subscribers),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "You don't have any followers yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "When people follow you, they'll appear here.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersList(List<UserSubscriptionModel> subscribers) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(subscribersProvider.notifier).loadSubscribers();
      },
      child: ListView.builder(
        itemCount: subscribers.length,
        itemBuilder: (context, index) {
          final user = subscribers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePhoto != null
                  ? NetworkImage(user.profilePhoto!)
                  : null,
              child: user.profilePhoto == null
                  ? Text(user.firstName.isNotEmpty && user.lastName.isNotEmpty
                      ? user.firstName[0] + user.lastName[0]
                      : user.username[0])
                  : null,
            ),
            title:
                Text(user.fullName.isNotEmpty ? user.fullName : user.username),
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
          );
        },
      ),
    );
  }
}
