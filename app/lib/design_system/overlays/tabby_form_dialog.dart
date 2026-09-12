import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../actions/tabby_button.dart';
import 'tabby_sheet.dart';

/// Dialog de formulaire — titre, contenu, Annuler + [FilledButton].
Future<T?> showTabbyFormDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showTabbyDialog<T>(context: context, builder: builder);
}

class TabbyFormDialog extends StatelessWidget {
  const TabbyFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.submitLabel,
    required this.onSubmit,
    this.cancelLabel,
    this.loading = false,
    this.danger = false,
  });

  final String title;
  final Widget child;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final String? cancelLabel;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cancel = cancelLabel ??
        MaterialLocalizations.of(context).cancelButtonLabel;
    final cs = context.tabbyColors;

    return AlertDialog(
      title: Text(title),
      content: child,
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: Text(cancel),
        ),
        FilledButton(
          style: danger ? context.tabbyDangerFilled : null,
          onPressed: loading ? null : onSubmit,
          child: loading
              ? TabbyButtonSpinner(
                  color: danger ? cs.onError : cs.onPrimary,
                  size: 16,
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}
