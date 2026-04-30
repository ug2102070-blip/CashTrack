// lib/presentation/settings/sections/about_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_l10n.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_group.dart';

/// About: version, feedback, and legal links only (no social/developer promo tiles).
class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.isDark});

  final bool isDark;

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('link_open_failed'))),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=CashTrack%20Support',
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('link_open_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      isDark: isDark,
      children: [
        SettingsTile(
          icon: Icons.info_rounded,
          iconColor: AppColors.info,
          title: context.t('app_version'),
          subtitle: context.t('app_version_detail'),
          showChevron: false,
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.star_rounded,
          iconColor: AppColors.warning,
          title: context.t('rate_app'),
          subtitle: context.t('love_rate_us'),
          onTap: () => _launchExternalUrl(context, AppConstants.appWebsiteUrl),
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.bug_report_rounded,
          iconColor: AppColors.error,
          title: context.t('report_bug'),
          subtitle: context.t('help_improve'),
          onTap: () => _launchEmail(context, AppConstants.supportEmail),
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.privacy_tip_rounded,
          iconColor: AppColors.secondary,
          title: context.t('privacy_policy'),
          subtitle: context.t('data_handling'),
          onTap: () =>
              _launchExternalUrl(context, AppConstants.privacyPolicyUrl),
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.description_rounded,
          iconColor: AppColors.primary,
          title: context.t('terms_service'),
          subtitle: '',
          onTap: () =>
              _launchExternalUrl(context, AppConstants.termsOfServiceUrl),
        ),
      ],
    );
  }
}
