import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppTheme.configureSymbols();
  await initializeDateFormatting('fr_FR');
  await initTokenStorage();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  Animate.restartOnHotReload = true;
  runApp(const TabbyApp());
}

class TabbyApp extends StatefulWidget {
  const TabbyApp({super.key});

  @override
  State<TabbyApp> createState() => _TabbyAppState();
}

class _TabbyAppState extends State<TabbyApp> {
  late final AuthCubit _authCubit;
  late final ThemeCubit _themeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit()..checkAuth();
    _themeCubit = ThemeCubit();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Tabby',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
