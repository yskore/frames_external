import 'package:http/http.dart' as http;
import 'dart:convert';


Future<bool> usernameExists(String username, String email) async {
  final response = await http.post(
    Uri.parse('https://x-fabric-419423.uc.r.appspot.com/user_exists'),
    body: jsonEncode({
      'username': username,
      'email': email,
    }),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200 || response.statusCode == 400) {
    // If the server returns a 200 OK response, then parse the JSON.
    return jsonDecode(response.body)['exists'];
  } else {
    // If the server returns an unsuccessful response code, then throw an exception.
    throw Exception('Failed to check username');
  }
}