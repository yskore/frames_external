import 'package:http/http.dart' as http;
import 'dart:convert';

// Functions to update the created user profile
Future<void> updateUserProfile(String username, String Bio, String ImageUrl, ) async {
  var url = Uri.parse('https://x-fabric-419423.uc.r.appspot.com/update_profile');

  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'username': username,
      'Bio': Bio,
      'imageUrl': ImageUrl,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('User Profile Updated successfully.');
  } else {
    print('Failed to update user Profile.');
  }
}
