import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';

class ExpressiveDropdownEntry<T> {
  const ExpressiveDropdownEntry({
    required this.value,
    required this.label,
    this.leading,
  });

  final T value;
  final String label;
  final Widget? leading;
}

/// Sélecteur M3 — champ rempli + menu [MenuAnchor] animé (fade / hauteur).
class ExpressiveDropdown<T> extends StatelessWidget {
  const ExpressiveDropdown({
    super.key,
    required this.entries,
    required this.onSelected,
    this.selected,
    this.hintText,
    this.leadingIcon,
    this.enabled = true,
    this.dense = false,
  });

  final List<ExpressiveDropdownEntry<T>> entries;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String? hintText;
  final Widget? leadingIcon;
  final bool enabled;
  final bool dense;

  String? get _selectedLabel {
    for (final entry in entries) {
      if (entry.value == selected) return entry.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;
    final label = _selectedLabel;
    final style = (dense ? tt.bodyMedium : tt.bodyLarge)?.copyWith(
      color: label == null ? cs.onSurfaceVariant.withValues(alpha: 0.42) : cs.onSurface,
    );

    return MenuAnchor(
      animated: true,
      consumeOutsideTap: true,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerLow),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor: WidgetStatePropertyAll(
          cs.shadow.withValues(alpha: 0.16),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: shapes.radiusExtraLarge),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        ),
      ),
      builder: (context, controller, _) {
        return SizedBox(
          width: double.infinity,
          child: Material(
          color: enabled
              ? cs.surfaceContainerHighest
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: shapes.radiusLarge),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: !enabled
                ? null
                : () => controller.isOpen ? controller.close() : controller.open(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                dense ? 12 : 16,
                dense ? 10 : 14,
                dense ? 10 : 12,
                dense ? 10 : 14,
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    SizedBox(width: dense ? 8 : 12),
                  ],
                  Expanded(
                    child: Text(
                      label ?? hintText ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  Icon(
                    controller.isOpen
                        ? Symbols.keyboard_arrow_up_rounded
                        : Symbols.keyboard_arrow_down_rounded,
                    size: dense ? 20 : 22,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
      menuChildren: [
        for (final entry in entries)
          Material(
            type: MaterialType.transparency,
            child: MenuItemButton(
              leadingIcon: entry.leading,
              trailingIcon: entry.value == selected
                  ? Icon(Symbols.check_rounded, size: 18, color: cs.primary)
                  : null,
              onPressed: () => onSelected(entry.value),
              child: Text(entry.label),
            ),
          ),
      ],
    );
  }
}
