import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import '../../shared/models/category.dart';

/// Sélecteur de catégorie — [DropdownMenu] M3 (pas [DropdownButtonFormField]).
class TabbyCategoryDropdown extends StatelessWidget {
  const TabbyCategoryDropdown({
    super.key,
    required this.categories,
    required this.onSelected,
    this.selected,
    this.label,
    this.hint,
    this.enabled = true,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category?> onSelected;
  final String? label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (selected != null && !categories.any((c) => c.id == selected!.id))
        selected!,
      ...categories,
    ];

    return DropdownMenu<Category>(
      initialSelection: selected,
      enabled: enabled,
      label: label == null ? null : Text(label!),
      hintText: hint,
      requestFocusOnTap: false,
      enableFilter: false,
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: [
        for (final c in items)
          DropdownMenuEntry<Category>(
            value: c,
            label: context.categoryName(c),
            leadingIcon: c.iconWidget(size: 18, color: c.resolvedColor),
          ),
      ],
      onSelected: onSelected,
    );
  }
}
