  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:frames_app/Screens/home_screen.dart'; // Import the HomeScreen

  Future<void> loginUser(String username, String password, BuildContext context) async {
    final response = await http.post(
      Uri.parse('https://x-fabric-419423.uc.r.appspot.com/login'),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, then parse the JSON.
      print('Logged in successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful'),
        ),
      );
        // Navigate to the HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(username: username)),
    );
    } else {
      // If the server returns an unsuccessful response code, then show a snackbar with the error message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed: incorrect username or password'),
        ),
      );
      throw Exception('Failed to login');
    }
  }