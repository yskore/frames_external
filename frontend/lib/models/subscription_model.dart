class UserSubscriptionModel {
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePhoto;

  UserSubscriptionModel({
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
  });

  String get fullName => '$firstName $lastName';

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      username: json['username'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePhoto: json['profilePhoto'],
    );
  }
}
