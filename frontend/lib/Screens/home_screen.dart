import 'package:flutter/material.dart';
import 'package:frames_app/Providers/user_profile_info.dart'; // Import the UserProfileInfoNotifier
import 'package:frames_app/Widgets/AR_core_view.dart';
import 'package:frames_app/Widgets/new_post_button.dart';
import 'package:frames_app/Widgets/search_bar.dart';
import 'package:frames_app/Widgets/take_picture.dart';
import 'package:frames_app/Widgets/search_bar.dart' as search_bar;
import 'package:frames_app/Widgets/view_filter_toggle_bar.dart';
import 'package:frames_app/Widgets/menu_button.dart';
import 'package:frames_app/Widgets/new_piece_frame.dart';



class HomeScreen extends StatefulWidget {
  final String username;

  HomeScreen({required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showNewPieceUploadFrame = false;

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;


    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: MenuButton(username: widget.username),
            ),
            Container(
              width: double.infinity,
              alignment: Alignment.topRight,
              child: SearchBarCustom(controller: TextEditingController()),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: PostButton(
                onPressed: () {
                  setState(() {
                    showNewPieceUploadFrame = !showNewPieceUploadFrame;
                  });
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CameraButton(
                onPressed: () {
                  // Handle the camera button press here
                },
              ),
            ),
            Column(
              children: [
                ToggleBar(),
                Container(
                  height: screenHeight * 0.8,
                  alignment: Alignment.bottomCenter,
                  child: UnityARView(),
                ),
              ],
            ),
            if (showNewPieceUploadFrame)
              Positioned(
                bottom: 0,
                left: screenWidth / 9, // adjust this value as needed
                child: const NewPiece_UploadFrame(),
              ),
          ],
        ),
      ),
    );
  }
}