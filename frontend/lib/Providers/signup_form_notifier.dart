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
}

class SignupFormNotifier extends StateNotifier<SignupForm> {
  SignupFormNotifier() : super(SignupForm());


  void updateUsername(String username) {
    state = SignupForm(
      username: username,
      password: state.password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updatePassword(String password) {
    state = SignupForm(
      username: state.username,
      password: password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updateFirstName(String firstName) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updateLastName(String lastName) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: state.firstName,
      lastName: lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updateDateOfBirth(String dateOfBirth) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updateCountry(String country) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updateEmail(String email) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: email,
      phoneNumber: state.phoneNumber,
      userType: state.userType,
    );
  }

  void updatePhoneNumber(String phoneNumber) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: phoneNumber,
      userType: state.userType,
    );
  }

  void updateUserType(String userType) {
    state = SignupForm(
      username: state.username,
      password: state.password,
      firstName: state.firstName,
      lastName: state.lastName,
      dateOfBirth: state.dateOfBirth,
      country: state.country,
      email: state.email,
      phoneNumber: state.phoneNumber,
      userType: userType,
    );
  }


  // Add similar update methods for the other fields
  // ...
}

final signupFormProvider = StateNotifierProvider<SignupFormNotifier, SignupForm>((ref) => SignupFormNotifier());