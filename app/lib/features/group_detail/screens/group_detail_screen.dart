import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/token_storage.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';
import '../cubit/group_detail_cubit.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupDetailCubit(groupId)..load(),
      child: const _GroupDetailView(),
    );
  }
}

class _GroupDetailView extends StatelessWidget {
  const _GroupDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailCubit, GroupDetailState>(
      listener: (context, state) {
        if (state is GroupDetailLeft) {
          context.go('/home');
        }
        if (state is GroupDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              action: SnackBarAction(
                label: 'Réessayer',
                onPressed: () => context.read<GroupDetailCubit>().load(),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          GroupDetailLoading() || GroupDetailInitial() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          GroupDetailLoaded(:final group, :final balances, :final expenses) =>
            _LoadedBody(group: group, balances: balances, expenses: expenses),
          GroupDetailError(:final message) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.error_outline_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<GroupDetailCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

// ─── Loaded Body ─────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.group,
    required this.balances,
    required this.expenses,
  });

  final Group group;
  final List<BalanceEntry> balances;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = tokenStorage.userId ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _GroupSliverAppBar(group: group),
          // Balances (qui doit à qui)
          if (balances.isNotEmpty) ...[
            _SectionHeader(title: 'À régler', icon: Symbols.payments_rounded),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: balances.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) =>
                    _BalanceTile(entry: balances[i], currentUserId: me),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
          // Membres
          _SectionHeader(title: 'Membres', icon: Symbols.group_rounded),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: group.members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _MemberTile(
                member: group.members[i],
                balances: balances,
                currentUserId: me,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: OutlinedButton.icon(
                onPressed: () => _showInviteDialog(context),
                icon: const Icon(Symbols.person_add_rounded),
                label: const Text('Inviter quelqu\'un'),
              ),
            ),
          ),
          // Dépenses
          if (expenses.isNotEmpty) ...[
            _SectionHeader(
                title: 'Dépenses (${expenses.length})',
                icon: Symbols.receipt_long_rounded),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) =>
                    _ExpenseTile(expense: expenses[i], currentUserId: me),
              ),
            ),
          ] else ...[
            _SectionHeader(
                title: 'Dépenses', icon: Symbols.receipt_long_rounded),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Text(
                    'Aucune dépense pour ce groupe.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final cubit = context.read<GroupDetailCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    final code = await cubit.generateInviteCode();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // ferme le loading
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de générer un code.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _InviteDialog(code: code),
    );
  }
}

// ─── SliverAppBar ─────────────────────────────────────────────────────────────

class _GroupSliverAppBar extends StatelessWidget {
  const _GroupSliverAppBar({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      backgroundColor: cs.surfaceContainerLow,
      foregroundColor: cs.onSurface,
      actions: [
        IconButton(
          icon: const Icon(Symbols.more_vert_rounded),
          tooltip: 'Options du groupe',
          onPressed: () => _showGroupActions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 56, 16),
        title: Text(
          group.name,
          style: tt.headlineSmall?.copyWith(color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 48),
          child: Row(
            children: [
              ...group.members.take(5).map((m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _Avatar(name: m.user.name, radius: 16),
                  )),
              if (group.members.length > 5)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Text(
                    '+${group.members.length - 5}',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupActions(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final state = cubit.state as GroupDetailLoaded;

    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _GroupActionsSheet(group: state.group),
      ),
    );
  }
}

// ─── Actions bottom sheet ─────────────────────────────────────────────────────

class _GroupActionsSheet extends StatelessWidget {
  const _GroupActionsSheet({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Symbols.edit_rounded),
            title: const Text('Modifier le nom'),
            onTap: () {
              Navigator.pop(context);
              _showEditNameDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Symbols.exit_to_app_rounded, color: cs.error),
            title: Text('Quitter le groupe',
                style: TextStyle(color: cs.error)),
            onTap: () {
              Navigator.pop(context);
              _confirmLeave(context);
            },
          ),
          ListTile(
            leading: Icon(Symbols.delete_rounded, color: cs.error),
            title: Text('Supprimer le groupe',
                style: TextStyle(color: cs.error)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom du groupe'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              context.read<GroupDetailCubit>().updateName(name);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le groupe'),
        content: const Text(
            'Vous ne pourrez plus accéder à ce groupe. Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final err =
                  await context.read<GroupDetailCubit>().leaveGroup();
              if (!context.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              }
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: const Text(
            'Toutes les dépenses seront supprimées. Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final err =
                  await context.read<GroupDetailCubit>().deleteGroup();
              if (!context.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(title,
                style: tt.titleMedium?.copyWith(color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

// ─── Balance tile ─────────────────────────────────────────────────────────────

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.entry, required this.currentUserId});
  final BalanceEntry entry;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isMine =
        entry.fromUserId == currentUserId || entry.toUserId == currentUserId;

    return Card(
      color: isMine
          ? cs.primaryContainer.withValues(alpha: 0.4)
          : cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Avatar(name: entry.fromUserName, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      children: [
                        TextSpan(
                          text: entry.fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' doit à '),
                        TextSpan(
                          text: entry.toUserName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.amount.toStringAsFixed(2)} €',
                    style: tt.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (isMine)
              FilledButton.tonal(
                onPressed: () => _confirmSettle(context),
                child: const Text('Régler'),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmSettle(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le remboursement'),
        content: Text(
          '${entry.fromUserName} rembourse ${entry.amount.toStringAsFixed(2)} € à ${entry.toUserName}.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await context.read<GroupDetailCubit>().settle(
                    fromUserId: entry.fromUserId,
                    toUserId: entry.toUserId,
                    amount: entry.amount,
                  );
              if (!context.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remboursement enregistré ✓')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

// ─── Member tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.balances,
    required this.currentUserId,
  });
  final GroupMember member;
  final List<BalanceEntry> balances;
  final String currentUserId;

  double get _memberBalance {
    double b = 0;
    for (final e in balances) {
      if (e.toUserId == member.user.id) b += e.amount;
      if (e.fromUserId == member.user.id) b -= e.amount;
    }
    return b;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final balance = _memberBalance;
    final isMe = member.user.id == currentUserId;

    Color balColor;
    String balLabel;
    if (balance > 0.01) {
      balColor = const Color(0xFF4C9A6A);
      balLabel = '+${balance.toStringAsFixed(2)} €';
    } else if (balance < -0.01) {
      balColor = const Color(0xFFE4573D);
      balLabel = '${balance.toStringAsFixed(2)} €';
    } else {
      balColor = cs.onSurfaceVariant;
      balLabel = 'Soldé';
    }

    return Card(
      color: cs.surfaceContainerHighest,
      child: ListTile(
        leading: _Avatar(name: member.user.name, radius: 20),
        title: Row(
          children: [
            Text(member.user.name, style: tt.titleSmall),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Moi',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onPrimaryContainer)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          'Rejoint le ${DateFormat('d MMM yyyy', 'fr_FR').format(member.joinedAt)}',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Text(
          balLabel,
          style: tt.labelLarge?.copyWith(
              color: balColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Expense tile ─────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.currentUserId});
  final Expense expense;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPaidByMe = expense.paidBy == currentUserId;

    return Card(
      color: cs.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () => _showExpenseActions(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icône catégorie
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconData(expense.category.icon),
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.name,
                        style: tt.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${isPaidByMe ? 'Payé par vous' : 'Payé par ${expense.paidByName}'} · ${DateFormat('d MMM', 'fr_FR').format(expense.expenseDate)}',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '${expense.amount.toStringAsFixed(2)} €',
                style: tt.titleSmall?.copyWith(
                  color: isPaidByMe ? const Color(0xFF4C9A6A) : cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<GroupDetailCubit>(),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Symbols.delete_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Supprimer la dépense',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                subtitle: Text(expense.name),
                onTap: () async {
                  Navigator.pop(context);
                  final err = await context
                      .read<GroupDetailCubit>()
                      .deleteExpense(expense.id);
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconData(String? iconName) {
    return switch (iconName) {
      'restaurant' => Symbols.restaurant_rounded,
      'home' => Symbols.home_rounded,
      'directions_car' => Symbols.directions_car_rounded,
      'local_grocery_store' => Symbols.local_grocery_store_rounded,
      'sports_esports' => Symbols.sports_esports_rounded,
      'flight' => Symbols.flight_rounded,
      'local_hospital' => Symbols.local_hospital_rounded,
      'shopping_bag' => Symbols.shopping_bag_rounded,
      'payments' => Symbols.payments_rounded,
      _ => Symbols.receipt_long_rounded,
    };
  }
}

// ─── Invite dialog ────────────────────────────────────────────────────────────

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Code d\'invitation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Partagez ce code avec la personne à inviter.'),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copié !')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: tt.displaySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Symbols.content_copy_rounded,
                      color: cs.onPrimaryContainer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Valable 24h',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

// ─── Avatar helper ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.radius});
  final String name;
  final double radius;

  static const _colors = [
    Color(0xFFE67E22),
    Color(0xFF27AE60),
    Color(0xFF2980B9),
    Color(0xFF8E44AD),
    Color(0xFF16A085),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % _colors.length : 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: _colors[idx],
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
