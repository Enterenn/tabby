import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _paths = ['/home', '/budget', '/add-expense', '/cards', '/profile'];
  static const _labels = ['Home', 'Budget', 'Add', 'Cards', 'Profil'];
  static const _icons = [
    Icons.home_rounded,
    Icons.savings_rounded,
    Icons.add_rounded,
    Icons.credit_card_rounded,
    Icons.person_rounded,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _paths.indexWhere((p) => location.startsWith(p));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_paths[i]),
        destinations: List.generate(_paths.length, (i) {
          final isAdd = _paths[i] == '/add-expense';
          if (isAdd) {
            // Bouton central M3 — FloatingActionButton-like dans la nav bar
            return NavigationDestination(
              icon: Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _icons[i],
                  color: const Color(0xFF2E2A22),
                  size: 20,
                ),
              ),
              label: _labels[i],
            );
          }
          return NavigationDestination(
            icon: Icon(_icons[i], size: 24),
            label: _labels[i],
          );
        }),
      ),
    );
  }
}
