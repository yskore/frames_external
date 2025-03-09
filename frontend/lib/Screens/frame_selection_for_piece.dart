import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frames_app/Screens/frame_preview_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frames_app/Functions/storage_credentials.dart';

class FrameSelectionForPiece extends StatefulWidget {
  @override
  _FrameSelectionForPieceState createState() => _FrameSelectionForPieceState();
}

class _FrameSelectionForPieceState extends State<FrameSelectionForPiece> {
  List frames = [];
  List filteredFrames = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFrames();
  }

  Future<void> fetchFrames() async {
    try {
      final response = await http.get(Uri.parse('https://x-fabric-419423.uc.r.appspot.com/frames'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          frames = data;
          filteredFrames = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load frames');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterSearchResults(String query) {
    List dummySearchList = List.from(frames);
    if (query.isNotEmpty) {
      List dummyListData = [];
      dummySearchList.forEach((item) {
        if (item['Frame_title'].toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        filteredFrames = dummyListData;
      });
      return;
    } else {
      setState(() {
        filteredFrames = frames;
      });
    }
  }
  Future<String> getFaceName(String title) async {
  for (var frame in frames) {
    if (frame['Frame_title'] == title) {
      return frame['Face_name'];
    }
  }
  throw Exception('Frame not found when using getFaceName');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Frame'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: filterSearchResults,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredFrames.length,
                    itemBuilder: (context, index) {
                      final frame = filteredFrames[index];
                      return FrameItem(
                        imageUrl: frame['Frame_display'],
                        title: frame['Frame_title'],
                        description: frame['Frame_description'],
                        getFaceName: getFaceName,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FrameItem extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final Future<String> Function(String) getFaceName;

  FrameItem({required this.imageUrl, required this.title, required this.description, required this.getFaceName});

  @override
  _FrameItemState createState() => _FrameItemState();
}

class _FrameItemState extends State<FrameItem> {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext BottomSheetcontext) {
                    return Container(
                      height: 60, // You can adjust this value as needed
                      color: Colors.white,
                      child: Center(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(BottomSheetcontext); // Close the bottom sheet
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              // Use the pickedFile
                              tempPieceImage = await piece_image_upload_url(File(pickedFile.path), 'x-fabric-419423.appspot.com', 'temp_image_upload');
                              String faceName = await widget.getFaceName(widget.title);
                              // Navigate to the FramePreviewScreen
                              if (faceName != null) {
        print(faceName);
        
        print('face name is: $faceName .\n Image URL is: $tempPieceImage .\n Frame name is: ${widget.title} .');
        
        Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => FramePreviewScreen(
      frameName: widget.title,
      faceName: faceName,
      imageUrl: tempPieceImage,
    ),
  ),
);;

       ;
      } 
                            }
                            else {print('No image selected');}
                          },
                          child: Text(
                            'Create with ${widget.title}',
                            style: TextStyle(fontSize: 24), // Adjust the style as needed
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(widget.description),
          ),
        ],
      ),
    );
  }
}
