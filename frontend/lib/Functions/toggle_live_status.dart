import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> togglePieceLiveStatus(String pieceId, bool liveStatus) async {
  var url =
      Uri.parse('https://x-fabric-419423.uc.r.appspot.com/toggle_live_status');

  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'piece_id': pieceId,
        'live_status': liveStatus,
      }),
    );

    if (response.statusCode == 200) {
      print('Piece live status updated successfully.');

      // Parse and print the response for debugging
      var responseData = jsonDecode(response.body);
      print('Server response: ${responseData['message']}');
    } else {
      print(
          'Failed to update piece live status. Status code: ${response.statusCode}');
      print('Error message: ${response.body}');
    }
  } catch (e) {
    print('Error toggling piece live status: $e');
    rethrow; // Rethrow to allow handling by caller
  }
}
