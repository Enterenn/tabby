import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../feedback/tabby_snack.dart';

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
    showTabbySnack(context, copiedLabel);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final large = size == TabbyInviteCodeSize.large;
    final bg = large ? cs.tertiaryContainer : cs.primaryContainer;
    final fg = large ? cs.onTertiaryContainer : cs.onPrimaryContainer;
    final letterSpacing = large ? 6.0 : 3.0;
    final style = large
        ? context.tabbyType.clockDisplay.copyWith(
            fontSize: 36,
            height: 1.15,
            letterSpacing: letterSpacing,
            color: fg,
          )
        : tt.headlineMedium?.copyWith(
            color: fg,
            height: 1.15,
            letterSpacing: letterSpacing,
          );

    return Material(
      color: bg,
      elevation: 0,
      shape: context.tabbyShapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copy(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            large ? 24 : 20,
            large ? 24 : 16,
            large ? 24 : 16,
            large ? 24 : 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    // Flutter adds [letterSpacing] after the last glyph.
                    padding: EdgeInsets.only(right: letterSpacing),
                    child: Text(
                      code,
                      maxLines: 1,
                      softWrap: false,
                      style: style,
                    ),
                  ),
                ),
              ),
              if (!large) ...[
                const SizedBox(width: 8),
                Icon(Symbols.content_copy_rounded, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
