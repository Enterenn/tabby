import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';

enum TabbyInviteCodeSize { compact, large }

/// Code d'invitation copiable — tokens `primary` / `tertiary` container.
class TabbyInviteCode extends StatelessWidget {
  const TabbyInviteCode({
    super.key,
    required this.code,
    required this.copiedLabel,
    this.size = TabbyInviteCodeSize.compact,
  });

  final String code;
  final String copiedLabel;
  final TabbyInviteCodeSize size;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copiedLabel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final large = size == TabbyInviteCodeSize.large;
    final bg = large ? cs.tertiaryContainer : cs.primaryContainer;
    final fg = large ? cs.onTertiaryContainer : cs.onPrimaryContainer;

    return Material(
      color: bg,
      elevation: 0,
      shape: context.tabbyShapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copy(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 40 : 24,
            vertical: large ? 28 : 16,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: large
                    ? context.tabbyType.clockDisplay.copyWith(
                        fontSize: 40,
                        letterSpacing: 12,
                        color: fg,
                      )
                    : tt.displaySmall?.copyWith(
                        color: fg,
                        letterSpacing: 8,
                      ),
              ),
              if (!large) ...[
                const SizedBox(width: 12),
                Icon(Symbols.content_copy_rounded, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
