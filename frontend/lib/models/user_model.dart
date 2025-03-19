import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/models/piece_model.dart';

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String country;
  final String email;
  final String phoneNumber;
  final String userType;

  final String profilePhoto;
  final String bio;
  final int followerCount;
  final int followingCount;
  final int pieceCount;
  final int livePieces;
  final List<Piece> pieces;
  final List<AnchorModel> anchors;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.country,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    this.profilePhoto = '',
    this.bio = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.pieceCount = 0,
    this.livePieces = 0,
    this.pieces = const [],
    this.anchors = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json;
    return UserModel(
      id: userData['_id'],
      username: userData['username'],
      firstName: userData['firstName'],
      lastName: userData['lastName'],
      dateOfBirth: DateTime.parse(userData['dateOfBirth']),
      country: userData['country'],
      email: userData['email'],
      phoneNumber: userData['phoneNumber'],
      userType: userData['userType'],
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? country,
    String? email,
    String? phoneNumber,
    String? userType,
    String? profilePhoto,
    String? bio,
    int? followerCount,
    int? followingCount,
    int? pieceCount,
    int? livePieces,
    List<Piece>? pieces,
    List<AnchorModel>? anchors,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      pieceCount: pieceCount ?? this.pieceCount,
      livePieces: livePieces ?? this.livePieces,
      pieces: pieces ?? this.pieces,
      anchors: anchors ?? this.anchors,
    );
  }
}
