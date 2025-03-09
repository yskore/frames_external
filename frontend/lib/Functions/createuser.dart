import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> createUser(String username, String password, String firstName, String lastName, String dateOfBirth, String country, String email, String phoneNumber, String userType) async {
  var url = Uri.parse('https://x-fabric-419423.uc.r.appspot.com/user_basic');

  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'username': username,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'country': country,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('User created successfully.');
  } else {
    print('Failed to create user.');
  }
}

Future<void> createUserProfile(String username) async {
  var url = Uri.parse('https://x-fabric-419423.uc.r.appspot.com/set_profile');

  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'username': username,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('User Profile Started up');
  } else {
    print('Failed to create user Profile');
  }
}