import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../../../shared/widgets/tabby_sheet.dart';
import '../../auth/cubit/auth_cubit.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final cs = context.tabbyColors;

        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.profile)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => pickAndUploadAvatar(context),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ExpressiveAvatar(
                              label: user?.name ?? '?',
                              size: 56,
                              color: cs.primaryContainer,
                              textColor: cs.onPrimaryContainer,
                              imageUrl: resolveMediaUrl(user?.avatarUrl),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Material(
                                color: cs.primary,
                                shape: context.tabbyShapes.circle(),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Symbols.photo_camera_rounded,
                                    size: 14,
                                    color: cs.onPrimary,
                                    fill: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? '',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              user?.email ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.editProfile,
                        onPressed: () => showEditProfileSheet(context),
                        icon: const Icon(Symbols.edit_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(context.l10n.appearance,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.theme,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.themeHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, mode) {
                          return ExpressiveButtonGroup<ThemeMode>(
                            value: mode,
                            onChanged: (next) =>
                                context.read<ThemeCubit>().setThemeMode(next),
                            segments: [
                              ExpressiveButtonGroupSegment(
                                value: ThemeMode.system,
                                label: context.l10n.themeSystem,
                              ),
                              ExpressiveButtonGroupSegment(
                                value: ThemeMode.light,
                                label: context.l10n.themeLight,
                              ),
                              ExpressiveButtonGroupSegment(
                                value: ThemeMode.dark,
                                label: context.l10n.themeDark,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<LocaleCubit, Locale?>(
                builder: (context, stored) {
                  final effective = Localizations.localeOf(context);
                  final label = stored == null
                      ? context.l10n.languageSystem
                      : effective.languageCode == 'fr'
                          ? context.l10n.languageFrench
                          : context.l10n.languageEnglish;
                  return Card(
                    child: ListTile(
                      title: Text(context.l10n.language),
                      subtitle: Text(
                        '$label — ${context.l10n.languageHint}',
                      ),
                      trailing: const Icon(Symbols.chevron_right_rounded),
                      shape: context.tabbyShapes.fieldShape,
                      onTap: () => _showLanguageSheet(context, stored),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(context.l10n.personalization,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Symbols.repeat_rounded,
                label: context.l10n.recurringExpenses,
                onTap: () => context.push('/profile/recurring'),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Symbols.category_rounded,
                label: context.l10n.myCategories,
                onTap: () => context.push('/profile/categories'),
              ),
              const SizedBox(height: 24),
              Text(context.l10n.account, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Symbols.logout_rounded,
                label: context.l10n.logout,
                color: cs.error,
                onTap: () async {
                  final confirm = await showTabbyDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(ctx.l10n.logoutConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(ctx.l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            ctx.l10n.logoutAction,
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<AuthCubit>().logout();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showLanguageSheet(BuildContext context, Locale? stored) {
  return showTabbySheet<void>(
    context,
    builder: (ctx) {
      final cubit = context.read<LocaleCubit>();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ctx.l10n.chooseLanguage,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: ctx.l10n.languageSystem,
                selected: stored == null,
                onTap: () {
                  cubit.setLocale(null);
                  Navigator.pop(ctx);
                },
              ),
              _LanguageOption(
                label: ctx.l10n.languageFrench,
                selected: stored?.languageCode == 'fr',
                onTap: () {
                  cubit.setLocale(const Locale('fr'));
                  Navigator.pop(ctx);
                },
              ),
              _LanguageOption(
                label: ctx.l10n.languageEnglish,
                selected: stored?.languageCode == 'en',
                onTap: () {
                  cubit.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Symbols.check_rounded) : null,
      selected: selected,
      shape: context.tabbyShapes.fieldShape,
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? cs.onSurface, size: 20),
        title: Text(label, style: TextStyle(color: color ?? cs.onSurface)),
        trailing: Icon(Symbols.chevron_right_rounded,
            color: cs.onSurfaceVariant, size: 20),
        onTap: onTap,
        shape: context.tabbyShapes.fieldShape,
      ),
    );
  }
}
