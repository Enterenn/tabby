import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/group.dart';
import '../cubit/home_cubit.dart';

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

    final balanceColor = isNeutral
        ? cs.onSurfaceVariant
        : (isPositive ? AppColors.success : AppColors.danger);

    final balanceLabel = isNeutral
        ? 'Tout est réglé'
        : isPositive
            ? 'On te doit'
            : 'Tu dois';

    final balanceAmount = isNeutral
        ? ''
        : '${isPositive ? '' : ''}${balance.abs().toStringAsFixed(0)} €';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/groups/${group.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Ligne 1 : avatars + menu ─────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarStack(
                    members: group.members.map((m) => m.user.name).toList(),
                    containerColor: cs.surfaceContainerHighest,
                  ),
                  const Spacer(),
                  // Bouton ··· (options groupe — Lot futur)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Symbols.more_horiz_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => context.push('/groups/${group.id}'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Nom du groupe ─────────────────────────────────────────────
              Text(
                group.name,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),

              // ── Solde + bouton dépense ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Solde
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balanceLabel,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (!isNeutral) ...[
                          const SizedBox(height: 2),
                          Text(
                            balanceAmount,
                            style: tt.headlineMedium?.copyWith(
                              color: balanceColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Bouton + Dépense
                  TextButton.icon(
                    onPressed: () async {
                      final added = await context
                          .push<bool>('/add-expense?groupId=${group.id}');
                      if ((added ?? false) && context.mounted) {
                        context.read<HomeCubit>().loadGroups();
                      }
                    },
                    icon: const Icon(Symbols.add_rounded, size: 18, fill: 1),
                    label: const Text('Dépense'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar stack ─────────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.members,
    required this.containerColor,
  });

  final List<String> members;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
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
                color: AppColors.categoryPalette[
                    i % AppColors.categoryPalette.length],
                border: Border.fromBorderSide(
                  BorderSide(color: containerColor, width: 2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
