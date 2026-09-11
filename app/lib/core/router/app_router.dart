import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/cards/screens/cards_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/group_detail/screens/create_group_screen.dart';
import '../../features/group_detail/screens/group_detail_screen.dart';
import '../../features/group_detail/screens/invite_screen.dart';
import '../../features/group_detail/screens/join_group_screen.dart';
import '../../features/profile/screens/category_management_screen.dart';
import '../../features/recurring/screens/recurring_expenses_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Navigue vers le groupe depuis une notification (appelé par TabbyApp).
void navigateToGroup(String groupId) {
  _rootNavigatorKey.currentContext?.push('/groups/$groupId');
}

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
        path: '/groups/:groupId',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: GroupDetailScreen(
            groupId: state.pathParameters['groupId']!,
          ),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
              SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.scaled,
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: '/profile/recurring',
        builder: (context, _) => const RecurringExpensesScreen(),
      ),
      GoRoute(
        path: '/profile/categories',
        builder: (context, _) => const CategoryManagementScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (context, state) => _fadePage(state, const BudgetScreen()),
          ),
          GoRoute(
            path: '/cards',
            pageBuilder: (context, state) => _fadePage(state, const CardsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _fadePage(state, const ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
        FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
