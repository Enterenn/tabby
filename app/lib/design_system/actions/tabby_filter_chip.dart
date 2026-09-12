import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Chip de filtre — [FilterChip] natif, `primaryContainer` à la sélection.
class TabbyFilterChip extends StatelessWidget {
  const TabbyFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      checkmarkColor: cs.onPrimaryContainer,
      selectedColor: cs.primaryContainer,
      backgroundColor: cs.surfaceContainerLow,
      labelStyle: TextStyle(
        color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide.none,
      onSelected: (_) => onSelected(),
    );
  }
}
