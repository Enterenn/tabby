part of 'add_expense_screen.dart';
// ─── PayerDropdown ────────────────────────────────────────────────────────────

class _PayerDropdown extends StatelessWidget {
  const _PayerDropdown({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  final List<GroupMember> members;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    return ExpressiveDropdown<String>(
      selected: selectedId,
      dense: true,
      leadingIcon: Icon(
        Symbols.person_rounded,
        size: 20,
        color: cs.onSurfaceVariant,
      ),
      entries: [
        for (final m in members)
          ExpressiveDropdownEntry(value: m.user.id, label: m.user.name),
      ],
      onSelected: onChanged,
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.value,
    required this.expenseDate,
    required this.onChanged,
  });

  final bool value;
  final DateTime expenseDate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;

    return Material(
      color: value ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: shapes.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: shapes.radiusLarge),
        secondary: Icon(
          Symbols.repeat_rounded,
          color: value ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          fill: value ? 1 : 0,
        ),
        title: Text(context.l10n.repeatMonthly),
        subtitle: value
            ? Text(
                context.l10n.repeatOnDay(expenseDate.day),
                style: tt.bodySmall?.copyWith(color: cs.primary),
              )
            : null,
      ),
    );
  }
}
