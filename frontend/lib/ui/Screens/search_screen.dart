import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/providers/piece_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/other_user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/search_bar.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/utils/debouncer.dart';
import 'dart:convert';

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
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchDebouncer.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Clear search results when switching tabs
    ref.read(searchScreenResultsProvider.notifier).state = [];
    // Re-run search if there's text in the search bar
    if (searchController.text.isNotEmpty) {
      _searchDebouncer.run(() {
        if (_tabController.index == 0) {
          searchUsers(searchController.text);
        } else {
          searchPieces(searchController.text);
        }
      });
    }
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

  Future<void> searchPieces(String query) async {
    if (query.isEmpty) {
      ref.read(searchScreenResultsProvider.notifier).state = [];
      return;
    }

    setState(() {
      isSearching = true;
    });

    final response = await ref.read(pieceProvider.notifier).searchPieces(query);

    if (response.isSuccess && response.data != null) {
      final List<dynamic> pieces = response.data!['pieces'];
      ref.read(searchScreenResultsProvider.notifier).state =
          pieces.map((piece) => piece as Map<String, dynamic>).toList();
    } else {
      ref.read(searchScreenResultsProvider.notifier).state = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching pieces: ${response.message}')),
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

  void _showPiecePreview(BuildContext context, Map<String, dynamic> pieceData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Extract piece ID
      final pieceId = pieceData['id'];
      
      if (pieceId != null && pieceId.isNotEmpty) {
        // Get complete piece data from API
        final pieceDetails = await ref.read(pieceProvider.notifier).getPieceDetails(pieceId);
        
        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (pieceDetails != null && mounted) {
          final piece = Piece.fromJson(pieceDetails);
          
          String pieceDataJson = jsonEncode({
            'frameName': piece.frameName,
            'faceName': 'Face',
            'imageUrl': piece.pieceDisplay,
            'PieceID': piece.pieceid,
          });

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return PiecePreviewPopup(
                piece: piece,
                pieceData: pieceDataJson,
                onPieceUpdated: () {
                  // No action needed for read-only mode
                },
                isReadOnly: true,
              );
            },
          );
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not retrieve piece details'),
              ),
            );
          }
        }
      } else {
        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid piece ID'),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading piece: $e'),
          ),
        );
      }
    }
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
            Tab(text: 'Pieces'),
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
                  if (_tabController.index == 0) {
                    searchUsers(query);
                  } else {
                    searchPieces(query);
                  }
                });
              },
              onSubmitted: (query) {
                  if (_tabController.index == 0) {
                    searchUsers(query);
                  } else {
                    searchPieces(query);
                  }
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

                // Pieces tab
                _buildPiecesTab(searchResults),
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
              child: user['profilePhoto'] != null && user['profilePhoto'].isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user['profilePhoto'],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            user['username'][0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
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

  Widget _buildPiecesTab(List<Map<String, dynamic>> searchResults) {
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
              'Search for pieces',
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
              Icons.art_track_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pieces found',
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
        final piece = searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: piece['imageUrl'] != null && piece['imageUrl'].isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        piece['imageUrl'],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.art_track,
                            color: Theme.of(context).primaryColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.art_track,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            title: Text(piece['title'] ?? 'Untitled'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('by ${piece['owner'] ?? 'Unknown'}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${piece['likes'] ?? 0} likes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${piece['impressions'] ?? 0} views',
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
              _showPiecePreview(context, piece);
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        );
      },
    );
  }
}
