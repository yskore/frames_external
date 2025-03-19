import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:image_picker/image_picker.dart';

class InitialProfileSetup extends ConsumerStatefulWidget {
  final String username;

  const InitialProfileSetup({super.key, required this.username});

  @override
  ConsumerState<InitialProfileSetup> createState() =>
      _InitialProfileSetupState();
}

class _InitialProfileSetupState extends ConsumerState<InitialProfileSetup> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();
  File? pickedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Text(
                    'Welcome ${widget.username}, lets complete your frames profile',
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          pickedImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 140,
                      backgroundColor: Colors.grey[200],
                      child: pickedImage != null
                          ? ClipOval(
                              child: Image.file(
                                pickedImage!,
                                fit: BoxFit.cover,
                                width: 240,
                                height: 240,
                              ),
                            )
                          : const Icon(Icons.add, size: 70),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 90,
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
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      final userNotifier = ref.read(userProvider.notifier);
                      final success = await userNotifier.updateUserProfile(
                        widget.username,
                        _bioController.text,
                        pickedImage,
                      );

                      if (success && mounted && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      }
                    },
                    child: const Text('Continue'),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
