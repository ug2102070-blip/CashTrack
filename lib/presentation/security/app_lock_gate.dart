import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/sms_service.dart';
import '../providers/app_providers.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _pinKey = 'app_lock_pin';

  bool _locked = false;
  bool _checking = false;
  String? _error;
  DateTime? _lastInactiveAt;
  String? _pin;
  String _enteredPin = '';

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _loadPin();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final settings = ref.read(settingsProvider);
        _syncLockState(settings);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastInactiveAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (!_locked) {
        SmsService().checkActiveNotifications();
      }

      final settings = ref.read(settingsProvider);
      final autoLockMinutes = settings['autoLockMinutes'] ?? 5;
      if (autoLockMinutes == 0) return;
      if (_lockRequired(settings) &&
          _lastInactiveAt != null &&
          DateTime.now().difference(_lastInactiveAt!).inSeconds >=
              autoLockMinutes * 60) {
        setState(() {
          _locked = true;
          _enteredPin = '';
          _error = null;
        });
        _attemptAutoBiometric();
      }
    }
  }

  Future<void> _loadPin() async {
    if (kIsWeb) {
      _pin = ref.read(settingsProvider)['appLockPin'] as String?;
    } else {
      _pin = await _secureStorage.read(key: _pinKey);
    }
    if (mounted) setState(() {});
  }

  void _syncLockState(Map<String, dynamic> settings) {
    _loadPin();
    if (!_lockRequired(settings)) {
      if (_locked) setState(() => _locked = false);
      return;
    }
    if (!_locked) {
      setState(() {
        _locked = true;
        _enteredPin = '';
        _error = null;
      });
      _attemptAutoBiometric();
    }
  }

  bool _lockRequired(Map<String, dynamic> settings) {
    final biometricLock = settings['biometricLock'] == true;
    final pinSet = settings['appLockPinSet'] == true;
    return biometricLock || pinSet;
  }

  void _attemptAutoBiometric() {
    final settings = ref.read(settingsProvider);
    if (!kIsWeb && settings['biometricLock'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _locked && !_checking) {
          _unlockWithBiometric(context);
        }
      });
    }
  }

  Future<void> _unlockWithBiometric(BuildContext context) async {
    if (_checking || kIsWeb) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: context.t('biometric_unlock_reason'),
      );
      if (ok) {
        HapticFeedback.mediumImpact();
        if (mounted) {
          setState(() {
            _locked = false;
            _enteredPin = '';
            _error = null;
          });
        }
      } else {
        HapticFeedback.heavyImpact();
        if (mounted) setState(() => _error = context.t('biometric_failed'));
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = context.t('biometric_failed'));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onDigitPressed(String digit, BuildContext context) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.selectionClick();

    setState(() {
      _enteredPin += digit;
      _error = null;
    });

    if (_enteredPin.length == 4) {
      _validatePin(context);
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _error = null;
    });
  }

  void _validatePin(BuildContext context) {
    if (_pin == null || _pin!.isEmpty) {
      setState(() => _error = context.t('pin_invalid'));
      _shakeAndReset();
      return;
    }

    if (_enteredPin == _pin) {
      HapticFeedback.mediumImpact();
      setState(() {
        _locked = false;
        _enteredPin = '';
        _error = null;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = context.t('pin_incorrect');
      });
      _shakeAndReset();
    }
  }

  void _shakeAndReset() {
    _shakeController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _enteredPin = '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    ref.listen<Map<String, dynamic>>(settingsProvider, (prev, next) {
      final wasRequired = prev != null && _lockRequired(prev);
      final isRequired = _lockRequired(next);
      _loadPin();
      if (!isRequired) {
        if (_locked) setState(() => _locked = false);
      } else if (!wasRequired && isRequired) {
        setState(() {
          _locked = true;
          _enteredPin = '';
          _error = null;
        });
        _attemptAutoBiometric();
      }
    });

    final bool isLockedScreen = _lockRequired(settings) && _locked;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: isLockedScreen
          ? _buildLockScreen(context, settings)
          : widget.child,
    );
  }

  Widget _buildLockScreen(BuildContext context, Map<String, dynamic> settings) {
    final biometricLock = settings['biometricLock'] == true;
    final pinSet = settings['appLockPinSet'] == true;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      key: const ValueKey('lock_screen'),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0D1117),
                    const Color(0xFF161B22),
                    Color.lerp(primary, const Color(0xFF0D1117), 0.85)!,
                  ]
                : [
                    const Color(0xFFF6F8FA),
                    Colors.white,
                    Color.lerp(primary, Colors.white, 0.94)!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield_rounded,
                        color: primary,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Lock Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 13, color: primary),
                        const SizedBox(width: 5),
                        Text(
                          context.t('app_locked'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // PIN Dots
                  if (pinSet) ...[
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final offset = sin(_shakeAnimation.value * pi * 4) * 8;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: _buildPinDots(primary),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error Message
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 15, color: theme.colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Numeric Keypad
                  if (pinSet)
                    _buildNumpad(context, primary, biometricLock, isDark),

                  // Biometric-only fallback button
                  if (!pinSet && biometricLock) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 240,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _checking
                            ? null
                            : () => _unlockWithBiometric(context),
                        icon: const Icon(Icons.fingerprint_rounded, size: 22),
                        label: Text(
                          context.t('unlock_with_biometrics'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: primary.withValues(alpha: 0.3),
                        ),
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

  Widget _buildPinDots(Color primary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? primary : primary.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad(
    BuildContext context,
    Color primary,
    bool showBiometric,
    bool isDark,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNumpadRow(['1', '2', '3'], context, isDark),
          const SizedBox(height: 12),
          _buildNumpadRow(['4', '5', '6'], context, isDark),
          const SizedBox(height: 12),
          _buildNumpadRow(['7', '8', '9'], context, isDark),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bottom Left: Biometric or blank
              if (showBiometric && !kIsWeb)
                _buildActionKey(
                  icon: Icons.fingerprint_rounded,
                  color: primary,
                  onTap: () => _unlockWithBiometric(context),
                  isDark: isDark,
                )
              else
                const SizedBox(width: 64, height: 64),

              // Zero
              _buildDigitKey('0', context, isDark),

              // Bottom Right: Backspace
              _buildActionKey(
                icon: Icons.backspace_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
                onTap: _onDeletePressed,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> digits, BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitKey(d, context, isDark)).toList(),
    );
  }

  Widget _buildDigitKey(String digit, BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _onDigitPressed(digit, context),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}
