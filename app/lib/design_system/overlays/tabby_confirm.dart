import 'package:material_ui/material_ui.dart';

import '../actions/expressive_cta_button.dart';
import 'tabby_sheet.dart';

/// Confirmation destructive ou neutre — blur [showTabbyDialog] + CTA compact.
Future<bool> showTabbyConfirm(
  BuildContext context, {
  required String title,
  String? body,
  String? cancelLabel,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showTabbyDialog<bool>(
    context: context,
    builder: (ctx) => TabbyConfirmDialog(
      title: title,
      body: body,
      cancelLabel: cancelLabel ?? MaterialLocalizations.of(ctx).cancelButtonLabel,
      confirmLabel: confirmLabel,
      danger: danger,
    ),
  );
  return result ?? false;
}

class TabbyConfirmDialog extends StatelessWidget {
  const TabbyConfirmDialog({
    super.key,
    required this.title,
    this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    this.danger = false,
  });

  final String title;
  final String? body;
  final String cancelLabel;
  final String confirmLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body!),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        ExpressiveCtaButton(
          label: confirmLabel,
          compact: true,
          variant: danger
              ? ExpressiveCtaVariant.danger
              : ExpressiveCtaVariant.filled,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
