import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/add_expense/screens/add_expense_screen.dart';
import '../../../shared/models/group.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../cubit/home_cubit.dart';

class GroupCard extends StatefulWidget {
  const GroupCard({super.key, required this.group, this.index = 0});

  final Group group;
  final int index;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;
    final group = widget.group;
    final balance = group.balance;
    final isNeutral = balance.abs() < 0.01;

    final balanceLabel = isNeutral ? 'Tout est réglé ✓' : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push('/groups/${group.id}');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(shapes.cornerExtraLarge),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: tt.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ExpressiveBalanceBadge(amount: balance),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpressiveAvatarStack(
                          names: group.members.map((m) => m.user.name).toList(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${group.members.length} membre${group.members.length > 1 ? 's' : ''}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isNeutral && balanceLabel != null)
                      Text(
                        balanceLabel,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 8),
                    _AddExpenseButton(group: group),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * widget.index))
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: shapes.buttonShape,
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      onPressed: () async {
        final added = await showAddExpenseSheet(
          context,
          groupId: group.id,
        );
        if ((added ?? false) && context.mounted) {
          context.read<HomeCubit>().loadGroups();
        }
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.add_rounded, size: 16, fill: 1),
          SizedBox(width: 4),
          Text('Dépense'),
        ],
      ),
    );
  }
}
