import 'package:flutter/material.dart';

class UserProfileIcon extends StatelessWidget {
  final String username;
  final String? imageUrl;

  const UserProfileIcon({super.key, required this.username, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.white,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              username,
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          CircleAvatar(
  backgroundColor: imageUrl == null ? Colors.black : null,
  backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
),
        ],
      ),
    );
  }
}