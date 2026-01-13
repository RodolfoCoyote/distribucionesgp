import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserBottomNav extends StatelessWidget {
  final int currentIndex;

  const UserBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.transparent,
      unselectedItemColor: Colors.transparent,
      items: [
        _buildItem(icon: Icons.home, index: 0),
        _buildItem(icon: Icons.settings, index: 1),
      ],
    );
  }

  BottomNavigationBarItem _buildItem({
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;

    return BottomNavigationBarItem(
      label: '',
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
