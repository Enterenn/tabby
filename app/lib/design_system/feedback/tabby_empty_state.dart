import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Présentation d'un état vide — icône muted ou pastille featured.
enum TabbyEmptyTone { muted, featured }

class TabbyEmptyState extends StatelessWidget {
  const TabbyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.tone = TabbyEmptyTone.muted,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final TabbyEmptyTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final featured = tone == TabbyEmptyTone.featured;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: featured ? 48 : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (featured)
              SizedBox(
                width: 96,
                height: 96,
                child: Material(
                  color: cs.primaryContainer,
                  elevation: 0,
                  shape: context.tabbyShapes.circle(),
                  clipBehavior: Clip.antiAlias,
                  child: Icon(
                    icon,
                    size: 48,
                    color: cs.onPrimaryContainer,
                    fill: 1,
                  ),
                ),
              )
            else
              Icon(icon, size: 56, color: cs.outlineVariant),
            SizedBox(height: featured ? 24 : 16),
            Text(title, style: tt.headlineSmall, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
