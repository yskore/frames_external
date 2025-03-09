import 'package:flutter/material.dart';
import 'package:frames_app/Functions/sendverificationcode.dart';
import 'package:frames_app/Providers/signup_form_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Screens/initial_profile_setup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frames_app/Functions/createuser.dart';

import 'dart:math'; // For generating random numbers

// ignore: must_be_immutable
class AuthenticationScreen extends ConsumerStatefulWidget {
  final String userEmail;
  String verificationCode;
  final String username;

  AuthenticationScreen(
      {super.key,
      required this.userEmail,
      required this.verificationCode,
      required this.username});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

String generateNewVerificationCode() {
  String verificationCode = '';
  for (int i = 0; i < 6; i++) {
    verificationCode += (Random().nextInt(10)).toString();
  }
  return verificationCode;
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen> {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final signupForm = ref.watch(signupFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please provide the 6-digit code sent to ${widget.userEmail}',
              textAlign: TextAlign.center,
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Verification Code'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement logic to resend code
                String newVerificationCode =
                    generateNewVerificationCode(); // Implement this function to generate a new verification code
                sendVerificationCode(widget.userEmail, newVerificationCode);
                setState(() {
                  widget.verificationCode =
                      newVerificationCode; // Update the verification code
                });
              },
              child: Text('Resend Code'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_codeController.text == widget.verificationCode) {
                  createUser(
                      signupForm.username!,
                      signupForm.password!,
                      signupForm.firstName!,
                      signupForm.lastName!,
                      signupForm.dateOfBirth!,
                      signupForm.country!,
                      signupForm.email!,
                      signupForm.phoneNumber!,
                      signupForm.userType!);
                  createUserProfile(signupForm.username!);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InitialProfileSetup(
                            username: signupForm.username!)),
                  );
                  print('User created successfully');
                } else {
                  // The codes do not match
                  // Do something else
                  print('Code does not match');
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
