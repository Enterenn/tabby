import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Home', path: '/home'),
    (icon: Icons.savings_rounded, label: 'Budget', path: '/budget'),
    (icon: Icons.add_circle_rounded, label: 'Add', path: '/add-expense'),
    (icon: Icons.credit_card_rounded, label: 'Cards', path: '/cards'),
    (icon: Icons.person_rounded, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((t) => location.startsWith(t.path));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((tab) {
          final isAdd = tab.path == '/add-expense';
          return NavigationDestination(
            icon: isAdd
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2C230),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tab.icon, color: const Color(0xFF2E2A22)),
                  )
                : Icon(tab.icon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}
