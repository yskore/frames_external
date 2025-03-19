import 'package:flutter/material.dart';

class SearchBarCustom extends StatefulWidget {
  final TextEditingController controller;

  const SearchBarCustom({super.key, required this.controller});

  @override
  State<SearchBarCustom> createState() => _SearchBarCustomState();
}

class _SearchBarCustomState extends State<SearchBarCustom>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        widget.controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      height: 35,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // Use app's background color
        border: Border.all(
          color: Theme.of(context).primaryColor, // Border with primary color
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? MediaQuery.of(context).size.width * 0.6 : 35,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              padding: EdgeInsets.zero,
              iconSize: 22,
              color: Colors.grey[700],
            ),
            Expanded(
              child: AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _isExpanded
                    ? TextField(
                        controller: widget.controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          // contentPadding: EdgeInsets.symmetric(vertical: 10),
                          hintText: 'Find users',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
