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
    final group = widget.group;
    final balance = group.balance;
    final memberCount = group.members.length;
    final onCard = cs.onSecondaryContainer;

    void openGroup() => context.push('/groups/${group.id}');

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Card(
        color: cs.secondaryContainer,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  openGroup();
                },
                onTapCancel: () => setState(() => _pressed = false),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onCard,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$memberCount membre${memberCount > 1 ? 's' : ''}',
                            style: tt.bodySmall?.copyWith(
                              color: onCard.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ExpressiveBalanceBadge(amount: balance),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: openGroup,
                      behavior: HitTestBehavior.opaque,
                      child: ExpressiveAvatarStack(
                        names: group.members.map((m) => m.user.name).toList(),
                      ),
                    ),
                  ),
                  _AddExpenseButton(group: group),
                ],
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

    return Material(
      color: cs.primary,
      elevation: 0,
      shape: shapes.pill(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final added = await showAddExpenseSheet(
            context,
            groupId: group.id,
          );
          if ((added ?? false) && context.mounted) {
            context.read<HomeCubit>().loadGroups();
          }
        },
        customBorder: shapes.pill(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.add_rounded, size: 18, color: cs.onPrimary, fill: 1),
              const SizedBox(width: 6),
              Text(
                'Dépense',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
