import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/telemetry_service.dart';

/// Graceful fallback widget rendered when an unhandled Flutter UI exception occurs.
/// Prevents the red/grey screen of death in production and reports crash telemetry.
class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const GlobalErrorWidget({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    // Report UI rendering exception to Crashlytics
    TelemetryService.recordFlutterError(details, fatal: false);

    final bool isDark = MediaQuery.maybeOf(context)?.platformBrightness == Brightness.dark;
    final Color backgroundColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final Color surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor = isDark ? Colors.white : AppColors.lightText;
    final Color subTextColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Something went wrong',
                    style: AppTextStyles.h2.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'An unexpected visual error occurred. Your financial data is safely stored offline and in the cloud.',
                    style: AppTextStyles.body2.copyWith(
                      color: subTextColor,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          try {
                            appRouter.go('/');
                          } catch (_) {
                            // If router is unavailable, reload window or do nothing
                          }
                        },
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text('Go to Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDefault,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final errorReport = '''
CashTrack Error Report:
Error: ${details.exception}
Context: ${details.context?.toDescription()}
Library: ${details.library}
StackTrace:
${details.stack}
''';
                          Clipboard.setData(ClipboardData(text: errorReport));
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(
                              content: Text('Error details copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: subTextColor.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bug_report_rounded, size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                'Debug Information',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details.exceptionAsString(),
                            style: AppTextStyles.caption.copyWith(
                              fontFamily: 'monospace',
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
