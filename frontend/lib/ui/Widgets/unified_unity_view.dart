import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';

/// A unified widget for displaying Unity content in the app.
/// 
/// This widget handles all interactions with Unity and provides a consistent interface
/// for loading scenes and handling messages.
class UnifiedUnityView extends ConsumerStatefulWidget {
  /// The initial scene to load when the widget is created
  final UnitySceneType initialScene;
  
  /// Callback for handling Unity messages
  final Function(String)? onUnityMessage;
  
  /// Callback for when a scene is loaded
  final Function(SceneLoaded?)? onUnitySceneLoaded;
  
  /// Whether to show debug information
  final bool showDebugInfo;

  const UnifiedUnityView({
    Key? key,
    required this.initialScene,
    this.onUnityMessage,
    this.onUnitySceneLoaded,
    this.showDebugInfo = false,
  }) : super(key: key);

   @override
  ConsumerState<UnifiedUnityView> createState() => _UnifiedUnityViewState();
}

class _UnifiedUnityViewState extends ConsumerState<UnifiedUnityView> {
  bool _isLoading = true;
  String _lastMessage = "";
  String _lastSceneName = "";
  bool _isDisposed = false;
  
  @override
  void dispose() {
    // Mark as disposed but don't actually dispose the controller here
    _isDisposed = true;
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main Unity widget
        Positioned.fill(
          child: UnityWidget(
            onUnityCreated: _handleUnityCreated,
            onUnityMessage: _handleUnityMessage,
            onUnitySceneLoaded: _handleUnitySceneLoaded,
            fullscreen: false,
            useAndroidViewSurface: true,
            // Add gesture recognizers to improve interaction
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            },
          ),
        ),
        
        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          
        // Debug info overlay (optional)
        if (widget.showDebugInfo)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Last Scene: $_lastSceneName",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    "Last Msg: $_lastMessage",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  void _handleUnityCreated(UnityWidgetController controller) {
    if (_isDisposed) return;
    
    final sceneManager = ref.read(unitySceneManagerProvider);
    
    // Set the controller in the scene manager
    sceneManager.setController(controller);
    
    // Load the initial scene
    sceneManager.loadScene(widget.initialScene).then((success) {
      if (_isDisposed) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (!success) {
        print('Failed to load initial scene: ${widget.initialScene.sceneName}');
      }
    });
  }
  void _handleUnityMessage(message) {
    final messageStr = message.toString();
    
    // Update debug info
    if (widget.showDebugInfo) {
      setState(() {
        _lastMessage = messageStr;
      });
    }
    
    // Pass the message to the callback if provided
    if (widget.onUnityMessage != null) {
      widget.onUnityMessage!(messageStr);
    }
    
    // If the message indicates AR initialization is complete, stop loading
    if (messageStr == 'AR_COMPONENTS_INITIALIZED' ||
        messageStr == 'SCENE_SWITCHED' ||
        messageStr.contains('_LOADED')) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _handleUnitySceneLoaded(SceneLoaded? sceneInfo) {
    if (sceneInfo != null && widget.showDebugInfo) {
      setState(() {
        _lastSceneName = sceneInfo.name!;
      });
    }
    
    // Pass the scene info to the callback if provided
    if (widget.onUnitySceneLoaded != null) {
      widget.onUnitySceneLoaded!(sceneInfo);
    }
  }
}