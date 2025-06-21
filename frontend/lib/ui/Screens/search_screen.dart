import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/other_user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/search_bar.dart';
import 'package:frames_app/utils/debouncer.dart';

// Provider for search results
final searchScreenResultsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(duration: const Duration(milliseconds: 300));
  late TabController _tabController;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchDebouncer.dispose();
    _tabController.dispose();
    super.dispose();
  }
  void _navigateBackToHome() {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const HomeScreen()),
  );
}

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      ref.read(searchScreenResultsProvider.notifier).state = [];
      return;
    }

    setState(() {
      isSearching = true;
    });

    final response = await ref.read(userProvider.notifier).searchUsers(query);

    if (response.isSuccess && response.data != null) {
      final List<dynamic> users = response.data!['users'];
      ref.read(searchScreenResultsProvider.notifier).state =
          users.map((user) => user as Map<String, dynamic>).toList();
    } else {
      ref.read(searchScreenResultsProvider.notifier).state = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: ${response.message}')),
        );
      }
    }

    if (mounted) {
      setState(() {
        isSearching = false;
      });
    }
  }

  void navigateToUserProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchScreenResultsProvider);

    return PopScope(
    canPop: false,
    onPopInvoked: (didPop) {
      if (didPop) return;
      _navigateBackToHome();
    },
    child:Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Map'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarCustom(
              controller: searchController,
              onChanged: (query) {
                _searchDebouncer.run(() {
                  searchUsers(query);
                });
              },
              onSubmitted: (query) {
                searchUsers(query);
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Users tab
                _buildUsersTab(searchResults),

                // Map tab (empty for now)
                const Center(
                  child: Text('Map view coming soon'),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildUsersTab(List<Map<String, dynamic>> searchResults) {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                user['username'][0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(user['username']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${user['subscriberCount'] ?? 0} subscribers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.art_track, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${user['livePiecesCount'] ?? 0} live pieces',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              navigateToUserProfile(user['username']);
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        );
      },
    );
  }
}
