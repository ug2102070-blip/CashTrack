// lib/presentation/widgets/web_sidebar.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../providers/app_providers.dart';

// ─── Sidebar Collapse State Provider ─────────────────────────────────────────
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

class WebSidebar extends ConsumerStatefulWidget {
  const WebSidebar({super.key});

  @override
  ConsumerState<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<WebSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    // User Profile data
    final profile = ref.watch(userProfileProvider);
    final fullName = (profile['fullName'] ?? '').trim();
    final profileEmail = (profile['email'] ?? '').trim();
    final photoBase64 = (profile['photoBase64'] ?? '').trim();

    final firebaseUser = AuthService().currentUser;
    final displayName = fullName.isNotEmpty
        ? fullName
        : profileEmail.isNotEmpty
            ? profileEmail
            : (firebaseUser?.email ?? 'User');

    final displayEmail = profileEmail.isNotEmpty
        ? profileEmail
        : (firebaseUser?.email ?? '');

    ImageProvider? profileImage;
    if (photoBase64.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(photoBase64));
      } catch (_) {}
    }

    // Get badge counts
    final debts = ref.watch(debtsProvider);
    final overdueDebts = debts.where((d) {
      return d.dueDate != null &&
          !d.isSettled &&
          d.dueDate!.isBefore(DateTime.now());
    }).length;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: isCollapsed ? 68 : 260,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              right: BorderSide(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                    : AppColors.lightBorder.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                children: [
                  // ─── Brand Header ──────────────────────────────────
                  _buildBrandHeader(context, primary, isDark, isCollapsed),

                  // ─── Quick Search ──────────────────────────────────
                  if (!isCollapsed) ...[
                    _buildQuickSearch(context, isDark, primary),
                    const SizedBox(height: 6),
                  ],

                  // ─── Add Transaction Button ────────────────────────
                  _buildAddTransactionBtn(context, primary, isDark, isCollapsed),

                  const SizedBox(height: 8),

                  // ─── Divider ────────────────────────────────────────
                  if (!isCollapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.3)
                            : AppColors.lightBorder.withValues(alpha: 0.5),
                      ),
                    ),

                  const SizedBox(height: 6),

                  // ─── Navigation Menu ──────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCollapsed ? 8 : 10,
                      ),
                      children: [
                        _buildSection(
                          context, 'OVERVIEW', isDark, isCollapsed,
                          [
                            _SidebarNavItem(
                              icon: Icons.space_dashboard_rounded,
                              label: context.t('dashboard'),
                              isSelected: location == '/dashboard',
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/dashboard'),
                              shortcut: '⌘1',
                            ),
                            _SidebarNavItem(
                              icon: Icons.receipt_long_rounded,
                              label: context.t('transactions'),
                              isSelected: location.startsWith('/transactions'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/transactions'),
                              shortcut: '⌘2',
                            ),
                            _SidebarNavItem(
                              icon: Icons.insights_rounded,
                              label: context.t('analytics'),
                              isSelected: location.startsWith('/analytics'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/analytics'),
                              shortcut: '⌘3',
                            ),
                            _SidebarNavItem(
                              icon: Icons.assessment_rounded,
                              label: 'Reports',
                              isSelected: location.startsWith('/reports'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/reports'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildSection(
                          context, 'PLANNING', isDark, isCollapsed,
                          [
                            _SidebarNavItem(
                              icon: Icons.account_balance_wallet_rounded,
                              label: context.t('budget'),
                              isSelected: location.startsWith('/budget'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/budget'),
                            ),
                            _SidebarNavItem(
                              icon: Icons.flag_rounded,
                              label: context.t('goals'),
                              isSelected: location.startsWith('/goals'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/goals'),
                            ),
                            _SidebarNavItem(
                              icon: Icons.swap_horiz_rounded,
                              label: context.t('debts'),
                              isSelected: location.startsWith('/debts'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/debts'),
                              badgeCount: overdueDebts,
                              badgeColor: AppColors.error,
                            ),
                            _SidebarNavItem(
                              icon: Icons.people_alt_rounded,
                              label: 'Split Expenses',
                              isSelected:
                                  location.startsWith('/split-expenses'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/split-expenses'),
                            ),
                            _SidebarNavItem(
                              icon: Icons.show_chart_rounded,
                              label: 'Investments',
                              isSelected:
                                  location.startsWith('/investments'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/investments'),
                            ),
                            _SidebarNavItem(
                              icon: Icons.real_estate_agent_rounded,
                              label: 'Assets',
                              isSelected: location.startsWith('/assets'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/assets'),
                            ),
                            _SidebarNavItem(
                              icon: Icons.apps_rounded,
                              label: context.t('planning'),
                              isSelected: location.startsWith('/tools'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/tools'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildSection(
                          context,
                          'ACCOUNTS',
                          isDark,
                          isCollapsed,
                          [
                            _SidebarNavItem(
                              icon: Icons.credit_card_rounded,
                              label: context.t('accounts') == 'accounts'
                                  ? 'Accounts'
                                  : context.t('accounts'),
                              isSelected: location.startsWith('/accounts'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/accounts'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildSection(
                          context, 'SYSTEM', isDark, isCollapsed,
                          [
                            _SidebarNavItem(
                              icon: Icons.auto_awesome_rounded,
                              label: 'AI Assistant',
                              isSelected:
                                  location.startsWith('/ai-assistant'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.push('/ai-assistant'),
                              badge: 'AI',
                              badgeColor: AppColors.accent,
                            ),
                            _SidebarNavItem(
                              icon: Icons.tune_rounded,
                              label: context.t('settings'),
                              isSelected: location.startsWith('/settings'),
                              isCollapsed: isCollapsed,
                              onTap: () => context.go('/settings'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // ─── Collapse Toggle ───────────────────────────────
                  _buildCollapseToggle(context, isDark, primary, isCollapsed),

                  // ─── Bottom: User Profile Card ─────────────────────
                  _buildUserProfile(
                    context, isDark, primary, isCollapsed,
                    displayName, displayEmail, profileImage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Brand Header ─────────────────────────────────────────────────────────
  Widget _buildBrandHeader(
      BuildContext ctx, Color primary, bool isDark, bool isCollapsed) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 12 : 20,
        vertical: 22,
      ),
      child: Row(
        children: [
          // Logo container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  Color.lerp(primary, AppColors.accent, 0.3)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CashTrack',
                    style: AppTextStyles.headingSm.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.lightText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Smart Finance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Quick Search ─────────────────────────────────────────────────────────
  Widget _buildQuickSearch(BuildContext ctx, bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ctx.push('/search'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search...',
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.4)
                        : AppColors.lightBorder.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '⌘K',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Add Transaction Button ───────────────────────────────────────────────
  Widget _buildAddTransactionBtn(
      BuildContext ctx, Color primary, bool isDark, bool isCollapsed) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 10 : 14,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ctx.push('/add-transaction'),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: isCollapsed
                  ? const Icon(Icons.add_rounded,
                      size: 20, color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'New Transaction',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────
  Widget _buildSection(BuildContext context, String title, bool isDark,
      bool isCollapsed, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 4, top: 14),
            child: Text(
              title,
              style: AppTextStyles.overline.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.darkTextTertiary.withValues(alpha: 0.6)
                    : AppColors.lightTextTertiary.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          const SizedBox(height: 6),
        ...items,
      ],
    );
  }

  // ─── Collapse Toggle ──────────────────────────────────────────────────────
  Widget _buildCollapseToggle(
      BuildContext ctx, bool isDark, Color primary, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 36,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated.withValues(alpha: 0.4)
                  : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                AnimatedRotation(
                  turns: isCollapsed ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Collapse',
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── User Profile Card ────────────────────────────────────────────────────
  Widget _buildUserProfile(
    BuildContext ctx,
    bool isDark,
    Color primary,
    bool isCollapsed,
    String displayName,
    String displayEmail,
    ImageProvider? profileImage,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.3)
                : AppColors.lightBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ctx.go('/profile'),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 14,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Profile Avatar with online dot
                Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: profileImage != null
                          ? CircleAvatar(
                              radius: 18,
                              backgroundImage: profileImage,
                            )
                          : Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'U',
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                    // Online status dot
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                        if (displayEmail.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            displayEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _WebIconButton(
                    icon: Icons.logout_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    hoverColor: AppColors.error,
                    tooltip: 'Sign Out',
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (dialogCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Sign Out'),
                          content: const Text(
                              'Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogCtx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogCtx, true),
                              child: const Text('Sign Out',
                                  style: TextStyle(
                                      color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await AuthService().signOut();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sidebar Nav Item with hover, selected indicator, collapse, badges ───────
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final String? badge;
  final int? badgeCount;
  final Color? badgeColor;
  final String? shortcut;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.badge,
    this.badgeCount,
    this.badgeColor,
    this.shortcut,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    Color bgColor() {
      if (widget.isSelected) {
        return isDark
            ? primary.withValues(alpha: 0.10)
            : primary.withValues(alpha: 0.06);
      }
      if (_isHovered) {
        return isDark
            ? Colors.white.withValues(alpha: 0.03)
            : AppColors.lightSurfaceElevated;
      }
      return Colors.transparent;
    }

    Color iconColor() {
      if (widget.isSelected) return primary;
      if (_isHovered) {
        return isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
      }
      return isDark
          ? AppColors.darkTextTertiary
          : AppColors.lightTextTertiary;
    }

    Color textColor() {
      if (widget.isSelected) {
        return isDark ? AppColors.darkText : AppColors.lightText;
      }
      if (_isHovered) {
        return isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
      }
      return isDark
          ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
          : AppColors.lightTextSecondary;
    }

    final itemContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 0 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: bgColor(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: widget.isCollapsed
              ? Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(widget.icon, size: 20, color: iconColor()),
                      if (widget.badgeCount != null &&
                          widget.badgeCount! > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: widget.badgeColor ?? primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.badgeCount}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.badge != null &&
                          (widget.badgeCount == null ||
                              widget.badgeCount == 0))
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: (widget.badgeColor ?? primary)
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.badge!,
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Left active indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 3,
                      height: widget.isSelected ? 18 : 0,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(
                      widget.icon,
                      size: 19,
                      color: iconColor(),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: AppTextStyles.navLabel.copyWith(
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textColor(),
                        ),
                      ),
                    ),
                    // Badge count
                    if (widget.badgeCount != null &&
                        widget.badgeCount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (widget.badgeColor ?? primary)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.badgeCount}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: widget.badgeColor ?? primary,
                          ),
                        ),
                      ),
                    // Badge text
                    if (widget.badge != null &&
                        (widget.badgeCount == null ||
                            widget.badgeCount == 0))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (widget.badgeColor ?? primary)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.badge!,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: widget.badgeColor ?? primary,
                          ),
                        ),
                      ),
                    // Keyboard shortcut hint (on hover)
                    if (widget.shortcut != null &&
                        _isHovered &&
                        !widget.isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder.withValues(alpha: 0.4)
                                : AppColors.lightBorder.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.shortcut!,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.label,
        preferBelow: false,
        child: itemContent,
      );
    }
    return itemContent;
  }
}

// ─── Hover Icon Button ──────────────────────────────────────────────────────
class _WebIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color hoverColor;
  final String tooltip;
  final VoidCallback onTap;

  const _WebIconButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.hoverColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_WebIconButton> createState() => _WebIconButtonState();
}

class _WebIconButtonState extends State<_WebIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.hoverColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: _hovered ? widget.hoverColor : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

