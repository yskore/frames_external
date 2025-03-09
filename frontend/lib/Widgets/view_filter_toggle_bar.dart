import 'package:flutter/material.dart';

class ToggleBar extends StatefulWidget {
  @override
  _ToggleBarState createState() => _ToggleBarState();
}

class _ToggleBarState extends State<ToggleBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0; // Set the default selected index
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: screenHeight * 0.05),
         // height: screenHeight * 0.05, // Set the height to the desired value
          child: ToggleButtons(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.025), // Set the padding to 5% of the screen width
                child: Text('Following'),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.025), // Set the padding to 5% of the screen width
                child: Text('Discover'),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.025), // Set the padding to 5% of the screen width
                child: Text('User-Specific'),
              ),
            ],
            onPressed: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            isSelected: List.generate(3, (index) => _selectedIndex == index),
          ),
        ),
      ],
    );
  }
}