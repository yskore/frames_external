import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/signup_form_notifier.dart';
import 'package:frames_app/ui/Screens/initial_profile_setup.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';

// ignore: must_be_immutable
class AuthenticationScreen extends ConsumerStatefulWidget {
  String verificationCode;

  AuthenticationScreen({
    super.key,
    required this.verificationCode,
  });

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen> {
  final _codeController = TextEditingController();

  void resendVerificationCode() async {
    final signupForm = ref.read(signupFormProvider);

    if (signupForm.email == null) {
      return;
    }

    final res = await ref
        .read(userProvider.notifier)
        .sendVerificationCode(signupForm.email ?? "");

    if (res == null) {
      return;
    }

    widget.verificationCode = res;
  }

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
              'Please provide the 6-digit code sent to ${signupForm.email}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Verification Code'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: resendVerificationCode,
              child: const Text('Resend Code'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_codeController.text != widget.verificationCode) {
                  ref
                      .read(errorProvider.notifier)
                      .setError('Invalid verification code. Please try again.');
                  return;
                }

                // Create user account data from the signupForm
                final userData = {
                  'username': signupForm.username!,
                  'password': signupForm.password!,
                  'firstName': signupForm.firstName!,
                  'lastName': signupForm.lastName!,
                  'dateOfBirth': signupForm.dateOfBirth!,
                  'country': signupForm.country!,
                  'email': signupForm.email!,
                  'phoneNumber': signupForm.phoneNumber!,
                  'userType': signupForm.userType!,
                };

                final userNotifier = ref.read(userProvider.notifier);
                final success = await userNotifier.signup(userData);

                if (success) {
                  if (mounted && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InitialProfileSetup(
                          username: signupForm.username!,
                        ),
                      ),
                    );
                  }
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
