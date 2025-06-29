// piece_unity_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/user_provider.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/ui/Widgets/unified_unity_view.dart';

class PieceUnityViewer extends ConsumerStatefulWidget {
  final String pieceData;
  final bool isFullScreen;
  final Function(String) onUnityMessage;
  final Function(String) onErrorMessage;
  final bool isLoading;
  final Piece? piece; // NEW: Optional piece parameter for hidden logic
  final bool forceShow; // NEW: Override hidden logic (for owners)

  const PieceUnityViewer({
    super.key,
    required this.pieceData,
    required this.isFullScreen,
    required this.onUnityMessage,
    required this.onErrorMessage,
    this.isLoading = true,
    this.piece,
    this.forceShow = false, 
  }) ;

  @override
  ConsumerState<PieceUnityViewer> createState() => _PieceUnityViewerState();
}

class _PieceUnityViewerState extends ConsumerState<PieceUnityViewer> {
  bool _isSceneReady = false;
  bool isTextureCompleted = false;
  bool _isWaitingForCorrectScene = false;
  bool _isLoading = true;
  String _errorMessage = '';

  
 bool _shouldShowUnityView() {
    // If forceShow is true (for owners), always show
    if (widget.forceShow) return true;
    
    // If no piece data, show Unity view (backward compatibility)
    if (widget.piece == null) return true;
    
    // Check ownership
    final currentUser = ref.watch(userProvider)?.username;
    final isOwner = currentUser != null && currentUser == widget.piece!.pieceOwner;
    
    // Show Unity view if user owns the piece or piece is not hidden
    return isOwner || !widget.piece!.isHidden;
  }

  void _handleLocalUnityMessage(String message) {
    widget.onUnityMessage(message);

    print('Received message from Unity: $message');

    switch (message.toString()) {
      case 'TEXTURE_LOADING_STARTED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_STARTED');
        break;
      case 'TEXTURE_LOADING_COMPLETED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_COMPLETED');
        setState(() {
          isTextureCompleted = true;
          _isLoading = false;
        });
        break;
      case 'TEXTURE_LOADING_FAILED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_FAILED');
        setErrorMessage('Failed to load texture');
        break;
      default:
        if (message.toString().startsWith('ACTIVE_SCENE:')) {
          String activeScene = message.toString().split(':')[1];
          if (activeScene == 'frames_test') {
            setState(() {
              _isWaitingForCorrectScene = false;
              _isSceneReady = true;
              _isLoading = false;
            });
            print('Current scene loaded: $activeScene');
            
            // Send piece data after scene is loaded
            _sendPieceDataToUnity();
          } else {
            print('Wrong scene loaded: $activeScene - switching to frames_test');
            _switchToFramesTestScene();
          }
        } else if (message == 'SCENE_SWITCHED') {
          setState(() {
            _isWaitingForCorrectScene = false;
            _isSceneReady = true;
            _isLoading = false;
          });
          print('Scene switched to frames_test');
          
          // Send piece data after scene is switched
          _sendPieceDataToUnity();
        }
        break;
    }
  }
void setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    print('Error: $message');
  }

  void _switchToFramesTestScene() {
    final sceneManager = ref.read(unitySceneManagerProvider);
    
    if (sceneManager.isUnityInitialized) {
      sceneManager.loadScene(UnitySceneType.previewScene);
      print('_switchToFramesTestScene called using SceneManager');
    }
  }

  void _sendPieceDataToUnity() {
    try {
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        final controller = sceneManager.getController();
        if (controller != null) {
          print('[LOGS] Sending piece data to Unity from PieceUnityViewer');
          controller.postMessage(
            'GameManager',
            'ReceiveDataFromFlutter',
            widget.pieceData,
          );
        }
      }
    } catch (e) {
      widget.onErrorMessage('Error sending data to Unity: $e');
    }
  }

 @override
Widget build(BuildContext context) {
  // Check if Unity view should be shown
  if (!_shouldShowUnityView()) {
    return SizedBox(
      height: widget.isFullScreen
          ? MediaQuery.of(context).size.height * 0.7
          : MediaQuery.of(context).size.height * 0.3,
      width: widget.isFullScreen
          ? MediaQuery.of(context).size.width * 0.95
          : double.infinity,
      child: _buildHiddenMessage(),
    );
  }

  return SizedBox(
    height: widget.isFullScreen
        ? MediaQuery.of(context).size.height * 0.7
        : MediaQuery.of(context).size.height * 0.3,
    width: widget.isFullScreen
        ? MediaQuery.of(context).size.width * 0.95
        : double.infinity,
    child: Stack(
      children: [
        // Always show the UnifiedUnityView
        Positioned.fill(
          child: UnifiedUnityView(
            initialScene: UnitySceneType.previewScene,
            onUnityMessage: _handleLocalUnityMessage,
            onUnitySceneLoaded: (sceneInfo) {
              if (sceneInfo?.name == UnitySceneType.previewScene.sceneName) {
                setState(() {
                  _isSceneReady = true;
                });
                _sendPieceDataToUnity();
              }
            },
          ),
        ),
        
        // Loading overlay
        if ( !isTextureCompleted) //widget.isLoading || !_isSceneReady ||
          Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildHiddenMessage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 48,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Hidden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'View in AR mode only',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


}