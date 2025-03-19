// signup_form_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupForm {
  final String? username;
  final String? password;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? country;
  final String? email;
  final String? phoneNumber;
  final String? userType;

  SignupForm({
    this.username,
    this.password,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.country,
    this.email,
    this.phoneNumber,
    this.userType,
  });

  SignupForm copyWith({
    String? username,
    String? password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? country,
    String? email,
    String? phoneNumber,
    String? userType,
  }) {
    return SignupForm(
      username: username ?? this.username,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
    );
  }
}

final signupFormProvider = StateProvider<SignupForm>((ref) => SignupForm());
