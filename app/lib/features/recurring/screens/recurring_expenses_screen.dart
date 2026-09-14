import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/auth/group_admin.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/recurring_expense.dart';
import '../../../design_system/design_system.dart';
import '../cubit/recurring_cubit.dart';
import 'edit_recurring_sheet.dart';

String? _ownerIdFor(BuildContext context, String groupId) {
  final home = context.read<HomeCubit>().state;
  if (home is HomeLoaded) {
    for (final group in home.groups) {
      if (group.id == groupId) return group.ownerId;
    }
  }
  return null;
}

List<GroupMember> _membersFor(BuildContext context, String groupId) {
  final home = context.read<HomeCubit>().state;
  if (home is HomeLoaded) {
    for (final group in home.groups) {
      if (group.id == groupId) return group.members;
    }
  }
  return const [];
}

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecurringCubit()..load(),
      child: const _RecurringView(),
    );
  }
}

class _RecurringView extends StatelessWidget {
  const _RecurringView();

  Future<void> _delete(BuildContext context, RecurringExpense item) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deleteRecurringTitle,
      body: context.l10n.deleteRecurringBody,
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final err = await context.read<RecurringCubit>().delete(item);
    if (!context.mounted || err == null) return;
    showTabbySnack(context, context.l10nError(err));
  }

  Future<void> _edit(BuildContext context, RecurringExpense item) {
    return showEditRecurringSheet(
      context: context,
      item: item,
      members: item.isPersonal
          ? const []
          : _membersFor(context, item.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recurringTitle)),
      body: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) {
          return switch (state) {
            RecurringLoading() => const TabbyLoading(),
            RecurringError(:final message) => TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<RecurringCubit>().load(),
              ),
            RecurringLoaded(:final items) when items.isEmpty => TabbyEmptyState(
                icon: Symbols.repeat_rounded,
                title: context.l10n.noRecurring,
                body: context.l10n.noRecurringHint,
              ),
            RecurringLoaded(:final items) => RefreshIndicator(
                onRefresh: () => context.read<RecurringCubit>().load(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final canManage = item.isPersonal ||
                        canManagePaidRecord(
                          userId: tokenStorage.userId,
                          ownerId: _ownerIdFor(context, item.groupId),
                          paidBy: item.paidBy,
                        );
                    return _RecurringCard(
                      item: item,
                      canManage: canManage,
                      onToggle: canManage
                          ? () async {
                              final err = await context
                                  .read<RecurringCubit>()
                                  .toggle(item);
                              if (!context.mounted || err == null) return;
                              showTabbySnack(context, context.l10nError(err));
                            }
                          : null,
                      onEdit: canManage ? () => _edit(context, item) : null,
                      onDelete: canManage ? () => _delete(context, item) : null,
                    );
                  },
                ),
              ),
          };
        },
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.canManage,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringExpense item;
  final bool canManage;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final space = context.tabbySpace;
    final tt = Theme.of(context).textTheme;
    final muted = !item.active;
    final onMuted = cs.onSurfaceVariant;

    return TabbyListCard(
      padding: EdgeInsets.fromLTRB(space.lg, space.lg, space.lg, space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabbyCategoryGlyph(
                icon: item.category.flutterIcon,
                background: muted
                    ? cs.surfaceContainerHighest
                    : context.tabbySemantic.chartColorFor(item.category),
                foreground: muted
                    ? onMuted
                    : context.tabbySemantic.onFor(
                        context.tabbySemantic.chartColorFor(item.category),
                        cs,
                      ),
                size: 48,
                iconSize: 24,
              ),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted ? onMuted : null,
                      ),
                    ),
                    SizedBox(height: space.xs),
                    Text(
                      context.categoryName(item.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: onMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: space.sm),
              ExpressiveFigure(
                value: formatMoney(context, item.amount),
                size: ExpressiveFigureSize.small,
                color: muted ? onMuted : null,
              ),
            ],
          ),
          SizedBox(height: space.md),
          Wrap(
            spacing: space.sm,
            runSpacing: space.sm,
            children: [
              ExpressiveBadge.compact(
                icon: item.isPersonal
                    ? Symbols.person_rounded
                    : Symbols.group_rounded,
                label: item.isPersonal
                    ? context.l10n.scopePersonal
                    : item.groupName,
                color: cs.surfaceContainerHighest,
                textColor: onMuted,
              ),
              ExpressiveBadge.compact(
                icon: Symbols.calendar_month_rounded,
                label: item.dayLabel(
                  context.l10n.recurringFirstOfMonth,
                  context.l10n.recurringNthOfMonth,
                ),
                color: cs.surfaceContainerHighest,
                textColor: onMuted,
              ),
            ],
          ),
          if (canManage) ...[
            SizedBox(height: space.md),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
            SizedBox(height: space.xs),
            Row(
              children: [
                Switch(
                  value: item.active,
                  onChanged: onToggle == null ? null : (_) => onToggle!(),
                ),
                const Spacer(),
                ExpressiveOverflowMenu(
                  tooltip: context.l10n.moreOptions,
                  actions: [
                    ExpressiveOverflowAction(
                      label: context.l10n.edit,
                      icon: Symbols.edit_rounded,
                      onTap: () => onEdit?.call(),
                    ),
                    ExpressiveOverflowAction(
                      label: context.l10n.delete,
                      icon: Symbols.delete_rounded,
                      danger: true,
                      onTap: () => onDelete?.call(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
