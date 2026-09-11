import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../features/add_expense/screens/add_expense_screen.dart';
import 'connectivity_banner.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _paths = ['/home', '/budget', '/add-expense', '/cards', '/profile'];
  static const _labels = ['Home', 'Budget', 'Add', 'Cards', 'Profil'];

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

  void _onAddTapped(BuildContext context) {
    showAddExpenseSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: ConnectivityBanner(child: child),
      bottomNavigationBar: _TabbyNavBar(
        currentIndex: currentIndex,
        onSelect: (i) {
          if (_paths[i] == '/add-expense') {
            _onAddTapped(context);
          } else {
            context.go(_paths[i]);
          }
        },
      ),
    );
  }
}

// ─── Nav bar — Add en vrai cercle, hors du layout NavigationBar ───────────────

class _TabbyNavBar extends StatelessWidget {
  const _TabbyNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      elevation: 3,
      surfaceTintColor: cs.primary,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(MainScaffold._paths.length, (i) {
              final isAdd = MainScaffold._paths[i] == '/add-expense';
              if (isAdd) {
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onSelect(i),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Symbols.add_rounded,
                          color: Color(0xFF2E2A22),
                          size: 28,
                          fill: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final selected = currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.secondaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          MainScaffold._icons[i],
                          size: 24,
                          fill: selected ? 1 : 0,
                          color: selected
                              ? cs.onSecondaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MainScaffold._labels[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? cs.secondary
                                  : cs.onSurfaceVariant,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

