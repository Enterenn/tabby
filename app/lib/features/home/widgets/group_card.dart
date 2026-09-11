import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/group.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final balance = group.balance;
    final isPositive = balance > 0;
    final isNeutral = balance == 0;

    return GestureDetector(
      onTap: () => context.push('/groups/${group.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _AvatarStack(members: group.members.map((m) => m.user.name).toList()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  if (isNeutral)
                    Text(
                      'Tout est réglé',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  else
                    Text(
                      isPositive
                          ? 'On te doit ${balance.toStringAsFixed(2)} €'
                          : 'Tu dois ${(-balance).toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isPositive ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/add-expense?groupId=${group.id}'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('+ Dépense', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const overlap = 12.0;
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
                border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.background, width: 2),
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
