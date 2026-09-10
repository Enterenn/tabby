import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/add_expense/screens/add_expense_screen.dart';
import '../../features/cards/screens/cards_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => const NoTransitionPage(child: BudgetScreen()),
        ),
        GoRoute(
          path: '/add-expense',
          pageBuilder: (context, state) => const NoTransitionPage(child: AddExpenseScreen()),
        ),
        GoRoute(
          path: '/cards',
          pageBuilder: (context, state) => const NoTransitionPage(child: CardsScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
  ],
);
