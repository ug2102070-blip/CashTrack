// lib/presentation/profile/profile_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';
import '../../data/models/transaction_model.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import 'profile_logic.dart';

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

  static const List<int> _animationDelays = [0, 80, 120, 160, 200];

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnimations = _animationDelays.map(_createFadeAnimation).toList();
    _slideAnimations = _animationDelays.map(_createSlideAnimation).toList();
    _avatarScale =
        CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animCtrl.stop();
    _avatarCtrl.stop();
    _animCtrl.dispose();
    _avatarCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void deactivate() {
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
        .animate(CurvedAnimation(
            parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut)));
  }

  Widget _anim({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  TextEditingController _controllerFor(_FieldConfig f) {
    return _controllers.putIfAbsent(
        f.fieldKey, () => TextEditingController(text: f.initialValue));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final transactions = ref.watch(transactionsProvider);
    final hasBudget = ref.watch(budgetsProvider).isNotEmpty;

    final fullName = (profile['fullName'] ?? '').trim();
    final email = (profile['email'] ?? '').trim();
    final emailManaged =
        UserProfileNotifier.accountEmailOf(AuthService().currentUser) != null;
    final phone = (profile['phone'] ?? '').trim();
    final dob = (profile['dob'] ?? '').trim();
    final dobDisplay =
        displayDob(dob, Localizations.localeOf(context).toString());
    final photoBase64 = (profile['photoBase64'] ?? '').trim();
    final profilePhotoBytes = _decodePhotoBytes(photoBase64);
    final displayName = fullName.isEmpty ? context.t('your_name') : fullName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                tooltip: context.t('back'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                // The route can be opened directly (web sidebar / deep link)
                // with nothing beneath it, where pop() would throw.
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/settings'),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  tooltip: context.t('profile_photo'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showPhotoOptions(context, photoBase64),
                  icon: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      Color.lerp(primary, Colors.indigo.shade900, 0.6)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _showPhotoOptions(context, photoBase64),
                                child: ScaleTransition(
                                  scale: _avatarScale,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
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
                                                        fontSize: 24,
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
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: primary, width: 2),
                                          ),
                                          child: Icon(Icons.edit_rounded,
                                              size: 10, color: primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Icon(Icons.email_rounded,
                                            size: 11,
                                            color: Colors.white
                                                .withValues(alpha: 0.6)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(email,
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.65),
                                                  fontSize: 11),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
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

          // ── Personal Info ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
                index: 1,
                child: _sectionLabel(context, context.t('personal_info'))),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 2,
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
                    keyboardType: TextInputType.emailAddress,
                    readOnly: emailManaged),
                _FieldConfig(
                    icon: Icons.phone_rounded,
                    label: context.t('phone'),
                    value: phone.isEmpty ? context.t('not_set') : phone,
                    fieldKey: 'phone',
                    initialValue: phone,
                    keyboardType: TextInputType.phone),
                _FieldConfig(
                    icon: Icons.cake_rounded,
                    label: context.t('date_of_birth'),
                    value: dob.isEmpty ? context.t('not_set') : dobDisplay,
                    fieldKey: 'dob',
                    initialValue: dob,
                    keyboardType: TextInputType.datetime,
                    isDate: true),
              ]),
            ),
          ),

          // ── Achievements ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _anim(
                index: 3,
                child: _sectionLabel(context, context.t('achievements'))),
          ),
          SliverToBoxAdapter(
            child: _anim(
              index: 4,
              child: _buildAchievements(context,
                  transactions: transactions,
                  hasBudget: hasBudget,
                  isDark: isDark),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
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
                onTap: () {
                  if (f.readOnly) {
                    _showSnack(context, context.t('profile_email_managed'));
                  } else if (f.isDate) {
                    _showDatePicker(context, f);
                  } else {
                    _showEditBottomSheet(context, f);
                  }
                },
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (f.isDate && f.initialValue.isNotEmpty)
                        IconButton(
                          tooltip: context.t('profile_dob_clear'),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _saveField(context, f, ''),
                          icon: Icon(Icons.close_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45)),
                        )
                      else
                        Icon(
                            f.readOnly
                                ? Icons.lock_outline_rounded
                                : Icons.edit_rounded,
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

  // ── Edit Bottom Sheet ──────────────────────────────────────────────────────
  Future<void> _showEditBottomSheet(
      BuildContext context, _FieldConfig f) async {
    final ctrl = _controllerFor(f);
    ctrl.text = f.initialValue;
    ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
    String? errorText;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${context.t('edit')} ${f.label}',
                    style:
                        AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: f.keyboardType,
                    textCapitalization: f.fieldKey == 'email'
                        ? TextCapitalization.none
                        : TextCapitalization.sentences,
                    maxLines: 1,
                    maxLength: kProfileFieldMaxLength[f.fieldKey],
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: f.label,
                      errorText: errorText,
                      errorMaxLines: 2,
                      prefixIcon: Icon(f.icon, color: primary, size: 20),
                      suffixIcon: ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                ctrl.clear();
                                setModalState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.02),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    onChanged: (text) {
                      setModalState(() => errorText = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            context.t('cancel'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final error =
                                      _validateField(context, f, ctrl.text);
                                  if (error != null) {
                                    setModalState(() => errorText = error);
                                    return;
                                  }
                                  setModalState(() => saving = true);
                                  final ok = await _saveField(
                                      this.context, f, ctrl.text);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    Navigator.pop(context);
                                  } else {
                                    setModalState(() => saving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  context.t('save'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Returns a localized error, or null when [raw] is acceptable.
  /// All fields are optional; empty clears the value.
  String? _validateField(BuildContext context, _FieldConfig f, String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final max = kProfileFieldMaxLength[f.fieldKey];
    if (max != null && value.length > max) {
      return context.t('error_max_length', params: {'max': '$max'});
    }
    switch (f.fieldKey) {
      case 'email':
        return Validators.email(context, value);
      case 'phone':
        return Validators.phone(context, normalizePhone(value));
    }
    return null;
  }

  /// Persists one field. Shows success only after the write completes.
  Future<bool> _saveField(
      BuildContext context, _FieldConfig f, String raw) async {
    var value = raw.trim();
    if (f.fieldKey == 'phone') value = normalizePhone(value);
    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateField(f.fieldKey, value);
      if (context.mounted) {
        _showSnack(
            context, context.t('field_updated', params: {'label': f.label}));
      }
      return true;
    } catch (e) {
      AppLogger.e('Profile field save failed (${f.fieldKey}): $e');
      if (context.mounted) {
        _showSnack(context, context.t('profile_save_failed'), isError: true);
      }
      return false;
    }
  }

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        duration: Duration(seconds: isError ? 3 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  // ── Achievements ──────────────────────────────────────────────────────────
  Widget _buildAchievements(
    BuildContext context, {
    required List<TransactionModel> transactions,
    required bool hasBudget,
    required bool isDark,
  }) {
    final txCount = transactions.where((t) => !t.isDeleted).length;
    final achievements = [
      _Achievement(context.t('ach_first_tx'), context.t('ach_first_tx_desc'),
          Icons.star_rounded, AppColors.warning, txCount >= 1),
      _Achievement(
          context.t('ach_budget_tracker'),
          context.t('ach_budget_tracker_desc'),
          Icons.pie_chart_rounded,
          AppColors.info,
          hasBudget),
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
          hasSavingsMonth(transactions)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: achievements.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: i < achievements.length - 1 ? 8 : 0),
              // The description says how to unlock it; previously never shown.
              child: Tooltip(
                message: a.description,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 3),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
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
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
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

  // ── Photo options ─────────────────────────────────────────────────────────
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
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(context, ImageSource.gallery);
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
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(context, ImageSource.camera);
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
                  try {
                    await ref
                        .read(userProfileProvider.notifier)
                        .clearProfilePhoto();
                    if (!context.mounted) return;
                    _showSnack(context, context.t('photo_removed'));
                  } catch (e) {
                    AppLogger.e('Profile photo removal failed: $e');
                    if (!context.mounted) return;
                    _showSnack(context, context.t('profile_save_failed'),
                        isError: true);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    try {
      // Resize/compress at pick time: the photo is stored base64 in Hive and
      // loaded at every startup, so multi-MB camera originals are not OK.
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: kProfilePhotoMaxDimension,
        maxHeight: kProfilePhotoMaxDimension,
        imageQuality: kProfilePhotoQuality,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > kProfilePhotoMaxBytes) {
        if (context.mounted) {
          _showSnack(context, context.t('profile_photo_too_large'),
              isError: true);
        }
        return;
      }
      await ref
          .read(userProfileProvider.notifier)
          .updateProfilePhoto(base64Encode(bytes));
      if (!context.mounted) return;
      _showSnack(context, context.t('photo_updated'));
    } catch (e) {
      // Permission denied, camera unavailable, read/write failure.
      AppLogger.e('Profile photo update failed: $e');
      if (!context.mounted) return;
      _showSnack(context, context.t('profile_photo_failed'), isError: true);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _showDatePicker(BuildContext context, _FieldConfig field) async {
    final now = DateTime.now();
    final firstDate = DateTime(1920);
    var initial = parseStoredDob(field.initialValue) ?? DateTime(1995, 1, 1);
    if (initial.isAfter(now) || initial.isBefore(firstDate)) {
      initial = DateTime(1995, 1, 1);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked == null || !context.mounted) return;
    // Stored in a fixed English format so it parses in any app language.
    await _saveField(context, field, formatDobForStorage(picked));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _initials(BuildContext context, String name) =>
      profileInitials(name, context.t('unknown_initial'));

  // Decoding a base64 photo on every rebuild also hands Image.memory a new
  // byte list each time, forcing a re-decode; memoize by source string.
  String? _photoCacheKey;
  Uint8List? _photoCacheBytes;

  Uint8List? _decodePhotoBytes(String photoBase64) {
    if (photoBase64.isEmpty) return null;
    if (photoBase64 == _photoCacheKey) return _photoCacheBytes;
    Uint8List? bytes;
    try {
      bytes = base64Decode(photoBase64);
    } catch (_) {
      bytes = null;
    }
    _photoCacheKey = photoBase64;
    _photoCacheBytes = bytes;
    return bytes;
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _FieldConfig {
  const _FieldConfig({
    required this.icon,
    required this.label,
    required this.value,
    required this.fieldKey,
    required this.initialValue,
    required this.keyboardType,
    this.isDate = false,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String fieldKey;
  final String initialValue;
  final TextInputType keyboardType;
  final bool isDate;
  final bool readOnly;
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
