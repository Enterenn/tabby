import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/group.dart';
import '../../../design_system/design_system.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, this.index = 0});

  final Group group;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final space = context.tabbySpace;
    final tt = Theme.of(context).textTheme;
    final onCard = cs.onSurface;

    return TabbyListCard(
      color: cs.surfaceContainerLow,
      margin: EdgeInsets.only(bottom: space.sm),
      onTap: () => context.push('/groups/${group.id}'),
      padding: EdgeInsets.fromLTRB(space.xl, space.lg, space.lg, space.lg),
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
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (group.isPinned) ...[
                      SizedBox(width: space.xs + 2),
                      Icon(
                        Symbols.push_pin_rounded,
                        size: space.lg,
                        fill: 1,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: space.md),
              ExpressiveBalanceBadge(amount: group.balance),
            ],
          ),
          SizedBox(height: space.md),
          ExpressiveAvatarStack(
            names: group.members.map((m) => m.user.name).toList(),
            imageUrls: group.members
                .map((m) => resolveMediaUrl(m.user.avatarUrl))
                .toList(),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
