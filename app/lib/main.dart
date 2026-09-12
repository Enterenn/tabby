import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api/token_storage.dart';
import 'core/auth/biometric_settings.dart';
import 'core/locale/locale_cubit.dart';
import 'shared/models/loyalty_brand_logos.dart';
import 'shared/models/loyalty_prefix_store.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/biometric_cubit.dart';
import 'features/auth/widgets/biometric_offer_listener.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppTheme.configureSymbols();
  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');
  await initTokenStorage();
  await initBiometricSettings();
  await LoyaltyPrefixStore.load();
  await LoyaltyBrandLogos.load();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  Animate.restartOnHotReload = true;
  final themePrefs = ThemePrefs();
  final initialTheme = await themePrefs.getThemeMode();
  runApp(TabbyApp(initialTheme: initialTheme, themePrefs: themePrefs));
}

class TabbyApp extends StatefulWidget {
  const TabbyApp({
    super.key,
    required this.initialTheme,
    required this.themePrefs,
  });

  final AppThemePreference initialTheme;
  final ThemePrefs themePrefs;

  @override
  State<TabbyApp> createState() => _TabbyAppState();
}

class _TabbyAppState extends State<TabbyApp> {
  late final AuthCubit _authCubit;
  late final ThemeCubit _themeCubit;
  late final LocaleCubit _localeCubit;
  late final BiometricCubit _biometricCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit()..checkAuth();
    _themeCubit = ThemeCubit(
      prefs: widget.themePrefs,
      initial: widget.initialTheme,
    );
    _localeCubit = LocaleCubit();
    _biometricCubit = BiometricCubit();
    _router = buildRouter(_authCubit);
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // App en background : tap sur la notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final groupId = msg.data['group_id'] as String?;
      if (groupId != null) navigateToGroup(groupId);
    });

    // App terminée : tap pour ouvrir
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg == null) return;
      final groupId = msg.data['group_id'] as String?;
      if (groupId != null) {
        // Petit délai pour que le router soit prêt
        Future.delayed(const Duration(milliseconds: 500), () {
          navigateToGroup(groupId);
        });
      }
    });
  }

  @override
  void dispose() {
    _authCubit.close();
    _themeCubit.close();
    _localeCubit.close();
    _biometricCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _localeCubit),
        BlocProvider.value(value: _biometricCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'Tabby',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeState.materialThemeMode,
                themeAnimationDuration: const Duration(milliseconds: 120),
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localeResolutionCallback: (device, supported) {
                  if (locale != null) return locale;
                  if (device != null) {
                    for (final candidate in supported) {
                      if (candidate.languageCode == device.languageCode) {
                        return candidate;
                      }
                    }
                  }
                  return const Locale('en');
                },
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                builder: (context, child) {
                  // Pont officiel le temps que go_router / animations /
                  // flutter_animate lisent encore flutter/material.dart.
                  return MaterialUiCompatibilityBridge(
                    // ignore: deprecated_member_use
                    child: BiometricOfferListener(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
                routerConfig: _router,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
