import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/other_user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/AR_core_view.dart';
import 'package:frames_app/ui/Widgets/menu_button.dart';
import 'package:frames_app/ui/Widgets/search_bar.dart';
import 'package:frames_app/ui/Widgets/take_picture.dart';
import 'package:frames_app/ui/Widgets/view_filter_toggle_bar.dart';
import 'package:frames_app/utils/debouncer.dart';

import 'frame_selection_for_piece.dart';

// Create a provider for user search results
final userSearchResultsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool showNewPieceUploadFrame = false;
  bool showSearchResults = false;
  final TextEditingController searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer();

  @override
  void dispose() {
    searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      ref.read(userSearchResultsProvider.notifier).state = [];
      return;
    }

    final response = await ref.read(userProvider.notifier).searchUsers(query);

    if (response.isSuccess && response.data != null) {
      final List<dynamic> users = response.data!['users'];
      ref.read(userSearchResultsProvider.notifier).state =
          users.map((user) => user as Map<String, dynamic>).toList();
    } else {
      ref.read(userSearchResultsProvider.notifier).state = [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: ${response.message}')),
      );
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
    final user = ref.watch(userProvider);
    final searchResults = ref.watch(userSearchResultsProvider);

    return GestureDetector(
      onTap: () {
        if (showNewPieceUploadFrame) {
          setState(() {
            showNewPieceUploadFrame = false;
          });
        }

        if (showSearchResults) {
          setState(() {
            showSearchResults = false;
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: showNewPieceUploadFrame
            ? _buildNewPieceUploadActions()
            : FloatingActionButton(
                onPressed: () {
                  setState(() {
                    showNewPieceUploadFrame = !showNewPieceUploadFrame;
                  });
                },
                child: const Icon(Icons.post_add),
              ),
        appBar: AppBar(
          centerTitle: true,
          leading: MenuButton(username: user?.username ?? 'User'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 180,
                child: SearchBarCustom(
                  controller: searchController,
                  onChanged: (query) {
                    setState(() {
                      showSearchResults = query.isNotEmpty;
                    });
                    _searchDebouncer.run(() {
                      searchUsers(query);
                    });
                  },
                  onSubmitted: (query) {
                    searchUsers(query);
                    setState(() {
                      showSearchResults = query.isNotEmpty;
                    });
                  },
                ),
              ),
            ),
          ],
          title: CameraButton(
            onPressed: () {},
          ),
        ),
        body: Stack(
          children: [
            const SafeArea(
              child: Column(
                children: [
                  ToggleBar(),
                  Expanded(
                    child: UnityARView(),
                  ),
                ],
              ),
            ),
            // Enhanced search results overlay
            if (showSearchResults)
              Positioned(
                top: 10,
                right: 8,
                width: 250,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.9),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Search Results',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const Divider(
                            color: Colors.white30, height: 1, thickness: 1),
                        Flexible(
                          child: searchResults.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off,
                                          color: Colors.white70, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'No users found',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = searchResults[index];
                                    return InkWell(
                                      onTap: () {
                                        navigateToUserProfile(user['username']);
                                        setState(() {
                                          showSearchResults = false;
                                          searchController.clear();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.9),
                                              child: Text(
                                                user['username'][0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user['username'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${user['firstName']} ${user['lastName']}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Column _buildNewPieceUploadActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: "createPiece",
          onPressed: () {
            setState(() {
              showNewPieceUploadFrame = false;
            });
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FrameSelectionForPiece(),
                ));
          },
          icon: const Icon(Icons.brush),
          label: const Text('Create Piece'),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: "addFrame",
          onPressed: () {
            setState(() {
              showNewPieceUploadFrame = false;
            });
          },
          icon: const Icon(Icons.filter_frames),
          label: const Text('Add Frame'),
        ),
      ],
    );
  }
}
