import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';

/// Sélecteur système / clair / sombre — persist via [ThemeCubit].
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return ExpressiveButtonGroup<AppThemePreference>(
          value: themeState.preference,
          onChanged: (preference) async {
            final saved = await context.read<ThemeCubit>().setThemePreference(
              preference,
            );
            if (!saved && context.mounted) {
              showTabbySnack(context, context.l10n.themeSaveFailed);
            }
          },
          segments: [
            ExpressiveButtonGroupSegment(
              value: AppThemePreference.system,
              label: context.l10n.themeSystem,
              semanticLabel: context.l10n.themeAppearanceSystem,
            ),
            ExpressiveButtonGroupSegment(
              value: AppThemePreference.light,
              label: context.l10n.themeLight,
              semanticLabel: context.l10n.themeAppearanceLight,
            ),
            ExpressiveButtonGroupSegment(
              value: AppThemePreference.dark,
              label: context.l10n.themeDark,
              semanticLabel: context.l10n.themeAppearanceDark,
            ),
          ],
        );
      },
    );
  }
}
