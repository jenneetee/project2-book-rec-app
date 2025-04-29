import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../screens/discussion_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum),
          label: 'Discussions',
        ),
      ],
    );
  }
}
