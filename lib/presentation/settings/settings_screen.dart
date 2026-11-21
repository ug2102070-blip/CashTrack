// lib/presentation/settings/settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
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
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_l10n.dart';
import '../../services/account_session_service.dart';
import '../../services/app_lock_pin_store.dart';
import '../../services/auth_service.dart';
import '../../services/sms_service.dart';
import '../../services/sync_service.dart';
import '../../services/backup_restore_service.dart';
import '../../services/statement_parser_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/notification_service.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animCtrl;
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Max content width so the list stays readable on tablets/desktop.
  static const double _maxContentWidth = 720;

  /// Settings box key for the last successful cloud backup (ISO-8601).
  static const String _lastCloudBackupKey = 'lastCloudBackupAt';

  /// Keys that must never be written to user-facing exports.
  static const Set<String> _nonExportableSettingKeys = {'appLockPin'};

  /// Identifies the long-running operation in progress (backup, restore,
  /// sign-out, …). Guards against double taps / concurrent runs.
  String? _busyOperation;

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

  // Pre-created animations — avoids creating new CurvedAnimation objects
  // on every build(), which leaks InheritedWidget dependents.
  static const List<int> _animDelays = [
    0,
    50,
    110,
    130,
    160,
    180,
    195,
    205,
    210,
    230,
    235,
    240,
    245,
    255,
    260,
    280,
    310,
  ];
  late final List<Animation<double>> _fadeAnims;
  late final Animation<double> _rootFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inherited widgets (ScaffoldMessenger, Localizations) are not available
    // during initState, so defer the permission check to after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSmsTrackPermission();
    });
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _rootFade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fadeAnims = _animDelays.map((ms) {
      final s = (ms / 650).clamp(0.0, 1.0);
      final e = ((ms + 280) / 650).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _anim({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnims[index],
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
    final smsMode = settings['smsMode'] ?? 'daily_summary';
    final hideAmounts = settings['hideAmounts'] ?? false;
    final screenIsDark = Theme.of(context).brightness == Brightness.dark;
    final language = settings['language'] ?? 'en';
    // Additional settings
    final notifEnabled = settings['notifications'] ?? true;
    final weeklyReport = settings['weeklyReport'] ?? false;
    final biometricLock = settings['biometricLock'] ?? false;

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
          opacity: _rootFade,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 0,
                        child: _buildPageHeader(context, screenIsDark)),
                  ),

                  // â”€â”€ Profile Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 1,
                        child: _buildProfileCard(context, profile, isDark)),
                  ),

                  // â”€â”€ Appearance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 2,
                        child: _sectionLabel(context, context.t('appearance'))),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                      index: 3,
                      child: _buildAppearanceSection(context, settings, isDark,
                          currency, hideAmounts, screenIsDark),
                    ),
                  ),

                  // â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 4,
                        child: _sectionLabel(context, context.t('general'))),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                      index: 5,
                      child: _buildGeneralSection(
                          context, smsTrack, smsMode, language, screenIsDark),
                    ),
                  ),

                  // â”€â”€ General â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 6,
                        child:
                            _sectionLabel(context, context.t('notifications'))),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                      index: 7,
                      child: _buildNotificationsSection(context, notifEnabled,
                          weeklyReport, dailyReminderTime, screenIsDark),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _anim(
                      index: 8,
                      child: _sectionLabel(
                          context, context.t('transaction_entry')),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                      index: 9,
                      child: _buildTransactionEntrySection(
                        context,
                        voiceTransactionInput,
                        receiptImageAttachment,
                        settings['defaultRecurring'] ?? false,
                        settings['defaultRecurringType'] ?? 'monthly',
                        screenIsDark,
                      ),
                    ),
                  ),

                  // â”€â”€ Security â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 10,
                        child: _sectionLabel(
                            context, context.t('security_privacy'))),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                      index: 11,
                      child: _buildSecuritySection(
                          context,
                          biometricLock,
                          screenshotProtection,
                          autoLockMinutes,
                          pinSet,
                          screenIsDark),
                    ),
                  ),

                  // â”€â”€ Data & Sync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 12,
                        child: _sectionLabel(context, context.t('data_sync'))),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 13,
                        child: _buildDataSection(
                          context,
                          screenIsDark,
                          settings[_lastCloudBackupKey] as String?,
                        )),
                  ),

                  // â”€â”€ About â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 14,
                        child: _sectionLabel(context, context.t('about'))),
                  ),
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 15,
                        child: _buildAboutSection(context, screenIsDark)),
                  ),

                  // â”€â”€ Danger Zone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: _anim(
                        index: 16,
                        child: _buildDangerZone(context, screenIsDark)),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
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
                  style: AppTextStyles.headingLg.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.t('customize_experience'),
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(displayEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            if (kIsWeb) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(context.t('feature_not_supported_web'))),
                );
              }
              return;
            }
            if (v) {
              final granted = await Permission.notification.request().isGranted;
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.t('settings_push_permission_required'),
                      ),
                    ),
                  );
                }
                return;
              }
            }
            await ref
                .read(settingsProvider.notifier)
                .update('notifications', v);
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
        iconColor: notifEnabled
            ? AppColors.info
            : AppColors.info.withValues(alpha: 0.4),
        title: context.t('weekly_report'),
        subtitle: _weeklyReportSubtitle(context, weeklyReport),
        trailing: Switch.adaptive(
          value: weeklyReport,
          onChanged: notifEnabled
              ? (v) async {
                  // Don't persist a setting the platform cannot honour.
                  if (kIsWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(context.t('feature_not_supported_web'))),
                    );
                    return;
                  }
                  await ref
                      .read(settingsProvider.notifier)
                      .update('weeklyReport', v);
                  await NotificationService().updateWeeklyReport(v);
                  if (v && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(context.t('settings_weekly_report_enabled')),
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
              : context.t('settings_turn_on_push_first'),
          onTap: notifEnabled
              ? () => _showTimePickerDialog(context, dailyReminderTime)
              : null,
        ),
      ),
    ]);
  }

  // â”€â”€ Planning & Tools Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€ General Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildGeneralSection(BuildContext context, bool smsTrack,
      String smsMode, String language, bool isDark) {
    final languageLabel =
        language == 'bn' ? context.t('bangla') : context.t('english');
    return _settingsGroup(context, isDark, [
      if (!kIsWeb) ...[
        _settingsTile(
          context,
          icon: Icons.notifications_active_rounded,
          iconColor: AppColors.success,
          title: context.t('sms_auto_import'),
          subtitle: context.t('import_sms'),
          trailing: Switch.adaptive(
            value: smsTrack,
            onChanged: (v) async {
              if (v) {
                // Persist true first to handle process kills on permission grant
                await ref.read(settingsProvider.notifier).updateSmsTrack(true);

                final granted = await SmsService.requestPermission();
                if (!granted) {
                  // Revert to false if not granted/cancelled
                  await ref
                      .read(settingsProvider.notifier)
                      .updateSmsTrack(false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(context.t('sms_permission_denied'))),
                    );
                  }
                  return;
                }

                // Check and request standard notification permission on Android 13+
                final notifGranted =
                    await Permission.notification.request().isGranted;
                if (!notifGranted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.t('settings_sms_notif_permission_required'),
                      ),
                    ),
                  );
                }

                // Request ignore battery optimizations exemption
                final batteryIgnored = await Permission
                    .ignoreBatteryOptimizations
                    .request()
                    .isGranted;
                if (!batteryIgnored && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.t('settings_battery_optimization_warning'),
                      ),
                    ),
                  );
                }

                // If still running (or returning granted), start listening
                await SmsService().init();
                if (context.mounted) {
                  _showBackgroundRunningTipsDialog(context);
                }
              } else {
                SmsService().stopListening();
                await ref.read(settingsProvider.notifier).updateSmsTrack(false);
              }
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
        _divider(context),
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
    bool defaultRecurring,
    String defaultRecurringType,
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
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.repeat_rounded,
        iconColor: AppColors.info,
        title: context.t('default_recurring_payment'),
        subtitle: defaultRecurring ? context.t('on') : context.t('off'),
        trailing: Switch.adaptive(
          value: defaultRecurring,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).updateDefaultRecurring(v),
          thumbColor: _switchThumbColor(context),
          trackColor: _switchTrackColor(context),
        ),
      ),
      if (defaultRecurring) ...[
        _divider(context),
        _settingsTile(
          context,
          icon: Icons.schedule_rounded,
          iconColor: AppColors.warning,
          title: context.t('default_recurring_frequency'),
          subtitle: _recurrenceLabelString(context, defaultRecurringType),
          onTap: () =>
              _showDefaultRecurringTypeDialog(context, defaultRecurringType),
        ),
      ],
    ]);
  }

  // â”€â”€ Security Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSecuritySection(
    BuildContext context,
    bool biometricLock,
    bool screenshotProtection,
    int autoLockMinutes,
    bool pinSet,
    bool isDark,
  ) {
    final passwordEmail = _passwordAccountEmail();
    return _settingsGroup(context, isDark, [
      // Only email/password accounts have a password to change; Google and
      // guest/local sessions are intentionally excluded.
      if (passwordEmail != null) ...[
        _settingsTile(
          context,
          icon: Icons.password_rounded,
          iconColor: AppColors.secondary,
          title: context.t('settings_change_password'),
          subtitle: context.t('settings_change_password_sub'),
          trailing:
              _busyOperation == 'reset_password' ? _busyIndicator() : null,
          onTap: () => _confirmPasswordReset(context, passwordEmail),
        ),
        _divider(context),
      ],
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

  Widget _buildDataSection(
    BuildContext context,
    bool isDark,
    String? lastCloudBackupIso,
  ) {
    final lastBackup = lastCloudBackupIso == null
        ? null
        : DateTime.tryParse(lastCloudBackupIso);
    final lastBackupLabel = lastBackup == null
        ? context.t('last_backup_never')
        : context.t('settings_last_cloud_backup', params: {
            'time': DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .add_jm()
                .format(lastBackup.toLocal()),
          });
    return _settingsGroup(context, isDark, [
      _settingsTile(
        context,
        icon: Icons.cloud_upload_rounded,
        iconColor: AppColors.info,
        title: context.t('backup_cloud'),
        subtitle: _busyOperation == 'cloud_backup'
            ? context.t('settings_backing_up')
            : lastBackupLabel,
        trailing: _busyOperation == 'cloud_backup' ? _busyIndicator() : null,
        onTap: () => _backupToCloud(context),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.save_alt_rounded,
        iconColor: AppColors.accent,
        title: context.t('backup_local'),
        subtitle: context.t('backup_local_sub'),
        trailing: _busyOperation == 'local_backup' ? _busyIndicator() : null,
        onTap: () => _handleLocalBackup(context),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.cloud_download_rounded,
        iconColor: AppColors.success,
        title: context.t('restore_cloud'),
        subtitle: _busyOperation == 'cloud_restore'
            ? context.t('settings_restoring')
            : context.t('restore_data'),
        trailing: _busyOperation == 'cloud_restore' ? _busyIndicator() : null,
        onTap: () => _confirmRestore(context),
      ),
      _divider(context),
      _settingsTile(
        context,
        icon: Icons.restore_page_rounded,
        iconColor: const Color(0xFF10B981),
        title: context.t('restore_local'),
        subtitle: _busyOperation == 'local_restore'
            ? context.t('settings_restoring')
            : context.t('restore_local_sub'),
        trailing: _busyOperation == 'local_restore' ? _busyIndicator() : null,
        onTap: () => _confirmLocalRestore(context),
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
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 26),
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
                    context.t('settings_app_tagline'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
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
          body: context.t('settings_privacy_body'),
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
          body: context.t('settings_terms_body'),
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
              trailing: _busyOperation == 'sign_out' ? _busyIndicator() : null,
              onTap: () => _confirmLogout(context),
              showChevron: false,
            ),
          ),
          // Local-only sessions have no server account; signing out already
          // erases their data.
          if (AccountSessionService().currentKind != AccountKind.localOnly) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.10 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: _settingsTile(
                context,
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.error,
                title: context.t('settings_delete_account'),
                subtitle: context.t('settings_delete_account_sub'),
                titleColor: AppColors.error,
                trailing: _busyOperation == 'delete_account'
                    ? _busyIndicator()
                    : null,
                onTap: () => _confirmDeleteAccount(context),
                showChevron: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Account deletion: warning (+ export offer) → re-authentication for
  /// registered users → server deletion → local erase + sign-out.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final session = AccountSessionService();
    final kind = session.currentKind;

    final proceed = await _showSignOutDialog(
      context,
      title: context.t('settings_delete_account_q'),
      body: context.t('settings_delete_account_body'),
      confirmLabel: context.t('settings_delete_permanently'),
      offerExport: true,
    );
    if (!proceed || !context.mounted) return;

    if (kind == AccountKind.registered) {
      final reauthed = await _reauthenticate(context);
      if (!reauthed || !context.mounted) return;
    }

    await _runExclusive(context, 'delete_account', () async {
      final result = await session.deleteAccount();
      if (!context.mounted) return;
      switch (result) {
        case DeleteAccountResult.deleted:
          // Router redirects to login once auth state clears; this snackbar
          // shows on the root messenger if the screen is still mounted.
          _showSnack(context, context.t('settings_account_deleted'),
              background: AppColors.success);
        case DeleteAccountResult.requiresRecentLogin:
          _showSnack(context, context.t('settings_reauth_expired'),
              background: AppColors.error);
        case DeleteAccountResult.failed:
          _showSnack(context, context.t('settings_delete_account_failed'),
              background: AppColors.error);
      }
    });
  }

  /// Confirms identity right before a destructive action. Returns true on
  /// success; shows an error and returns false otherwise.
  Future<bool> _reauthenticate(BuildContext context) async {
    final auth = AuthService();
    try {
      if (auth.hasPasswordProvider) {
        final password = await showDialog<String>(
          context: context,
          builder: (_) => const _PasswordPromptDialog(),
        );
        if (password == null || password.isEmpty) return false;
        await auth.reauthenticateWithPassword(password);
        return true;
      }
      return await auth.reauthenticateWithGoogle();
    } on FirebaseAuthException catch (e) {
      debugPrint('Re-authentication failed: ${e.code}');
      if (!context.mounted) return false;
      final key = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'settings_reauth_wrong',
        'user-mismatch' => 'settings_reauth_mismatch',
        'too-many-requests' => 'settings_reauth_too_many',
        _ => 'settings_reauth_failed',
      };
      _showSnack(context, context.t(key), background: AppColors.error);
      return false;
    } catch (e) {
      debugPrint('Re-authentication failed: $e');
      if (!context.mounted) return false;
      _showSnack(context, context.t('settings_reauth_failed'),
          background: AppColors.error);
      return false;
    }
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _settingsGroup(
      BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.7)),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
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
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor ??
                          (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
            trailing ??
                (showChevron && onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _busyIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2),
    );
  }

  /// Runs [action] as the single in-flight long operation. A second tap while
  /// anything is running is rejected with a message instead of starting a
  /// concurrent backup/restore/sign-out.
  Future<void> _runExclusive(
    BuildContext context,
    String operation,
    Future<void> Function() action,
  ) async {
    if (_busyOperation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('settings_operation_in_progress'))),
      );
      return;
    }
    setState(() => _busyOperation = operation);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busyOperation = null);
    }
  }

  void _showSnack(BuildContext context, String message, {Color? background}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  /// Email of the signed-in user if they use email/password auth, else null.
  String? _passwordAccountEmail() {
    final user = AuthService().currentUser;
    if (user == null || user.isAnonymous) return null;
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return null;
    final hasPasswordProvider =
        user.providerData.any((p) => p.providerId == 'password');
    return hasPasswordProvider ? email : null;
  }

  Future<void> _confirmPasswordReset(BuildContext context, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('settings_change_password')),
        content: Text(context
            .t('settings_change_password_confirm', params: {'email': email})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('settings_send_link')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _runExclusive(context, 'reset_password', () async {
      try {
        await AuthService().resetPassword(email);
        if (!context.mounted) return;
        _showSnack(
          context,
          context.t('settings_reset_link_sent', params: {'email': email}),
          background: AppColors.success,
        );
      } catch (e) {
        debugPrint('Password reset email failed: $e');
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_reset_link_failed'),
            background: AppColors.error);
      }
    });
  }

  Future<void> _backupToCloud(BuildContext context) async {
    await _runExclusive(context, 'cloud_backup', () async {
      final result = await SyncService().backupToCloud();
      if (result == SyncService.syncCompleteMessage) {
        await ref.read(settingsProvider.notifier).update(
            _lastCloudBackupKey, DateTime.now().toUtc().toIso8601String());
        if (!context.mounted) return;
        _showSnack(context, context.t('backup_complete'),
            background: AppColors.success);
      } else if (result == SyncService.syncSkippedSignInMessage) {
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_sign_in_required_cloud'));
      } else {
        debugPrint('Cloud backup failed: $result');
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_backup_failed'),
            background: AppColors.error);
      }
    });
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 67),
      child: Divider(
        height: 1,
        color: isDark
            ? AppColors.darkBorder.withValues(alpha: 0.4)
            : AppColors.lightBorder.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
          color:
              isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
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

  String _recurrenceLabelString(BuildContext context, String typeStr) {
    switch (typeStr) {
      case 'daily':
        return context.t('daily');
      case 'weekly':
        return context.t('weekly');
      case 'monthly':
        return context.t('monthly');
      case 'yearly':
        return context.t('yearly');
      default:
        return context.t('once');
    }
  }

  void _showDefaultRecurringTypeDialog(BuildContext context, String current) {
    final types = [
      ('daily', context.t('daily')),
      ('weekly', context.t('weekly')),
      ('monthly', context.t('monthly')),
      ('yearly', context.t('yearly')),
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
              Text(context.t('default_recurring_frequency'),
                  style: AppTextStyles.h5),
              const SizedBox(height: 12),
              ...types.map((t) {
                final isSelected = current == t.$1;
                final primary = theme.colorScheme.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(t.$2,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? primary : null)),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: primary)
                        : null,
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .updateDefaultRecurringType(t.$1);
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
    if (kIsWeb) {
      // Local scheduled notifications are not available on web; don't
      // persist a reminder that can never fire.
      _showSnack(context, context.t('feature_not_supported_web'));
      return;
    }
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
    await NotificationService().scheduleDailyReminder(time);
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
    // The secure store is the source of truth; the `appLockPinSet` flag can
    // drift (e.g. legacy web builds), so don't rely on [pinSet] alone.
    final hasPin = await AppLockPinStore.instance.hasPin();
    if (!context.mounted) return;

    final result = await showDialog<_PinDialogResult>(
      context: context,
      builder: (_) => _PinSetupDialog(hasExistingPin: hasPin),
    );
    if (result == null || !context.mounted) return;

    try {
      if (result.remove) {
        await _removePin();
        if (!context.mounted) return;
        _showSnack(context, context.t('pin_removed'));
      } else if (result.newPin != null) {
        await _savePin(result.newPin!);
        if (!context.mounted) return;
        _showSnack(context, context.t('pin_saved'),
            background: AppColors.success);
      }
    } catch (e) {
      debugPrint('PIN update failed: $e');
      if (!context.mounted) return;
      _showSnack(context, context.t('settings_pin_save_failed'),
          background: AppColors.error);
    }
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
      'settings': {
        for (final entry in settings.entries)
          if (!_nonExportableSettingKeys.contains(entry.key))
            entry.key: entry.value,
      },
      'profile': profile,
    });
  }

  String _buildExportCsv() {
    final categories = {
      '': 'Uncategorized',
      for (final category in ref.read(categoriesProvider))
        category.id: category.name,
    };
    final accounts = {
      '': 'No Account',
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
          (transaction.amount / 100).toStringAsFixed(2),
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
      '': 'Uncategorized',
      for (final category in ref.read(categoriesProvider))
        category.id: category.name,
    };
    final accounts = {
      '': 'No Account',
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

    int income = 0;
    int expense = 0;
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
        '$sign$currency${(transaction.amount / 100).toStringAsFixed(2)}',
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
          pw.Text(
              'Exported: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.Text('Income: $currency${(income / 100).toStringAsFixed(2)}'),
          pw.Text('Expense: $currency${(expense / 100).toStringAsFixed(2)}'),
          pw.Text(
              'Net: $currency${((income - expense) / 100).toStringAsFixed(2)}'),
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

  Future<void> _handleLocalBackup(BuildContext context) async {
    await _runExclusive(context, 'local_backup', () async {
      try {
        await BackupRestoreService().exportBackupFile();
        if (!context.mounted) return;
        _showSnack(context, context.t('backup_complete'),
            background: AppColors.success);
      } catch (e) {
        // The service already logs + records telemetry; keep raw errors
        // (paths, exception text) out of the UI.
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_backup_failed'),
            background: AppColors.error);
      }
    });
  }

  void _confirmLocalRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('restore_local')),
        content: Text(
          context.t('settings_restore_local_body'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _restoreFromLocalFile(context);
            },
            child: Text(context.t('restore')),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromLocalFile(BuildContext context) async {
    await _runExclusive(context, 'local_restore', () async {
      final result = await BackupRestoreService().pickAndRestoreBackup();
      if (!result.success && result.message == 'No backup file selected') {
        return; // User cancelled the picker.
      }

      if (!mounted) return;
      _reloadAppDataProviders();
      if (!context.mounted) return;

      if (result.success) {
        final total = result.restoredCounts.values
            .fold<int>(0, (sum, count) => sum + count);
        _showSnack(
          context,
          context
              .t('settings_restore_local_success', params: {'count': '$total'}),
          background: AppColors.success,
        );
      } else {
        // Service messages describe file/format problems in English only;
        // show them as detail under a localized headline.
        _showSnack(
          context,
          context.t('error_with_detail', params: {'error': result.message}),
          background: AppColors.error,
        );
      }
    });
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    await _runExclusive(context, 'cloud_restore', () async {
      final result = await SyncService().restoreLatestBackupFromCloud();
      if (!mounted) return;
      if (result == SyncService.restoreCompleteMessage) {
        _reloadAppDataProviders();
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_restore_complete'),
            background: AppColors.success);
      } else if (result == SyncService.restoreSkippedSignInMessage) {
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_sign_in_required_cloud'));
      } else {
        debugPrint('Cloud restore failed: $result');
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_restore_failed'),
            background: AppColors.error);
      }
    });
  }

  /// Re-reads every data provider from Hive after a restore. The `load*`
  /// methods are synchronous.
  void _reloadAppDataProviders() {
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

  String _hideAmountsSubtitle(BuildContext context, bool enabled) {
    return context.t(enabled
        ? 'settings_hide_amounts_sub_on'
        : 'settings_hide_amounts_sub_off');
  }

  String _pushNotificationsSubtitle(BuildContext context, bool enabled) {
    return context
        .t(enabled ? 'settings_push_sub_on' : 'settings_push_sub_off');
  }

  String _weeklyReportSubtitle(BuildContext context, bool enabled) {
    // Workmanager schedules a ~7-day periodic task starting near 9 AM; it is
    // not pinned to a weekday, so the copy must not promise one.
    if (enabled) return context.t('settings_weekly_report_on');
    return context.t('settings_weekly_report_off');
  }

  String _notificationScheduleSubtitle(
      BuildContext context, String reminderLabel) {
    return context
        .t('settings_daily_reminder_label', params: {'time': reminderLabel});
  }

  String _voiceInputSubtitle(BuildContext context) {
    return context.t('settings_voice_input_sub');
  }

  String _receiptOptionSubtitle(BuildContext context) {
    return context.t('settings_receipt_option_sub');
  }

  String _screenshotProtectionSubtitle(BuildContext context) {
    return context.t('settings_screenshot_protection_sub');
  }

  String _exportSubtitle(BuildContext context) {
    return context.t('settings_export_sub');
  }

  String _termsSubtitle(BuildContext context) {
    return context.t('settings_terms_sub');
  }

  String _colorPickerSubtitle(BuildContext context) {
    return context.t('settings_accent_color_sub');
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetCtx) {
        final media = MediaQuery.of(sheetCtx);
        final maxHeight = media.size.height - media.padding.top - 16;

        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + media.padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                      context.t('export_data'),
                      style: AppTextStyles.h5
                          .copyWith(fontWeight: FontWeight.w800),
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
                      subtitle: context.t('settings_export_csv_sub'),
                      format: 'csv',
                    ),
                    const SizedBox(height: 10),
                    _exportFormatTile(
                      context: context,
                      sheetCtx: sheetCtx,
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFEF4444),
                      title: 'PDF',
                      subtitle: context.t('settings_export_pdf_sub'),
                      format: 'pdf',
                    ),
                    const SizedBox(height: 10),
                    _exportFormatTile(
                      context: context,
                      sheetCtx: sheetCtx,
                      icon: Icons.data_object_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'JSON',
                      subtitle: context.t('settings_export_json_sub'),
                      format: 'json',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  /// Sign-out erases this device's copy of the user's data so the next person
  /// can't see it (or have it synced into their account):
  ///  * registered account → back up first; if that fails, warn before erasing.
  ///  * guest / local-only → data has no recoverable copy; warn + offer export.
  Future<void> _confirmLogout(BuildContext context) async {
    final session = AccountSessionService();
    final kind = session.currentKind;

    final proceed = await _showSignOutDialog(
      context,
      title: context.t('sign_out_q'),
      body: kind == AccountKind.registered
          ? context.t('settings_sign_out_registered_body')
          : context.t('settings_sign_out_guest_body'),
      confirmLabel: kind == AccountKind.registered
          ? context.t('sign_out')
          : context.t('settings_erase_and_sign_out'),
      offerExport: kind != AccountKind.registered,
    );
    if (!proceed || !context.mounted) return;

    await _runExclusive(context, 'sign_out', () async {
      if (kind == AccountKind.registered) {
        final backup = await session.backupBeforeSignOut();
        if (backup == SignOutBackupResult.failed) {
          if (!context.mounted) return;
          final eraseAnyway = await _showSignOutDialog(
            context,
            title: context.t('settings_backup_failed_title'),
            body: context.t('settings_sign_out_backup_failed_body'),
            confirmLabel: context.t('settings_erase_and_sign_out'),
            offerExport: true,
          );
          if (!eraseAnyway) return;
        }
      }
      try {
        await session.eraseLocalDataAndSignOut();
      } catch (e) {
        debugPrint('Sign out failed: $e');
        if (!context.mounted) return;
        _showSnack(context, context.t('settings_sign_out_failed'),
            background: AppColors.error);
      }
    });
  }

  /// Returns true when the user confirms. "Export backup" opens the share
  /// sheet and then re-shows the same dialog, so the user still decides.
  Future<bool> _showSignOutDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required bool offerExport,
  }) async {
    while (true) {
      if (!context.mounted) return false;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(context.t('cancel')),
            ),
            if (offerExport)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'export'),
                child: Text(context.t('settings_export_backup_first')),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, 'confirm'),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      if (choice == 'confirm') return true;
      if (choice != 'export' || !context.mounted) return false;
      try {
        await BackupRestoreService().exportBackupFile();
      } catch (_) {
        if (!context.mounted) return false;
        _showSnack(context, context.t('settings_backup_failed'),
            background: AppColors.error);
      }
    }
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
          context.t(enable
              ? 'settings_voice_toggled_on'
              : 'settings_voice_toggled_off'),
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
          context.t(enable
              ? 'settings_receipt_toggled_on'
              : 'settings_receipt_toggled_off'),
        ),
      ),
    );
  }

  Future<void> _toggleScreenshotProtection(
      BuildContext context, bool enable) async {
    if (kIsWeb) {
      // Don't persist a protection flag the browser cannot enforce.
      _showSnack(context, context.t('feature_not_supported_web'));
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .update('screenshotProtection', enable);
    final applied =
        await ScreenshotProtectionService.instance.apply(enabled: enable);
    if (!context.mounted) return;
    if (!applied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('settings_screenshot_maybe_unsupported'),
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

  // The PIN itself goes only to [AppLockPinStore]; settings state carries
  // just the `appLockPinSet` flag so the PIN can't leak into exports/UI.
  Future<void> _savePin(String pin) async {
    await AppLockPinStore.instance.write(pin);
    await ref.read(settingsProvider.notifier).update('appLockPinSet', true);
  }

  Future<void> _removePin() async {
    await AppLockPinStore.instance.delete();
    await ref.read(settingsProvider.notifier).update('appLockPinSet', false);
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

  Future<void> _syncSmsTrackPermission() async {
    final settings = ref.read(settingsProvider);
    final smsTrack = settings['smsTrack'] ?? false;
    if (smsTrack && !kIsWeb) {
      final messenger = ScaffoldMessenger.of(context);
      final disabledMessage = context.t('settings_sms_disabled_no_permission');

      final isGranted = await SmsService.isPermissionGranted();
      if (!isGranted && mounted) {
        await ref.read(settingsProvider.notifier).updateSmsTrack(false);
        SmsService().stopListening();
        messenger.showSnackBar(
          SnackBar(content: Text(disabledMessage)),
        );
      }
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
      final parseResult =
          await StatementParserService().parseCsvContent(csvString);
      if (!parseResult.isSuccess || parseResult.items.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parseResult.errorMessage ?? context.t('import_empty'),
            ),
          ),
        );
        return;
      }

      await _ensureImportDependenciesLoaded();
      if (!context.mounted) return;
      _showStatementPreviewModal(context, parseResult);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t('error_with_detail', params: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  void _showStatementPreviewModal(
    BuildContext context,
    StatementParseResult parseResult,
  ) {
    final accounts = ref.read(accountsProvider);
    final categories = ref.read(categoriesProvider);
    final categoryMap = {
      for (final c in categories) c.name.toLowerCase(): c.id,
    };

    String selectedAccountId =
        accounts.isNotEmpty ? accounts.first.id : AppConstants.defaultAccountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final currency =
                (ref.read(settingsProvider)['currency'] as String?) ?? '৳';
            final selectedCount = parseResult.selectedCount;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.t('statement_import_preview'),
                            style: AppTextStyles.h5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            parseResult.detectedFormat,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Account selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      decoration: InputDecoration(
                        labelText: context.t('select_target_account'),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Text(
                            acc.nickname?.isNotEmpty == true
                                ? acc.nickname!
                                : acc.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedAccountId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Summary pills
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('income'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency${(parseResult.totalIncomePaisa / 100.0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('expense'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency${(parseResult.totalExpensePaisa / 100.0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.t('selected_items', params: {
                        'selected': selectedCount.toString(),
                        'total': parseResult.items.length.toString(),
                      }),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // List of parsed transactions
                    Expanded(
                      child: ListView.separated(
                        itemCount: parseResult.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = parseResult.items[idx];
                          final isIncome = item.type == TransactionType.income;
                          final dateStr =
                              DateFormat('dd MMM yyyy').format(item.date);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: item.isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                item.isSelected = val ?? false;
                              });
                            },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'} $currency${item.amountInTaka.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isIncome
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.suggestedCategory,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                if (item.isDuplicate) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      context.t('already_imported'),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: selectedCount == 0
                            ? null
                            : () async {
                                Navigator.pop(sheetCtx);
                                await _commitStatementImport(
                                  context: context,
                                  items: parseResult.items
                                      .where((i) => i.isSelected)
                                      .toList(),
                                  targetAccountId: selectedAccountId,
                                  categoryMap: categoryMap,
                                );
                              },
                        child: Text(
                          context.t('import_selected_btn', params: {
                            'count': selectedCount.toString(),
                          }),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _commitStatementImport({
    required BuildContext context,
    required List<ParsedStatementItem> items,
    required String targetAccountId,
    required Map<String, String> categoryMap,
  }) async {
    int imported = 0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final categoryId = categoryMap[item.suggestedCategory.toLowerCase()] ??
          AppConstants.defaultCategoryId;

      final tx = TransactionModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_import_$i',
        type: item.type,
        amount: item.amount,
        categoryId: categoryId,
        accountId: targetAccountId,
        date: item.date,
        note: item.description,
        smsId: item.trxId,
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
          content: Text(
            context
                .t('import_complete', params: {'count': imported.toString()}),
          ),
        ),
      );
    }
  }

  Future<void> _applyAccountAndBudget(TransactionModel tx) async {
    final accountNotifier = ref.read(accountsProvider.notifier);
    final delta = tx.type == TransactionType.income ? tx.amount : -tx.amount;
    final account = accountNotifier.getAccountById(tx.accountId);
    if (account != null) {
      await accountNotifier.updateBalance(
        tx.accountId,
        account.balance + delta,
      );
    }
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSmsTrackPermission();
    }
  }

  void _showBackgroundRunningTipsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(
            Icons.info_outline_rounded,
            size: 40,
            color: AppColors.info,
          ),
          title: Text(
            ctx.t('settings_background_tips_title'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            ctx.t('background_running_tips'),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  ctx.t('ok'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Outcome of [_PinSetupDialog]: either a validated new PIN or a removal
/// request. The current PIN has already been verified when required.
class _PinDialogResult {
  const _PinDialogResult.save(String pin)
      : newPin = pin,
        remove = false;
  const _PinDialogResult.remove()
      : newPin = null,
        remove = true;

  final String? newPin;
  final bool remove;
}

/// Set / change / remove the app-lock PIN.
///
/// When a PIN already exists the current PIN must be entered before it can be
/// changed or removed, so an unlocked device left unattended can't silently
/// disable the lock. Owns its controllers so they are disposed correctly.
class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog({required this.hasExistingPin});

  final bool hasExistingPin;

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _currentCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _verifying = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<bool> _currentPinOk() async {
    if (!widget.hasExistingPin) return true;
    final current = _currentCtrl.text.trim();
    if (!AppLockPinStore.isValidFormat(current)) {
      setState(() => _error = context.t('settings_pin_current_wrong'));
      return false;
    }
    // Shares the lock screen's persisted limiter, so this dialog can't be
    // used to brute-force the PIN on an unattended unlocked device.
    final result = await AppLockPinStore.instance.verifyWithLimit(current);
    if (!mounted) return false;
    switch (result.status) {
      case PinVerifyStatus.success:
        return true;
      case PinVerifyStatus.lockedOut:
        final seconds = (result.retryAfter ?? Duration.zero).inSeconds;
        final time =
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
        setState(
            () => _error = context.t('pin_locked_out', params: {'time': time}));
        return false;
      case PinVerifyStatus.incorrect:
      case PinVerifyStatus.noPin:
        setState(() => _error = context.t('settings_pin_current_wrong'));
        return false;
    }
  }

  Future<void> _submit() async {
    if (_verifying) return;
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (!AppLockPinStore.isValidFormat(pin) ||
        !AppLockPinStore.isValidFormat(confirm)) {
      setState(() => _error = context.t('pin_invalid'));
      return;
    }
    if (pin != confirm) {
      setState(() => _error = context.t('pin_mismatch'));
      return;
    }
    setState(() => _verifying = true);
    final ok = await _currentPinOk();
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) Navigator.pop(context, _PinDialogResult.save(pin));
  }

  Future<void> _remove() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    final ok = await _currentPinOk();
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) Navigator.pop(context, const _PinDialogResult.remove());
  }

  Widget _pinField(TextEditingController controller, String label,
      {bool autofocus = false}) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(AppLockPinStore.pinLength),
      ],
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = widget.hasExistingPin;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(hasPin ? context.t('change_pin') : context.t('set_pin')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPin) ...[
              _pinField(_currentCtrl, context.t('settings_current_pin'),
                  autofocus: true),
              const SizedBox(height: 6),
            ],
            _pinField(
              _pinCtrl,
              hasPin ? context.t('settings_new_pin') : context.t('enter_pin'),
              autofocus: !hasPin,
            ),
            const SizedBox(height: 6),
            _pinField(_confirmCtrl, context.t('confirm_pin')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (hasPin)
          TextButton(
            onPressed: _verifying ? null : _remove,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.t('remove_pin')),
          ),
        TextButton(
          onPressed: _verifying ? null : () => Navigator.pop(context),
          child: Text(context.t('cancel')),
        ),
        ElevatedButton(
          onPressed: _verifying ? null : _submit,
          child: Text(context.t('save')),
        ),
      ],
    );
  }
}

/// Asks an email/password user for their password before a destructive
/// action. Returns the entered password, or null when cancelled.
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.t('settings_confirm_identity')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('settings_enter_password_to_continue')),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: context.t('settings_password'),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.t('settings_continue')),
        ),
      ],
    );
  }
}
