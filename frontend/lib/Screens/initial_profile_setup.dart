import 'dart:io';
import 'dart:convert';
import 'package:frames_app/Functions/updateuser.dart';
import 'package:frames_app/Screens/home_screen.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/user_profile_info.dart'; // Import the UserProfileInfoNotifier
import 'package:frames_app/Providers/profile_picture_picker.dart';
import 'package:image_picker/image_picker.dart'; // Import the ImagePickerNotifier
import 'package:frames_app/providers/signup_form_notifier.dart';
import 'package:frames_app/Functions/storage_credentials.dart';



class InitialProfileSetup extends ConsumerWidget {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();
  final String username; 
  InitialProfileSetup({required this.username}); // Modify the constructor

 @override
Widget build(BuildContext context, WidgetRef ref) {
  final userProfileInfo = ref.watch(userProfileInfoProvider);
  final pickedImage = ref.watch(imagePickerProvider);
  const bucketName = 'x-fabric-419423.appspot.com';
  const folderName = 'profile_pictures';
  

  return Scaffold(
    appBar: AppBar(
      title: Text('Profile Setup'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: MediaQuery.of(context).size.height, // Set the height of the Container

            child: Column(
              children: [
                Text(
                  'Welcome $username, lets complete your frames profile',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        ref.read(imagePickerProvider.notifier).pickImage(File(pickedFile.path));
                      }
                  },
                  child: CircleAvatar(
                    radius: 140, // Increase the size of the image container
                    backgroundColor: Colors.grey[200],
                    child: pickedImage != null
                        ? ClipOval(child: Image.file(pickedImage, fit: BoxFit.cover))
                        : Icon(Icons.add, size: 70),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  height: 90, // Reduce the size of the text box for the bio
                  child: TextField(
                    controller: _bioController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                    ElevatedButton(
            onPressed: () async {
                    // Handle continue button press
                    
                    if (pickedImage!= null) {
                      final imageURL = await uploadImage(pickedImage, bucketName, folderName); 
                      updateUserProfile(username, _bioController.text, imageURL);
                      }

                      else {
                        updateUserProfile(username, _bioController.text, '');
                      }
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(username: username)),
    );    

            },
            child: Text('Continue'),
                    ),
                    Spacer(),
                    Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
                    onPressed: () {
                       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(username: username)),
    );
            // Handle skip button press
                    },
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Skip'),
            ),
                    ),
                // Rest of your widgets go here
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
