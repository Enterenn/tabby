part of 'add_expense_screen.dart';

// ─── Split preview (Tricount-style include / exclude) ─────────────────────────

class _SplitParticipants extends StatelessWidget {
  const _SplitParticipants({
    required this.mode,
    required this.members,
    required this.includedIds,
    required this.amounts,
    required this.shares,
    required this.splitCtrls,
    required this.total,
    required this.splitsTotal,
    required this.isValid,
    required this.onToggle,
    required this.onSelectAll,
    required this.onSelectNone,
    required this.onModeChanged,
    required this.onShareChanged,
  });

  final ExpenseSplitMode mode;
  final List<GroupMember> members;
  final Set<String> includedIds;
  final Map<String, double> amounts;
  final Map<String, int> shares;
  final Map<String, TextEditingController> splitCtrls;
  final double total;
  final double splitsTotal;
  final bool isValid;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;
  final ValueChanged<ExpenseSplitMode> onModeChanged;
  final void Function(String userId, int value) onShareChanged;

  String _modeLabel(BuildContext context, ExpenseSplitMode value) =>
      switch (value) {
        ExpenseSplitMode.equal => context.l10n.splitEqual,
        ExpenseSplitMode.shares => context.l10n.splitShares,
        ExpenseSplitMode.amounts => context.l10n.splitCustom,
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;
    final allOn = includedIds.length == members.length && members.isNotEmpty;
    final allOff = includedIds.isEmpty;
    void toggleAll() => allOn ? onSelectNone() : onSelectAll();

    return Material(
      color: cs.surfaceContainerHigh,
      elevation: 0,
      shape: shapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: allOn
                      ? true
                      : allOff
                      ? false
                      : null,
                  onChanged: (_) => toggleAll(),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: toggleAll,
                    child: Text(
                      context.l10n.split,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _SplitModeButton(
                  mode: mode,
                  label: _modeLabel(context, mode),
                  onChanged: onModeChanged,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
          ...members.asMap().entries.expand((entry) {
            final index = entry.key;
            final m = entry.value;
            final id = m.user.id;
            final included = includedIds.contains(id);
            final amount = mode == ExpenseSplitMode.amounts
                ? (double.tryParse(
                        splitCtrls[id]?.text.replaceAll(',', '.') ?? '',
                      ) ??
                      0)
                : (amounts[id] ?? 0);
            final count = shares[id] ?? 0;
            final amountCtrl = splitCtrls[id];

            return [
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              InkWell(
                onTap: () => onToggle(id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                  child: Row(
                    children: [
                      IgnorePointer(
                        child: Checkbox(
                          value: included,
                          onChanged: (_) {},
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ExpressiveAvatar(
                        label: m.user.name,
                        size: 32,
                        color: included
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        textColor: included
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.user.name,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: included
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: included
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (mode == ExpenseSplitMode.shares && included) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: count <= 1
                              ? null
                              : () => onShareChanged(id, count - 1),
                          icon: const Icon(Symbols.remove_rounded, size: 20),
                        ),
                        Text('$count', style: tt.titleMedium),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: count >= 99
                              ? null
                              : () => onShareChanged(id, count + 1),
                          icon: const Icon(Symbols.add_rounded, size: 20),
                        ),
                      ],
                      if (mode == ExpenseSplitMode.amounts &&
                          included &&
                          amountCtrl != null)
                        SizedBox(
                          width: 100,
                          child: TabbyAmountField(
                            controller: amountCtrl,
                            dense: true,
                            textAlign: TextAlign.right,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        )
                      else
                        _SplitAmountChip(amount: amount, emphasized: included),
                    ],
                  ),
                ),
              ),
            ];
          }),
          if (mode == ExpenseSplitMode.amounts) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.splitTotal, style: tt.bodySmall),
                  Text(
                    '${formatMoney(context, splitsTotal)} / ${formatMoney(context, total)}',
                    style: tt.bodyMedium?.copyWith(
                      color: isValid
                          ? context.tabbySemantic.success
                          : context.tabbySemantic.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitModeButton extends StatelessWidget {
  const _SplitModeButton({
    required this.mode,
    required this.label,
    required this.onChanged,
  });

  final ExpenseSplitMode mode;
  final String label;
  final ValueChanged<ExpenseSplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return MenuAnchor(
      animated: true,
      consumeOutsideTap: true,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerLow),
        surfaceTintColor: WidgetStatePropertyAll(cs.surfaceContainerLow),
        shape: WidgetStatePropertyAll(context.tabbyShapes.cardShape),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      builder: (context, controller, _) {
        return Material(
          color: cs.tertiaryContainer,
          shape: context.tabbyShapes.pill(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: tt.labelLarge?.copyWith(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Symbols.arrow_drop_down_rounded,
                    color: cs.onTertiaryContainer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        for (final value in ExpenseSplitMode.values)
          Material(
            type: MaterialType.transparency,
            child: MenuItemButton(
              onPressed: () => onChanged(value),
              trailingIcon: value == mode
                  ? const Icon(Symbols.check_rounded, size: 18)
                  : null,
              child: Text(switch (value) {
                ExpenseSplitMode.equal => context.l10n.splitEqual,
                ExpenseSplitMode.shares => context.l10n.splitShares,
                ExpenseSplitMode.amounts => context.l10n.splitCustom,
              }),
            ),
          ),
      ],
    );
  }
}

class _SplitAmountChip extends StatelessWidget {
  const _SplitAmountChip({required this.amount, required this.emphasized});

  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: emphasized ? cs.primaryContainer : cs.surfaceContainerHigh,
      shape: context.tabbyShapes.pill(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          formatMoney(context, amount),
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: emphasized ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
