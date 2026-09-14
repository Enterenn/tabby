import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';

class TabbyOfflineState extends StatelessWidget {
  const TabbyOfflineState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tabbyColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.cloud_off_rounded, size: 48, color: colors.outline),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
