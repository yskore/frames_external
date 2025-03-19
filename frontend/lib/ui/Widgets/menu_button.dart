import 'package:flutter/material.dart';
import 'package:frames_app/ui/Screens/user_menu.dart';

class MenuButton extends StatelessWidget {
  final String username;
  const MenuButton({super.key, required this.username});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      },
    );
  }
}
