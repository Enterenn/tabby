import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/locale/locale_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../../auth/cubit/auth_cubit.dart';

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
                      ExpressiveAvatar(
                        label: user?.name ?? '?',
                        size: 56,
                        color: cs.primaryContainer,
                        textColor: cs.onPrimaryContainer,
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.language,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.languageHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<LocaleCubit, Locale>(
                        builder: (context, locale) {
                          return ExpressiveButtonGroup<Locale>(
                            value: locale,
                            onChanged: (next) =>
                                context.read<LocaleCubit>().setLocale(next),
                            segments: [
                              ExpressiveButtonGroupSegment(
                                value: const Locale('fr'),
                                label: context.l10n.languageFrench,
                              ),
                              ExpressiveButtonGroupSegment(
                                value: const Locale('en'),
                                label: context.l10n.languageEnglish,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
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
                  final confirm = await showDialog<bool>(
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
