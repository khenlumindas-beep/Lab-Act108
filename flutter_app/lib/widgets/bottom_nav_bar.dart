import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRoute;

  const BottomNavBar({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getIndexFromRoute(),
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/travels');
            break;
          case 2:
            context.go('/documents');
            break;
          case 3:
            context.go('/announcements');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.flight_takeoff),
          label: 'Travels',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Documents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Announcements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getIndexFromRoute() {
    if (currentRoute == '/') return 0;
    if (currentRoute == '/travels') return 1;
    if (currentRoute == '/documents') return 2;
    if (currentRoute == '/announcements') return 3;
    if (currentRoute == '/profile') return 4;
    return 0;
  }
}
