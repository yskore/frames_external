
import 'package:flutter/material.dart';

class PostButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PostButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.post_add),
      onPressed: onPressed,
    );
  }
}