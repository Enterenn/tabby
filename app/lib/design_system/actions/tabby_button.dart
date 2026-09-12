import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Spinner aligné sur un bouton Material (couleur `on*` du bouton parent).
class TabbyButtonSpinner extends StatelessWidget {
  const TabbyButtonSpinner({
    super.key,
    this.color,
    this.size = 20,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? context.tabbyColors.onPrimary,
      ),
    );
  }
}

/// Styles ponctuels — le reste vient de [FilledButtonTheme] / [OutlinedButtonTheme].
extension TabbyButtonStyles on BuildContext {
  ButtonStyle get tabbyDangerFilled => FilledButton.styleFrom(
        backgroundColor: tabbyColors.error,
        foregroundColor: tabbyColors.onError,
      );
}
