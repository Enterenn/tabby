import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../design_system/design_system.dart';
import '../../l10n/l10n.dart';
import '../models/category.dart';

Future<void> showCategoryEditorSheet({
  required BuildContext context,
  Category? initial,
  required Future<Category?> Function({
    required String name,
    required String icon,
    required String color,
  }) onSubmit,
}) {
  return showTabbySheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => CategoryEditorSheet(
      initial: initial,
      onSubmit: onSubmit,
    ),
  );
}

class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final Category? initial;
  final Future<Category?> Function({
    required String name,
    required String icon,
    required String color,
  }) onSubmit;

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedIcon;
  late Color _selectedColor;
  bool _loading = false;
  bool _colorInitialized = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _selectedIcon = initial != null
        ? CategoryIcons.normalize(initial.icon)
        : 'category';
    if (initial != null) {
      _selectedColor = initial.resolvedColor;
      _colorInitialized = true;
    }
  }

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

  String _colorToHex(Color c) {
    final hex = (c.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return '#$hex';
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final cat = await widget.onSubmit(
      name: name,
      icon: _selectedIcon,
      color: _colorToHex(_selectedColor),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (cat != null) {
      Navigator.of(context).pop();
    } else {
      showTabbySnack(
        context,
        _isEditing ? context.l10n.errorUpdate : context.l10n.errorCreate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final shapes = context.tabbyShapes;
    final palette = [
      if (!semantic.categoryPalette.contains(_selectedColor)) _selectedColor,
      ...semantic.categoryPalette,
    ];
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
              title: _isEditing
                  ? context.l10n.editCategory
                  : context.l10n.newCategory,
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
                              ? Icon(
                                  Symbols.check_rounded,
                                  color: semantic.onFor(color, cs),
                                  size: 18,
                                )
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
                label: _isEditing
                    ? context.l10n.save
                    : context.l10n.createCategory,
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
