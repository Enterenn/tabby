import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/group.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final balance = group.balance;
    final isPositive = balance > 0;
    final isNeutral = balance == 0;

    final balanceColor =
        isNeutral ? cs.onSurfaceVariant : (isPositive ? AppColors.success : AppColors.danger);

    final balanceLabel = isNeutral
        ? 'Tout est réglé'
        : isPositive
            ? '+${balance.toStringAsFixed(2)} €'
            : '${balance.toStringAsFixed(2)} €';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/groups/${group.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              _AvatarStack(
                members: group.members.map((m) => m.user.name).toList(),
                containerColor: cs.surfaceContainerHighest,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: tt.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (!isNeutral)
                          Icon(
                            isPositive
                                ? Symbols.arrow_upward_rounded
                                : Symbols.arrow_downward_rounded,
                            size: 14,
                            color: balanceColor,
                            fill: 1,
                          ),
                        if (!isNeutral) const SizedBox(width: 2),
                        Text(
                          balanceLabel,
                          style: tt.bodySmall?.copyWith(
                            color: balanceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () =>
                    context.push('/add-expense?groupId=${group.id}'),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.add_rounded, size: 16, fill: 1),
                    const SizedBox(width: 4),
                    Text(
                      'Dépense',
                      style: tt.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.members,
    required this.containerColor,
  });

  final List<String> members;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const overlap = 10.0;
    final displayed = members.take(3).toList();
    final width = size + (displayed.length - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: displayed.asMap().entries.map((entry) {
          final i = entry.key;
          final name = entry.value;
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.categoryPalette[i % AppColors.categoryPalette.length],
                border: Border.fromBorderSide(
                  // Bordure couleur de la card pour l'effet de séparation
                  BorderSide(color: containerColor, width: 2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
