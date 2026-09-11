import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/add_expense/screens/add_expense_screen.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../group_invite.dart';
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
          // pop() résout la Future de context.push() dans GroupCard → loadGroups() est appelé
          context.pop();
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
    final tt = Theme.of(context).textTheme;
    final me = tokenStorage.userId ?? '';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _GroupSliverAppBar(group: group),
          // Total des dépenses — hero display
          if (expenses.isNotEmpty)
            SliverToBoxAdapter(
              child: _TotalHero(expenses: expenses),
            ),
          // ── 1. Dépenses ──────────────────────────────────────────────────
          _SectionHeader(
            title: expenses.isEmpty
                ? 'Dépenses'
                : 'Dépenses (${expenses.length})',
            icon: Symbols.receipt_long_rounded,
          ),
          if (expenses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Text(
                    'Aucune dépense pour ce groupe.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) =>
                    _ExpenseTile(expense: expenses[i], currentUserId: me),
              ),
            ),
          // ── 2. Membres ───────────────────────────────────────────────────
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
          // ── 3. À régler ──────────────────────────────────────────────────
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
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
          ExpressiveScreenFabMenu(
            actions: [
              ExpressiveFabMenuAction(
                icon: Symbols.receipt_long_rounded,
                label: 'Ajouter une dépense',
                onSelected: () async {
                  await showAddExpenseSheet(context, groupId: group.id);
                  if (context.mounted) {
                    context.read<GroupDetailCubit>().load();
                  }
                },
              ),
              ExpressiveFabMenuAction(
                icon: Symbols.person_add_rounded,
                label: 'Inviter quelqu\'un',
                onSelected: () =>
                    showGroupInviteDialog(context, groupId: group.id),
              ),
            ],
          ),
        ],
      ),
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
      backgroundColor: cs.surfaceContainerLow,
      foregroundColor: cs.onSurface,
      title: Text(
        group.name,
        style: tt.headlineSmall?.copyWith(color: cs.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.more_vert_rounded),
          tooltip: 'Options du groupe',
          onPressed: () => _showGroupActions(context),
        ),
      ],
    );
  }

  void _showGroupActions(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final state = cubit.state as GroupDetailLoaded;

    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        // pageContext = contexte de la page (toujours vivant après la fermeture du sheet)
        child: _GroupActionsSheet(group: state.group, pageContext: context),
      ),
    );
  }
}

// ─── Actions bottom sheet ─────────────────────────────────────────────────────

class _GroupActionsSheet extends StatelessWidget {
  const _GroupActionsSheet({required this.group, required this.pageContext});
  final Group group;
  /// Contexte de la page parente — reste valide après la fermeture du sheet.
  final BuildContext pageContext;

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
              borderRadius: context.tabbyShapes.radiusExtraSmall,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Symbols.edit_rounded),
            title: const Text('Modifier le nom'),
            onTap: () {
              Navigator.pop(context);
              _showEditNameDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Symbols.exit_to_app_rounded, color: cs.error),
            title: Text('Quitter le groupe', style: TextStyle(color: cs.error)),
            onTap: () {
              Navigator.pop(context);
              _confirmLeave();
            },
          ),
          ListTile(
            leading: Icon(Symbols.delete_rounded, color: cs.error),
            title: Text('Supprimer le groupe', style: TextStyle(color: cs.error)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: group.name);
    showDialog(
      context: pageContext,
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
              pageContext.read<GroupDetailCubit>().updateName(name);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: pageContext,
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
              final err = await pageContext.read<GroupDetailCubit>().leaveGroup();
              if (!pageContext.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(pageContext)
                    .showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: pageContext,
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
              final err = await pageContext.read<GroupDetailCubit>().deleteGroup();
              if (!pageContext.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(pageContext)
                    .showSnackBar(SnackBar(content: Text(err)));
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
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
            ExpressiveAvatar(label: entry.fromUserName, size: 36),
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
                  ExpressiveFigure(
                    value: entry.amount.toStringAsFixed(2),
                    suffix: ' €',
                    size: ExpressiveFigureSize.small,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
            if (isMine)
              FilledButton.tonal(
                // Override nécessaire : le thème global force minimumSize à double.infinity
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
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

    final semantic = context.tabbySemantic;
    Color balColor;
    String balLabel;
    if (balance > 0.01) {
      balColor = semantic.success;
      balLabel = '+${balance.toStringAsFixed(2)} €';
    } else if (balance < -0.01) {
      balColor = semantic.danger;
      balLabel = '${balance.toStringAsFixed(2)} €';
    } else {
      balColor = cs.onSurfaceVariant;
      balLabel = 'Soldé';
    }

    return Card(
      color: cs.surfaceContainerHighest,
      child: ListTile(
        leading: ExpressiveAvatar(label: member.user.name, size: 40),
        title: Row(
          children: [
            Text(member.user.name, style: tt.titleSmall),
            if (isMe) ...[
              const SizedBox(width: 6),
              ExpressiveBadge(
                label: 'Moi',
                color: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          style: tt.titleMedium?.copyWith(
            color: balColor,
          ),
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
        borderRadius: context.tabbyShapes.radiusExtraLarge,
        onLongPress: () => _showExpenseActions(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icône / emoji catégorie
              Material(
                color: expense.category.flutterColor.withValues(alpha: 0.12),
                shape: context.tabbyShapes.circle(),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: expense.category.iconWidget(
                      size: 22,
                      color: expense.category.flutterColor,
                    ),
                  ),
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
              ExpressiveFigure(
                value: expense.amount.toStringAsFixed(2),
                suffix: ' €',
                size: ExpressiveFigureSize.small,
                color: isPaidByMe
                    ? context.tabbySemantic.success
                    : cs.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<GroupDetailCubit>();
    final state = cubit.state as GroupDetailLoaded;

    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Symbols.edit_rounded),
                title: const Text('Modifier la dépense'),
                subtitle: Text(expense.name),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, state, cubit);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Symbols.delete_rounded, color: cs.error),
                title: Text('Supprimer', style: TextStyle(color: cs.error)),
                subtitle: Text(expense.name),
                onTap: () async {
                  Navigator.pop(context);
                  final err = await cubit.deleteExpense(expense.id);
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

  void _showEditDialog(
      BuildContext context, GroupDetailLoaded state, GroupDetailCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => _EditExpenseDialog(
        expense: expense,
        members: state.group.members,
        cubit: cubit,
      ),
    );
  }

}

// ─── Total card ───────────────────────────────────────────────────────────────

// Remplace l'ancienne mini card par un hero stat expressif
class _TotalHero extends StatelessWidget {
  const _TotalHero({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final count = expenses.length;

    return ExpressiveHeroBanner(
      label: 'Total dépenses',
      value: total.toStringAsFixed(2),
      suffix: ' €',
      subtitle: '$count dépense${count > 1 ? 's' : ''}',
      variant: ExpressiveTonalVariant.coral,
      accentIcon: Symbols.receipt_long_rounded,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    );
  }
}

// ─── Edit expense dialog ──────────────────────────────────────────────────────

class _EditExpenseDialog extends StatefulWidget {
  const _EditExpenseDialog({
    required this.expense,
    required this.members,
    required this.cubit,
  });
  final Expense expense;
  final List<GroupMember> members;
  final GroupDetailCubit cubit;

  @override
  State<_EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<_EditExpenseDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late String _paidBy;
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.expense.name);
    _amountCtrl = TextEditingController(
        text: widget.expense.amount.toStringAsFixed(2));
    _paidBy = widget.expense.paidBy;
    _date = widget.expense.expenseDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final dateLabel =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return AlertDialog(
      title: const Text('Modifier la dépense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 12),
            Text('Payé par', style: tt.labelMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _paidBy,
              decoration: const InputDecoration(),
              items: widget.members
                  .map((m) => DropdownMenuItem(
                        value: m.user.id,
                        child: Text(m.user.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v ?? _paidBy),
            ),
            const SizedBox(height: 12),
            Text('Date', style: tt.labelMedium),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: context.tabbyShapes.radiusMedium,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: context.tabbyShapes.radiusMedium,
                ),
                child: Row(
                  children: [
                    Icon(Symbols.calendar_month_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(dateLabel, style: tt.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) return;

    setState(() => _loading = true);
    final err = await widget.cubit.updateExpense(
      expenseId: widget.expense.id,
      name: name,
      amount: amount,
      paidBy: _paidBy,
      expenseDate: _date,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pop(context);
    }
  }
}

