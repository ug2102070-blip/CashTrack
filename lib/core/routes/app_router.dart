import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

import '../../data/models/transaction_model.dart';
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
import '../../presentation/auth/verify_email_screen.dart';
import '../../presentation/debts/debts_screen.dart';
import '../../presentation/widgets/bottom_nav_bar.dart';
import '../../presentation/widgets/web_sidebar.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/tools/calculator_screen.dart';
import '../../presentation/tools/emi_calculator_screen.dart';
import '../../presentation/tools/notes_screen.dart';
import '../../presentation/tools/tools_screen.dart';
import '../../presentation/split_expenses/split_expenses_screen.dart';
import '../../presentation/investments/investments_screen.dart';
import '../../presentation/assets/assets_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/subscriptions/subscription_calendar_screen.dart';
import '../../services/auth_service.dart';
import '../../presentation/landing/landing_page.dart';
import '../animations/page_transitions.dart';

final _authService = AuthService();
final _routerRefresh = GoRouterRefreshStream(_authService.authStateChanges);

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _routerRefresh,
  redirect: (context, state) {
    final bool isLoggedIn = _authService.isAuthenticated;
    final bool isOnLogin = state.matchedLocation == '/login';
    final bool isOnOnboarding = state.matchedLocation == '/onboarding';
    final bool isOnVerifyEmail = state.matchedLocation == '/verify-email';
    final bool isOnRoot = state.matchedLocation == '/';

    // Check onboarding completion
    final box = Hive.isBoxOpen('settingsBox') ? Hive.box('settingsBox') : null;
    final bool onboardingComplete = box?.get('onboardingComplete', defaultValue: false) as bool? ?? false;

    // First time user onboarding check
    if (kIsWeb) {
      if (!onboardingComplete && !isOnOnboarding && !isOnRoot && !isOnLogin && !isOnVerifyEmail) {
        return '/onboarding';
      }
      if (onboardingComplete && isOnOnboarding) {
        return '/';
      }
    } else {
      if (!onboardingComplete && !isOnOnboarding) {
        return '/onboarding';
      }
      if (onboardingComplete && isOnOnboarding) {
        return '/login';
      }
    }

    // Unauthenticated redirects
    if (!isLoggedIn) {
      if (kIsWeb) {
        // If user tries to access any app-only route (not login, onboarding, verify-email or root landing)
        if (!isOnRoot && !isOnLogin && !isOnVerifyEmail && !isOnOnboarding) {
          return '/';
        }
      } else {
        // On mobile, there is no landing page. Unauthenticated users go to login.
        if (isOnRoot || (!isOnLogin && !isOnVerifyEmail && !isOnOnboarding)) {
          return '/login';
        }
      }
      return null;
    }

    // Authenticated redirects
    if (isLoggedIn) {
      final user = _authService.currentUser;
      // If the user is logged in with email, but NOT verified, redirect to /verify-email
      if (user != null && !user.isAnonymous && !user.emailVerified) {
        if (!isOnVerifyEmail) {
          return '/verify-email';
        }
        return null;
      }

      // If verified (or guest) and on root landing, login, or verify-email, redirect to dashboard (or onboarding if not complete)
      if (isOnRoot || isOnLogin || isOnVerifyEmail) {
        if (!onboardingComplete) {
          return '/onboarding';
        }
        return '/dashboard';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const DashboardScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const AnalyticsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/ai-assistant',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const AiAssistantScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const SettingsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/add-transaction',
          pageBuilder: (context, state) {
            final tx = state.extra as TransactionModel?;
            return slideRightTransitionPage(
              child: AddTransactionForm(transactionToEdit: tx),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const TransactionsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const BudgetScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const GoalsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const CategoriesScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/accounts',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const AccountsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const ReportsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/debts',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const DebtsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const ProfileScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const NotificationsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const SearchScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/calculator',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const CalculatorScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const NotesScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/tools',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const ToolsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/emi-calculator',
          pageBuilder: (context, state) => slideRightTransitionPage(
            child: const EmiCalculatorScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/split-expenses',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const SplitExpensesScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/split-expenses/:groupId',
          pageBuilder: (context, state) {
            final groupId = state.pathParameters['groupId'];
            return slideRightTransitionPage(
              child: SplitExpensesScreen(groupId: groupId),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/investments',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const InvestmentsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/assets',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const AssetsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/subscriptions',
          pageBuilder: (context, state) => fadeSlideTransitionPage(
            child: const SubscriptionCalendarScreen(),
            state: state,
          ),
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
      case '/dashboard':
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
      case '/tools':
        return 'Tools';
      case '/emi-calculator':
        return 'EMI Calculator';
      case '/split-expenses':
        return 'Split Expenses';
      default:
        return 'CashTrack';
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final mediaQuery = MediaQuery.of(context);
    final isWideScreen = mediaQuery.size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hideBottomNav = ['/add-transaction', '/login'].contains(location) || isWideScreen;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 100;
    // Hide the shell FAB on screens that have their own FAB or when typing (keyboard open)
    final hideShellFab = ['/add-transaction', '/login'].contains(location) || isKeyboardOpen || isWideScreen;

    // Pages that are presented modally or have a custom AppBar
    // will not show the generic shell AppBar.
    final hideGenericAppBar = [
      '/dashboard',
      '/analytics',
      '/add-transaction',
      '/search',
      '/ai-assistant',
      '/tools',
      '/emi-calculator',
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
      '/investments',
      '/assets',
      '/subscriptions',
    ].contains(location) ||
        location.startsWith('/split-expenses');

    // Tab-level routes that use go() — back should not exit app from these
    const tabRoutes = ['/dashboard', '/analytics', '/tools', '/settings'];
    final isTabRoute = tabRoutes.contains(location);

    // Breadcrumb building
    final pageTitle = _getTitleForLocation(location);
    final parentTitle = _getParentTitle(location);

    return PopScope(
      canPop: !isTabRoute, // sub-pages can pop normally; tab pages cannot
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return; // already popped (sub-page)
        // On a tab page: go to Dashboard if not already there
        if (location != '/dashboard') {
          context.go('/dashboard');
        }
        // If already on Dashboard, do nothing — prevents app exit
      },
      child: Scaffold(
        appBar: (hideGenericAppBar || isWideScreen)
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
        body: isWideScreen
            ? Row(
                children: [
                  const WebSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        // ─── Premium Web Top Header Bar ─────────────────
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.85),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder.withValues(alpha: 0.3)
                                        : AppColors.lightBorder.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Breadcrumb navigation
                                  if (parentTitle != null) ...[
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => context.go('/dashboard'),
                                        child: Text(
                                          parentTitle,
                                          style: AppTextStyles.bodySm.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextTertiary
                                                : AppColors.lightTextTertiary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
                                    ),
                                  ],
                                  Text(
                                    pageTitle,
                                    style: AppTextStyles.headingMd.copyWith(
                                      color: isDark
                                          ? AppColors.darkText
                                          : AppColors.lightText,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Quick Search Hint
                                  if (isWideScreen)
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => context.push('/search'),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 16),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
                                                : AppColors.lightSurfaceElevated,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.darkBorder.withValues(alpha: 0.3)
                                                  : AppColors.lightBorder.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.search_rounded, size: 14,
                                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Search...',
                                                style: AppTextStyles.bodySm.copyWith(
                                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                '⌘K',
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Actions
                                  _WebHeaderIcon(
                                    icon: Icons.notifications_none_rounded,
                                    onTap: () =>
                                        context.push('/notifications'),
                                    tooltip: 'Notifications',
                                  ),
                                  const SizedBox(width: 8),
                                  _WebHeaderIcon(
                                    icon: Icons.auto_awesome_rounded,
                                    onTap: () =>
                                        context.push('/ai-assistant'),
                                    tooltip: 'AI Assistant',
                                    isSpecial: true,
                                  ),
                                  const SizedBox(width: 12),
                                  // Profile Mini
                                  _buildWebProfileTrigger(context, isDark),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // ─── Content Area with Animated Transitions ─────
                        Expanded(
                          child: Container(
                            color: isDark
                                ? AppColors.darkBg
                                : AppColors.lightBg,
                            child: ClipRect(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.02),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(location),
                                  child: location == '/'
                                      ? child
                                      : Padding(
                                          padding:
                                              const EdgeInsets.all(24),
                                          child: Center(
                                            child: ConstrainedBox(
                                              constraints:
                                                  const BoxConstraints(
                                                      maxWidth: 1000),
                                              child: child,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : child,
        bottomNavigationBar: hideBottomNav ? null : const CustomBottomNavBar(),
        floatingActionButton: hideShellFab
            ? null
            : FloatingActionButton(
                onPressed: () => context.push('/add-transaction'),
                child: const Icon(Icons.add, size: 28),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  String? _getParentTitle(String location) {
    if (location == '/') return null;
    // Planning sub-routes
    if (['/budget', '/goals', '/debts', '/split-expenses', '/investments', '/assets', '/emi-calculator', '/calculator', '/notes', '/subscriptions']
        .any((r) => location.startsWith(r))) {
      return 'Planning';
    }
    // Overview sub-routes
    if (['/transactions', '/analytics', '/reports']
        .any((r) => location.startsWith(r))) {
      return 'Overview';
    }
    // System sub-routes
    if (['/settings', '/ai-assistant', '/profile', '/notifications', '/search']
        .any((r) => location.startsWith(r))) {
      return 'System';
    }
    return 'Dashboard';
  }

  Widget _buildWebProfileTrigger(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/profile'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
                : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.3)
                  : AppColors.lightBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hoverable Web Header Icon ──────────────────────────────────────────────
class _WebHeaderIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isSpecial;

  const _WebHeaderIcon({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
    this.isSpecial = false,
  });

  @override
  State<_WebHeaderIcon> createState() => _WebHeaderIconState();
}

class _WebHeaderIconState extends State<_WebHeaderIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final color = widget.isSpecial ? AppColors.accent : primary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered
                  ? color.withValues(alpha: isDark ? 0.15 : 0.08)
                  : (isDark
                      ? AppColors.darkSurfaceElevated.withValues(alpha: 0.4)
                      : AppColors.lightSurfaceElevated),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? color.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered
                  ? color
                  : (isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary),
            ),
          ),
        ),
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
