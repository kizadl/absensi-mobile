import 'package:flutter/material.dart';

/// Bottom-navigation shell with 3 tabs.
///
/// Part 2 swaps in HomeScreen + AttendanceProvider, Part 3 HistoryScreen,
/// Part 4 ProfileScreen. The tab structure and name stay stable.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  static const _placeholders = <Widget>[
    Center(child: Text('Home')),
    Center(child: Text('Histori')),
    Center(child: Text('Profil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _placeholders[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Histori'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}
