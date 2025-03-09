import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfileInfo {
  final String id;
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String country;
  final String email;
  final String phoneNumber;
  final String userType;

  UserProfileInfo({
    required this.id,
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.country,
    required this.email,
    required this.phoneNumber,
    required this.userType,
  });

  factory UserProfileInfo.fromJson(Map<String, dynamic> json) {
    return UserProfileInfo(
      id: json['_id'],
      username: json['username'],
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      country: json['country'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      userType: json['userType'],
    );
  }
}

class UserProfileInfoNotifier extends StateNotifier<UserProfileInfo?> {
  UserProfileInfoNotifier() : super(null);

  Future<void> getUserInfo(String username) async {
    final response = await http.get(Uri.parse('https://x-fabric-419423.uc.r.appspot.com/user_info?username=$username'));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      state = UserProfileInfo.fromJson(responseBody['user']);
    } else {
      throw Exception('Failed to load user');
    }
  }
}

final userProfileInfoProvider = StateNotifierProvider<UserProfileInfoNotifier, UserProfileInfo?>((ref) {
  return UserProfileInfoNotifier();
});