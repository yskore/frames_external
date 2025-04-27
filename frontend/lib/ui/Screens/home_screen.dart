import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Widgets/AR_core_view.dart';
import 'package:frames_app/ui/Widgets/menu_button.dart';
import 'package:frames_app/ui/Widgets/search_bar.dart';
import 'package:frames_app/ui/Widgets/take_picture.dart';
import 'package:frames_app/ui/Widgets/view_filter_toggle_bar.dart';

import 'frame_selection_for_piece.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool showNewPieceUploadFrame = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return GestureDetector(
      onTap: () {
        if (showNewPieceUploadFrame) {
          setState(() {
            showNewPieceUploadFrame = false;
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
                // label: const Text('Add Post'),
              ),
        appBar: AppBar(
            centerTitle: true,
            leading: MenuButton(username: user?.username ?? 'User'),
            actions: [SearchBarCustom(controller: TextEditingController())],
            title: CameraButton(
              onPressed: () {},
            )),
        body: const SafeArea(
          child: Column(
            children: [
             // ToggleBar(),
              Expanded(
                child: UnityARView(),
              ),
            ],
          ),
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
