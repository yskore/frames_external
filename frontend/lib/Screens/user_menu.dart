import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Screens/home_screen.dart';
import 'package:frames_app/Screens/user_profile_screen.dart';
import 'package:frames_app/Providers/unity_scene_provider.dart';
// Import your unitySceneProvider

class MenuScreen extends ConsumerWidget {
  final String username;

  MenuScreen({required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(username: username,)),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Menu for $username'),
           leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Handle back button press in AppBar
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen(username: username)),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(username: username),
                      ),
                    );
                  },
                  child: Text('My Profile'),
                ),
              ),           
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to My Offers
                  },
                  child: Text('My Offers'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Modules
                  },
                  child: Text('Modules'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to User Preferences
                  },
                  child: Text('User Preferences'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Transactions
                  },
                  child: Text('Transactions'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Billing
                  },
                  child: Text('Billing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}