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
}
