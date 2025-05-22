import 'anchor_model.dart';
import 'piece_model.dart';

class UserProfileModel {
  final String username;
  final String bio;
  final String Profile_photo;
  final int live_pieces;
  final bool is_premium;
  final int frame_count;
  final List<AnchorModel> anchors;
  final List<Piece> pieces;
  final int subscriberCount;
  final int subscriptionCount;
  final int totalImpressions;
  final int pieceCount;

  UserProfileModel({
    required this.username,
    required this.bio,
    required this.Profile_photo,
    required this.live_pieces,
    required this.is_premium,
    required this.frame_count,
    this.anchors = const [],
    this.pieces = const [],
    this.subscriberCount = 0,
    this.subscriptionCount = 0,
    this.totalImpressions = 0,
    this.pieceCount = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'],
      bio: json['User_bio'] ?? '',
      Profile_photo: json['Profile_photo'] ?? '',
      live_pieces: json['Live_pieces'] ?? 0,
      is_premium: json['Is_premium'] ?? false,
      frame_count: json['Frame_count'] ?? 0,
      subscriberCount: json['subscriberCount'] ?? 0,
      pieceCount: json['pieceCount'] ?? 0,
      subscriptionCount: json['subscriptionCount'] ?? 0,
    );
  }

  UserProfileModel copyWith({
    String? username,
    String? bio,
    String? Profile_photo,
    int? live_pieces,
    bool? is_premium,
    int? frame_count,
    List<AnchorModel>? anchors,
    List<Piece>? pieces,
    int? pieceCount,
    int? subscriberCount,
    int? subscriptionCount,
  }) {
    return UserProfileModel(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      Profile_photo: Profile_photo ?? this.Profile_photo,
      live_pieces: live_pieces ?? this.live_pieces,
      is_premium: is_premium ?? this.is_premium,
      frame_count: frame_count ?? this.frame_count,
      anchors: anchors ?? this.anchors,
      pieces: pieces ?? this.pieces,
      pieceCount: pieceCount ?? this.pieceCount,
    );
  }
}
