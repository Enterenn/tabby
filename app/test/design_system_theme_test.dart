import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/core/theme/app_theme.dart';
import 'package:tabby/design_system/surfaces/expressive_tonal_card.dart';

void main() {
  test('theme exposes M3 semantic extensions', () {
    final theme = AppTheme.light;
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.secondaryContainer, isNot(theme.colorScheme.surface));
    expect(theme.extensions.values, contains(isA<TabbySemanticColors>()));
  });

  testWidgets('tonal card renders its child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ExpressiveTonalCard(
          variant: ExpressiveTonalVariant.coral,
          child: Text('content'),
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
  });
}
