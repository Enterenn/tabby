import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _paths = ['/home', '/budget', '/add-expense', '/cards', '/profile'];
  static const _labels = ['Home', 'Budget', 'Add', 'Cards', 'Profil'];

  // Material Symbols — rounded style, fill géré par le thème
  static const _icons = [
    Symbols.home_rounded,
    Symbols.savings_rounded,
    Symbols.add_rounded,
    Symbols.credit_card_rounded,
    Symbols.person_rounded,
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
        onDestinationSelected: (i) {
          if (_paths[i] == '/add-expense') {
            // /add-expense est hors ShellRoute → push pour conserver l'historique
            context.push('/add-expense');
          } else {
            context.go(_paths[i]);
          }
        },
        destinations: List.generate(_paths.length, (i) {
          final isAdd = _paths[i] == '/add-expense';
          if (isAdd) {
            // Bouton central : pill M3 avec couleur primaire de marque
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
                  fill: 1,
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
