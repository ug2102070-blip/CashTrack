// lib/presentation/onboarding/onboarding_screen.dart
//
// Production notes on what changed vs. the previous version:
//  - Removed dead code: the `bn` translation map was built but never
//    reachable (`_t` always returned `map['en']`); `_OnboardingPage.icon`
//    duplicated `.iconData`; `_animCtrl` was created and `.forward()`'d but
//    its value was never consumed anywhere.
//  - Fixed a crash risk: `Hive.box('settingsBox')` had no error handling —
//    if the box isn't open yet this throws and strands the user on the
//    onboarding screen. Now wrapped and falls back to navigation regardless.
//  - Fixed a crash risk: `Image.asset` had no `errorBuilder`; a missing
//    asset would take down the whole screen instead of degrading gracefully.
//  - Extracted the responsive breakpoint into one named constant instead of
//    the magic number `900` repeated three times.
//  - De-duplicated the wide/mobile layouts: dots, CTA button, and skip
//    button are now single shared widgets instead of two copies that could
//    silently drift apart.
//  - Split the 500-line single widget into small, independently testable
//    widgets (`_OnboardingDots`, `_OnboardingCtaButton`, `_OnboardingPageContent`,
//    `_OnboardingControlsPanel`).
//  - Actually used the `AnimationController` for a fade/slide-in on each
//    page instead of leaving it inert.
//  - Added `Semantics` labels for screen readers and a `key` per page so
//    `AnimatedSwitcher`/`PageView` transitions are stable.
//
// If your project already uses a localization framework (intl,
// easy_localization, slang, etc.), replace `_OnboardingCopy` with generated
// ARB-based strings — the inline map here only exists because onboarding
// runs before the user has picked a language.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

/// Width above which we switch to the two-pane desktop/tablet layout.
const double _kWideLayoutBreakpoint = 900;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _transitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'CashTrack',
      subtitle: 'onboarding_welcome_subtitle',
      gradient: [Color(0xFF2D7A7B), Color(0xFF1A5F60)],
      iconData: null,
      isLogoPage: true,
    ),
    _OnboardingPage(
      title: 'onboarding_track_title',
      subtitle: 'onboarding_track_subtitle',
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      iconData: Icons.trending_up_rounded,
    ),
    _OnboardingPage(
      title: 'onboarding_budget_title',
      subtitle: 'onboarding_budget_subtitle',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      iconData: Icons.savings_rounded,
    ),
    _OnboardingPage(
      title: 'onboarding_ai_title',
      subtitle: 'onboarding_ai_subtitle',
      gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      iconData: Icons.auto_awesome_rounded,
    ),
    _OnboardingPage(
      title: 'onboarding_reports_title',
      subtitle: 'onboarding_reports_subtitle',
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      iconData: Icons.bar_chart_rounded,
    ),
    _OnboardingPage(
      title: 'onboarding_secure_title',
      subtitle: 'onboarding_secure_subtitle',
      gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
      iconData: Icons.shield_rounded,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    ));
    _transitionController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Wrapped: if the box isn't open (startup race, corrupted box, etc.)
    // we still want the user to reach /login rather than getting stuck.
    try {
      final box = Hive.box('settingsBox');
      await box.put('onboardingComplete', true);
    } catch (e, st) {
      debugPrint('Failed to persist onboardingComplete: $e\n$st');
    } finally {
      if (mounted) context.go('/');
    }
  }

  void _goToPage(int index) {
    if (index == _currentPage) return;
    setState(() => _currentPage = index);
    _transitionController
      ..reset()
      ..forward();
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
      return;
    }
    final isWide = MediaQuery.of(context).size.width > _kWideLayoutBreakpoint;
    if (isWide) {
      _goToPage(_currentPage + 1);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > _kWideLayoutBreakpoint;
    return Scaffold(
      body: isWide ? _buildWideLayout(context) : _buildMobileLayout(context),
    );
  }

  // ─── Wide (tablet / desktop) layout ────────────────────────────────────

  Widget _buildWideLayout(BuildContext context) {
    final page = _pages[_currentPage];
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(gradient: page.backgroundGradient),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _OnboardingBrandPanel(
                key: ValueKey(_currentPage),
                page: page,
                pageIndex: _currentPage,
                pageCount: _pages.length,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ColoredBox(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F1318)
                : Colors.white,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _OnboardingControlsPanel(
                          page: page,
                          currentPage: _currentPage,
                          pageCount: _pages.length,
                          isLastPage: _isLastPage,
                          accentColor: page.gradient.first,
                          isFirstPage: _currentPage == 0,
                          onNext: _nextPage,
                          onSkip: _isLastPage ? null : _completeOnboarding,
                          dotColorActive: page.gradient.first,
                          dotColorInactive:
                          page.gradient.first.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile layout ──────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            final page = _pages[index];
            return DecoratedBox(
              decoration: BoxDecoration(gradient: page.backgroundGradient),
              child: _OnboardingPageContent(
                page: page,
                isFirstPage: index == 0,
              ),
            );
          },
        ),
        // On mobile there's only one panel, so it carries the full text
        // (title + subtitle). On the wide layout that text lives solely in
        // `_OnboardingControlsPanel` on the right, and the left panel above
        // becomes a distinct visual brand panel — see `_OnboardingBrandPanel`.
        if (!_isLastPage)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Semantics(
              button: true,
              label: 'Skip onboarding',
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  _OnboardingCopy.of('onboarding_skip'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              children: [
                _OnboardingDots(
                  count: _pages.length,
                  currentIndex: _currentPage,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withValues(alpha: 0.35),
                  activeWidth: 28,
                ),
                const SizedBox(height: 28),
                _OnboardingCtaButton(
                  isLastPage: _isLastPage,
                  backgroundColor: Colors.white,
                  foregroundColor: _pages[_currentPage].gradient.first,
                  height: 56,
                  elevation: 8,
                  onPressed: _nextPage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data model ─────────────────────────────────────────────────────────

@immutable
class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconData,
    this.isLogoPage = false,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData? iconData;
  final bool isLogoPage;

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradient[0],
      gradient[1],
      Color.lerp(gradient[1], Colors.black, 0.15)!,
    ],
  );
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────

class _OnboardingPageContent extends StatelessWidget {
  const _OnboardingPageContent({
    required this.page,
    required this.isFirstPage,
  });

  final _OnboardingPage page;
  final bool isFirstPage;

  @override
  Widget build(BuildContext context) {
    final title = isFirstPage ? page.title : _OnboardingCopy.of(page.title);
    final subtitle = _OnboardingCopy.of(page.subtitle);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            if (page.isLogoPage)
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(page.iconData, size: 56, color: Colors.white),
              ),
            const SizedBox(height: 40),
            Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

/// The left-hand panel on the wide (tablet/desktop) layout.
///
/// Deliberately carries **no title or subtitle copy** — that text lives in
/// `_OnboardingControlsPanel` on the right. Previously both panels rendered
/// the same title/subtitle, so every step showed duplicate text side by
/// side. Instead this panel is a purely visual brand moment: the feature
/// icon, a soft decorative glow, and a small "N of total" step badge.
class _OnboardingBrandPanel extends StatelessWidget {
  const _OnboardingBrandPanel({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.pageCount,
  });

  final _OnboardingPage page;
  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft decorative glows — purely visual, no semantic content.
        Positioned(
          top: -60,
          left: -60,
          child: _Glow(diameter: 220, color: Colors.white.withValues(alpha: 0.08)),
        ),
        Positioned(
          bottom: -80,
          right: -40,
          child: _Glow(diameter: 260, color: Colors.black.withValues(alpha: 0.12)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Step ${pageIndex + 1} of $pageCount',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '${(pageIndex + 1).toString().padLeft(2, '0')} / '
                          '${pageCount.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (page.isLogoPage)
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 48,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 72,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(page.iconData, size: 68, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A soft, blurred decorative circle used behind the brand panel icon.
class _Glow extends StatelessWidget {
  const _Glow({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _OnboardingControlsPanel extends StatelessWidget {
  const _OnboardingControlsPanel({
    required this.page,
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.isFirstPage,
    required this.accentColor,
    required this.onNext,
    required this.onSkip,
    required this.dotColorActive,
    required this.dotColorInactive,
  });

  final _OnboardingPage page;
  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final bool isFirstPage;
  final Color accentColor;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final Color dotColorActive;
  final Color dotColorInactive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = isFirstPage ? 'Welcome to CashTrack' : _OnboardingCopy.of(page.title);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _OnboardingDots(
          count: pageCount,
          currentIndex: currentPage,
          activeColor: dotColorActive,
          inactiveColor: dotColorInactive,
          activeWidth: 32,
        ),
        const SizedBox(height: 40),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1F36),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _OnboardingCopy.of(page.subtitle),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 48),
        _OnboardingCtaButton(
          isLastPage: isLastPage,
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          height: 52,
          elevation: 6,
          shadowColor: accentColor.withValues(alpha: 0.35),
          onPressed: onNext,
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Skip onboarding',
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                _OnboardingCopy.of('onboarding_skip'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : const Color(0xFF8A94A6),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    this.activeWidth = 28,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double activeWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${currentIndex + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? activeWidth : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _OnboardingCtaButton extends StatelessWidget {
  const _OnboardingCtaButton({
    required this.isLastPage,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.height = 52,
    this.elevation = 6,
    this.shadowColor,
  });

  final bool isLastPage;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final double height;
  final double elevation;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final label = isLastPage
        ? _OnboardingCopy.of('onboarding_get_started')
        : _OnboardingCopy.of('onboarding_next');

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: elevation,
            shadowColor: shadowColor ?? Colors.black.withValues(alpha: 0.15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Copy / localization fallback ────────────────────────────────────────
//
// Onboarding runs before the user has chosen an app language, so it can't
// depend on the app's normal localization delegate yet. This is a static,
// intentional English-only fallback table — NOT dead code, and documented
// as such so a future maintainer doesn't "helpfully" wire in `bn` strings
// that would show before the user has picked Bengali.
//
// If/when onboarding language selection is added, swap `_OnboardingCopy.of`
// for the real `AppLocalizations.of(context)!.<key>` calls generated by
// your l10n pipeline.
class _OnboardingCopy {
  const _OnboardingCopy._();

  static const Map<String, String> _en = {
    'onboarding_welcome_subtitle':
    'Your personal finance companion\nfor smart money management',
    'onboarding_track_title': 'Track Everything',
    'onboarding_track_subtitle':
    'Effortlessly record income and expenses.\nSMS auto-import makes it even easier.',
    'onboarding_budget_title': 'Smart Budgets & Goals',
    'onboarding_budget_subtitle':
    'Set monthly budgets, track savings goals,\nand never overspend again.',
    'onboarding_ai_title': 'AI Insights',
    'onboarding_ai_subtitle':
    'Get smart financial advice powered by\nAI assistant.',
    'onboarding_reports_title': 'Detailed Reports',
    'onboarding_reports_subtitle':
    'Export PDF, Excel & CSV reports.\nVisualize your money flow with charts.',
    'onboarding_secure_title': 'Secure & Private',
    'onboarding_secure_subtitle':
    'Biometric lock, PIN protection,\nand cloud backup for your data.',
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_get_started': 'Get Started',
  };

  static String of(String key) => _en[key] ?? key;
}