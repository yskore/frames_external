import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/models/user_profile_model.dart';
import 'package:frames_app/Providers/user_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const OtherUserProfileScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  bool _isLoading = true;
  UserProfileModel? _userProfile;
  List<Piece>? _pieces;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    
    // Set Unity scene to preview mode when entering profile screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        sceneManager.loadScene(UnitySceneType.previewScene);
      }
    });
  }

  Future<void> _loadProfileData() async {
    try {
      final userNotifier = ref.read(userProvider.notifier);
      final response = await userNotifier.getProfileWithPieces(widget.username);

      log(response.toString());
      log('Response: ${response.message}');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userProfile = UserProfileModel.fromJson(response.data!['profile']);
          _pieces = (response.data!['pieces'] as List)
              .map((piece) => Piece.fromJson(piece))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load user profile';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      log('Error loading profile data: $e $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Method to navigate back to home with scene switching
  void _navigateBackToHome() {
    // Pre-load AR scene before navigation
    final sceneManager = ref.read(unitySceneManagerProvider);
    if (sceneManager.isUnityInitialized) {
      // Set the scene back to AR mode first
      sceneManager.loadScene(UnitySceneType.arScene).then((_) {
        // Then navigate back to home once the scene is loaded
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
            settings: const RouteSettings(name: 'HomeScreen'),
          ),
        );
      });
    } else {
      // If Unity isn't initialized, just navigate normally
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: const RouteSettings(name: 'HomeScreen'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle back button press to ensure scene switching
      onWillPop: () async {
        _navigateBackToHome();
        return false; // We're handling navigation manually
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.username),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBackToHome, // Use custom navigation method
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile: $_errorMessage',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateBackToHome, // Use custom navigation method
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            _buildProfileInfoRow(context, _userProfile!),
            const Divider(),
            Expanded(
              child: _buildGalleryView(context, ref, _pieces!),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfileInfoRow(
      BuildContext context, UserProfileModel userProfile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: userProfile.Profile_photo.isNotEmpty
                ? NetworkImage(userProfile.Profile_photo)
                : const NetworkImage('https://dummyimage.com/250/ffffff'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(userProfile.bio),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCountColumn(
                        'Followers', userProfile.followerCount.toString()),
                    _buildCountColumn(
                        'Following', userProfile.followingCount.toString()),
                    _buildCountColumn(
                        'Live Pieces', userProfile.live_pieces.toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGalleryView(
      BuildContext context, WidgetRef ref, List<Piece> pieces) {
    if (pieces.isEmpty) {
      return const Center(child: Text('No pieces available'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        return _buildPieceItem(context, ref, pieces[index]);
      },
    );
  }

  Widget _buildPieceItem(BuildContext context, WidgetRef ref, Piece piece) {
    return GestureDetector(
      onTap: () => _showPiecePreview(context, piece),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              piece.pieceDisplay ?? 'https://dummyimage.com/250/ffffff',
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2.0,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      piece.liveStatus ? 'Live' : 'Draft',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: piece.liveStatus ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPiecePreview(BuildContext context, Piece piece) {
    String pieceData = jsonEncode({
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
          pieceData: pieceData,
          onPieceUpdated: () {
            // Handle piece update if needed
          },
          isReadOnly:
              true,  // Set to read-only since it's not the current user's profile
        );
      },
    );
  }
}