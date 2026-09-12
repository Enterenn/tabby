import 'package:material_ui/material_ui.dart';

import '../actions/expressive_cta_button.dart';
import 'tabby_sheet.dart';

/// Dialog de formulaire — titre, contenu, Annuler + CTA compact (loading).
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

    return AlertDialog(
      title: Text(title),
      content: child,
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: Text(cancel),
        ),
        ExpressiveCtaButton(
          label: submitLabel,
          compact: true,
          loading: loading,
          variant: danger
              ? ExpressiveCtaVariant.danger
              : ExpressiveCtaVariant.filled,
          onPressed: loading ? null : onSubmit,
        ),
      ],
    );
  }
}
