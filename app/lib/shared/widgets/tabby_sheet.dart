import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// Bottom sheet au-dessus de la nav flottante (root navigator), fond flouté.
Future<T?> showTabbySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    TabbySheetRoute<T>(
      builder: builder,
      isScrollControlled: isScrollControlled,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    ),
  );
}

class TabbySheetRoute<T> extends ModalBottomSheetRoute<T> {
  TabbySheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.backgroundColor,
  }) : super(
          showDragHandle: true,
          useSafeArea: true,
          modalBarrierColor: Colors.black.withValues(alpha: 0.22),
        );

  @override
  Widget buildModalBarrier() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: super.buildModalBarrier(),
    );
  }
}

/// Dialog avec le même voile flou que les sheets.
Future<T?> showTabbyDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          type: MaterialType.transparency,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.22),
            child: Stack(
              children: [
                if (barrierDismissible)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                Center(child: builder(ctx)),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
