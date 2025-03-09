import 'package:flutter/material.dart';

class SearchBarCustom extends StatelessWidget {
  final TextEditingController controller;

  SearchBarCustom({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight, // Align the widget to the top right
      child: Container(
        width: MediaQuery.of(context).size.width * 0.3, // Set the width to 80% of the screen width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            icon: Icon(Icons.search),
            hintText: 'find users',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}