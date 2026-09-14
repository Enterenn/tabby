import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tabby/core/theme/app_theme.dart';
import 'package:tabby/design_system/design_system.dart';
import 'package:tabby/features/group_detail/screens/create_group_screen.dart';
import 'package:tabby/features/group_detail/screens/join_group_screen.dart';
import 'package:tabby/l10n/l10n.dart';

Widget _localizedApp(Widget home) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light,
  home: home,
);

void main() {
  void useCompactViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('create group remains scrollable on a compact viewport', (
    tester,
  ) async {
    useCompactViewport(tester);
    await tester.pumpWidget(_localizedApp(const CreateGroupScreen()));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.text('Créer le groupe'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('join group remains scrollable on a compact viewport', (
    tester,
  ) async {
    useCompactViewport(tester);
    await tester.pumpWidget(_localizedApp(const JoinGroupScreen()));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.text('Rejoindre'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending repayment confirmation uses rejection wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTabbyConfirm(
                context,
                title: context.l10n.rejectRepaymentTitle,
                body: context.l10n.rejectRepaymentBody('Remboursement'),
                confirmLabel: context.l10n.rejectRepayment,
                danger: true,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Rejeter ce remboursement ?'), findsOneWidget);
    expect(find.text('Rejeter le remboursement'), findsOneWidget);
    expect(find.textContaining('Aucun remboursement'), findsOneWidget);
  });

  testWidgets('group expense deletion has a destructive confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTabbyConfirm(
                context,
                title: context.l10n.deleteExpenseTitle,
                body: context.l10n.deleteExpenseBody('Restaurant'),
                confirmLabel: context.l10n.delete,
                danger: true,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette dépense ?'), findsOneWidget);
    expect(find.textContaining('Restaurant'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('loyalty card deletion has a destructive confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTabbyConfirm(
                context,
                title: context.l10n.deleteLoyaltyCardTitle,
                body: context.l10n.deleteLoyaltyCardBody('Picard'),
                confirmLabel: context.l10n.delete,
                danger: true,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette carte ?'), findsOneWidget);
    expect(find.textContaining('Picard'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });
}
