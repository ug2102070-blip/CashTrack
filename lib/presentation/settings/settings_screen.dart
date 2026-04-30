// lib/presentation/settings/settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_l10n.dart';
import '../../services/auth_service.dart';
import '../../services/sms_service.dart';
import '../../services/sync_service.dart';
import '../../services/notification_service.dart';
import '../../services/ai_service.dart';
import '../../services/screenshot_protection_service.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../providers/app_providers.dart';
import '../../data/models/transaction_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _pinKey = 'app_lock_pin';

  final List<(Color, String)> accentColorEntries = const [
    (Color(0xFF2D7A7B), 'Teal'),
    (Color(0xFF3B82F6), 'Blue'),
    (Color(0xFFEF4444), 'Red'),
    (Color(0xFF10B981), 'Emerald'),
    (Color(0xFF8B5CF6), 'Violet'),
    (Color(0xFFF59E0B), 'Amber'),
    (Color(0xFFEC4899), 'Pink'),
    (Color(0xFF06B6D4), 'Cyan'),
    (Color(0xFF0F766E), 'Jade'),
    (Color(0xFF2563EB), 'Royal'),
    (Color(0xFFDC2626), 'Crimson'),
    (Color(0xFF7C3AED), 'Purple'),
    (Color(0xFFE11D48), 'Rose'),
    (Color(0xFF0891B2), 'Ocean'),
    (Color(0xFF4F46E5), 'Indigo'),
    (Color(0xFFD97706), 'Gold'),
    (Color(0xFF059669), 'Forest'),
    (Color(0xFF9333EA), 'Grape'),
    (Color(0xFF0284C7), 'Sky'),
    (Color(0xFF64748B), 'Slate'),
    (Color(0xFFDB2777), 'Magenta'),
    (Color(0xFF16A34A), 'Green'),
    (Color(0xFFC026D3), 'Fuchsia'),
    (Color(0xFFEA580C), 'Flame'),
  ];

  List<Color> get accentColors => accentColorEntries.map((e) => e.$1).toList();

  WidgetStateProperty<Color?> _switchThumbColor(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return primary;
      }
      return null;
    });
  }

  WidgetStateProperty<Color?> _switchTrackColor(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return primary.withValues(alpha: 0.45);
      }
      return null;
    });
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _anim({required int ms, required Widget child}) {
    final s = (ms / 650).clamp(0.0, 1.0);
    final e = ((ms + 280) / 650).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(userProfileProvider);
    final isDark = settings['darkMode'] ?? false;
    final smsTrack = settings['smsTrack'] ?? false;
    final rawCurrency = settings['currency'] as String?;
    final currency = _normalizeCurrency(rawCurrency);
    final smsMode = settings['smsMode'] ?? 'ask';
    final hideAmounts = settings['hideAmounts'] ?? false;
    final screenIsDark = Theme.of(context).brightness == Brightness.dark;
    final language = settings['language'] ?? 'en';
    // Additional settings
    final notifEnabled = settings['notifications'] ?? true;
    final weeklyReport = settings['weeklyReport'] ?? false;
    final biometricLock = settings['biometricLock'] ?? false;

    final rolloverBudget = settings['rolloverBudget'] ?? false;
    final dailyReminderTime = settings['dailyReminderTime'] as String?;
    final screenshotProtection = settings['screenshotProtection'] ?? false;
    final autoLockMinutes = settings['autoLockMinutes'] ?? 5;
    final pinSet = settings['appLockPinSet'] ?? false;
    final voiceTransactionInput = settings['voiceTransactionInput'] ?? false;
    final receiptImageAttachment = settings['receiptImageAttachment'] ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 0, child: _buildPageHeader(context, screenIsDark)),
              ),

              // â”€â”€ Profile Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 50, child: _buildProfileCard(context, profile, isDark)),
              ),

              // â”€â”€ Appearance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 110,
                    child: _sectionLabel(context, context.t('appearance'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 130,
                  child: _buildAppearanceSection(context, settings, isDark,
                      currency, hideAmounts, screenIsDark),
                ),
              ),

              // â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 160,
                    child: _sectionLabel(context, context.t('notifications'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 180,
                  child: _buildNotificationsSection(context, notifEnabled,
                      weeklyReport, dailyReminderTime, screenIsDark),
                ),
              ),

              // â”€â”€ Planning & Tools â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 195,
                    child: _sectionLabel(context, context.t('planning_tools'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 205,
                  child: _buildPlanningSection(
                    context,
                    rolloverBudget,
                    screenIsDark,
                  ),
                ),
              ),

              // â”€â”€ General â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 210,
                    child: _sectionLabel(context, context.t('general'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 230,
                  child: _buildGeneralSection(
                      context, smsTrack, smsMode, language, screenIsDark),
                ),
              ),

              SliverToBoxAdapter(
                child: _anim(
                  ms: 235,
                  child: _sectionLabel(context, context.t('transaction_entry')),
                ),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 240,
                  child: _buildTransactionEntrySection(
                    context,
                    voiceTransactionInput,
                    receiptImageAttachment,
                    screenIsDark,
                  ),
                ),
              ),

              // ── AI Assistant ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _anim(
                    ms: 245,
                    child: _sectionLabel(context, context.t('ai_assistant'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 255,
                  child: _buildAiSection(context, screenIsDark),
                ),
              ),

              // â”€â”€ Security â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 260,
                    child:
                        _sectionLabel(context, context.t('security_privacy'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                  ms: 280,
                  child: _buildSecuritySection(
                      context,
                      biometricLock,
                      hideAmounts,
                      screenshotProtection,
                      autoLockMinutes,
                      pinSet,
                      screenIsDark),
                ),
              ),

              // â”€â”€ Data & Sync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 310,
                    child: _sectionLabel(context, context.t('data_sync'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    ms: 330, child: _buildDataSection(context, screenIsDark)),
              ),

              // â”€â”€ About â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 360, child: _sectionLabel(context, context.t('about'))),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    ms: 380, child: _buildAboutSection(context, screenIsDark)),
              ),

              // â”€â”€ Danger Zone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: _anim(
                    ms: 410, child: _buildDangerZone(context, screenIsDark)),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Page header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPageHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('settings'),
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  context.t('customize_experience'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Profile Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildProfileCard(
      BuildContext context, Map<String, String> profile, bool isDark) {
    final fullName = (profile['fullName'] ?? '').trim();
    final email = (profile['email'] ?? '').trim();
    final displayName =
        fullName.isEmpty ? context.t('add_your_name') : fullName;
    final displayEmail =
        email.isEmpty ? context.t('tap_complete_profile') : email;
    final initials = _initials(context, displayName);
    final photoBase64 = (profile['photoBase64'] ?? '').trim();
    final profilePhotoBytes = _decodePhotoBytes(photoBase64);
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => context.push('/profile'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary,
              Color.lerp(primary, Colors.indigo.shade700, 0.45)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: profilePhotoBytes != null
                    ? Image.memory(profilePhotoBytes, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: AppTextStyles.h5.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(displayEmail,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    Map<String, dynamic> settings,
    bool isDark,
    String currency,
    bool hideAmounts,
    bool screenIsDark,
  ) {
    final primary = Theme.of(context).colorScheme.primary;

    return _settingsGroup(context, screenIsDark, [
      // Dark mode
      _settingsTile(
        context,
        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        iconColor: isDark ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B),
        title: context.t('dark_mode'),
        subtitle:
            isDark ? context.t('currently_dark') : context.t('currently_light'),
        trailing: Switch.adaptive(
          value: isDark,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).updateDarkMode(v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      _divider(context),

      // Accent color
      _settingsTile(
        context,
        icon: Icons.palette_rounded,
        iconColor: primary,
        title: context.t('accent_color'),
        subtitle: context.t('personalize_color'),
        trailing: _buildColorPickerPreview(context, settings),
        onTap: () => _showAccentColorDialog(context, settings),
      ),
      _divider(context),

      // Currency
      _settingsTile(
        context,
        icon: Icons.currency_exchange_rounded,
        iconColor: AppColors.success,
        title: context.t('currency'),
        subtitle: currency,
        onTap: () => _showCurrencyDialog(context),
      ),
      _divider(context),

      // Hide amounts
      _settingsTile(
        context,
        icon: hideAmounts
            ? Icons.visibility_off_rounded
            : Icons.visibility_rounded,
        iconColor: AppColors.info,
        title: context.t('hide_amounts'),
        subtitle: _hideAmountsSubtitle(context, hideAmounts),
        trailing: Switch.adaptive(
          value: hideAmounts,
          onChanged: (v) async {
            await ref.read(settingsProvider.notifier).updateHideAmounts(v);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  v
                      ? context.t('hide_amounts_on_hint')
                      : context.t('hide_amounts_off_hint'),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
    ]);
  }

  // â”€â”€ Notifications Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildNotificationsSection(
    BuildContext context,
    bool notifEnabled,
    bool weeklyReport,
    String? dailyReminderTime,
    bool isDark,
  ) {
    final reminderLabel = dailyReminderTime == null
        ? context.t('daily_reminder_time')
        : context.t(
            'daily_reminder_time_value',
            params: {'time': _formatTimeString(dailyReminderTime, context)},
          );
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.notifications_rounded,
        iconColor: AppColors.warning,
        title: context.t('push_notifications'),
        subtitle: _pushNotificationsSubtitle(context, notifEnabled),
        trailing: Switch.adaptive(
          value: notifEnabled,
          onChanged: (v) async {
            await ref
                .read(settingsProvider.notifier)
                .update('notifications', v);
            if (kIsWeb) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(context.t('feature_not_supported_web'))),
                );
              }
              return;
            }
            await NotificationService().setNotificationsEnabled(v);
            if (v && dailyReminderTime != null) {
              final time = _timeFromString(dailyReminderTime);
              if (time != null) {
                await NotificationService().scheduleDailyReminder(time);
              }
            }
            if (v && weeklyReport) {
              await NotificationService().updateWeeklyReport(true);
            }
          },
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.summarize_rounded,
        iconColor: notifEnabled ? AppColors.info : AppColors.info.withValues(alpha: 0.4),
        title: context.t('weekly_report'),
        subtitle: _weeklyReportSubtitle(context, weeklyReport),
        trailing: Switch.adaptive(
          value: weeklyReport,
          onChanged: notifEnabled
              ? (v) async {
                  await ref.read(settingsProvider.notifier).update('weeklyReport', v);
                  if (kIsWeb) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.t('feature_not_supported_web'))),
                      );
                    }
                    return;
                  }
                  await NotificationService().updateWeeklyReport(v);
                  if (v && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isBangla(context)
                              ? 'প্রতি রবিবার সকালে সাপ্তাহিক আয়-ব্যয়ের সামারি নোটিফিকেশন আসবে'
                              : 'Weekly summary notification will arrive every Sunday morning',
                        ),
                      ),
                    );
                  }
                }
              : null,
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      _divider(context),
      Opacity(
        opacity: notifEnabled ? 1.0 : 0.45,
        child: _settingsTile(
          context,
          icon: Icons.campaign_rounded,
          iconColor: AppColors.primary,
          title: context.t('notification_schedule'),
          subtitle: notifEnabled
              ? _notificationScheduleSubtitle(context, reminderLabel)
              : (_isBangla(context) ? 'Push Notifications চালু করুন' : 'Turn on Push Notifications first'),
          onTap: notifEnabled
              ? () => _showTimePickerDialog(context, dailyReminderTime)
              : null,
        ),
      ),
    ]);
  }

  // â”€â”€ Planning & Tools Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPlanningSection(
    BuildContext context,
    bool rolloverBudget,
    bool isDark,
  ) {
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.category_rounded,
        iconColor: AppColors.info,
        title: context.t('manage_categories'),
        subtitle: _manageCategoriesSubtitle(context),
        onTap: () => context.push('/categories'),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppColors.primary,
        title: context.t('manage_budgets'),
        subtitle: context.t('manage_budgets_desc'),
        onTap: () => context.push('/budget'),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.sync_alt_rounded,
        iconColor: AppColors.secondary,
        title: context.t('rollover_budget'),
        subtitle: _budgetRolloverSubtitle(context, rolloverBudget),
        trailing: Switch.adaptive(
          value: rolloverBudget,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).updateRolloverBudget(v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
    ]);
  }

  // â”€â”€ General Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildGeneralSection(BuildContext context, bool smsTrack,
      String smsMode, String language, bool isDark) {
    final languageLabel =
        language == 'bn' ? context.t('bangla') : context.t('english');
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.sms_rounded,
        iconColor: AppColors.success,
        title: context.t('sms_auto_import'),
        subtitle: context.t('import_sms'),
        trailing: Switch.adaptive(
          value: smsTrack,
          onChanged: (v) async {
            if (v) {
              final granted = await SmsService.requestPermission();
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('sms_permission_denied'))),
                  );
                }
                return;
              }
            }
            ref.read(settingsProvider.notifier).updateSmsTrack(v);
          },
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      if (smsTrack) ...[
        _divider(context),
        _settingsTile(
          context,
          icon: Icons.tune_rounded,
          iconColor: AppColors.info,
          title: context.t('sms_import_mode'),
          subtitle: _smsModeLabel(smsMode),
          onTap: () => _showSmsModeDialog(context, smsMode),
        ),
      ],
      _settingsTile(
        context,
        icon: Icons.language_rounded,
        iconColor: AppColors.secondary,
        title: context.t('language'),
        subtitle: languageLabel,
        onTap: () => _showLanguageDialog(context),
      ),
    ]);
  }

  Widget _buildTransactionEntrySection(
    BuildContext context,
    bool voiceEnabled,
    bool receiptEnabled,
    bool isDark,
  ) {
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.mic_rounded,
        iconColor: AppColors.primary,
        title: context.t('voice_transaction_input'),
        subtitle: _voiceInputSubtitle(context),
        trailing: Switch.adaptive(
          value: voiceEnabled,
          onChanged: (v) => _toggleVoiceTransactionInput(context, v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.image_rounded,
        iconColor: AppColors.secondary,
        title: context.t('receipt_photo_option'),
        subtitle: _receiptOptionSubtitle(context),
        trailing: Switch.adaptive(
          value: receiptEnabled,
          onChanged: (v) => _toggleReceiptAttachment(context, v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
    ]);
  }

  // AI Assistant Section

  Widget _buildAiSection(BuildContext context, bool isDark) {
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF8B5CF6),
        title: context.t('gemini_api_key'),
        subtitle: context.t('gemini_key_desc'),
        onTap: () => _showApiKeyDialog(context),
      ),
    ]);
  }

  void _showApiKeyDialog(BuildContext context) {
    final TextEditingController ctrl = TextEditingController();
    AiService.loadApiKey().then((k) {
      if (ctrl.text.isEmpty) ctrl.text = k;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.auto_awesome_rounded,
              color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(context.t('gemini_api_key'),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('gemini_key_info'),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await AiService.saveApiKey(ctrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('api_key_saved'))),
                );
              }
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Security Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSecuritySection(
    BuildContext context,
    bool biometricLock,
    bool hideAmounts,
    bool screenshotProtection,
    int autoLockMinutes,
    bool pinSet,
    bool isDark,
  ) {
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.fingerprint_rounded,
        iconColor: AppColors.primary,
        title: context.t('biometric_lock'),
        subtitle: context.t('fingerprint_face'),
        trailing: Switch.adaptive(
          value: biometricLock,
          onChanged: (v) => _toggleBiometricLock(context, v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.lock_rounded,
        iconColor: AppColors.warning,
        title: context.t('app_lock_pin'),
        subtitle: pinSet ? context.t('pin_set') : context.t('set_4_digit'),
        onTap: () => _showPinDialog(context, pinSet),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.screen_lock_portrait_rounded,
        iconColor: AppColors.info,
        title: context.t('auto_lock'),
        subtitle: _autoLockLabel(context, autoLockMinutes),
        onTap: () => _showAutoLockDialog(context, autoLockMinutes),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.screenshot_monitor_rounded,
        iconColor: AppColors.error,
        title: context.t('screenshot_protection'),
        subtitle: _screenshotProtectionSubtitle(context),
        trailing: Switch.adaptive(
          value: screenshotProtection,
          onChanged: (v) => _toggleScreenshotProtection(context, v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
    ]);
  }

  // â”€â”€ Data Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDataSection(BuildContext context, bool isDark) {
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.cloud_upload_rounded,
        iconColor: AppColors.info,
        title: context.t('backup_cloud'),
        subtitle: context.t('last_backup_never'),
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('backup_started'))),
          );
          final result = await SyncService().backupToCloud();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.contains('Backed up')
                      ? context.t('backup_complete')
                      : result,
                ),
              ),
            );
          }
        },
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.cloud_download_rounded,
        iconColor: AppColors.success,
        title: context.t('restore_cloud'),
        subtitle: context.t('restore_data'),
        onTap: () => _confirmRestore(context),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.upload_file_rounded,
        iconColor: AppColors.warning,
        title: context.t('export_data'),
        subtitle: _exportSubtitle(context),
        onTap: () => _showExportDialog(context),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.download_rounded,
        iconColor: AppColors.secondary,
        title: context.t('import_data'),
        subtitle: context.t('import_from_csv'),
        onTap: () => _importFromCsv(context),
      ),
    ]);
  }

  // â”€â”€ About Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return _settingsGroup(context, isDark, [
      // App info card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isBangla(context)
                        ? 'ব্যক্তিগত অর্থ ব্যবস্থাপনা অ্যাপ'
                        : 'Personal Finance Manager',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.star_rounded,
        iconColor: AppColors.warning,
        title: context.t('rate_app'),
        subtitle: context.t('love_rate_us'),
        onTap: () => _launchExternalUrl(AppConstants.appWebsiteUrl),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.bug_report_rounded,
        iconColor: AppColors.error,
        title: context.t('report_bug'),
        subtitle: context.t('help_improve'),
        onTap: () => _launchEmail(AppConstants.supportEmail),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.privacy_tip_rounded,
        iconColor: AppColors.secondary,
        title: context.t('privacy_policy'),
        subtitle: context.t('data_handling'),
        onTap: () => _showInfoDialog(
          context,
          title: context.t('privacy_policy'),
          body: _isBangla(context)
              ? 'CashTrack আপনার আর্থিক ডেটা স্থানীয়ভাবে ডিভাইসে সংরক্ষণ করে। ক্লাউড ব্যাকআপ শুধুমাত্র আপনার অনুমতিতে হয়।'
              : 'CashTrack stores your financial data locally on your device. Cloud backups only happen when you explicitly enable them.',
        ),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.description_rounded,
        iconColor: AppColors.primary,
        title: context.t('terms_service'),
        subtitle: _termsSubtitle(context),
        onTap: () => _showInfoDialog(
          context,
          title: context.t('terms_service'),
          body: _isBangla(context)
              ? 'এই অ্যাপটি ব্যক্তিগত অর্থ ট্র্যাকিংয়ের জন্য। আমদানি করা ডেটা যাচাই করা এবং ব্যাকআপ রাখা আপনার দায়িত্ব।'
              : 'This app is for personal finance tracking. You are responsible for reviewing imported data and keeping your own backups.',
        ),
      ),
    ]);
  }

  // â”€â”€ Danger Zone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDangerZone(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          // Logout
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
            ),
            child: _settingsTile(
              context,
              icon: Icons.logout_rounded,
              iconColor: AppColors.error,
              title: context.t('sign_out'),
              subtitle: context.t('sign_out_subtitle'),
              titleColor: AppColors.error,
              onTap: () => _confirmLogout(context),
              showChevron: false,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _settingsGroup(
      BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showChevron = true,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          titleColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (showChevron && onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3))
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 67),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildColorPickerPreview(
      BuildContext context, Map<String, dynamic> settings) {
    final Object? stored = settings['accentColor'];
    final int accentInt = stored is int ? stored : AppColors.primary.toARGB32();
    final Color currentColor = Color(accentInt);
    final previewColors = accentColors.take(4).toList();
    return SizedBox(
      width: 88,
      height: 28,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          for (var i = 0; i < previewColors.length; i++)
            Positioned(
              right: i * 16,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: previewColors[previewColors.length - 1 - i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          Positioned(
            left: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccentColorDialog(
    BuildContext context,
    Map<String, dynamic> settings,
  ) {
    final Object? stored = settings['accentColor'];
    final int accentInt = stored is int ? stored : AppColors.primary.toARGB32();
    final currentColor = Color(accentInt);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.t('accent_color'),
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _colorPickerSubtitle(context),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                itemCount: accentColorEntries.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (gridContext, index) {
                  final entry = accentColorEntries[index];
                  final color = entry.$1;
                  final name = entry.$2;
                  final selected =
                      color.toARGB32() == currentColor.toARGB32();
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await ref
                          .read(settingsProvider.notifier)
                          .updateAccentColor(color.toARGB32());
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : color.withValues(alpha: 0.25),
                                width: selected ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: selected
                                ? const Center(
                                    child: Icon(Icons.check_rounded,
                                        color: Colors.white, size: 26))
                                : null,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? color
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ Dialogs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showCurrencyDialog(BuildContext context) {
    final currencies = [
      ('\u09F3', 'Bangladeshi Taka'),
      ('\$', 'US Dollar'),
      ('\u20AC', 'Euro'),
      ('\u00A3', 'British Pound'),
      ('\u20B9', 'Indian Rupee'),
      ('\u00A5', 'Japanese Yen'),
      ('\u20BA', 'Turkish Lira'),
      ('\u20A9', 'Korean Won'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.7;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 24 + MediaQuery.of(ctx).padding.bottom),
          child: SafeArea(
            top: false,
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(context.t('select_currency'), style: AppTextStyles.h5),
                const SizedBox(height: 12),
                SizedBox(
                  height: sheetHeight,
                  child: ListView.separated(
                    itemCount: currencies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final pair = currencies[i];
                      final rawCurrent =
                          ref.read(settingsProvider)['currency'] as String?;
                      final current = rawCurrent == '৳'
                          ? '\u09F3'
                          : (rawCurrent ?? '\u09F3');
                      final isSelected = current == pair.$1;
                      final primary = Theme.of(ctx).colorScheme.primary;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: primary.withValues(
                              alpha: isSelected ? 0.12 : 0.06),
                          child: Text(
                            pair.$1,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        title: Text(
                          pair.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(pair.$1),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: primary)
                            : null,
                        onTap: () {
                          ref
                              .read(settingsProvider.notifier)
                              .updateCurrency(pair.$1);
                          Navigator.pop(ctx);
                        },
                        selected: isSelected,
                        selectedTileColor: primary.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSmsModeDialog(BuildContext context, String current) {
    final modes = [
      (
        'ask',
        context.t('ask_before_adding'),
        Icons.help_outline_rounded,
        context.t('manual_review_sms')
      ),
      (
        'silent',
        context.t('auto_silent'),
        Icons.volume_off_rounded,
        context.t('import_without_notif')
      ),
      (
        'daily_summary',
        context.t('auto_daily_summary'),
        Icons.summarize_rounded,
        context.t('auto_import_digest')
      ),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 24 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(context.t('sms_mode_title'), style: AppTextStyles.h5),
              const SizedBox(height: 12),
              ...modes.map((m) {
                final isSelected = current == m.$1;
                final primary = theme.colorScheme.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.1)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.$3,
                          color: isSelected
                              ? primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                    ),
                    title: Text(m.$2,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? primary : null)),
                    subtitle: Text(m.$4),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: primary)
                        : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).updateSmsMode(m.$1);
                      Navigator.pop(ctx);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    selected: isSelected,
                    selectedTileColor: primary.withValues(alpha: 0.05),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTimePickerDialog(BuildContext context, String? current) async {
    final initial =
        _timeFromString(current) ?? const TimeOfDay(hour: 20, minute: 0);
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time == null || !context.mounted) return;
    final value = _timeToString(time);
    await ref
        .read(settingsProvider.notifier)
        .update('dailyReminderTime', value);
    if (!kIsWeb) {
      await NotificationService().scheduleDailyReminder(time);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('feature_not_supported_web'))),
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context
            .t('reminder_set_for', params: {'time': time.format(context)})),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final langs = [
      ('en', context.t('english')),
      ('bn', context.t('bangla')),
    ];
    showDialog(
      context: context,
      builder: (ctx) {
        final current =
            (ref.read(settingsProvider)['language'] as String?) ?? 'en';
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.t('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: langs.map((l) {
              final isSelected = l.$1 == current;
              return ListTile(
                title: Text(l.$2),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).updateLanguage(l.$1);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showPinDialog(BuildContext context, bool pinSet) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final hasPin = await _hasPin();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(hasPin ? context.t('change_pin') : context.t('set_pin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.t('enter_pin'),
                counterText: '',
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.t('confirm_pin'),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          if (hasPin)
            TextButton(
              onPressed: () async {
                await _removePin();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('pin_removed'))),
                  );
                }
              },
              child: Text(context.t('remove_pin')),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();
              if (pin.length != 4 || confirm.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('pin_invalid'))),
                );
                return;
              }
              if (pin != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('pin_mismatch'))),
                );
                return;
              }
              await _savePin(pin);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('pin_saved'))),
                );
              }
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  void _showAutoLockDialog(BuildContext context, int currentMinutes) {
    final options = <int, String>{
      1: context.t('one_minute'),
      5: context.t('five_minutes'),
      15: context.t('fifteen_minutes'),
      30: context.t('thirty_minutes'),
      0: context.t('never'),
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 24 + MediaQuery.of(ctx).padding.bottom),
          child: SafeArea(
            top: false,
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(context.t('auto_lock'), style: AppTextStyles.h5),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final minutes = options.keys.elementAt(i);
                    final label = options[minutes]!;
                    return ListTile(
                      title: Text(label),
                      trailing: minutes == currentMinutes
                          ? Icon(Icons.check_circle_rounded,
                              color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      onTap: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .update('autoLockMinutes', minutes);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportData(
    BuildContext context, {
    required String format,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final extension = switch (format) {
        'csv' => 'csv',
        'pdf' => 'pdf',
        _ => 'json',
      };
      final file = File('${dir.path}/cashtrack_export_$timestamp.$extension');

      if (format == 'csv') {
        await file.writeAsString(_buildExportCsv(), flush: true);
      } else if (format == 'pdf') {
        await file.writeAsBytes(await _buildExportPdf().save(), flush: true);
      } else {
        await file.writeAsString(_buildExportJson(), flush: true);
      }

      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'CashTrack ${format.toUpperCase()} export',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('error_with_detail', params: {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  String _buildExportJson() {
    final transactions = ref.read(transactionsProvider);
    final categories = ref.read(categoriesProvider);
    final accounts = ref.read(accountsProvider);
    final budgets = ref.read(budgetsProvider);
    final goals = ref.read(goalsProvider);
    final debts = ref.read(debtsProvider);
    final assets = ref.read(assetsProvider);
    final investments = ref.read(investmentsProvider);
    final settings = ref.read(settingsProvider);
    final profile = ref.read(userProfileProvider);

    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'app': AppConstants.appName,
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'debts': debts.map((e) => e.toJson()).toList(),
      'assets': assets.map((e) => e.toJson()).toList(),
      'investments': investments.map((e) => e.toJson()).toList(),
      'settings': settings,
      'profile': profile,
    });
  }

  String _buildExportCsv() {
    final categories = {
      for (final category in ref.read(categoriesProvider))
        category.id: category.name,
    };
    final accounts = {
      for (final account in ref.read(accountsProvider))
        account.id: account.name,
    };

    final rows = <List<String>>[
      ['date', 'type', 'category', 'amount', 'account', 'note'],
      ...ref.read(transactionsProvider).map((transaction) {
        return [
          transaction.date.toIso8601String(),
          transaction.type.name,
          categories[transaction.categoryId] ?? transaction.categoryId,
          transaction.amount.toStringAsFixed(2),
          accounts[transaction.accountId] ?? transaction.accountId,
          transaction.note ?? '',
        ];
      }),
    ];

    return const ListToCsvConverter().convert(rows);
  }

  pw.Document _buildExportPdf() {
    final transactions = ref.read(transactionsProvider);
    final categories = {
      for (final category in ref.read(categoriesProvider))
        category.id: category.name,
    };
    final accounts = {
      for (final account in ref.read(accountsProvider))
        account.id: account.name,
    };
    final settings = ref.read(settingsProvider);
    // PDF default fonts don't support Bengali taka sign (৳),
    // so we use 'Tk' as a safe fallback for PDF rendering.
    final rawCurrency = _normalizeCurrency(settings['currency'] as String?);
    final currency = (rawCurrency == '\u09F3' || rawCurrency == '৳')
        ? 'Tk '
        : '$rawCurrency ';

    double income = 0;
    double expense = 0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        expense += transaction.amount;
      }
    }

    final pdf = pw.Document();
    final rows = transactions.take(20).map((transaction) {
      final sign = transaction.type == TransactionType.income ? '+' : '-';
      return [
        DateFormat('dd MMM yyyy').format(transaction.date),
        transaction.type.name,
        categories[transaction.categoryId] ?? transaction.categoryId,
        '$sign$currency${transaction.amount.toStringAsFixed(2)}',
        accounts[transaction.accountId] ?? transaction.accountId,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            AppConstants.appName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF2D7A7B),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Exported: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.Text('Income: $currency${income.toStringAsFixed(2)}'),
          pw.Text('Expense: $currency${expense.toStringAsFixed(2)}'),
          pw.Text('Net: $currency${(income - expense).toStringAsFixed(2)}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Recent Transactions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (rows.isEmpty)
            pw.Text('No transactions available')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Type', 'Category', 'Amount', 'Account'],
              data: rows,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('restore_data'))),
    );

    final result = await SyncService().restoreLatestBackupFromCloud();
    await _reloadAppDataProviders();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result)),
    );
  }

  Future<void> _reloadAppDataProviders() async {
    ref.read(transactionsProvider.notifier).loadTransactions();
    ref.read(categoriesProvider.notifier).loadCategories();
    ref.read(accountsProvider.notifier).loadAccounts();
    ref.read(budgetsProvider.notifier).loadBudgets();
    ref.read(goalsProvider.notifier).loadGoals();
    ref.read(debtsProvider.notifier).loadDebts();
    ref.read(assetsProvider.notifier).loadAssets();
    ref.read(investmentsProvider.notifier).loadInvestments();
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('close')),
          ),
        ],
      ),
    );
  }

  bool _isBangla(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'bn';

  String _hideAmountsSubtitle(BuildContext context, bool enabled) {
    return _isBangla(context)
        ? (enabled
            ? 'ড্যাশবোর্ড, প্রোফাইল ও রিপোর্টে টাকার অঙ্ক লুকানো থাকবে'
            : 'ব্যালেন্স ও রিপোর্টের অঙ্ক স্বাভাবিকভাবে দেখা যাবে')
        : (enabled
            ? 'Balances and reports stay masked until you reveal them'
            : 'Balances and reports stay visible across the app');
  }

  String _pushNotificationsSubtitle(BuildContext context, bool enabled) {
    return _isBangla(context)
        ? (enabled
            ? 'রিমাইন্ডার, বাজেট অ্যালার্ট ও সাপ্তাহিক সামারি নোটিফিকেশন আসবে'
            : 'বন্ধ থাকলে অ্যাপের কোনো লোকাল নোটিফিকেশন দেখাবে না')
        : (enabled
            ? 'Daily reminders, alerts and weekly summaries can appear'
            : 'When off, the app will not show local notifications');
  }

  String _weeklyReportSubtitle(BuildContext context, bool enabled) {
    return _isBangla(context)
        ? (enabled
            ? '\u09aa\u09cd\u09b0\u09a4\u09bf \u09b0\u09ac\u09bf\u09ac\u09be\u09b0 \u09b8\u0995\u09be\u09b2 \u09ef\u099f\u09be\u09af\u09bc \u0986\u09af\u09bc-\u09ac\u09cd\u09af\u09af\u09bc\u09c7\u09b0 \u09b8\u09be\u09ae\u09be\u09b0\u09bf \u09a8\u09cb\u099f\u09bf\u09ab\u09bf\u0995\u09c7\u09b6\u09a8 \u0986\u09b8\u09ac\u09c7'
            : '\u09ac\u09a8\u09cd\u09a7 \u09a5\u09be\u0995\u09b2\u09c7 \u09b8\u09be\u09aa\u09cd\u09a4\u09be\u09b9\u09bf\u0995 \u09b8\u09be\u09ae\u09be\u09b0\u09bf \u09a8\u09cb\u099f\u09bf\u09ab\u09bf\u0995\u09c7\u09b6\u09a8 \u09af\u09be\u09ac\u09c7 \u09a8\u09be')
        : (enabled
            ? 'Every Sunday at 9 AM, a weekly income vs expense summary notification arrives'
            : 'No weekly summary notification will be sent');
  }

  String _notificationScheduleSubtitle(
      BuildContext context, String reminderLabel) {
    return _isBangla(context)
        ? 'দৈনিক রিমাইন্ডার সময়: $reminderLabel'
        : 'Daily reminder time: $reminderLabel';
  }


  String _manageCategoriesSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'খাবার, ভাড়া, ইউটিলিটি, ফ্রিল্যান্সসহ ডিফল্ট ক্যাটাগরি ম্যানেজ করুন'
        : 'Manage expanded defaults like rent, utilities, freelance and more';
  }

  String _budgetRolloverSubtitle(BuildContext context, bool enabled) {
    return _isBangla(context)
        ? (enabled
            ? 'মাস শেষে বাকি বাজেট পরের মাসে carry forward হবে'
            : 'প্রতি মাসের বাজেট আলাদা থাকবে, carry forward হবে না')
        : (enabled
            ? 'Unused monthly budget carries into the next month'
            : 'Each month starts fresh without carrying leftovers');
  }

  String _voiceInputSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'ট্রানজ্যাকশন ফর্মে মাইক বাটন দেখাবে এবং ভয়েস থেকে amount/note নিতে পারবে'
        : 'Shows a mic button in the transaction form to capture amount and note';
  }

  String _receiptOptionSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'ট্রানজ্যাকশনের সাথে ক্যামেরা/গ্যালারি থেকে রিসিপ্ট যোগ করা যাবে'
        : 'Lets users attach a receipt image from camera or gallery';
  }

  String _screenshotProtectionSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'Android এ sensitive screen-এর screenshot ও recent preview ব্লক করবে'
        : 'Blocks screenshots and recent-app previews on Android';
  }

  String _exportSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'CSV, JSON বা PDF আকারে ডেটা এক্সপোর্ট করুন'
        : 'Export your data as CSV, JSON or PDF';
  }


  String _termsSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'ব্যবহার ও দায়িত্ব সম্পর্কিত সংক্ষিপ্ত তথ্য'
        : 'A short summary of usage expectations';
  }

  String _colorPickerSubtitle(BuildContext context) {
    return _isBangla(context)
        ? 'একটি অ্যাকসেন্ট রঙ বেছে নিন'
        : 'Choose the accent color you want across the app';
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.t('export_data'),
                style:
                    AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _exportSubtitle(context),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 18),
              _exportFormatTile(
                context: context,
                sheetCtx: sheetCtx,
                icon: Icons.table_chart_rounded,
                color: const Color(0xFF10B981),
                title: 'CSV',
                subtitle: _isBangla(context)
                    ? 'Excel / Google Sheets এ ওপেন করা যাবে'
                    : 'Opens in Excel or Google Sheets',
                format: 'csv',
              ),
              const SizedBox(height: 10),
              _exportFormatTile(
                context: context,
                sheetCtx: sheetCtx,
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFEF4444),
                title: 'PDF',
                subtitle: _isBangla(context)
                    ? 'প্রিন্ট বা শেয়ার করার জন্য উপযুক্ত'
                    : 'Ready to print or share',
                format: 'pdf',
              ),
              const SizedBox(height: 10),
              _exportFormatTile(
                context: context,
                sheetCtx: sheetCtx,
                icon: Icons.data_object_rounded,
                color: const Color(0xFF3B82F6),
                title: 'JSON',
                subtitle: _isBangla(context)
                    ? 'সম্পূর্ণ ডেটা ব্যাকআপ ফরম্যাট'
                    : 'Full data backup format',
                format: 'json',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportFormatTile({
    required BuildContext context,
    required BuildContext sheetCtx,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String format,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        Navigator.pop(sheetCtx);
        await _exportData(context, format: format);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('restore_data_q')),
        content: Text(context.t('restore_overwrite')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _restoreFromCloud(context);
            },
            child: Text(context.t('restore')),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('sign_out_q')),
        content: Text(context.t('sign_out_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            child: Text(context.t('sign_out')),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometricLock(BuildContext context, bool enable) async {
    if (!enable) {
      await ref.read(settingsProvider.notifier).update('biometricLock', false);
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('feature_not_supported_web'))),
      );
      return;
    }
    final isSupported = await _localAuth.isDeviceSupported();
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!context.mounted) return;
    if (!isSupported || !canCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('biometric_not_supported'))),
      );
      return;
    }
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: context.t('biometric_unlock_reason'),
      );
      if (!context.mounted) return;
      if (ok) {
        await ref.read(settingsProvider.notifier).update('biometricLock', true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('biometric_failed'))),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('biometric_failed'))),
      );
    }
  }

  Future<void> _toggleVoiceTransactionInput(
    BuildContext context,
    bool enable,
  ) async {
    await ref
        .read(settingsProvider.notifier)
        .update('voiceTransactionInput', enable);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBangla(context)
              ? (enable
                  ? 'ট্রানজ্যাকশন ফর্মে ভয়েস ইনপুট চালু হয়েছে'
                  : 'ভয়েস ইনপুট বন্ধ করা হয়েছে')
              : (enable
                  ? 'Voice input is enabled in the transaction form'
                  : 'Voice input has been turned off'),
        ),
      ),
    );
  }

  Future<void> _toggleReceiptAttachment(
    BuildContext context,
    bool enable,
  ) async {
    await ref
        .read(settingsProvider.notifier)
        .update('receiptImageAttachment', enable);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBangla(context)
              ? (enable
                  ? 'রিসিপ্ট ছবি অপশন চালু হয়েছে'
                  : 'রিসিপ্ট ছবি অপশন বন্ধ করা হয়েছে')
              : (enable
                  ? 'Receipt image support is enabled'
                  : 'Receipt image support has been turned off'),
        ),
      ),
    );
  }

  Future<void> _toggleScreenshotProtection(
      BuildContext context, bool enable) async {
    await ref
        .read(settingsProvider.notifier)
        .update('screenshotProtection', enable);
    final applied =
        await ScreenshotProtectionService.instance.apply(enabled: enable);
    if (!context.mounted) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('feature_not_supported_web'))),
      );
      return;
    }
    if (!applied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBangla(context)
                ? 'এই ডিভাইসে screenshot protection পুরোপুরি support নাও করতে পারে'
                : 'This device may not fully support screenshot protection',
          ),
        ),
      );
    }
  }

  String _autoLockLabel(BuildContext context, int minutes) {
    switch (minutes) {
      case 1:
        return context.t('one_minute');
      case 5:
        return context.t('five_minutes');
      case 15:
        return context.t('fifteen_minutes');
      case 30:
        return context.t('thirty_minutes');
      case 0:
        return context.t('never');
      default:
        return context.t('five_minutes');
    }
  }

  Future<void> _savePin(String pin) async {
    if (kIsWeb) {
      await ref.read(settingsProvider.notifier).update('appLockPin', pin);
    } else {
      await _secureStorage.write(key: _pinKey, value: pin);
    }
    await ref.read(settingsProvider.notifier).update('appLockPinSet', true);
  }

  Future<void> _removePin() async {
    if (kIsWeb) {
      await ref.read(settingsProvider.notifier).update('appLockPin', null);
    } else {
      await _secureStorage.delete(key: _pinKey);
    }
    await ref.read(settingsProvider.notifier).update('appLockPinSet', false);
  }

  Future<bool> _hasPin() async {
    if (kIsWeb) {
      final v = ref.read(settingsProvider)['appLockPin'];
      return v != null && (v as String).isNotEmpty;
    }
    final v = await _secureStorage.read(key: _pinKey);
    return v != null && v.isNotEmpty;
  }

  String _timeToString(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay? _timeFromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeString(String value, BuildContext context) {
    final t = _timeFromString(value);
    if (t == null) return value;
    return t.format(context);
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('link_open_failed'))),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=CashTrack%20Support',
    );
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('link_open_failed'))),
      );
    }
  }

  Future<void> _importFromCsv(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      if (!context.mounted) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) return;

      final csvString = utf8.decode(bytes);
      final rows = const CsvToListConverter(shouldParseNumbers: false)
          .convert(csvString);
      if (rows.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('import_empty'))),
        );
        return;
      }

      await _ensureImportDependenciesLoaded();
      final categories = ref.read(categoriesProvider);
      final accounts = ref.read(accountsProvider);
      final categoryMap = {
        for (final c in categories) c.name.toLowerCase(): c.id,
      };
      final accountMap = {
        for (final a in accounts) a.name.toLowerCase(): a.id,
      };

      final headerRow =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final hasHeader = headerRow.contains('date') ||
          headerRow.contains('type') ||
          headerRow.contains('amount');
      final startIndex = hasHeader ? 1 : 0;

      int imported = 0;
      if (!context.mounted) return;
      final AppL10n l10n = AppL10n.of(context);
      for (var i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final typeStr = _cell(row, headerRow, 'type', 1);
        final amountStr = _cell(row, headerRow, 'amount', 3);
        final dateStr = _cell(row, headerRow, 'date', 0);
        if (typeStr.isEmpty || amountStr.isEmpty || dateStr.isEmpty) continue;

        final type = _parseType(typeStr, l10n);
        final amount = _parseAmount(amountStr);
        final date = _parseDate(dateStr);
        if (type == null || amount == null || date == null) continue;

        final categoryName = _cell(row, headerRow, 'category', 2);
        final accountName = _cell(row, headerRow, 'account', 4);
        final note = _cell(row, headerRow, 'note', 5);

        final categoryId = categoryMap[categoryName.toLowerCase()] ??
            AppConstants.defaultCategoryId;
        final accountId = accountMap[accountName.toLowerCase()] ??
            AppConstants.defaultAccountId;

        final tx = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          type: type,
          amount: amount,
          categoryId: categoryId,
          accountId: accountId,
          date: date,
          note: note.isEmpty ? null : note,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref.read(transactionsProvider.notifier).addTransaction(tx);
        await _applyAccountAndBudget(tx);
        imported++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.t('import_complete',
                  params: {'count': imported.toString()}))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.t('error_with_detail', params: {
            'error': e.toString(),
          }))),
        );
      }
    }
  }

  Future<void> _applyAccountAndBudget(TransactionModel tx) async {
    final accountNotifier = ref.read(accountsProvider.notifier);
    final budgetNotifier = ref.read(budgetsProvider.notifier);
    final delta = tx.type == TransactionType.income ? tx.amount : -tx.amount;
    final account = accountNotifier.getAccountById(tx.accountId);
    if (account != null) {
      await accountNotifier.updateBalance(
        tx.accountId,
        account.balance + delta,
      );
    }

    if (tx.type == TransactionType.expense) {
      final budget = budgetNotifier.getBudgetByCategory(tx.categoryId, tx.date);
      if (budget != null) {
        await budgetNotifier.updateSpent(
          budget.id,
          (budget.spent + tx.amount).clamp(0.0, double.infinity),
        );
      }
    }
  }

  String _cell(
    List<dynamic> row,
    List<String> header,
    String key,
    int fallbackIndex,
  ) {
    final idx = header.indexOf(key);
    if (idx >= 0 && idx < row.length) {
      return row[idx].toString().trim();
    }
    if (fallbackIndex < row.length) {
      return row[fallbackIndex].toString().trim();
    }
    return '';
  }

  TransactionType? _parseType(String raw, AppL10n l10n) {
    final s = raw.trim().toLowerCase();
    if (s == 'income' || s == l10n.t('income').toLowerCase()) {
      return TransactionType.income;
    }
    if (s == 'expense' || s == l10n.t('expense').toLowerCase()) {
      return TransactionType.expense;
    }
    return null;
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\\.-]'), '');
    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    final formats = [
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd'),
    ];
    for (final f in formats) {
      try {
        return f.parseStrict(trimmed);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _ensureImportDependenciesLoaded() async {
    await CategoryRepository().init();
    await AccountRepository().init();
    ref.read(categoriesProvider.notifier).loadCategories();
    ref.read(accountsProvider.notifier).loadAccounts();
  }

  String _smsModeLabel(String mode) {
    switch (mode) {
      case 'silent':
        return context.t('auto_silent');
      case 'daily_summary':
        return context.t('auto_daily_summary');
      default:
        return context.t('ask_before_adding');
    }
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

  String _normalizeCurrency(String? rawCurrency) {
    if (rawCurrency == null || rawCurrency.isEmpty || rawCurrency == '?') {
      return '\u09F3';
    }
    if (rawCurrency == 'à§³') {
      return '\u09F3';
    }
    return rawCurrency;
  }
}
