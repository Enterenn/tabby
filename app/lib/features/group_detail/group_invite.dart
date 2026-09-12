import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../design_system/design_system.dart';

/// Génère un code d'invitation et affiche la boîte de dialogue de partage.
Future<void> showGroupInviteDialog(
  BuildContext context, {
  required String groupId,
}) async {
  showTabbyDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
  );

  String? code;
  try {
    final res = await apiClient.dio.post('/groups/$groupId/invite');
    code = res.data['code'] as String;
  } catch (_) {
    code = null;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (code == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.inviteGenerateFailed)),
    );
    return;
  }

  showTabbyDialog(
    context: context,
    builder: (_) => _InviteDialog(code: code!),
  );
}

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(context.l10n.inviteCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.inviteCodeShareShort),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.codeCopied)),
              );
            },
            borderRadius: context.tabbyShapes.radiusLarge,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: context.tabbyShapes.radiusLarge,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: tt.displaySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Symbols.content_copy_rounded, color: cs.onPrimaryContainer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.inviteValid24h,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }
}
