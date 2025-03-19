import 'package:flutter/material.dart';

class ToggleBar extends StatefulWidget {
  const ToggleBar({super.key});

  @override
  _ToggleBarState createState() => _ToggleBarState();
}

class _ToggleBarState extends State<ToggleBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ToggleButtons(
            onPressed: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(24),
            borderWidth: 1,
            borderColor: Colors.grey.shade300,
            selectedBorderColor: Theme.of(context).primaryColor,
            fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
            selectedColor: Theme.of(context).primaryColor,
            color: Colors.grey.shade600,
            constraints: BoxConstraints(
              minWidth: screenWidth * 0.27,
              minHeight: 40,
            ),
            isSelected: List.generate(3, (index) => _selectedIndex == index),
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Following',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Discover',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('User-Specific',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
