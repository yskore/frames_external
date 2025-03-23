import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/signup_form_notifier.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/initial_profile_setup.dart';

class AuthenticationScreen extends ConsumerStatefulWidget {
  const AuthenticationScreen({
    super.key,
  });

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  void resendVerificationCode() async {
    final signupForm = ref.read(signupFormProvider);

    if (signupForm.email == null) {
      ref.read(errorProvider.notifier).setError('Email address not found');
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref
        .read(userProvider.notifier)
        .sendVerificationCode(signupForm.email!);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent')),
      );
    }
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
              onPressed: _isLoading ? null : resendVerificationCode,
              child: _isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Resend Code'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_codeController.text.isEmpty) {
                        ref
                            .read(errorProvider.notifier)
                            .setError('Please enter the verification code');
                        return;
                      }

                      setState(() => _isLoading = true);

                      // Verify OTP via API
                      final isVerified = await ref
                          .read(userProvider.notifier)
                          .verifyOTP(signupForm.email!, _codeController.text);

                      if (!isVerified) {
                        setState(() => _isLoading = false);
                        return; // Error is already set in the provider
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

                      setState(() => _isLoading = false);

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
              child: _isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
