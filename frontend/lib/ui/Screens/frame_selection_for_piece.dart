import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/frame_model.dart';
import 'package:frames_app/providers/piece_provider.dart';
import 'package:frames_app/ui/Screens/frame_preview_screen.dart';
import 'package:image_picker/image_picker.dart';

class FrameSelectionForPiece extends ConsumerStatefulWidget {
  const FrameSelectionForPiece({super.key});

  @override
  _FrameSelectionForPieceState createState() => _FrameSelectionForPieceState();
}

class _FrameSelectionForPieceState
    extends ConsumerState<FrameSelectionForPiece> {
  List<Frame> filteredFrames = [];
  TextEditingController searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      Future.microtask(() => _fetchFrames());
      _isInitialized = true;
    }
  }

  Future<void> _fetchFrames() async {
    await ref.read(pieceProvider.notifier).fetchFrames();
  }

  void filterSearchResults(String query) {
    final frames = ref.read(framesProvider);

    if (query.isNotEmpty) {
      List<Frame> dummyListData = [];
      for (var frame in frames) {
        if (frame.frameTitle.toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(frame);
        }
      }
      setState(() {
        filteredFrames = dummyListData;
      });
    } else {
      setState(() {
        filteredFrames = frames;
      });
    }
  }

  String getFaceName(String title) {
    final frames = ref.read(framesProvider);
    for (var frame in frames) {
      if (frame.frameTitle == title) {
        return frame.faceName;
      }
    }
    return "Face"; // Default face name
  }

  @override
  Widget build(BuildContext context) {
    final frames = ref.watch(framesProvider);

    // Initialize filteredFrames if empty
    if (filteredFrames.isEmpty && frames.isNotEmpty) {
      filteredFrames = frames;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Frame'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: filterSearchResults,
              decoration: const InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredFrames.length,
              itemBuilder: (context, index) {
                final frame = filteredFrames[index];
                return FrameItem(
                  imageUrl: frame.frameDisplay,
                  title: frame.frameTitle,
                  description: frame.frameDescription,
                  faceName: frame.faceName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FrameItem extends ConsumerWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String faceName;

  const FrameItem({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.faceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (!context.mounted) return;

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext bottomSheetContext) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: Text(
                              'Create with $title',
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle:
                                const Text('Select an image from your gallery'),
                            onTap: () async {
                              Navigator.pop(bottomSheetContext);

                              // Show loading indicator
                              bool isLoading = true;
                              if (!context.mounted) return;

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext dialogContext) {
                                  return StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return AlertDialog(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            if (isLoading) ...[
                                              const CircularProgressIndicator(),
                                              const SizedBox(height: 16),
                                              const Text('Processing image...'),
                                            ] else
                                              const Text(
                                                  'Image uploaded successfully!'),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );

                              try {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );

                                if (pickedFile != null && context.mounted) {
                                  final pieceNotifier =
                                      ref.read(pieceProvider.notifier);
                                  final res = await pieceNotifier
                                      .uploadPieceImage(File(pickedFile.path));

                                  // Dismiss loading dialog
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  if (res == null || !context.mounted) return;

                                  // Navigate to the FramePreviewScreen
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FramePreviewScreen(
                                          frameName: title,
                                          faceName: faceName,
                                          imageUrl: res,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  // User canceled image selection
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              } catch (e) {
                                // Handle any errors
                                if (context.mounted) {
                                  Navigator.pop(
                                      context); // Dismiss loading dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.cancel),
                            title: const Text('Cancel'),
                            onTap: () {
                              Navigator.pop(bottomSheetContext);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                );
              },
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
