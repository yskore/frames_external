import 'package:http/http.dart' as http;
import 'dart:convert';

Future<int> getFollowerCount(String username) async {
  final response = await http.post(
    Uri.parse('https://x-fabric-419423.uc.r.appspot.com/getfollowercount'),
    body: jsonEncode({'username': username}),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, then parse the JSON.
    return jsonDecode(response.body)['followerCount'] ?? 'n/a';
  } else if (response.statusCode == 400) {
    // Handle bad request (e.g., missing username)
    throw Exception('Bad request: ${jsonDecode(response.body)['error']}');
  } else {
    // If the server returns an unsuccessful response code, then throw an exception.
    throw Exception('Failed to get followerCount. Status code: ${response.statusCode}');
  }
}

Future<int> getFollowingCount(String username) async {
  final response = await http.post(
    Uri.parse('https://x-fabric-419423.uc.r.appspot.com/getfollowingcount'),
    body: jsonEncode({'username': username}),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, then parse the JSON.
    return jsonDecode(response.body)['followingCount'] ?? 'n/a';
  } else if (response.statusCode == 400) {
    // Handle bad request (e.g., missing username)
    throw Exception('Bad request: ${jsonDecode(response.body)['error']}');
  } else {
    // If the server returns an unsuccessful response code, then throw an exception.
    throw Exception('Failed to get followingCount. Status code: ${response.statusCode}');
  }
}

Future<int> getPieceCount(String username) async {
  final response = await http.post(
    Uri.parse('https://x-fabric-419423.uc.r.appspot.com/getPieceCount'),
    body: jsonEncode({'username': username}),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['pieceCount'];
  } else if (response.statusCode == 400) {
    throw Exception('Bad request: ${jsonDecode(response.body)['error']}');
  } else {
    throw Exception('Failed to get piece count. Status code: ${response.statusCode}');
  }
}

class Piece {
  final String pieceid;
  final String pieceObject;
  final String pieceOwner;
  final String pieceTitle;
  final String frameName;
  final bool liveStatus;
  final int pieceLikes;
  final Map<String, dynamic>? pieceLocation;
  final String? pieceDescription;
  final DateTime pieceCreationDate;
  final String? pieceDisplay;
  final bool pieceForSale;
  final double piecePrice;

  Piece({
    required this.pieceid,
    required this.pieceObject,
    required this.pieceOwner,
    required this.pieceTitle,
    required this.frameName,
    required this.liveStatus,
    required this.pieceLikes,
    this.pieceLocation,
    this.pieceDescription,
    required this.pieceCreationDate,
    this.pieceDisplay,
    required this.pieceForSale,
    required this.piecePrice,
  });

  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      pieceid: json['Piece_id'] ?? '',
      pieceObject: json['Piece_Object'] ?? '',
      pieceOwner: json['Piece_owner'] ?? '',
      pieceTitle: json['Piece_title'] ?? '',
      frameName: json['Frame_name'] ?? 'not_found',
      liveStatus: json['live_status'] ?? false,
      pieceLikes: json['Piece_likes'] ?? 0,
      pieceLocation: json['Piece_location'],
      pieceDescription: json['Piece_description'],
      pieceCreationDate: json['Piece_creation_date'] != null
          ? DateTime.parse(json['Piece_creation_date'])
          : DateTime.now(),
      pieceDisplay: json['Piece_display'],
      pieceForSale: json['Piece_for_sale'] ?? false,
      piecePrice: (json['Piece_price'] ?? 0).toDouble(),
    );
  }
}

Future<List<Piece>> getPiecesByOwner(String username) async {
  final response = await http.post(
    Uri.parse('https://x-fabric-419423.uc.r.appspot.com/getpiecesbyowner'),
    body: jsonEncode({'username': username}),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> piecesJson = data['pieces'];
    print('piecesJson = $piecesJson');
    return piecesJson.map((json) => Piece.fromJson(json)).toList();
  } else if (response.statusCode == 400) {
    throw Exception('Bad request: ${jsonDecode(response.body)['error']}');
  } else {
    throw Exception('Failed to get pieces. Status code: ${response.statusCode}');
  }
}

class UserProfile {
  final String username;
  final String bio;
  final String Profile_photo;
  final int live_pieces;
  final bool is_premium;
  final int frame_count;

  UserProfile({
    required this.username,
    required this.bio,
    required this.Profile_photo,
    required this.live_pieces,
    required this.is_premium,
    required this.frame_count,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'],
      bio: json['User_bio'],
      Profile_photo: json['Profile_photo'],
      live_pieces: json['Live_pieces'],
      is_premium: json['Is_premium'],
      frame_count: json['Frame_count'],
    );
  }
}

Future<UserProfile> getUserProfile(String username) async {
  final response = await http.post(
    Uri.parse('https://x-fabric-419423.uc.r.appspot.com/getProfile'),
    body: jsonEncode({'username': username}),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    return UserProfile.fromJson(jsonDecode(response.body));
  } else if (response.statusCode == 404) {
    throw Exception('User profile not found');
  } else {
    throw Exception('Failed to get user profile. Status code: ${response.statusCode}');
  }
}
