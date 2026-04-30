// lib/presentation/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animCtrl;

  static const _pages = [
    _OnboardingPage(
      icon: null, // Logo page — uses image
      title: 'CashTrack',
      subtitle: 'onboarding_welcome_subtitle',
      gradient: [Color(0xFF2D7A7B), Color(0xFF1A5F60)],
      iconData: null,
    ),
    _OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'onboarding_track_title',
      subtitle: 'onboarding_track_subtitle',
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      iconData: Icons.trending_up_rounded,
    ),
    _OnboardingPage(
      icon: Icons.savings_rounded,
      title: 'onboarding_budget_title',
      subtitle: 'onboarding_budget_subtitle',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      iconData: Icons.savings_rounded,
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'onboarding_ai_title',
      subtitle: 'onboarding_ai_subtitle',
      gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      iconData: Icons.auto_awesome_rounded,
    ),
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      title: 'onboarding_reports_title',
      subtitle: 'onboarding_reports_subtitle',
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      iconData: Icons.bar_chart_rounded,
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'onboarding_secure_title',
      subtitle: 'onboarding_secure_subtitle',
      gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
      iconData: Icons.shield_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final box = Hive.box('settingsBox');
    await box.put('onboardingComplete', true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  // Localization helper — falls back to key if context not ready
  String _t(String key) {
    const onboardingTexts = <String, Map<String, String>>{
      'onboarding_welcome_subtitle': {
        'en': 'Your personal finance companion\nfor smart money management',
        'bn': 'আপনার ব্যক্তিগত অর্থ ব্যবস্থাপনার\nস্মার্ট সহচর',
      },
      'onboarding_track_title': {
        'en': 'Track Everything',
        'bn': 'সব ট্র্যাক করুন',
      },
      'onboarding_track_subtitle': {
        'en': 'Effortlessly record income and expenses.\nSMS auto-import makes it even easier.',
        'bn': 'আয় ও ব্যয় সহজেই রেকর্ড করুন।\nSMS অটো-ইমপোর্ট আরও সহজ করে।',
      },
      'onboarding_budget_title': {
        'en': 'Smart Budgets & Goals',
        'bn': 'স্মার্ট বাজেট ও লক্ষ্য',
      },
      'onboarding_budget_subtitle': {
        'en': 'Set monthly budgets, track savings goals,\nand never overspend again.',
        'bn': 'মাসিক বাজেট সেট করুন, সঞ্চয় ট্র্যাক করুন,\nখরচ নিয়ন্ত্রণ করুন।',
      },
      'onboarding_ai_title': {
        'en': 'AI Insights',
        'bn': 'এআই ইনসাইটস',
      },
      'onboarding_ai_subtitle': {
        'en': 'Get smart financial advice powered by\nGoogle Gemini AI assistant.',
        'bn': 'Google Gemini AI দিয়ে\nস্মার্ট আর্থিক পরামর্শ পান।',
      },
      'onboarding_reports_title': {
        'en': 'Detailed Reports',
        'bn': 'বিস্তারিত রিপোর্ট',
      },
      'onboarding_reports_subtitle': {
        'en': 'Export PDF, Excel & CSV reports.\nVisualize your money flow with charts.',
        'bn': 'PDF, Excel ও CSV রিপোর্ট এক্সপোর্ট করুন।\nচার্টে অর্থ প্রবাহ দেখুন।',
      },
      'onboarding_secure_title': {
        'en': 'Secure & Private',
        'bn': 'নিরাপদ ও প্রাইভেট',
      },
      'onboarding_secure_subtitle': {
        'en': 'Biometric lock, PIN protection,\nand cloud backup for your data.',
        'bn': 'বায়োমেট্রিক লক, পিন সুরক্ষা,\nও ক্লাউড ব্যাকআপ।',
      },
      'onboarding_skip': {
        'en': 'Skip',
        'bn': 'স্কিপ',
      },
      'onboarding_next': {
        'en': 'Next',
        'bn': 'পরবর্তী',
      },
      'onboarding_get_started': {
        'en': 'Get Started',
        'bn': 'শুরু করুন',
      },
    };

    final map = onboardingTexts[key];
    if (map == null) return key;
    // Always use English for onboarding — language selection hasn't happened yet
    return map['en'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page, index);
            },
          ),

          // Skip button (top-right)
          if (!isLastPage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  _t('onboarding_skip'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].gradient[0],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage
                                ? _t('onboarding_get_started')
                                : _t('onboarding_next'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.gradient[0],
            page.gradient[1],
            Color.lerp(page.gradient[1], Colors.black, 0.15)!,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Icon or Logo
              if (index == 0)
                // Logo page
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
                  child: Icon(
                    page.iconData,
                    size: 56,
                    color: Colors.white,
                  ),
                ),

              const SizedBox(height: 40),

              // Title
              Text(
                index == 0 ? page.title : _t(page.title),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                _t(page.subtitle),
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
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconData,
  });

  final IconData? icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData? iconData;
}
