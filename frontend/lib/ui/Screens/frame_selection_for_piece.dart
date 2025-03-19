import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/ui/Screens/frame_preview_screen.dart';
import 'package:frames_app/models/frame_model.dart';
import 'package:frames_app/providers/piece_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchFrames();
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
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext bottomSheetContext) {
                    return Container(
                      height: 60,
                      color: Colors.white,
                      child: Center(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(
                                bottomSheetContext); // Close the bottom sheet
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (pickedFile != null) {
                              final pieceNotifier =
                                  ref.read(pieceProvider.notifier);

                              final res = await pieceNotifier
                                  .uploadPieceImage(File(pickedFile.path));
                              if (res == null || !context.mounted) return;

                              // Navigate to the FramePreviewScreen
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FramePreviewScreen(
                                      frameName: title,
                                      faceName: faceName,
                                      imageUrl: res,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Create with $title',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
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
