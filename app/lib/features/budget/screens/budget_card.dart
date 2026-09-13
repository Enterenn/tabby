part of 'budget_screen.dart';
// ─── Budget card ──────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.selected,
    required this.canManage,
  });
  final Budget budget;
  final bool selected;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    final b = budget;
    final catColor = b.category.resolvedColor;
    final onCat = b.category.onResolvedColor;
    final statusColor = b.statusColor(semantic);
    final clampedPercent = (b.percent / 100).clamp(0.0, 1.0);
    final isDanger = b.status == BudgetStatus.danger;
    final mutedColor =
        isDanger ? semantic.onDangerContainer : cs.onSurfaceVariant;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TabbyCategoryGlyph(
              icon: b.category.flutterIcon,
              background: isDanger ? semantic.danger : catColor,
              foreground: isDanger ? semantic.onDanger : onCat,
              size: 40,
              iconSize: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.categoryName(b.category),
                    style: tt.titleMedium?.copyWith(
                      color: isDanger ? semantic.onDangerContainer : null,
                    ),
                  ),
                  Text(
                    context.l10n.budgetPerMonth(
                      formatMoney(context, b.limitAmount, decimalDigits: 0),
                    ),
                    style: tt.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            ExpressiveBadge.compact(
              label: b.status == BudgetStatus.danger
                  ? context.l10n.overBudget
                  : b.status == BudgetStatus.warning
                      ? context.l10n.warning
                      : context.l10n.ok,
              color: isDanger
                  ? semantic.danger
                  : b.status == BudgetStatus.warning
                      ? semantic.warningContainer
                      : semantic.successContainer,
              textColor: isDanger
                  ? semantic.onDanger
                  : b.status == BudgetStatus.warning
                      ? semantic.onWarningContainer
                      : semantic.onSuccessContainer,
            ),
            if (canManage)
              IconButton(
                tooltip: context.l10n.budgetActions,
                icon: const Icon(Symbols.more_vert_rounded),
                onPressed: () => _showActions(context),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: shapes.radiusExtraSmall,
          child: LinearProgressIndicator(
            value: clampedPercent,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDanger ? semantic.danger : statusColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.spentAmount(formatMoney(context, b.spentAmount)),
              style: tt.bodySmall?.copyWith(
                color: isDanger ? semantic.onDangerContainer : null,
              ),
            ),
            Text(
              b.remaining >= 0
                  ? context.l10n.remainingAmount(
                      formatMoney(context, b.remaining),
                    )
                  : context.l10n.overspendAmount(
                      formatMoney(context, b.remaining.abs()),
                    ),
              style: tt.bodySmall?.copyWith(
                color: isDanger ? semantic.onDangerContainer : mutedColor,
                fontWeight: isDanger ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ],
    );

    void onConsult() =>
        context.read<BudgetCubit>().selectCategory(b.category.id);

    if (isDanger) {
      return ExpressiveTonalCard(
        variant: ExpressiveTonalVariant.danger,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
        onTap: onConsult,
        child: content,
      );
    }

    return TabbyListCard(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? catColor.withValues(alpha: 0.12) : null,
      onTap: onConsult,
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
      child: content,
    );
  }

  void _showActions(BuildContext context) {
    showTabbyActionSheet(
      context,
      title: context.categoryName(budget.category),
      actions: [
        TabbyActionSheetItem(
          label: context.l10n.editLimit,
          icon: Symbols.edit_rounded,
          onTap: () => _showEditDialog(context),
        ),
        TabbyActionSheetItem(
          label: context.l10n.delete,
          icon: Symbols.delete_rounded,
          danger: true,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showTabbyFormDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: _EditBudgetDialog(budget: budget),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deleteBudgetTitle,
      body: context.l10n.deleteBudgetBody(
        context.categoryName(budget.category),
      ),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (confirmed && context.mounted) {
      await context.read<BudgetCubit>().deleteBudget(budgetId: budget.id);
    }
  }
}

// ─── Edit budget dialog ───────────────────────────────────────────────────────

class _EditBudgetDialog extends StatefulWidget {
  const _EditBudgetDialog({required this.budget});
  final Budget budget;

  @override
  State<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<_EditBudgetDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.budget.limitAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = TabbyAmountField.parse(_ctrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().updateBudget(
          budgetId: widget.budget.id,
          limitAmount: amount,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final b = widget.budget;
    final catColor = b.category.resolvedColor;

    return TabbyFormDialog(
      title: context.l10n.editBudget,
      submitLabel: context.l10n.save,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      onSubmit: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TabbyCategoryGlyph(
                icon: b.category.flutterIcon,
                background: catColor,
                foreground: b.category.onResolvedColor,
                size: 36,
                iconSize: 20,
              ),
              const SizedBox(width: 10),
              Text(context.categoryName(b.category), style: tt.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.l10n.monthlyLimit, style: tt.labelLarge),
          const SizedBox(height: 6),
          TabbyAmountField(
            controller: _ctrl,
          ),
        ],
      ),
    );
  }
}

// ─── Create budget dialog ─────────────────────────────────────────────────────

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.state});
  final BudgetLoaded state;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  Category? _selectedCategory;
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  List<Category> get _availableCategories {
    return context.read<BudgetCubit>().availableCategories(
          budgets: widget.state.budgets,
          allCategories: widget.state.allCategories,
        );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        TabbyAmountField.parse(_amountCtrl.text);
    if (_selectedCategory == null || amount == null || amount <= 0) {
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<BudgetCubit>().createBudget(
          categoryId: _selectedCategory!.id,
          limitAmount: amount,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return TabbyFormDialog(
      title: context.l10n.newBudget,
      submitLabel: context.l10n.create,
      cancelLabel: context.l10n.cancel,
      loading: _loading,
      scrollable: true,
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabbyCategoryDropdown(
            categories: _availableCategories,
            selected: _selectedCategory,
            label: context.l10n.category,
            hint: context.l10n.chooseCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.monthlyLimit, style: tt.labelLarge),
          const SizedBox(height: 6),
          TabbyAmountField(controller: _amountCtrl),
        ],
      ),
    );
  }
}
