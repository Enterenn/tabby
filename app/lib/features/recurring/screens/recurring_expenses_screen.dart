import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/recurring_expense.dart';
import '../../../shared/widgets/expressive/expressive.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() =>
      _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  List<RecurringExpense>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final resp = await apiClient.dio.get('/recurring-expenses');
      setState(() {
        _items = (resp.data as List)
            .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _toggle(RecurringExpense item) async {
    try {
      final resp = await apiClient.dio.patch(
        '/groups/${item.groupId}/recurring-expenses/${item.id}/toggle',
      );
      final updated = RecurringExpense.fromJson(
          resp.data as Map<String, dynamic>);
      setState(() {
        final idx = _items!.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items![idx] = updated;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorUpdate)),
        );
      }
    }
  }

  Future<void> _delete(RecurringExpense item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteRecurringTitle),
        content: Text(ctx.l10n.deleteRecurringBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.l10n.delete,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.dio.delete(
        '/groups/${item.groupId}/recurring-expenses/${item.id}',
      );
      setState(() => _items!.removeWhere((e) => e.id == item.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorDelete)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recurringTitle)),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10nError(_error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                      onPressed: _load, child: Text(context.l10n.retry)),
                ],
              ),
            )
          : _items == null
              ? const Center(child: CircularProgressIndicator())
              : _items!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.repeat_rounded,
                              size: 56, color: cs.outlineVariant),
                          const SizedBox(height: 16),
                          Text(context.l10n.noRecurring,
                              style: tt.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.noRecurringHint,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items!.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _RecurringCard(
                          item: _items![i],
                          onToggle: () => _toggle(_items![i]),
                          onDelete: () => _delete(_items![i]),
                        ),
                      ),
                    ),
    );
  }
}

// ─── Card item ────────────────────────────────────────────────────────────────

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
    final shapes = context.tabbyShapes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            // Icône catégorie
            Material(
              color: item.active
                  ? context.tabbySemantic.chartColorFor(item.category)
                  : cs.surfaceContainerHighest,
              shape: shapes.circle(),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  item.category.flutterIcon,
                  color: item.active
                      ? context.tabbySemantic.onFor(
                          context.tabbySemantic.chartColorFor(item.category),
                          cs,
                        )
                      : cs.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Infos
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
                        color: item.active
                            ? cs.secondary
                            : cs.onSurfaceVariant,
                      ),
                      Text(
                        ' · ${item.dayLabel(context.l10n.recurringFirstOfMonth, context.l10n.recurringNthOfMonth)}',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Text(
                    item.groupName,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: item.active,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(
                  icon: Icon(Symbols.delete_rounded,
                      size: 20, color: cs.error),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
