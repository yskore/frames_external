import 'package:flutter/material.dart';
import 'package:frames_app/Screens/user_menu.dart';


  class MenuButton extends StatelessWidget {
    final String username;
    const MenuButton({required this.username});
    @override
    Widget build(BuildContext context) {
      return IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuScreen(username: username,)),
          );
        },
      );
    }
  }
