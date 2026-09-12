import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/biometric_cubit.dart';
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
              TabbyListCard(
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
              const SizedBox(height: 24),
              Text(context.l10n.appearance,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TabbyListCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.theme,
                        style: Theme.of(context).textTheme.titleSmall,
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
              const SizedBox(height: 12),
              BlocBuilder<LocaleCubit, Locale?>(
                builder: (context, stored) {
                  final label = stored == null
                      ? context.l10n.languageSystem
                      : stored.languageCode == 'fr'
                          ? context.l10n.languageFrench
                          : context.l10n.languageEnglish;
                  final flag = _languageFlag(stored?.languageCode);
                  return TabbyListCard(
                    child: ListTile(
                      title: Text(flag == null ? label : '$flag  $label'),
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
              BlocBuilder<BiometricCubit, BiometricState>(
                builder: (context, bio) {
                  if (!bio.available && !bio.enabled) {
                    return const SizedBox.shrink();
                  }
                  return TabbyListCard(
                    child: SwitchListTile(
                      secondary: const Icon(Symbols.fingerprint_rounded),
                      title: Text(context.l10n.biometricSetting),
                      value: bio.enabled,
                      shape: context.tabbyShapes.fieldShape,
                      onChanged: (value) async {
                        final cubit = context.read<BiometricCubit>();
                        if (!value) {
                          await cubit.disable();
                          return;
                        }
                        if (!bio.available) return;
                        final ok = await cubit.enable(
                          context.l10n.biometricLockReason,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.biometricFailed),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Symbols.logout_rounded,
                label: context.l10n.logout,
                color: cs.error,
                onTap: () async {
                  final confirm = await showTabbyConfirm(
                    context,
                    title: context.l10n.logoutConfirm,
                    confirmLabel: context.l10n.logoutAction,
                    danger: true,
                  );
                  if (confirm && context.mounted) {
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
                flag: _languageFlag('fr'),
                selected: stored?.languageCode == 'fr',
                onTap: () {
                  cubit.setLocale(const Locale('fr'));
                  Navigator.pop(ctx);
                },
              ),
              _LanguageOption(
                label: ctx.l10n.languageEnglish,
                flag: _languageFlag('en'),
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

String? _languageFlag(String? languageCode) => switch (languageCode) {
      'fr' => '🇫🇷',
      'en' => '🇬🇧',
      _ => null,
    };

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.flag,
  });

  final String label;
  final String? flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(flag == null ? label : '$flag  $label'),
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

    return TabbyListCard(
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
