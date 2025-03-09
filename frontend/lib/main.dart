import 'package:flutter/material.dart';
import 'package:frames_app/Screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Widgets/AR_core_view.dart';
import 'package:frames_app/Widgets/camera_view.dart';
void main() {
  runApp(const ProviderScope(child: MainApp()) );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRAMES',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:  LoginScreen(),
      //LoginScreen(),
    );
  }
}