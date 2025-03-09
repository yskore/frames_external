
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

Future<void> createPiece(String Piece_Object , String Piece_owner, String  Piece_title, String Frame_name, String live_status, String piece_likes, String Piece_location, String Piece_description, String Piece_creation_date, String Piece_display, 
String Piece_for_sale, String Piece_price) async {
    var uuid = Uuid();
    String pieceId = uuid.v4();
  var url = Uri.parse('https://x-fabric-419423.uc.r.appspot.com/new_piece');

  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'Piece_id': pieceId,
      'Piece_Object': Piece_Object,
      'Piece_owner': Piece_owner,
      'Piece_title': Piece_title,
      'Frame_name': Frame_name,
      'live_status': live_status,
      'piece_likes': piece_likes,
      'Piece_location': Piece_location,
      'Piece_description': Piece_description,
      'Piece_creation_date': Piece_creation_date,
      'Piece_display': Piece_display,
      'Piece_for_sale': Piece_for_sale,
      'Piece_price': Piece_price,

    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Piece created successfully.');
  } else {
    print('Failed to create piece.');
  }
}