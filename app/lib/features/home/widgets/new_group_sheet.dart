import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Ouvre le choix créer / rejoindre un groupe.
Future<void> showNewGroupSheet(BuildContext context) {
  return showTabbySheet<void>(
    context,
    builder: (_) => _NewGroupSheet(),
  );
}

class _NewGroupSheet extends StatelessWidget {
  const _NewGroupSheet();

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.newGroup, style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(
            context.l10n.newGroupSheetSubtitle,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Symbols.add_rounded,
            title: context.l10n.createGroup,
            subtitle: context.l10n.createGroupSubtitle,
            color: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            onTap: () {
              Navigator.pop(context);
              context.push('/groups/create');
            },
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Symbols.group_add_rounded,
            title: context.l10n.joinGroup,
            subtitle: context.l10n.joinGroupSubtitle,
            color: cs.secondaryContainer,
            iconColor: cs.onSecondaryContainer,
            onTap: () {
              Navigator.pop(context);
              context.push('/groups/join');
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;

    return Material(
      color: color,
      elevation: 0,
      shape: shapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Material(
                color: iconColor.withValues(alpha: 0.18),
                shape: shapes.circle(),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(icon, color: iconColor, fill: 1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: context.tabbyColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right_rounded,
                color: context.tabbyColors.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
