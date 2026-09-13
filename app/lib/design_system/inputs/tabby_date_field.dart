import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format/date.dart';
import '../../core/theme/app_theme.dart';

enum TabbyDateFieldVariant { form, sheet }

/// Champ date — [showDatePicker] + décoration formulaire ou chrome sheet.
class TabbyDateField extends StatelessWidget {
  const TabbyDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.firstDate,
    this.lastDate,
    this.variant = TabbyDateFieldVariant.form,
  });

  const TabbyDateField.sheet({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  })  : label = null,
        variant = TabbyDateFieldVariant.sheet;

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TabbyDateFieldVariant variant;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final labelText = formatDisplayDate(context, value);

    if (variant == TabbyDateFieldVariant.sheet) {
      final cs = context.tabbyColors;
      final tt = Theme.of(context).textTheme;
      final space = context.tabbySpace;
      return Material(
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: context.tabbyShapes.radiusLarge,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _pick(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(space.md, 10, 10, 10),
            child: Row(
              children: [
                Icon(
                  Symbols.calendar_month_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                SizedBox(width: space.sm),
                Expanded(
                  child: Text(
                    labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: context.tabbyShapes.radiusMedium,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Symbols.calendar_month_rounded, size: 18),
        ),
        child: Text(labelText, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
