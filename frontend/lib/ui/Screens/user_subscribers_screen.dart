import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/subscription_repository.dart';
import 'package:frames_app/models/subscription_model.dart';
import 'package:frames_app/ui/Screens/other_user_profile_screen.dart';

class UserSubscribersScreen extends ConsumerStatefulWidget {
  final String username;
  final String displayName;

  const UserSubscribersScreen({
    super.key,
    required this.username,
    required this.displayName,
  });

  @override
  ConsumerState<UserSubscribersScreen> createState() =>
      _UserSubscribersScreenState();
}

class _UserSubscribersScreenState extends ConsumerState<UserSubscribersScreen> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  List<UserSubscriptionModel> _subscribers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscribers();
  }

  Future<void> _loadSubscribers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response =
          await _repository.getSubscribersByUsername(widget.username);

      if (response.isSuccess && response.data != null) {
        final subscribersData = response.data!['subscribers'] as List<dynamic>;
        setState(() {
          _subscribers = subscribersData
              .map((json) => UserSubscriptionModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load subscribers';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.displayName}\'s Followers'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubscribers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_subscribers.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildSubscribersList();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "${widget.displayName} doesn't have any followers yet",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersList() {
    return RefreshIndicator(
      onRefresh: _loadSubscribers,
      child: ListView.builder(
        itemCount: _subscribers.length,
        itemBuilder: (context, index) {
          final user = _subscribers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                      ? NetworkImage(user.profilePhoto!)
                      : null,
              child: (user.profilePhoto == null || user.profilePhoto!.isEmpty)
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
