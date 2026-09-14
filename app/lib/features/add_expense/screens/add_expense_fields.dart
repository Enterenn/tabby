part of 'add_expense_screen.dart';

class _ExpenseKindSelector extends StatelessWidget {
  const _ExpenseKindSelector({required this.forMe, required this.onChanged});

  final bool forMe;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpressiveButtonGroup<bool>(
      value: forMe,
      onChanged: onChanged,
      segments: [
        ExpressiveButtonGroupSegment(
          value: false,
          label: context.l10n.expenseShared,
        ),
        ExpressiveButtonGroupSegment(
          value: true,
          label: context.l10n.expenseForMe,
        ),
      ],
    );
  }
}

class _ExpenseAmountCard extends StatelessWidget {
  const _ExpenseAmountCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final type = context.tabbyType;

    return ExpressiveTonalCard(
      variant: ExpressiveTonalVariant.lime,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: IntrinsicWidth(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.end,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  cursorColor: cs.onTertiaryContainer,
                  style: type.figureHero.copyWith(
                    color: cs.onTertiaryContainer,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  decoration: InputDecoration(
                    filled: false,
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: '0,00',
                    hintStyle: type.figureHero.copyWith(
                      color: cs.onTertiaryContainer.withValues(alpha: 0.34),
                    ),
                    errorStyle: const TextStyle(fontSize: 0, height: 0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.required;
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return context.l10n.invalid;
                    }
                    return null;
                  },
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => Text(
                ' €',
                style: type.figureMedium.copyWith(
                  color: cs.onTertiaryContainer.withValues(
                    alpha: value.text.isEmpty ? 0.34 : 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseGroupField extends StatelessWidget {
  const _ExpenseGroupField({required this.ready, required this.onSelected});

  final AddExpenseReady ready;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return ExpressiveSheetSection(
      label: context.l10n.group,
      child: ready.groups.isEmpty
          ? Text(
              context.l10n.createGroupFirst,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          : ready.groupLocked && ready.group != null
          ? InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Symbols.lock_rounded, size: 18),
              ),
              child: Text(ready.group!.name, style: tt.bodyLarge),
            )
          : ExpressiveDropdown<String>(
              selected: ready.group?.id,
              hintText: context.l10n.chooseGroup,
              leadingIcon: Icon(
                Symbols.group_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              entries: [
                for (final group in ready.groups)
                  ExpressiveDropdownEntry(value: group.id, label: group.name),
              ],
              onSelected: onSelected,
            ),
    );
  }
}
