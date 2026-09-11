import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/group.dart';
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final group = widget.group;
    final balance = group.balance;
    final isPositive = balance > 0.01;
    final isNegative = balance < -0.01;
    final isNeutral = !isPositive && !isNegative;

    final balanceColor = isNeutral
        ? cs.onSurfaceVariant
        : isPositive
            ? AppColors.success
            : AppColors.danger;

    final balanceLabel = isNeutral
        ? 'Tout est réglé ✓'
        : isPositive
            ? 'On te doit'
            : 'Tu dois';

    final balanceStr = isNeutral
        ? ''
        : '${balance.abs().toStringAsFixed(2)} €';

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
              // ── Header coloré ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    // Initiale du groupe
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : '?',
                        style: tt.titleLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nom du groupe
                    Expanded(
                      child: Text(
                        group.name,
                        style: tt.headlineSmall?.copyWith(
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge balance
                    if (!isNeutral)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '${isPositive ? '+' : '-'} $balanceStr',
                          style: tt.labelLarge?.copyWith(
                            color: balanceColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Réglé ✓',
                          style: tt.labelMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Corps ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatars + membres
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AvatarStack(
                          members:
                              group.members.map((m) => m.user.name).toList(),
                          containerColor: cs.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${group.members.length} membre${group.members.length > 1 ? 's' : ''}',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Solde si neutre — label au milieu
                    if (isNeutral)
                      Text(
                        balanceLabel,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    // Bouton + Dépense
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

// ─── Bouton + Dépense ─────────────────────────────────────────────────────────

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: cs.secondaryContainer,
        foregroundColor: cs.onSecondaryContainer,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      onPressed: () async {
        final added = await context
            .push<bool>('/add-expense?groupId=${group.id}');
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

// ─── Avatar stack ─────────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members, required this.containerColor});

  final List<String> members;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    const size    = 36.0;
    const overlap = 10.0;
    final displayed = members.take(4).toList();
    final extra     = members.length - displayed.length;
    final total = displayed.length + (extra > 0 ? 1 : 0);
    final width = size + (total - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          ...displayed.asMap().entries.map((e) {
            final i    = e.key;
            final name = e.value;
            return Positioned(
              left: i * (size - overlap),
              child: _Avatar(
                name: name,
                size: size,
                color: AppColors.avatarPalette[i % AppColors.avatarPalette.length],
                border: containerColor,
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: displayed.length * (size - overlap),
              child: _Avatar(
                name: '+$extra',
                size: size,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: containerColor,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.size,
    required this.color,
    required this.border,
    this.textColor,
  });

  final String name;
  final double size;
  final Color  color;
  final Color  border;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final label = name.startsWith('+') ? name : name[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.37,
        ),
      ),
    );
  }
}
