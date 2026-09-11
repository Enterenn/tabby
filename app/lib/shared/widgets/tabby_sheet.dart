import 'package:flutter/material.dart';

/// Bottom sheet au-dessus de la nav flottante (root navigator).
Future<T?> showTabbySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}
