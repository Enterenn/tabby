import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/add_expense/screens/add_expense_screen.dart';
import '../../features/cards/screens/cards_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/group_detail/screens/create_group_screen.dart';
import '../../features/group_detail/screens/invite_screen.dart';
import '../../features/group_detail/screens/join_group_screen.dart';
import '../../features/profile/screens/category_management_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _AuthListenable(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuth = authState is AuthAuthenticated;
      final isOnAuth = state.uri.path.startsWith('/login') ||
          state.uri.path.startsWith('/register');

      if (!isAuth && !isOnAuth) return '/login';
      if (isAuth && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, _) => const RegisterScreen()),
      GoRoute(path: '/groups/create', builder: (context, _) => const CreateGroupScreen()),
      GoRoute(path: '/groups/join', builder: (context, _) => const JoinGroupScreen()),
      GoRoute(
        path: '/groups/:groupId/invite',
        builder: (context, state) =>
            InviteScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/profile/categories',
        builder: (context, _) => const CategoryManagementScreen(),
      ),
      // Add expense — hors ShellRoute pour un écran plein sans nav bar
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => AddExpenseScreen(
          groupId: state.uri.queryParameters['groupId'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, _) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (context, _) => const NoTransitionPage(child: BudgetScreen()),
          ),
          GoRoute(
            path: '/cards',
            pageBuilder: (context, _) => const NoTransitionPage(child: CardsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
