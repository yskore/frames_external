import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/signup_form_notifier.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/authentication_screen.dart';
import 'package:frames_app/ui/Widgets/country_picker_tile.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _selectedCountry;
  String? _selectedUserType;

  void _handleCountrySelected(String country) {
    _selectedCountry = country;
  }

  void handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Check country selection
      if (_selectedCountry == null || _selectedCountry!.isEmpty) {
        ref.read(errorProvider.notifier).setError('Please select a country');
        return;
      }

      // Check DOB selection
      if (_dobController.text.isEmpty) {
        ref
            .read(errorProvider.notifier)
            .setError('Please select your date of birth');
        return;
      }

      // Check if user exists and send OTP
      final success = await ref
          .read(userProvider.notifier)
          .checkUserExistsAndSendOTP(
              _usernameController.text, _emailController.text);

      if (!success) {
        return; // Error is already set in the provider
      }

      // Save form data
      final signupForm = SignupForm(
        username: _usernameController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dobController.text,
        country: _selectedCountry,
        email: _emailController.text,
        phoneNumber: _phoneNumberController.text,
        userType: _selectedUserType,
      );

      ref.read(signupFormProvider.notifier).state = signupForm;

      if (mounted && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthenticationScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      setState(() {
                        _dobController.text = formattedDate;
                      });
                    }
                  },
                  child: Text(
                    _dobController.text.isEmpty
                        ? 'Select Date of Birth'
                        : _dobController.text,
                  ),
                ),
                const SizedBox(height: 10),
                CountryPickerTile(onCountrySelected: _handleCountrySelected),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'User Type'),
                  value: _selectedUserType,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a user type';
                    }
                    return null;
                  },
                  items: const [
                    DropdownMenuItem(
                        value: 'personal', child: Text('Personal')),
                    DropdownMenuItem(value: 'company', child: Text('Company')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleSubmit,
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
