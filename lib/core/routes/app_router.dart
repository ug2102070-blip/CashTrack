// lib/core/routes/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/analytics/analytics_screen.dart';
import '../../presentation/transactions/add_transaction_form.dart';
import '../../presentation/transactions/transactions_screen.dart';
import '../../presentation/ai_assistant/ai_assistant_screen.dart';
import '../../presentation/budget/budget_screen.dart';
import '../../presentation/goals/goals_screen.dart';
import '../../presentation/categories/categories_screen.dart';
import '../../presentation/accounts/accounts_screen.dart';
import '../../presentation/reports/reports_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/debts/debts_screen.dart';
import '../../presentation/widgets/bottom_nav_bar.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/tools/calculator_screen.dart';
import '../../presentation/tools/notes_screen.dart';
import '../../presentation/tools/tools_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../services/auth_service.dart';

final _authService = AuthService();
final _routerRefresh = GoRouterRefreshStream(_authService.authStateChanges);

String _initialLocation() {
  if (!Hive.isBoxOpen('settingsBox')) return '/login';
  final box = Hive.box('settingsBox');
  final onboardingDone =
      box.get('onboardingComplete', defaultValue: false) as bool;
  if (!onboardingDone) return '/onboarding';
  return '/login';
}

final appRouter = GoRouter(
  initialLocation: _initialLocation(),
  refreshListenable: _routerRefresh,
  redirect: (context, state) {
    final bool isLoggedIn = _authService.isAuthenticated;
    final bool isOnLogin = state.matchedLocation == '/login';
    final bool isOnOnboarding = state.matchedLocation == '/onboarding';

    // Allow onboarding to be shown without auth
    if (isOnOnboarding) return null;

    if (!isLoggedIn && !isOnLogin) {
      return '/login';
    }

    if (isLoggedIn && isOnLogin) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/ai-assistant',
          builder: (context, state) => const AiAssistantScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/add-transaction',
          builder: (context, state) => const AddTransactionForm(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/goals',
          builder: (context, state) => const GoalsScreen(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountsScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/debts',
          builder: (context, state) => const DebtsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/calculator',
          builder: (context, state) => const CalculatorScreen(),
        ),
        GoRoute(
          path: '/notes',
          builder: (context, state) => const NotesScreen(),
        ),
        GoRoute(
          path: '/tools',
          builder: (context, state) => const ToolsScreen(),
        ),
      ],
    ),
  ],
);

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  String _getTitleForLocation(String location) {
    switch (location) {
      case '/':
        return 'Dashboard';
      case '/analytics':
        return 'Analytics';
      case '/transactions':
        return 'Transactions';
      case '/budget':
        return 'Budget';
      case '/goals':
        return 'Goals';
      case '/categories':
        return 'Categories';
      case '/accounts':
        return 'Accounts';
      case '/reports':
        return 'Reports';
      case '/debts':
        return 'Debts';
      case '/profile':
        return 'Profile';
      case '/notifications':
        return 'Notifications';
      case '/settings':
        return 'Settings';
      default:
        return 'CashTrack';
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    final hideBottomNav = ['/add-transaction', '/login'].contains(location);

    // Pages that are presented modally or have a custom AppBar
    // will not show the generic shell AppBar.
    final hideGenericAppBar = [
      '/',
      '/analytics',
      '/add-transaction',
      '/search',
      '/ai-assistant',
      '/tools',
      '/budget',
      '/goals',
      '/categories',
      '/accounts',
      '/transactions',
      '/reports',
      '/debts',
      '/profile',
      '/notifications',
      '/settings',
      '/calculator',
      '/notes',
    ].contains(location);

    // Tab-level routes that use go() — back should not exit app from these
    const tabRoutes = ['/', '/analytics', '/tools', '/settings'];
    final isTabRoute = tabRoutes.contains(location);

    return PopScope(
      canPop: !isTabRoute, // sub-pages can pop normally; tab pages cannot
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return; // already popped (sub-page)
        // On a tab page: go to Dashboard if not already there
        if (location != '/') {
          context.go('/');
        }
        // If already on Dashboard, do nothing — prevents app exit
      },
      child: Scaffold(
        appBar: hideGenericAppBar
            ? null
            : AppBar(
                title: Text(_getTitleForLocation(location)),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.push('/search'),
                  ),
                  IconButton(
                    icon: const Icon(Icons
                        .auto_awesome), // A suitable icon for an AI assistant
                    onPressed: () => context.push('/ai-assistant'),
                  ),
                ],
              ),
        body: child,
        bottomNavigationBar: hideBottomNav ? null : const CustomBottomNavBar(),
        floatingActionButton: hideBottomNav
            ? null
            : FloatingActionButton(
                onPressed: () => context.push('/add-transaction'),
                child: const Icon(Icons.add, size: 28),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
