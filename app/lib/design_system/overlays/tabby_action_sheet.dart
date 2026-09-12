import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import 'expressive_sheet.dart';
import 'tabby_sheet.dart';

/// Ligne d'un [TabbyActionSheet] — action ou séparateur.
class TabbyActionSheetItem {
  const TabbyActionSheetItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.danger = false,
  }) : isDivider = false;

  const TabbyActionSheetItem.divider()
      : label = '',
        onTap = _noop,
        icon = null,
        subtitle = null,
        danger = false,
        isDivider = true;

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;
  final bool danger;
  final bool isDivider;

  static void _noop() {}
}

/// Sheet d'actions — handle unique (celui de [showTabbySheet]), tone danger.
Future<void> showTabbyActionSheet(
  BuildContext context, {
  String? title,
  String? subtitle,
  required List<TabbyActionSheetItem> actions,
}) {
  return showTabbySheet<void>(
    context,
    builder: (ctx) => TabbyActionSheet(
      title: title,
      subtitle: subtitle,
      actions: [
        for (final action in actions)
          if (action.isDivider)
            action
          else
            TabbyActionSheetItem(
              label: action.label,
              icon: action.icon,
              subtitle: action.subtitle,
              danger: action.danger,
              onTap: () {
                Navigator.pop(ctx);
                action.onTap();
              },
            ),
      ],
    ),
  );
}

class TabbyActionSheet extends StatelessWidget {
  const TabbyActionSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.actions,
  });

  final String? title;
  final String? subtitle;
  final List<TabbyActionSheetItem> actions;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              ExpressiveSheetHeader(title: title!, subtitle: subtitle),
            for (final action in actions)
              if (action.isDivider)
                const Divider(height: 1)
              else
                ListTile(
                  leading: action.icon == null
                      ? null
                      : Icon(
                          action.icon,
                          color: action.danger ? cs.error : cs.onSurface,
                        ),
                  title: Text(
                    action.label,
                    style: TextStyle(
                      color: action.danger ? cs.error : cs.onSurface,
                    ),
                  ),
                  subtitle: action.subtitle == null
                      ? null
                      : Text(action.subtitle!),
                  shape: shapes.fieldShape,
                  onTap: action.onTap,
                ),
          ],
        ),
      ),
    );
  }
}
