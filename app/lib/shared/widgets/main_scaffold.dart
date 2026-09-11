import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/group.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _GroupPickerSheet(
        onGroupSelected: (group) {
          context.push('/add-expense?groupId=${group.id}');
        },
      ),
    );
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
            _onAddTapped(context);
          } else {
            context.go(_paths[i]);
          }
        },
        destinations: List.generate(_paths.length, (i) {
          final isAdd = _paths[i] == '/add-expense';
          if (isAdd) {
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

// ─── Group picker sheet ────────────────────────────────────────────────────────

class _GroupPickerSheet extends StatefulWidget {
  const _GroupPickerSheet({required this.onGroupSelected});

  final ValueChanged<Group> onGroupSelected;

  @override
  State<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends State<_GroupPickerSheet> {
  List<Group>? _groups;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await apiClient.dio.get('/groups');
      setState(() {
        _groups = (resp.data as List)
            .map((g) => Group.fromJson(g as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Dans quel groupe ?', style: tt.headlineSmall),
          const SizedBox(height: 16),
          if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(_error!, style: tt.bodyMedium),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Réessayer')),
                ],
              ),
            )
          else if (_groups == null)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ))
          else if (_groups!.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Tu n\'es dans aucun groupe',
                  style:
                      tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...(_groups!.map((g) {
              final balance = g.balance;
              final isPositive = balance > 0;
              final isNeutral = balance == 0;
              final balanceColor = isNeutral
                  ? cs.onSurfaceVariant
                  : (isPositive ? AppColors.success : AppColors.danger);
              final balanceStr = isNeutral
                  ? 'Réglé'
                  : '${isPositive ? '+' : ''}${balance.toStringAsFixed(0)} €';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                    style: tt.titleMedium
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
                title: Text(g.name, style: tt.titleMedium),
                subtitle: Text(
                  balanceStr,
                  style: tt.bodySmall?.copyWith(color: balanceColor),
                ),
                trailing: const Icon(Symbols.arrow_forward_ios_rounded,
                    size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onGroupSelected(g);
                },
              );
            })),
        ],
      ),
    );
  }
}
