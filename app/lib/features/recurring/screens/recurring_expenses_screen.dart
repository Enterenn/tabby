import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/recurring_expense.dart';
import '../../../design_system/design_system.dart';
import '../cubit/recurring_cubit.dart';

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
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _RecurringCard(
                    item: items[i],
                    onToggle: () async {
                      final err =
                          await context.read<RecurringCubit>().toggle(items[i]);
                      if (!context.mounted || err == null) return;
                      showTabbySnack(context, context.l10nError(err));
                    },
                    onDelete: () => _delete(context, items[i]),
                  ),
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
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringExpense item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return TabbyListCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          TabbyCategoryGlyph(
            icon: item.category.flutterIcon,
            background: item.active
                ? context.tabbySemantic.chartColorFor(item.category)
                : cs.surfaceContainerHighest,
            foreground: item.active
                ? context.tabbySemantic.onFor(
                    context.tabbySemantic.chartColorFor(item.category),
                    cs,
                  )
                : cs.onSurfaceVariant,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: tt.titleMedium?.copyWith(
                    color: item.active ? null : cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    ExpressiveFigure(
                      value: item.amount.toStringAsFixed(2),
                      suffix: ' €',
                      size: ExpressiveFigureSize.small,
                      color: item.active ? cs.secondary : cs.onSurfaceVariant,
                    ),
                    Text(
                      ' · ${item.dayLabel(context.l10n.recurringFirstOfMonth, context.l10n.recurringNthOfMonth)}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                Text(
                  item.groupName,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: item.active,
                onChanged: (_) => onToggle(),
              ),
              IconButton(
                icon: Icon(Symbols.delete_rounded, size: 20, color: cs.error),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
