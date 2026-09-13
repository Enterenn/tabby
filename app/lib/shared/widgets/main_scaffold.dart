import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../features/add_expense/screens/add_expense_screen.dart';
import '../../l10n/l10n.dart';
import 'connectivity_banner.dart';
import '../../design_system/design_system.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _paths = ['/home', '/budget', '/add-expense', '/cards', '/profile'];

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
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(bottom: context.tabBarClearance),
        child: ConnectivityBanner(child: child),
      ),
      bottomNavigationBar: _NavFade(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: _TabbyNavBar(
            currentIndex: currentIndex,
            onSelect: (i) {
              if (_paths[i] == '/add-expense') {
                _onAddTapped(context);
              } else {
                context.go(_paths[i]);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NavFade extends StatelessWidget {
  const _NavFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surface.withValues(alpha: 0),
            cs.surface.withValues(alpha: 0.55),
            cs.surface.withValues(alpha: 0.88),
            cs.surface,
          ],
          stops: const [0, 0.35, 0.7, 1],
        ),
      ),
      child: child,
    );
  }
}

class _TabbyNavBar extends StatelessWidget {
  const _TabbyNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final l10n = context.l10n;
    final labels = [
      l10n.navHome,
      l10n.navBudget,
      '',
      l10n.navCards,
      l10n.navProfile,
    ];

    return Material(
      color: cs.surfaceContainer,
      elevation: 0,
      shape: shapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(MainScaffold._paths.length, (i) {
              final isAdd = MainScaffold._paths[i] == '/add-expense';
              if (isAdd) {
                return Expanded(
                  child: Center(
                    child: ExpressiveActionButton(
                      icon: Symbols.add_rounded,
                      onPressed: () => onSelect(i),
                      tooltip: l10n.navAddExpense,
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
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer
                              : Colors.transparent,
                          borderRadius: shapes.radiusFull,
                        ),
                        child: Icon(
                          MainScaffold._icons[i],
                          size: 24,
                          fill: selected ? 1 : 0,
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? cs.onPrimaryContainer
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
