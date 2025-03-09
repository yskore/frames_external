import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:frames_app/Widgets/country_picker_tile.dart';
import 'package:intl/intl.dart';
import 'authentication_screen.dart'; // Import the authentication screen
import 'dart:math';
import 'package:frames_app/Functions/sendverificationcode.dart';
import 'package:frames_app/Providers/signup_form_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Functions/user_exists.dart';


class SignUpScreen extends ConsumerStatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
    void _handleCountrySelected(String country) {
    ref.read(signupFormProvider.notifier).updateCountry(country);
  }
  @override
  Widget build(BuildContext context) {
    final signupForm = ref.watch(signupFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
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
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a username')),
        );
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    ref.read(signupFormProvider.notifier).updateUsername(value);
                  },
                ),
                SizedBox(height: 10),
                 SizedBox(height: 10),
      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(labelText: 'Password'),
        obscureText: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a password')),
        );
            return 'Please enter a password';
          }
          return null;
        },
        onChanged: (value) {
          ref.read(signupFormProvider.notifier).updatePassword(value);
        },
      ),
      SizedBox(height: 10),
      TextFormField(
        controller: _confirmPasswordController,
        decoration: InputDecoration(labelText: 'Confirm Password'),
        obscureText: true,
        validator: (value) {
          if (value != _passwordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
            return 'Passwords do not match';
          }
          return null;
        },
      ),
      SizedBox(height: 10),
      TextFormField(
        controller: _firstNameController,
        decoration: InputDecoration(labelText: 'First Name'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your first name')),
        );
            return 'Please enter your first name';
          }
          return null;
        },
        onChanged: (value) {
          ref.read(signupFormProvider.notifier).updateFirstName(value);
        },
      ),
      SizedBox(height: 10),
      TextFormField(
        controller: _lastNameController,
        decoration: InputDecoration(labelText: 'Last Name'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your last name')),
        );
            return 'Please enter your last name';
          }
          return null;
        },
        onChanged: (value) {
          ref.read(signupFormProvider.notifier).updateLastName(value);
        },
      ),      SizedBox(height: 10),
TextButton(
  onPressed: () async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      _dobController.text = formattedDate;
      ref.read(signupFormProvider.notifier).updateDateOfBirth(formattedDate);
    }
  },
  child: Text(
    _dobController.text.isEmpty ? 'Select Date of Birth' : _dobController.text,
  ),
),
      SizedBox(height: 10), 
      CountryPickerTile(onCountrySelected: _handleCountrySelected),
      SizedBox(height: 10),
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')),
        );
            return 'Please enter your email';
          }
          return null;
        },
        onChanged: (value) {
          ref.read(signupFormProvider.notifier).updateEmail(value);
        },
      ),TextFormField(
  controller: _phoneNumberController,
  decoration: InputDecoration(labelText: 'Phone Number'),
  keyboardType: TextInputType.phone,
  validator: (value) {
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')),
        );

      return 'Please enter your phone number';
    }
    return null;
  },
  onChanged: (value) {
    ref.read(signupFormProvider.notifier).updatePhoneNumber(value);
  },
),
SizedBox(height: 10),
DropdownButtonFormField(
  decoration: InputDecoration(labelText: 'User Type'),
  validator: (value) {
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user type')),
        );
      return 'Please select a user type';
      
    }
    return null;
  },
  items: [
    DropdownMenuItem(child: Text('Personal'), value: 'personal'),
    DropdownMenuItem(child: Text('Company'), value: 'company'),
  ],
  onChanged: (value) {
    ref.read(signupFormProvider.notifier).updateUserType(value.toString());
  },
),
SizedBox(height: 20),
ElevatedButton(
  onPressed: () async {
    if (_formKey.currentState?.validate() ?? false) {
        String? country = ref.read(signupFormProvider).country;
      if (country == null || country.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a country')),
        );
        return;
      }
    print('Checking if username or email exists');
    bool exists = await usernameExists(_usernameController.text, _emailController.text);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username or Email already exists'),
        ),
      );
      return;
    }
      String verificationCode = '';
      for (int i = 0; i < 6; i++) {
        verificationCode += (Random().nextInt(10)).toString();
      }

      // Send the verification code to the user's email address
      sendVerificationCode(_emailController.text, verificationCode);

      // Navigate to authentication screen with email address and verification code
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthenticationScreen(userEmail: _emailController.text, verificationCode: verificationCode, username: _usernameController.text),
        ),
      );
    }
  },
  child: Text('Sign Up'),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}