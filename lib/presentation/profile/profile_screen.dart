// lib/presentation/profile/profile_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/amount_mask.dart';
import '../../core/l10n/app_l10n.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../data/models/transaction_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late AnimationController _avatarCtrl;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;
  late final Animation<double> _avatarScale;
  late final DateTime _analyticsMonth;

  static const List<int> _animationDelays = [
    0,
    80,
    120,
    140,
    180,
    200,
    260,
    280,
    320,
    340,
  ];

  @override
  void initState() {
    super.initState();
    _analyticsMonth = DateTime.now();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnimations = _animationDelays.map(_createFadeAnimation).toList();
    _slideAnimations = _animationDelays.map(_createSlideAnimation).toList();
    _avatarScale = CurvedAnimation(
        parent: _avatarCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animCtrl.stop();
    _avatarCtrl.stop();
    _animCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Stop animations BEFORE element is removed from the tree.
    // This reduces the chance of stale animation dependents during route exit.
    _animCtrl.stop();
    _avatarCtrl.stop();
    super.deactivate();
  }

  Animation<double> _createFadeAnimation(int ms) {
    final s = (ms / 700).clamp(0.0, 1.0);
    final e = ((ms + 300) / 700).clamp(0.0, 1.0);
    return CurvedAnimation(
        parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut));
  }

  Animation<Offset> _createSlideAnimation(int ms) {
    final s = (ms / 700).clamp(0.0, 1.0);
    final e = ((ms + 300) / 700).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
      CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut)),
    );
  }

  Widget _anim({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final settings = ref.watch(settingsProvider);
    final transactions = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);
    final analytics = ref.watch(monthlyAnalyticsProvider(_analyticsMonth));

    final fullName = (profile['fullName'] ?? '').trim();
    final email = (profile['email'] ?? '').trim();
    final phone = (profile['phone'] ?? '').trim();
    final address = (profile['address'] ?? '').trim();
    final occupation = (profile['occupation'] ?? '').trim();
    final bio = (profile['bio'] ?? '').trim();
    final dob = (profile['dob'] ?? '').trim();
    final photoBase64 = (profile['photoBase64'] ?? '').trim();
    final profilePhotoBytes = _decodePhotoBytes(photoBase64);
    final displayName = fullName.isEmpty ? context.t('your_name') : fullName;
    final rawCurrency = (settings['currency'] as String?)?.trim();
    final currency = (rawCurrency == null ||
            rawCurrency.isEmpty ||
            rawCurrency == '?' ||
            rawCurrency == 'à§³')
        ? '৳'
        : rawCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final categoryMap = {
      for (final category in categories) category.id: category.name,
    };

    final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);
    final totalIncome = analytics.totalIncome;
    final totalExpense = analytics.totalExpense;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Custom App Bar with gradient ──────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(context, photoBase64),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      Color.lerp(primary, Colors.indigo.shade800, 0.5)!
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: -15,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Avatar + Name
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: () =>
                                    _showPhotoOptions(context, photoBase64),
                                child: ScaleTransition(
                                  scale: _avatarScale,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: profilePhotoBytes != null
                                              ? Image.memory(profilePhotoBytes,
                                                  fit: BoxFit.cover)
                                              : Container(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  child: Center(
                                                    child: Text(
                                                      _initials(
                                                          context, displayName),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: primary, width: 2),
                                          ),
                                          child: Icon(Icons.edit_rounded,
                                              size: 11, color: primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    if (occupation.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(occupation,
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.75),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.email_rounded,
                                              size: 12,
                                              color: Colors.white
                                                  .withValues(alpha: 0.6)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(email,
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.65),
                                                    fontSize: 11),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bio / About ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
              index: 1,
              child: _buildBioSection(context, bio, isDark, primary),
            ),
          ),

          // ── Personal Info ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
                index: 2,
                child: _sectionLabel(context, context.t('personal_info'))),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 3,
              child: _buildInfoGroup(context, isDark, primary, [
                _FieldConfig(
                    icon: Icons.person_rounded,
                    label: context.t('full_name'),
                    value: fullName.isEmpty ? context.t('not_set') : fullName,
                    fieldKey: 'fullName',
                    initialValue: fullName,
                    keyboardType: TextInputType.name),
                _FieldConfig(
                    icon: Icons.email_rounded,
                    label: context.t('email'),
                    value: email.isEmpty ? context.t('not_set') : email,
                    fieldKey: 'email',
                    initialValue: email,
                    keyboardType: TextInputType.emailAddress),
                _FieldConfig(
                    icon: Icons.phone_rounded,
                    label: context.t('phone'),
                    value: phone.isEmpty ? context.t('not_set') : phone,
                    fieldKey: 'phone',
                    initialValue: phone,
                    keyboardType: TextInputType.phone),
                _FieldConfig(
                    icon: Icons.work_rounded,
                    label: context.t('occupation'),
                    value:
                        occupation.isEmpty ? context.t('not_set') : occupation,
                    fieldKey: 'occupation',
                    initialValue: occupation,
                    keyboardType: TextInputType.text),
              ]),
            ),
          ),

          // ── Additional Info ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
                index: 4,
                child: _sectionLabel(context, context.t('additional_info'))),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 5,
              child: _buildInfoGroup(context, isDark, primary, [
                _FieldConfig(
                    icon: Icons.location_on_rounded,
                    label: context.t('address'),
                    value: address.isEmpty ? context.t('not_set') : address,
                    fieldKey: 'address',
                    initialValue: address,
                    keyboardType: TextInputType.streetAddress),
                _FieldConfig(
                    icon: Icons.cake_rounded,
                    label: context.t('date_of_birth'),
                    value: dob.isEmpty ? context.t('not_set') : dob,
                    fieldKey: 'dob',
                    initialValue: dob,
                    keyboardType: TextInputType.datetime,
                    isDate: true),
                _FieldConfig(
                    icon: Icons.info_rounded,
                    label: context.t('bio'),
                    value: bio.isEmpty ? context.t('not_set') : bio,
                    fieldKey: 'bio',
                    initialValue: bio,
                    keyboardType: TextInputType.multiline,
                    isMultiline: true),
              ]),
            ),
          ),

          // ── Financial summary (monthly) ───────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
              index: 6,
              child: _sectionLabel(context, context.t('monthly_summary')),
            ),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 6,
              child: _buildFinancialSummary(
                context,
                currency,
                totalBalance,
                totalIncome,
                totalExpense,
                isDark,
                primary,
              ),
            ),
          ),

          // ── Recent activity ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
              index: 7,
              child: _sectionLabel(context, context.t('recent_activity')),
            ),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 7,
              child: _buildRecentActivity(
                context,
                isDark,
                primary,
                transactions,
                currency,
                categoryMap,
              ),
            ),
          ),

          // ── Achievements ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child:
                _anim(index: 8, child: _sectionLabel(context, 'ACHIEVEMENTS')),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 9,
              child: _buildAchievements(
                  context, transactions.length, isDark, primary),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  // ── Financial Summary ─────────────────────────────────────────────────────

  Widget _buildFinancialSummary(
      BuildContext context,
      String currency,
      double totalBalance,
      double totalIncome,
      double totalExpense,
      bool isDark,
      Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _summaryCard(
                  context,
                  formatAmount(currency, totalBalance, decimals: 0),
                  context.t('total_balance'),
                  Icons.account_balance_wallet_rounded,
                  primary,
                  isDark)),
          const SizedBox(width: 8),
          Expanded(
              child: _summaryCard(
                  context,
                  formatAmount(currency, totalIncome, decimals: 0),
                  context.t('this_month_income'),
                  Icons.arrow_downward_rounded,
                  AppColors.success,
                  isDark)),
          const SizedBox(width: 8),
          Expanded(
              child: _summaryCard(
                  context,
                  formatAmount(currency, totalExpense, decimals: 0),
                  context.t('expense'),
                  Icons.arrow_upward_rounded,
                  AppColors.expense,
                  isDark)),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String value, String label,
      IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Bio Section ───────────────────────────────────────────────────────────

  Widget _buildBioSection(
      BuildContext context, String bio, bool isDark, Color primary) {
    return GestureDetector(
      onTap: () => _editField(
        context,
        _FieldConfig(
          icon: Icons.info_rounded,
          label: context.t('bio'),
          value: bio,
          fieldKey: 'bio',
          initialValue: bio,
          keyboardType: TextInputType.multiline,
          isMultiline: true,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.format_quote_rounded, color: primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('about_me'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4))),
                  const SizedBox(height: 4),
                  Text(
                    bio.isEmpty ? context.t('tap_add_bio') : bio,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: bio.isEmpty
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded,
                size: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }

  // ── Info Group ────────────────────────────────────────────────────────────

  Widget _buildInfoGroup(BuildContext context, bool isDark, Color primary,
      List<_FieldConfig> fields) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: fields.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          final isLast = i == fields.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () => f.isDate
                    ? _showDatePicker(context, f)
                    : _editField(context, f),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon, color: primary, size: 18),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              f.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: f.value == context.t('not_set')
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.3)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: f.isMultiline ? 3 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded,
                          size: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.25)),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 65),
                  child: Divider(
                      height: 1,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.5)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────────

  Widget _buildRecentActivity(
    BuildContext context,
    bool isDark,
    Color primary,
    List<TransactionModel> transactions,
    String currency,
    Map<String, String> categoryMap,
  ) {
    final recent = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final visibleTransactions = recent.take(3).toList();

    if (visibleTransactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Center(
          child: Text(context.t('no_transactions_yet'),
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4))),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: visibleTransactions.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final isIncome = t.type == TransactionType.income;
          final color = isIncome ? AppColors.success : AppColors.error;
          final isLast = i == visibleTransactions.length - 1;
          final categoryName = categoryMap[t.categoryId] ?? t.categoryId;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: color,
                          size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categoryName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(DateFormat('MMM dd').format(t.date),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}$currency ${t.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 66),
                  child: Divider(
                      height: 1,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.5)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────

  Widget _buildAchievements(
      BuildContext context, int txCount, bool isDark, Color primary) {
    final achievements = [
      _Achievement(context.t('ach_first_tx'), context.t('ach_first_tx_desc'),
          Icons.star_rounded, AppColors.warning, txCount >= 1),
      _Achievement(
          context.t('ach_budget_tracker'),
          context.t('ach_budget_tracker_desc'),
          Icons.pie_chart_rounded,
          AppColors.info,
          false),
      _Achievement(
          context.t('ach_power_user'),
          context.t('ach_power_user_desc'),
          Icons.bolt_rounded,
          AppColors.secondary,
          txCount >= 50),
      _Achievement(
          context.t('ach_savings_master'),
          context.t('ach_savings_master_desc'),
          Icons.savings_rounded,
          AppColors.success,
          false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: achievements.map((a) {
          final isLast = achievements.indexOf(a) == achievements.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: a.unlocked
                      ? a.color.withValues(alpha: 0.08)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: a.unlocked
                        ? a.color.withValues(alpha: 0.25)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: a.unlocked
                            ? a.color.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon,
                          color: a.unlocked
                              ? a.color
                              : Colors.grey.withValues(alpha: 0.4),
                          size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(a.title,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: a.unlocked
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.35)),
                        textAlign: TextAlign.center,
                        maxLines: 2),
                    if (a.unlocked) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(context.t('unlocked'),
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: a.color)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _showPhotoOptions(
      BuildContext context, String currentPhoto) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(ctx.t('profile_photo'), style: AppTextStyles.h5),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.photo_library_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              title: Text(ctx.t('choose_from_gallery')),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final file =
                    await picker.pickImage(source: ImageSource.gallery);
                if (file == null) return;
                final bytes = await file.readAsBytes();
                final b64 = base64Encode(bytes);
                await ref
                    .read(userProfileProvider.notifier)
                    .updateProfilePhoto(b64);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('photo_updated'))));
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.camera_alt_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              title: Text(ctx.t('take_photo')),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final file = await picker.pickImage(source: ImageSource.camera);
                if (file == null) return;
                final bytes = await file.readAsBytes();
                final b64 = base64Encode(bytes);
                await ref
                    .read(userProfileProvider.notifier)
                    .updateProfilePhoto(b64);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('photo_updated'))));
              },
            ),
            if (currentPhoto.isNotEmpty)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_rounded,
                      color: AppColors.error, size: 20),
                ),
                title: Text(ctx.t('remove_photo')),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(userProfileProvider.notifier)
                      .clearProfilePhoto();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('photo_removed'))));
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, _FieldConfig field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final formatted = DateFormat('dd MMM yyyy').format(picked);
    final current = ref.read(userProfileProvider);
    final Map<String, String> updated = {
      'fullName': current['fullName'] ?? '',
      'email': current['email'] ?? '',
      'phone': current['phone'] ?? '',
      'address': current['address'] ?? '',
      'occupation': current['occupation'] ?? '',
      'bio': current['bio'] ?? '',
      'dob': formatted,
      'photoBase64': current['photoBase64'] ?? '',
    };
    // Defer state update to next frame so the picker animation finishes first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(userProfileProvider.notifier).updateProfile(
            fullName: updated['fullName']!,
            email: updated['email']!,
            phone: updated['phone']!,
            address: updated['address']!,
            occupation: updated['occupation']!,
            bio: updated['bio']!,
            dob: updated['dob']!,
            photoBase64: updated['photoBase64'],
          );
    });
  }

  Future<void> _editField(BuildContext context, _FieldConfig field) async {
    final controller = TextEditingController(text: field.initialValue);
    final focusNode = FocusNode();
    String? result;

    result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(ctx).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(ctx.t('edit_field', params: {'label': field.label}),
                  style: AppTextStyles.h5),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: field.keyboardType,
                maxLines: field.isMultiline ? 4 : 1,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: field.label,
                  prefixIcon: Icon(field.icon),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        focusNode.unfocus();
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(ctx.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        focusNode.unfocus();
                        Navigator.pop(ctx, controller.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(ctx.t('save_changes')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Do NOT dispose focusNode/controller here — the bottom sheet exit animation
    // is still running and the TextField will try to use them. Defer disposal
    // to the next frame when the animation has fully completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.dispose();
      controller.dispose();
    });

    if (result == null || !mounted) return;

    // Capture the values we need before any async gap
    final current = ref.read(userProfileProvider);
    final Map<String, String> updated = {
      'fullName': current['fullName'] ?? '',
      'email': current['email'] ?? '',
      'phone': current['phone'] ?? '',
      'address': current['address'] ?? '',
      'occupation': current['occupation'] ?? '',
      'bio': current['bio'] ?? '',
      'dob': current['dob'] ?? '',
      'photoBase64': current['photoBase64'] ?? '',
    };
    updated[field.fieldKey] = result;

    final fieldLabel = field.label;

    // Defer the state update to the next frame so the bottom sheet
    // exit animation and any remaining dependents are fully cleaned up.
    // This prevents the '_dependents.isEmpty' assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(userProfileProvider.notifier).updateProfile(
            fullName: updated['fullName']!,
            email: updated['email']!,
            phone: updated['phone']!,
            address: updated['address']!,
            occupation: updated['occupation']!,
            bio: updated['bio']!,
            dob: updated['dob']!,
            photoBase64: updated['photoBase64'],
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.t('field_updated', params: {'label': fieldLabel})),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  String _initials(BuildContext context, String name) {
    final parts = name
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return context.t('unknown_initial');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Uint8List? _decodePhotoBytes(String photoBase64) {
    if (photoBase64.isEmpty) return null;
    try {
      return base64Decode(photoBase64);
    } catch (_) {
      return null;
    }
  }
}

class _FieldConfig {
  const _FieldConfig({
    required this.icon,
    required this.label,
    required this.value,
    required this.fieldKey,
    required this.initialValue,
    required this.keyboardType,
    this.isMultiline = false,
    this.isDate = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String fieldKey;
  final String initialValue;
  final TextInputType keyboardType;
  final bool isMultiline;
  final bool isDate;
}

class _Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const _Achievement(
      this.title, this.description, this.icon, this.color, this.unlocked);
}
