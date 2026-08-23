// lib/presentation/landing/landing_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late final ScrollController _scrollCtrl;
  late final AnimationController _heroAnimCtrl;
  double _scrollOffset = 0;

  // GlobalKeys for scroll mapping
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollCtrl.offset);
      });
    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroAnimCtrl.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // 1. Interactive Grid Mesh Background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridMeshPainter(isDark: isDark),
            ),
          ),

          // 2. Green Accent Ribbon Background (matching the demo style)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GreenAccentPainter(isDark: isDark),
              ),
            ),
          ),

          // 3. Background gradient orbs (Stripe/Linear ambient style)
          _buildBackgroundOrbs(isDark, size),

          // 3. Scrollable content
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // Sticky Nav Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _LandingNavBarDelegate(
                  scrollOffset: _scrollOffset,
                  isDark: isDark,
                  isWide: isWide,
                  onLogin: () => context.go('/login'),
                  onLinkTap: (label) {
                    if (label == 'Features') _scrollToSection(_featuresKey);
                    if (label == 'Pricing') _scrollToSection(_pricingKey);
                    if (label == 'FAQ') _scrollToSection(_faqKey);
                  },
                ),
              ),

              // Hero Section
              SliverToBoxAdapter(
                child: _buildHeroSection(context, isDark, isWide),
              ),

              // Interactive Dashboard Preview
              SliverToBoxAdapter(
                child: _buildDashboardPreview(context, isDark, isWide),
              ),

              // Features
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _featuresKey,
                  child: _buildFeatureShowcase(context, isDark, isWide),
                ),
              ),

              // Stats Ticker
              SliverToBoxAdapter(
                child: _buildStatsTicker(context, isDark, isWide),
              ),

              // Testimonials
              SliverToBoxAdapter(
                child: _buildTestimonials(context, isDark, isWide),
              ),

              // Pricing
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _pricingKey,
                  child: _buildPricing(context, isDark, isWide),
                ),
              ),

              // FAQ
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _faqKey,
                  child: _buildFAQ(context, isDark, isWide),
                ),
              ),

              // CTA Banner
              SliverToBoxAdapter(
                child: _buildCTABanner(context, isDark, isWide),
              ),

              // Footer
              SliverToBoxAdapter(
                child: _buildFooter(context, isDark, isWide),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Background Ambient Glows ──────────────────────────────────────────────
  Widget _buildBackgroundOrbs(bool isDark, Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.35,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.10 : 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Section ──────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context, bool isDark, bool isWide) {
    final heroFade = CurvedAnimation(
      parent: _heroAnimCtrl,
      curve: Curves.easeOut,
    );
    final heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroAnimCtrl,
      curve: Curves.easeOutCubic,
    ));

    final textColumn = Column(
      crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Title text matching the demo image layout
        Text(
          'The only app that\ngets your money\ninto shape',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isWide ? 58 : 34,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -1.8,
            color: isDark ? AppColors.darkText : const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 20),

        // Subtitle matching the demo image layout
        Text(
          'Manage money on the go in the app',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: AppTextStyles.bodyLg.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: isWide ? 18 : 15,
          ),
        ),
        const SizedBox(height: 32),

        // Download Badges
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          children: const [
            _AppStoreBadge(),
            _GooglePlayBadge(),
          ],
        ),
      ],
    );

    const mockupsColumn = FittedBox(
      fit: BoxFit.contain,
      child: _DeviceMockupsStack(),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 20,
        vertical: isWide ? 100 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FadeTransition(
            opacity: heroFade,
            child: SlideTransition(
              position: heroSlide,
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 5, child: textColumn),
                        const SizedBox(width: 40),
                        const Expanded(flex: 6, child: mockupsColumn),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        textColumn,
                        const SizedBox(height: 50),
                        mockupsColumn,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Dashboard Preview Mockup ──────────────────────────────────────────────
  Widget _buildDashboardPreview(BuildContext context, bool isDark, bool isWide) {
    return const SizedBox.shrink();
  }

  // ─── Features Showcase ─────────────────────────────────────────────────────
  Widget _buildFeatureShowcase(BuildContext context, bool isDark, bool isWide) {
    final features = [
      _FeatureData(
        icon: Icons.insights_rounded,
        color: AppColors.primary,
        title: 'Smart Analytics',
        desc: 'Personalized spending summaries, heatmap matrices, and intelligent trend calculations.',
      ),
      _FeatureData(
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
        title: 'Budget Enforcer',
        desc: 'Interactive visual budgets with alerts triggered before you exceed category thresholds.',
      ),
      _FeatureData(
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'AI Advisor',
        desc: 'Calculates your overall Financial Health score and flags redundant subscriptions.',
      ),
      _FeatureData(
        icon: Icons.trending_up_rounded,
        color: AppColors.info,
        title: 'Goal Planner',
        desc: 'Custom savings milestones with predictive deadlines and deposit schedule estimators.',
      ),
      _FeatureData(
        icon: Icons.people_alt_rounded,
        color: AppColors.warning,
        title: 'Split Expenses',
        desc: 'Share group bills, specify unequal ratios, and settle balances seamlessly.',
      ),
      _FeatureData(
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF10B981),
        title: 'Zero Latency Sync',
        desc: 'Offline-first database operations with automatic background cloud synchronization.',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: isWide ? 80 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionBadge(label: 'FEATURES', isDark: isDark),
              const SizedBox(height: 16),
              Text(
                'Everything you need to manage money smarter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isWide ? 40 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -1.5,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: features.map((f) {
                  final cardWidth = isWide
                      ? (MediaQuery.of(context).size.width.clamp(0, 1200) - 200) / 3
                      : double.infinity;
                  return SizedBox(
                    width: cardWidth,
                    child: _FeatureCard(feature: f, isDark: isDark),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Ticker ──────────────────────────────────────────────────────────
  Widget _buildStatsTicker(BuildContext context, bool isDark, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: '50K+', label: 'Active Savers', isDark: isDark),
              _StatDivider(isDark: isDark),
              _StatItem(value: '৳10Cr+', label: 'Tracked Assets', isDark: isDark),
              _StatDivider(isDark: isDark),
              _StatItem(value: '4.9★', label: 'App Store Rating', isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Testimonials ──────────────────────────────────────────────────────────
  Widget _buildTestimonials(BuildContext context, bool isDark, bool isWide) {
    final testimonials = [
      _TestimonialData(
        quote: 'CashTrack has completely streamlined my freelance budgeting. The insights saved me thousands.',
        name: 'Sayed Rahman',
        role: 'Creative Director',
        initials: 'SR',
      ),
      _TestimonialData(
        quote: 'The offline-first support is excellent. I log expenses on the go and sync when back online.',
        name: 'Jannat Khan',
        role: 'Tech Consultant',
        initials: 'JK',
      ),
      _TestimonialData(
        quote: 'Shared group budgets made tracking family expenses stress-free. Very high-quality UX.',
        name: 'Imran Chowdhury',
        role: 'Business Owner',
        initials: 'IC',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: isWide ? 80 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionBadge(label: 'REVIEWS', isDark: isDark),
              const SizedBox(height: 16),
              Text(
                'Trusted by smart teams & individuals',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isWide ? 40 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -1.5,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 48),
              isWide
                  ? Row(
                      children: testimonials
                          .map((t) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: _TestimonialCard(data: t, isDark: isDark),
                                ),
                              ))
                          .toList(),
                    )
                  : Column(
                      children: testimonials
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _TestimonialCard(data: t, isDark: isDark),
                              ))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pricing Plan Options ──────────────────────────────────────────────────
  Widget _buildPricing(BuildContext context, bool isDark, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: isWide ? 80 : 40,
      ),
      color: isDark
          ? AppColors.darkSurfaceElevated.withValues(alpha: 0.15)
          : AppColors.lightSurfaceElevated.withValues(alpha: 0.4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              _SectionBadge(label: 'PRICING', isDark: isDark),
              const SizedBox(height: 16),
              Text(
                'Simple transparent pricing plans',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isWide ? 40 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -1.5,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 48),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PricingCard(
                            title: 'Free',
                            price: '0',
                            period: 'forever',
                            features: const [
                              'Unlimited transaction logging',
                              'Standard category charts',
                              '3 active budgets limit',
                              'Offline local database storage',
                            ],
                            isDark: isDark,
                            onTap: () => context.go('/login'),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _PricingCard(
                            title: 'Pro',
                            price: '149',
                            period: '/month',
                            isPopular: true,
                            features: const [
                              'All Free plan benefits',
                              'AI-Powered Health Score & insights',
                              'Unlimited goal milestones',
                              'Shared group expense splitting',
                              'Priority cloud backups',
                              'PDF & CSV report generation',
                            ],
                            isDark: isDark,
                            onTap: () => context.go('/login'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _PricingCard(
                          title: 'Free',
                          price: '0',
                          period: 'forever',
                          features: const [
                            'Unlimited transaction logging',
                            'Standard category charts',
                            '3 active budgets limit',
                          ],
                          isDark: isDark,
                          onTap: () => context.go('/login'),
                        ),
                        const SizedBox(height: 20),
                        _PricingCard(
                          title: 'Pro',
                          price: '149',
                          period: '/month',
                          isPopular: true,
                          features: const [
                            'All Free plan benefits',
                            'AI-Powered Health Score & insights',
                            'Unlimited goal milestones',
                            'Shared group expense splitting',
                          ],
                          isDark: isDark,
                          onTap: () => context.go('/login'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FAQ ───────────────────────────────────────────────────────────────────
  Widget _buildFAQ(BuildContext context, bool isDark, bool isWide) {
    final faqs = [
      _FAQItem('How does the offline mode work?',
          'CashTrack saves your logs locally in your browser/device database immediately. Once you establish internet connectivity, your updates safely sync back to your Firebase account.'),
      _FAQItem('Is my bank details requested or linked?',
          'No, CashTrack is a privacy-focused manual ledger. We do not require linking or signing in with your banking credentials.'),
      _FAQItem('Is the Pro subscription billed automatically?',
          'Pro billing is handled transparently without hidden recurring cycles. Cancel or reactivate at any time from your settings panel.'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: isWide ? 80 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _SectionBadge(label: 'FAQ', isDark: isDark),
              const SizedBox(height: 16),
              Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isWide ? 36 : 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -1.2,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 40),
              ...faqs.map((faq) => _FAQExpansionTile(faq: faq, isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CTA Banner ────────────────────────────────────────────────────────────
  Widget _buildCTABanner(BuildContext context, bool isDark, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: isWide ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: EdgeInsets.all(isWide ? 56 : 32),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Join CashTrack today',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isWide ? 36 : 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unleash the full potential of smart tracking and AI predictions.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 32),
                _LandingButton(
                  label: 'Start Now',
                  isPrimary: false,
                  isWhite: true,
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, bool isDark, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 48,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand block
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'CashTrack',
                                style: AppTextStyles.headingSm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Premium personal finance ledger.',
                            style: AppTextStyles.bodySm.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Navigation link blocks
                    _FooterLinkColumn(
                      title: 'Product',
                      links: const ['Features', 'Pricing', 'FAQ'],
                      isDark: isDark,
                      onLinkTap: (label) {
                        if (label == 'Features') _scrollToSection(_featuresKey);
                        if (label == 'Pricing') _scrollToSection(_pricingKey);
                        if (label == 'FAQ') _scrollToSection(_faqKey);
                      },
                    ),
                    _FooterLinkColumn(
                      title: 'Platform',
                      links: const ['Android', 'iOS', 'Web App'],
                      isDark: isDark,
                      onLinkTap: (label) => context.go('/login'),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      'CashTrack © 2026',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Custom Mesh Grid Painter ──────────────────────────────────────────────
class _GridMeshPainter extends CustomPainter {
  final bool isDark;
  _GridMeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02)
      ..strokeWidth = 1.5;

    const double step = 50.0;

    // Draw grid mesh lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw subtle intersecting dots for the developer mesh feel
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridMeshPainter oldDelegate) => false;
}

// ─── Reusable Sticky Nav Bar Delegate ────────────────────────────────────────
class _LandingNavBarDelegate extends SliverPersistentHeaderDelegate {
  final double scrollOffset;
  final bool isDark;
  final bool isWide;
  final VoidCallback onLogin;
  final ValueChanged<String> onLinkTap;

  _LandingNavBarDelegate({
    required this.scrollOffset,
    required this.isDark,
    required this.isWide,
    required this.onLogin,
    required this.onLinkTap,
  });

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scrolled = scrollOffset > 20;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: scrolled ? 16 : 0, sigmaY: scrolled ? 16 : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20),
          decoration: BoxDecoration(
            color: scrolled
                ? (isDark ? AppColors.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9))
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: scrolled
                    ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.5))
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            children: [
              // Logo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CashTrack',
                    style: AppTextStyles.headingSm.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Navigation Links
              if (isWide) ...[
                _NavLink(label: 'Features', isDark: isDark, onTap: () => onLinkTap('Features')),
                _NavLink(label: 'Pricing', isDark: isDark, onTap: () => onLinkTap('Pricing')),
                _NavLink(label: 'FAQ', isDark: isDark, onTap: () => onLinkTap('FAQ')),
                const SizedBox(width: 24),
              ],

              // CTA button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onLogin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sign In',
                      style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LandingNavBarDelegate oldDelegate) {
    return scrollOffset != oldDelegate.scrollOffset ||
        isDark != oldDelegate.isDark ||
        isWide != oldDelegate.isWide;
  }
}

// ─── Nav Link ────────────────────────────────────────────────────────────────
class _NavLink extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.isDark, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.label,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: _hovered
                  ? AppColors.primary
                  : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Trust Badges & Buttons ──────────────────────────────────────────────────
class _SectionBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionBadge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LandingButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool isDark;
  final bool isWhite;
  final VoidCallback onTap;

  const _LandingButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDark = false,
    this.isWhite = false,
  });

  @override
  State<_LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<_LandingButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isWhite
                ? Colors.white
                : widget.isPrimary
                    ? AppColors.primary
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isWhite
                  ? Colors.white
                  : widget.isPrimary
                      ? AppColors.primary
                      : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1.5,
            ),
            boxShadow: _hovered && widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.buttonSmall.copyWith(
              color: widget.isWhite
                  ? AppColors.primary
                  : widget.isPrimary
                      ? Colors.white
                      : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feature Card ────────────────────────────────────────────────────────────
class _FeatureData {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  _FeatureData({required this.icon, required this.color, required this.title, required this.desc});
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final bool isDark;
  const _FeatureCard({required this.feature, required this.isDark});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? f.color.withValues(alpha: 0.4)
                : (widget.isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6)),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: f.color.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: f.color.withValues(alpha: widget.isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(f.icon, color: f.color, size: 22),
            ),
            const SizedBox(height: 20),
            Text(
              f.title,
              style: AppTextStyles.headingSm.copyWith(
                color: widget.isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              f.desc,
              style: AppTextStyles.bodySm.copyWith(
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Ticker Widgets ─────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  const _StatItem({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.5),
    );
  }
}

// ─── Testimonial Card ────────────────────────────────────────────────────────
class _TestimonialData {
  final String quote;
  final String name;
  final String role;
  final String initials;
  _TestimonialData({required this.quote, required this.name, required this.role, required this.initials});
}

class _TestimonialCard extends StatelessWidget {
  final _TestimonialData data;
  final bool isDark;
  const _TestimonialCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 16, color: AppColors.warning)),
          ),
          const SizedBox(height: 16),
          Text(
            '"${data.quote}"',
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  data.initials,
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                  Text(
                    data.role,
                    style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pricing Card ────────────────────────────────────────────────────────────
class _PricingCard extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isDark;
  final bool isPopular;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isDark,
    required this.onTap,
    this.isPopular = false,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isPopular
                ? AppColors.primary.withValues(alpha: 0.5)
                : (widget.isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6)),
            width: widget.isPopular ? 2 : 1,
          ),
          boxShadow: widget.isPopular && _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.headingSm.copyWith(
                    color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                if (widget.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'POPULAR',
                      style: AppTextStyles.overline.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${widget.price}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    widget.period,
                    style: AppTextStyles.bodySm.copyWith(
                      color: widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LandingButton(
              label: widget.isPopular ? 'Start Free Trial' : 'Get Started',
              isPrimary: widget.isPopular,
              isDark: widget.isDark,
              onTap: widget.onTap,
            ),
            const SizedBox(height: 24),
            ...widget.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: widget.isPopular ? AppColors.primary : AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: AppTextStyles.bodySm.copyWith(
                            color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ Expansion Card ──────────────────────────────────────────────────────
class _FAQItem {
  final String question;
  final String answer;
  _FAQItem(this.question, this.answer);
}

class _FAQExpansionTile extends StatefulWidget {
  final _FAQItem faq;
  final bool isDark;
  const _FAQExpansionTile({required this.faq, required this.isDark});

  @override
  State<_FAQExpansionTile> createState() => _FAQExpansionTileState();
}

class _FAQExpansionTileState extends State<_FAQExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : (widget.isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6)),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: _expanded ? AppColors.primary : (widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            ),
          ),
          title: Text(
            widget.faq.question,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          children: [
            Text(
              widget.faq.answer,
              style: AppTextStyles.bodySm.copyWith(
                height: 1.7,
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer Link Column ──────────────────────────────────────────────────────
class _FooterLinkColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  final bool isDark;
  final ValueChanged<String>? onLinkTap;

  const _FooterLinkColumn({
    required this.title,
    required this.links,
    required this.isDark,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
          ),
          const SizedBox(height: 16),
          ...links.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onLinkTap?.call(link),
                    child: Text(
                      link,
                      style: AppTextStyles.bodySm.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Custom Painter for green accent diagonal ribbons ───────────────────────
class _GreenAccentPainter extends CustomPainter {
  final bool isDark;
  _GreenAccentPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLightGreen = Paint()
      ..color = const Color(0xFF00C57D).withValues(alpha: isDark ? 0.25 : 0.85)
      ..style = PaintingStyle.fill;
    final paintDarkGreen = Paint()
      ..color = const Color(0xFF059669).withValues(alpha: isDark ? 0.15 : 0.45)
      ..style = PaintingStyle.fill;

    // Top-right light green triangle
    final path1 = Path()
      ..moveTo(size.width * 0.75, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..close();
    canvas.drawPath(path1, paintLightGreen);

    // Top-right dark green accent ribbon next to it
    final path2 = Path()
      ..moveTo(size.width * 0.84, 0)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.13)
      ..close();
    canvas.drawPath(path2, paintDarkGreen);

    // Bottom-right light green corner shape
    final path3 = Path()
      ..moveTo(size.width, size.height * 0.88)
      ..lineTo(size.width * 0.88, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path3, paintLightGreen);
  }

  @override
  bool shouldRepaint(covariant _GreenAccentPainter oldDelegate) => false;
}

// ─── App Store and Google Play Download Badges ──────────────────────────────
class _AppStoreBadge extends StatelessWidget {
  const _AppStoreBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apple, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Download on the',
                style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'Inter', height: 1.0),
              ),
              Text(
                'App Store',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter', height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GooglePlayBadge extends StatelessWidget {
  const _GooglePlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(18, 20),
            painter: _PlayStoreLogoPainter(),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GET IT ON',
                style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'Inter', height: 1.0),
              ),
              Text(
                'Google Play',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter', height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayStoreLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blue triangle
    final p1 = Path()
      ..moveTo(2, 2)
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(2, h - 2)
      ..close();
    canvas.drawPath(p1, Paint()..color = const Color(0xFF00E5FF));

    // Green triangle
    final p2 = Path()
      ..moveTo(2, 2)
      ..lineTo(w - 2, h * 0.5)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(p2, Paint()..color = const Color(0xFF00E676));

    // Orange/Red triangle
    final p3 = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w - 2, h * 0.5)
      ..lineTo(2, h - 2)
      ..close();
    canvas.drawPath(p3, Paint()..color = const Color(0xFFFF3D00));
  }

  @override
  bool shouldRepaint(covariant _PlayStoreLogoPainter oldDelegate) => false;
}

// ─── High-Fidelity Overlapping Mockups ──────────────────────────────────────
class _DeviceMockupsStack extends StatelessWidget {
  const _DeviceMockupsStack();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 580,
      height: 380,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Macbook in the background
          Positioned(
            right: 0,
            bottom: 40,
            child: _MacbookMockup(),
          ),
          // 2. Green phone on the left, slightly behind the white phone
          Positioned(
            left: 20,
            bottom: 10,
            child: _GreenPhoneMockup(),
          ),
          // 3. White phone in center/front
          Positioned(
            left: 175,
            bottom: 0,
            child: _WhitePhoneMockup(),
          ),
        ],
      ),
    );
  }
}

class _GreenPhoneMockup extends StatelessWidget {
  const _GreenPhoneMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 345,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1E293B), width: 6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1:42', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.black, size: 8),
                      SizedBox(width: 2),
                      Icon(Icons.battery_full_rounded, color: Colors.black, size: 8),
                    ],
                  )
                ],
              ),
            ),
            // Header: "Analytics"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.black54, size: 10),
                  ),
                ],
              ),
            ),
            // Date Filter: "July 2026"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: Color(0xFF0F766E), size: 6),
                        SizedBox(width: 3),
                        Text(
                          'July 2026',
                          style: TextStyle(color: Color(0xFF0F766E), fontSize: 6, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Grid 2x2 cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _analyticsGridCard('Income', '৳75', const Color(0xFF10B981), Icons.arrow_downward_rounded)),
                      const SizedBox(width: 6),
                      Expanded(child: _analyticsGridCard('Expense', '৳685', const Color(0xFFEF4444), Icons.arrow_upward_rounded)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _analyticsGridCard('Net Savings', '৳610', const Color(0xFFEF4444), Icons.trending_down_rounded, sub: 'Deficit')),
                      const SizedBox(width: 6),
                      Expanded(child: _analyticsGridCard('Savings Rate', '813.3%', const Color(0xFFEF4444), Icons.percent_rounded)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Category Breakdown Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, color: Color(0xFF0F766E), size: 9),
                        SizedBox(width: 4),
                        Text(
                          'Category Breakdown',
                          style: TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Chart bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _categoryBar('Food', const Color(0xFF6366F1), 48),
                        _categoryBar('Ent.', const Color(0xFF10B981), 28),
                        _categoryBar('Educ.', const Color(0xFFF59E0B), 20),
                        _categoryBar('Rocket', const Color(0xFFEF4444), 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Bottom navigation bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.dashboard_rounded, color: Colors.black26, size: 12),
                      Icon(Icons.insights_rounded, color: Color(0xFF0F766E), size: 12), // Selected
                      SizedBox(width: 14), // Gap for FAB
                      Icon(Icons.grid_view_rounded, color: Colors.black26, size: 12),
                      Icon(Icons.settings_rounded, color: Colors.black26, size: 12),
                    ],
                  ),
                  Positioned(
                    top: -12,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D7A7B),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analyticsGridCard(String title, String val, Color iconCol, IconData icon, {String? sub}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: iconCol.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: iconCol, size: 8),
              ),
              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, height: 1.0),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.black38, fontSize: 6, height: 1.2),
          ),
          if (sub != null)
            Text(
              sub,
              style: TextStyle(color: iconCol, fontSize: 5, fontWeight: FontWeight.bold, height: 1.0),
            ),
        ],
      ),
    );
  }

  Widget _categoryBar(String label, Color color, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 5)),
      ],
    );
  }
}

class _Segment {
  final double start;
  final double sweep;
  final Color color;
  _Segment({required this.start, required this.sweep, required this.color});
}

class _DonutChartRealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;

    // Real pie sections representing the dashboard breakdown:
    // Magenta/Red (Food 51%), Green (Entertainment 26%), Orange (Education 15%), Blue/Violet (other/Rocket 8%)
    final segments = [
      _Segment(start: -0.5 * 3.1415, sweep: 0.51 * 2 * 3.1415, color: const Color(0xFFEF4444)),
      _Segment(start: (-0.5 + 0.51) * 2 * 3.1415, sweep: 0.26 * 2 * 3.1415, color: const Color(0xFF10B981)),
      _Segment(start: (-0.5 + 0.51 + 0.26) * 2 * 3.1415, sweep: 0.15 * 2 * 3.1415, color: const Color(0xFFF59E0B)),
      _Segment(start: (-0.5 + 0.51 + 0.26 + 0.15) * 2 * 3.1415, sweep: 0.08 * 2 * 3.1415, color: const Color(0xFF6366F1)),
    ];

    for (final seg in segments) {
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        seg.start,
        seg.sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartRealPainter oldDelegate) => false;
}

class _WhitePhoneMockup extends StatelessWidget {
  const _WhitePhoneMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      height: 350,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1E293B), width: 6),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1:42', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.black, size: 8),
                      SizedBox(width: 2),
                      Icon(Icons.battery_full_rounded, color: Colors.black, size: 8),
                    ],
                  )
                ],
              ),
            ),
            // Header profile row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF2D7A7B).withValues(alpha: 0.2),
                    child: const Text('JH', style: TextStyle(color: Color(0xFF2D7A7B), fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good night', style: TextStyle(color: Colors.black45, fontSize: 5, height: 1.0)),
                        Text('Jahid Hasan', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold, height: 1.1)),
                        Text('01704642575', style: TextStyle(color: Colors.black38, fontSize: 4, height: 1.0)),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_none_rounded, color: Colors.black54, size: 10),
                  const SizedBox(width: 3),
                  const Icon(Icons.search_rounded, color: Colors.black54, size: 10),
                  const SizedBox(width: 3),
                  const Icon(Icons.auto_awesome_rounded, color: Colors.black54, size: 10),
                ],
              ),
            ),
            // Total Balance Gradient Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E6F70), Color(0xFF1B4D6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wallet, color: Colors.white70, size: 8),
                          SizedBox(width: 3),
                          Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 7)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('0% saved', style: TextStyle(color: Colors.white, fontSize: 5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('৳840.00', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(height: 0.5, color: Colors.white24),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Income', style: TextStyle(color: Colors.white60, fontSize: 5)),
                            Text('৳75', style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(width: 0.5, height: 12, color: Colors.white24),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Expense', style: TextStyle(color: Colors.white60, fontSize: 5)),
                            Text('৳685', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Accounts and Debts side by side
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Accounts
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Accounts', style: TextStyle(color: Colors.black87, fontSize: 7, fontWeight: FontWeight.bold)),
                              Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 8),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('৳840', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          const Text('4 accounts', style: TextStyle(color: Colors.black38, fontSize: 5)),
                          const SizedBox(height: 4),
                          _miniListRow('Cash', '৳340'),
                          _miniListRow('Online', '৳500'),
                          const SizedBox(height: 4),
                          // Dots indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 6, height: 2, decoration: BoxDecoration(color: const Color(0xFF2D7A7B), borderRadius: BorderRadius.circular(1))),
                              const SizedBox(width: 2),
                              Container(width: 2, height: 2, decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Debts
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Debts', style: TextStyle(color: Colors.black87, fontSize: 7, fontWeight: FontWeight.bold)),
                              Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 8),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('৳800', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          const Text('2 due', style: TextStyle(color: Colors.black38, fontSize: 5)),
                          const SizedBox(height: 4),
                          _miniDebtRow('To receive', '৳300', true),
                          _miniDebtRow('To pay', '৳500', false),
                          const SizedBox(height: 4),
                          // Dots indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 6, height: 2, decoration: BoxDecoration(color: const Color(0xFF2D7A7B), borderRadius: BorderRadius.circular(1))),
                              const SizedBox(width: 2),
                              Container(width: 2, height: 2, decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Expense Breakdown Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Expense Breakdown', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D7A7B).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Expense', style: TextStyle(color: Color(0xFF2D7A7B), fontSize: 5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 4,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DonutChartRealPainter(),
                            ),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('৳685', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, height: 1.0)),
                              Text('Total', style: TextStyle(color: Colors.black38, fontSize: 5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Bottom Navigation Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.dashboard_rounded, color: Color(0xFF0F766E), size: 12), // Selected
                      Icon(Icons.insights_rounded, color: Colors.black26, size: 12),
                      SizedBox(width: 14), // Gap for FAB
                      Icon(Icons.grid_view_rounded, color: Colors.black26, size: 12),
                      Icon(Icons.settings_rounded, color: Colors.black26, size: 12),
                    ],
                  ),
                  Positioned(
                    top: -12,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D7A7B),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniListRow(String item, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item, style: const TextStyle(color: Colors.black54, fontSize: 5)),
          Text(val, style: const TextStyle(color: Colors.black87, fontSize: 5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _miniDebtRow(String item, String val, bool receive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item, style: const TextStyle(color: Colors.black54, fontSize: 5)),
          Row(
            children: [
              Text(val, style: TextStyle(color: receive ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 5, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: (receive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('1', style: TextStyle(color: receive ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 4, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacbookMockup extends StatelessWidget {
  const _MacbookMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: 270,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          // Browser Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: const Color(0xFFE2E8F0),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  ],
                ),
                const Spacer(),
                // Browser tab
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(3)),
                  child: const Row(
                    children: [
                      Icon(Icons.public, size: 7, color: Colors.blue),
                      SizedBox(width: 3),
                      Text('CashTrack Dashboard', style: TextStyle(color: Colors.black87, fontSize: 6)),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.menu, size: 8, color: Colors.black45),
              ],
            ),
          ),
          // Browser content area containing sidebar and main panel
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sidebar mock
                Container(
                  width: 95,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.04))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar Brand Logo
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E6F70),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 8),
                          ),
                          const SizedBox(width: 3),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('CashTrack', style: TextStyle(color: Colors.black, fontSize: 6, fontWeight: FontWeight.bold, height: 1.0)),
                              Text('Smart Finance', style: TextStyle(color: Colors.black38, fontSize: 4, height: 1.0)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, size: 6, color: Colors.black38),
                            SizedBox(width: 2),
                            Text('Search...', style: TextStyle(color: Colors.black38, fontSize: 5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E6F70),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('+ New Transaction', style: TextStyle(color: Colors.white, fontSize: 5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('OVERVIEW', style: TextStyle(color: Colors.black38, fontSize: 4, fontWeight: FontWeight.bold)),
                      _macSidebarItem(Icons.dashboard_rounded, 'Dashboard', isSelected: true),
                      _macSidebarItem(Icons.receipt_long_rounded, 'Transactions'),
                      _macSidebarItem(Icons.insights_rounded, 'Analytics'),
                      _macSidebarItem(Icons.assessment_rounded, 'Reports'),
                      const SizedBox(height: 6),
                      const Text('PLANNING', style: TextStyle(color: Colors.black38, fontSize: 4, fontWeight: FontWeight.bold)),
                      _macSidebarItem(Icons.pie_chart_rounded, 'Budget'),
                      _macSidebarItem(Icons.flag_rounded, 'Goals'),
                      _macSidebarItem(Icons.payment_rounded, 'Debts'),
                      const Spacer(),
                      _macSidebarItem(Icons.chevron_left_rounded, 'Collapse'),
                      _macSidebarItem(Icons.person_outline_rounded, 'User'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text('Dashboard > Dashboard', style: TextStyle(color: Colors.black38, fontSize: 5)),
                            const Spacer(),
                            const Icon(Icons.search, size: 8, color: Colors.black38),
                            const SizedBox(width: 4),
                            const Icon(Icons.notifications_none_rounded, size: 8, color: Colors.black38),
                            const SizedBox(width: 4),
                            const Icon(Icons.auto_awesome_rounded, size: 8, color: Colors.black38),
                            const SizedBox(width: 4),
                            CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.teal.shade100,
                              child: const Text('U', style: TextStyle(fontSize: 4, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Good night, User', style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold, height: 1.0)),
                        const Text('Monday, July 13', style: TextStyle(color: Colors.black38, fontSize: 5, height: 1.2)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _macStatCard('TOTAL BALANCE', '৳550', 'Balance')),
                            const SizedBox(width: 4),
                            Expanded(child: _macStatCard('INCOME', '৳1000', 'Income')),
                            const SizedBox(width: 4),
                            Expanded(child: _macStatCard('EXPENSE', '৳450', 'Expense')),
                            const SizedBox(width: 4),
                            Expanded(child: _macStatCard('NET SAVINGS', '৳550', '55% saved')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Expense Breakdown', style: TextStyle(color: Colors.black, fontSize: 6, fontWeight: FontWeight.bold)),
                                          Row(
                                            children: [
                                              Text('Expense', style: TextStyle(color: Color(0xFF1E6F70), fontSize: 5, fontWeight: FontWeight.bold)),
                                              SizedBox(width: 4),
                                              Text('Income', style: TextStyle(color: Colors.black38, fontSize: 5)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: _DonutChartWebRealPainter(),
                                              ),
                                            ),
                                            const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('৳450', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold, height: 1.0)),
                                                Text('Total', style: TextStyle(color: Colors.black38, fontSize: 4)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
                                        ),
                                        child: const Row(
                                          children: [
                                            SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    value: 0.95,
                                                    strokeWidth: 3,
                                                    color: Color(0xFF34D399),
                                                    backgroundColor: Color(0xFFD1FAE5),
                                                  ),
                                                  Text('95', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('FINANCIAL HEALTH', style: TextStyle(color: Colors.black38, fontSize: 4, fontWeight: FontWeight.bold, height: 1.0)),
                                                  Text('Excellent status', style: TextStyle(color: Color(0xFF10B981), fontSize: 6, fontWeight: FontWeight.bold, height: 1.1)),
                                                  Text('Your savings rate is high...', style: TextStyle(color: Colors.black54, fontSize: 4, height: 1.0), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.deepPurple.shade50]),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.purple.shade100.withValues(alpha: 0.5)),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.auto_awesome, color: Colors.purple, size: 10),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('AI INSIGHT', style: TextStyle(color: Colors.purple, fontSize: 4, fontWeight: FontWeight.bold, height: 1.0)),
                                                  Text('Dining expenses are 18% higher...', style: TextStyle(color: Colors.purple, fontSize: 5, height: 1.1), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 4,
            color: const Color(0xFF475569),
          )
        ],
      ),
    );
  }

  Widget _macSidebarItem(IconData icon, String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E6F70).withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 7, color: isSelected ? const Color(0xFF1E6F70) : Colors.black45),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E6F70) : Colors.black54,
              fontSize: 5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macStatCard(String title, String val, String sub) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.black38, fontSize: 4, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(sub, style: TextStyle(color: Colors.teal.shade700, fontSize: 3.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, height: 1.0)),
        ],
      ),
    );
  }
}

class _DonutChartWebRealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * 0.28;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;

    // Web dashboard breakdown values:
    // Magenta/Red (50%), Green (30%), Orange (10%), Blue/Violet (10%)
    final segments = [
      _Segment(start: -0.5 * 3.1415, sweep: 0.5 * 2 * 3.1415, color: const Color(0xFFEF4444)),
      _Segment(start: (-0.5 + 0.5) * 2 * 3.1415, sweep: 0.3 * 2 * 3.1415, color: const Color(0xFF10B981)),
      _Segment(start: (-0.5 + 0.5 + 0.3) * 2 * 3.1415, sweep: 0.1 * 2 * 3.1415, color: const Color(0xFFF59E0B)),
      _Segment(start: (-0.5 + 0.5 + 0.3 + 0.1) * 2 * 3.1415, sweep: 0.1 * 2 * 3.1415, color: const Color(0xFF6366F1)),
    ];

    for (final seg in segments) {
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        seg.start,
        seg.sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartWebRealPainter oldDelegate) => false;
}
