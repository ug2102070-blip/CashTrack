import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/app_providers.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _pinKey = 'app_lock_pin';

  bool _locked = false;
  bool _checking = false;
  String? _error;
  DateTime? _lastInactiveAt;
  String? _pin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPin();
    // ref.listen cannot be called in initState; it is called in build() below.
    // We read the initial settings once synchronously here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLockState(ref.read(settingsProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final settings = ref.read(settingsProvider);
      final autoLockMinutes = settings['autoLockMinutes'] ?? 5;
      if (autoLockMinutes == 0) return;
      if (_lockRequired(settings) &&
          _lastInactiveAt != null &&
          DateTime.now().difference(_lastInactiveAt!).inMinutes >=
              autoLockMinutes) {
        setState(() => _locked = true);
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
      setState(() => _locked = true);
    }
  }

  bool _lockRequired(Map<String, dynamic> settings) {
    final biometricLock = settings['biometricLock'] == true;
    final pinSet = settings['appLockPinSet'] == true;
    return biometricLock || pinSet;
  }

  Future<void> _unlockWithBiometric(BuildContext context) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: context.t('biometric_unlock_reason'),
      );
      if (ok) {
        if (mounted) setState(() => _locked = false);
      } else {
        if (mounted) setState(() => _error = context.t('biometric_failed'));
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.t('biometric_failed'));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _unlockWithPin(BuildContext context, String entered) {
    if (_pin == null || _pin!.isEmpty) {
      setState(() => _error = context.t('pin_invalid'));
      return;
    }
    if (entered == _pin) {
      setState(() {
        _locked = false;
        _error = null;
      });
    } else {
      setState(() => _error = context.t('pin_incorrect'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // ref.listen must be called inside build, not initState.
    ref.listen<Map<String, dynamic>>(settingsProvider, (prev, next) {
      _syncLockState(next);
    });

    final biometricLock = settings['biometricLock'] == true;
    final pinSet = settings['appLockPinSet'] == true;
    if (!_lockRequired(settings) || !_locked) {
      return widget.child;
    }

    final pinController = TextEditingController();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1419),
                    const Color(0xFF1A2332),
                    Color.lerp(primary, const Color(0xFF0F1419), 0.8)!,
                  ]
                : [
                    const Color(0xFFF8FAFE),
                    Colors.white,
                    Color.lerp(primary, Colors.white, 0.92)!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App name
                  Text(
                    'CashTrack',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lock status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 14, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          context.t('app_locked'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Biometric button
                  if (biometricLock)
                    SizedBox(
                      width: 240,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _checking
                            ? null
                            : () => _unlockWithBiometric(context),
                        icon: const Icon(Icons.fingerprint_rounded, size: 22),
                        label: Text(
                          context.t('unlock_with_biometrics'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                  // PIN input
                  if (pinSet) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: context.t('enter_pin'),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                        onSubmitted: (v) => _unlockWithPin(context, v.trim()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 240,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _unlockWithPin(context, pinController.text.trim()),
                        icon: const Icon(Icons.lock_open_rounded, size: 18),
                        label: Text(context.t('unlock')),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: primary),
                        ),
                      ),
                    ),
                  ],

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
