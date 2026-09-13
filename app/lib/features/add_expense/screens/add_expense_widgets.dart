part of 'add_expense_screen.dart';
// ─── Custom split section ─────────────────────────────────────────────────────

class _CustomSplitSection extends StatelessWidget {
  const _CustomSplitSection({
    required this.members,
    required this.splitCtrls,
    required this.total,
    required this.splitsTotal,
    required this.isValid,
    required this.onChanged,
  });

  final List<GroupMember> members;
  final Map<String, TextEditingController> splitCtrls;
  final double total;
  final double splitsTotal;
  final bool isValid;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final diff = (total - splitsTotal).abs();

    return ExpressiveTonalCard(
      variant: ExpressiveTonalVariant.neutral,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...members.map((m) {
              final ctrl = splitCtrls[m.user.id]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ExpressiveAvatar(
                      label: m.user.name,
                      size: 32,
                      color: cs.primaryContainer,
                      textColor: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(m.user.name, style: tt.bodyMedium),
                    ),
                    SizedBox(
                      width: 100,
                      child: TabbyAmountField(
                        controller: ctrl,
                        dense: true,
                        textAlign: TextAlign.right,
                        onChanged: (_) => onChanged(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.splitTotal, style: tt.bodySmall),
              Row(
                children: [
                  if (!isValid)
                    Text(
                      diff < 0.01
                          ? '≈ ok'
                          : '${diff > 0 ? '-' : '+'}${diff.toStringAsFixed(2)} €',
                      style: tt.bodySmall?.copyWith(
                        color: context.tabbySemantic.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${splitsTotal.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} €',
                    style: tt.bodyMedium?.copyWith(
                      color: isValid
                          ? context.tabbySemantic.success
                          : context.tabbySemantic.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category rail (une seule catégorie par dépense) ─────────────────────────

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onCreate,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _CategoryRailAdd(onTap: onCreate);
          }
          final category = categories[index];
          return _CategoryRailItem(
            category: category,
            selected: selected?.id == category.id,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _CategoryRailItem extends StatelessWidget {
  const _CategoryRailItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final color = semantic.chartColorFor(category);
    final onColor = semantic.onFor(color, cs);

    return SizedBox(
      width: 68,
      child: ExpressivePressScale(
        onTap: onTap,
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: selected ? 1 : 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                final size = 52.0 + 4.0 * t;
                return SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: ClipPath(
                      clipper: ExpressiveAccentClipper(
                        lobes: 8,
                        amplitude: 0.07 * t,
                        rotation: 0.12 * t,
                      ),
                      child: ColoredBox(
                        color: Color.lerp(cs.surfaceContainerLow, color, t)!,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Center(
                            child: category.iconWidget(
                              size: 22 + 2 * t,
                              color: Color.lerp(
                                cs.onSurfaceVariant,
                                onColor,
                                t,
                              ),
                              fill: t,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRailAdd extends StatelessWidget {
  const _CategoryRailAdd({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return SizedBox(
      width: 68,
      child: ExpressivePressScale(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Center(
                child: Material(
                  color: cs.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: shapes.radiusLarge.topLeft,
                      topRight: shapes.radiusExtraLarge.topRight,
                      bottomRight: shapes.radiusMedium.bottomRight,
                      bottomLeft: shapes.radiusExtraLarge.bottomLeft,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Symbols.add_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.newFeminine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final shapes = context.tabbyShapes;
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide.none,
        ),
      ),
      items: members
          .map((m) => DropdownMenuItem(value: m.user.id, child: Text(m.user.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Recurring tile ───────────────────────────────────────────────────────────

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: shapes.radiusLarge,
      ),
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

// ─── Create Category bottom sheet ─────────────────────────────────────────────

class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet({
    required this.onCreated,
  });

  final ValueChanged<Category> onCreated;

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'category';
  late Color _selectedColor;
  bool _loading = false;
  bool _colorInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_colorInitialized) {
      _selectedColor = context.tabbySemantic.categoryPalette.first;
      _colorInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
      '${c.g.round().toRadixString(16).padLeft(2, '0')}'
      '${c.b.round().toRadixString(16).padLeft(2, '0')}';

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final cat = await context.read<AddExpenseCubit>().createCategory(
          name: name,
          icon: _selectedIcon,
          color: _colorToHex(_selectedColor),
        );
    if (mounted) {
      setState(() => _loading = false);
      if (cat != null) {
        widget.onCreated(cat);
        Navigator.of(context).pop();
      } else {
        showTabbySnack(context, context.l10n.errorCreate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    final palette = semantic.categoryPalette;
    final onSelected = semantic.onFor(_selectedColor, cs);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpressiveSheetHeader(
            title: context.l10n.newCategory,
            subtitle: context.l10n.categoryNamePrivacyHint,
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: shapes.radiusLarge,
                ),
                child: Center(
                  child: Icon(
                    CategoryIcons.resolve(_selectedIcon),
                    size: 26,
                    color: onSelected,
                    fill: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: context.l10n.name),
                  autofocus: true,
                ),
              ),
            ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpressiveSheetSection(
              label: context.l10n.icon,
              child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CategoryIcons.all.map((entry) {
              final id = entry.$1;
              final icon = entry.$2;
              final isSelected = id == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor
                        : cs.surfaceContainerLow,
                    borderRadius: shapes.radiusMedium,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? onSelected : cs.onSurfaceVariant,
                    fill: isSelected ? 1 : 0,
                  ),
                ),
              );
            }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpressiveSheetSection(
              label: context.l10n.color,
              child: Wrap(
                spacing: 10,
                children: palette.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Material(
                      color: color,
                      shape: shapes.circle(),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: isSelected
                            ? Icon(Symbols.check_rounded,
                                color: semantic.onFor(color, cs), size: 18)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ExpressiveSheetSubmit(
              label: context.l10n.createCategory,
              loading: _loading,
              onPressed: _submit,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
