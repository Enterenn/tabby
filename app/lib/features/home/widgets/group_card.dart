import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/group.dart';
import '../../../shared/widgets/expressive/expressive.dart';

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
    final onCard = cs.onSurface;

    void openGroup() => context.push('/groups/${group.id}');

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Card(
        color: cs.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openGroup,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onCard,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Symbols.push_pin_rounded,
                              size: 16,
                              fill: 1,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ExpressiveBalanceBadge(amount: balance),
                  ],
                ),
                const SizedBox(height: 14),
                ExpressiveAvatarStack(
                  names: group.members.map((m) => m.user.name).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * widget.index))
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
