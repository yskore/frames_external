import 'package:flutter/material.dart';
import 'package:frames_app/Screens/frame_selection_for_piece.dart';


// ignore: camel_case_types
class NewPiece_UploadFrame extends StatelessWidget {
  const NewPiece_UploadFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ElevatedButton(
          onPressed: () {
             Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FrameSelectionForPiece(),
            ));
          },
          child: const Text('Create New Piece'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle upload frame
          },
          child: const Text('Upload Frame'),
        ),
      ],
    );
  }
}