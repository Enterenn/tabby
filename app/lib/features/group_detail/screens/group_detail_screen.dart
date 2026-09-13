import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/auth/group_admin.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/add_expense/screens/add_expense_screen.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../group_invite.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/group.dart';
import '../cubit/group_detail_cubit.dart';

part 'group_detail_widgets.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => GroupDetailCubit(
        groupId,
        ctx.read<HomeCubit>(),
      )..load(),
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
          showTabbySnack(
            context,
            context.l10nError(state.message),
            actionLabel: context.l10n.retry,
            onAction: () => context.read<GroupDetailCubit>().load(),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          GroupDetailLoading() || GroupDetailInitial() => const Scaffold(
            body: TabbyLoading(),
          ),
          GroupDetailLoaded(:final group, :final balances, :final expenses) =>
            _LoadedBody(group: group, balances: balances, expenses: expenses),
          GroupDetailError(:final message) => Scaffold(
            body: TabbyErrorState(
              message: context.l10nError(message),
              retryLabel: context.l10n.retry,
              onRetry: () => context.read<GroupDetailCubit>().load(),
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
                  child: _TotalHero(expenses: expenses, currentUserId: me),
                ),
              SliverToBoxAdapter(
                child: _GroupDetailSheet(
                  group: group,
                  expenses: expenses,
                  balances: balances,
                  currentUserId: me,
                ),
              ),
              // ── 3. À régler ──────────────────────────────────────────────────
              if (balances.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.toSettle,
                  icon: Symbols.payments_rounded,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: balances.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _BalanceTile(entry: balances[i], currentUserId: me),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          ExpressiveScreenFabMenu(
            actions: [
              ExpressiveFabMenuAction(
                icon: Symbols.receipt_long_rounded,
                label: context.l10n.addExpense,
                onSelected: () async {
                  await showAddExpenseSheet(context, groupId: group.id);
                  if (context.mounted) {
                    context.read<GroupDetailCubit>().load();
                  }
                },
              ),
              ExpressiveFabMenuAction(
                icon: Symbols.person_add_rounded,
                label: context.l10n.inviteSomeone,
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
      title: Row(
        children: [
          Flexible(
            child: Text(
              group.name,
              style: tt.headlineSmall?.copyWith(color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (group.isPinned) ...[
            const SizedBox(width: 8),
            Icon(
              Symbols.push_pin_rounded,
              size: 18,
              fill: 1,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.more_vert_rounded),
          tooltip: context.l10n.groupOptions,
          onPressed: () => _showGroupActions(context),
        ),
      ],
    );
  }

  void _showGroupActions(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final group = (cubit.state as GroupDetailLoaded).group;

    showTabbyActionSheet(
      context,
      actions: [
        TabbyActionSheetItem(
          icon: group.isPinned
              ? Symbols.keep_off_rounded
              : Symbols.push_pin_rounded,
          label: group.isPinned
              ? context.l10n.unpinGroup
              : context.l10n.pinGroup,
          onTap: () async {
            final err = await cubit.setPinned(!group.isPinned);
            if (err != null && context.mounted) {
              showTabbySnack(context, context.l10nError(err));
            }
          },
        ),
        if (isGroupAdmin(userId: tokenStorage.userId, ownerId: group.ownerId))
          TabbyActionSheetItem(
            icon: Symbols.edit_rounded,
            label: context.l10n.editName,
            onTap: () => _showEditNameDialog(context, group),
          ),
        const TabbyActionSheetItem.divider(),
        TabbyActionSheetItem(
          icon: Symbols.exit_to_app_rounded,
          label: context.l10n.leaveGroup,
          danger: true,
          onTap: () => _confirmLeave(context),
        ),
        if (tokenStorage.userId != null && tokenStorage.userId == group.ownerId)
          TabbyActionSheetItem(
            icon: Symbols.delete_rounded,
            label: context.l10n.deleteGroup,
            danger: true,
            onTap: () => _confirmDelete(context),
          ),
      ],
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, Group group) async {
    final ctrl = TextEditingController(text: group.name);
    await showTabbyFormDialog<void>(
      context: context,
      builder: (ctx) => TabbyFormDialog(
        title: ctx.l10n.editName,
        submitLabel: ctx.l10n.save,
        cancelLabel: ctx.l10n.cancel,
        onSubmit: () async {
          final name = ctrl.text.trim();
          if (name.isEmpty) return;
          Navigator.pop(ctx);
          final err = await context.read<GroupDetailCubit>().updateName(name);
          if (!context.mounted || err == null) return;
          showTabbySnack(context, context.l10nError(err));
        },
        child: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.l10n.groupName),
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showTabbyConfirm(
      context,
      title: context.l10n.leaveGroup,
      body: context.l10n.leaveGroupBody,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.leave,
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final err = await context.read<GroupDetailCubit>().leaveGroup();
    if (err != null && context.mounted) {
      showTabbySnack(context, context.l10nError(err));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showTabbyConfirm(
      context,
      title: context.l10n.deleteGroup,
      body: context.l10n.deleteGroupBody,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final err = await context.read<GroupDetailCubit>().deleteGroup();
    if (err != null && context.mounted) {
      showTabbySnack(context, context.l10nError(err));
    }
  }
}

