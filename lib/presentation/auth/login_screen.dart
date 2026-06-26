// lib/presentation/auth/login_screen.dart
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/l10n/app_l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _bgAnimCtrl, _contentAnimCtrl;
  late Animation<double> _logoScale, _titleFade, _featuresFade, _buttonsFade;
  late Animation<Offset> _titleSlide, _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _contentAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));

    _logoScale = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _contentAnimCtrl,
        curve: const Interval(0, 0.35, curve: Curves.elasticOut)));
    _titleFade = CurvedAnimation(
        parent: _contentAnimCtrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _contentAnimCtrl,
            curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic)));
    _featuresFade = CurvedAnimation(
        parent: _contentAnimCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut));
    _buttonsFade = CurvedAnimation(
        parent: _contentAnimCtrl,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut));
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _contentAnimCtrl,
            curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic)));
    _contentAnimCtrl.forward();
  }

  @override
  void dispose() {
    _bgAnimCtrl.dispose();
    _contentAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInGuest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().signInAnonymously();
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    debugPrint('[CashTrack Auth Error] Raw: $msg');
    final friendly = _friendlyError(msg);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(friendly, style: const TextStyle(fontSize: 13))),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('email-not-verified')) {
      return context.t('email_not_verified');
    }
    if (lower.contains('billing_not_enabled') ||
        lower.contains('billing-not-enabled')) {
      return 'Phone auth requires Firebase Blaze plan. Use Email or Guest sign-in instead.';
    }
    if (lower.contains('email-already-in-use')) {
      return 'This email is already registered. Try signing in.';
    }
    if (lower.contains('account-exists-with-different-credential')) {
      return 'This email is linked to Google Sign-In. Please use "Continue with Google" instead.';
    }
    if (lower.contains('wrong-password') ||
        lower.contains('invalid-credential')) {
      return 'Incorrect email or password. If you signed in with Google before, use "Continue with Google".';
    }
    if (lower.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (lower.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (lower.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (lower.contains('network-request-failed') ||
        lower.contains('network_error')) {
      return 'No internet connection. Please check your network.';
    }
    if (lower.contains('apiexception: 7')) {
      return 'Google Sign-In failed: Check your internet connection or try another sign-in method.';
    }
    if (lower.contains('apiexception: 10')) {
      return 'Google Sign-In configuration error. Please use Email or Guest sign-in.';
    }
    if (lower.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please use Guest sign-in.';
    }
    if (lower.contains('api-key-expired') ||
        lower.contains('api-key-not-valid')) {
      return 'Firebase API key issue. Using local session instead.';
    }
    if (lower.contains('configuration-not-found')) {
      return 'Firebase is not configured yet. Using local session.';
    }
    if (lower.contains('quota') || lower.contains('billing')) {
      return 'Phone verification is not available on the free Firebase plan. Use Email or Guest sign-in.';
    }
    if (lower.contains('invalid-phone-number')) {
      return 'Please enter a valid phone number with country code (e.g. +880...).';
    }
    if (lower.contains('missing-client-identifier')) {
      return 'Phone verification requires app verification. Please try Email or Guest sign-in.';
    }
    // OAuth/Client ID errors - comprehensive handling for web
    if (lower.contains('invalid_client') || lower.contains('invalid-client')) {
      return 'Google Sign-In configuration error: Invalid OAuth client ID. '
          'On web: Update web/index.html with your Web Client ID from Firebase Console > Project Settings.';
    }
    if (lower.contains('clientid') ||
        lower.contains('client_id') ||
        lower.contains('client-id')) {
      return 'Google Sign-In is not configured correctly. '
          'Check web/index.html for the Google OAuth client ID configuration.';
    }
    if (lower.contains('popup_closed') || lower.contains('popup closed')) {
      return 'Google Sign-In popup was closed. Please try again.';
    }
    if (lower.contains('unknown_reason') || lower.contains('unknown reason')) {
      return 'Google Sign-In failed. Please try Email or Guest sign-in.';
    }
    if (lower.contains('access-blocked') || lower.contains('authorization')) {
      return 'Authorization was blocked. Please ensure Google Sign-In is properly configured.';
    }
    // Strip Firebase exception wrapper for cleaner display
    final match = RegExp(r'] (.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  // ── Email validation ──────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // ── Password strength ─────────────────────────────────────────────────
  int _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return context.t('password_strength_weak');
      case 2:
        return context.t('password_strength_fair');
      case 3:
        return context.t('password_strength_good');
      default:
        return context.t('password_strength_strong');
    }
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  // ── Email/Password Dialog ─────────────────────────────────────────────
  // Show error inside a specific scaffold context (e.g. bottom sheet)
  void _showErrorIn(BuildContext ctx, String msg) {
    debugPrint('[CashTrack Auth Error] Raw (sheet): $msg');
    final friendly = _friendlyError(msg);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(friendly, style: const TextStyle(fontSize: 13))),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showSuccessIn(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF10B981),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showEmailDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSignUp = false;
    bool loading = false;
    bool obscurePass = true;
    bool obscureConfirm = true;
    String? emailError;
    String? passError;
    String? confirmPassError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final primary = theme.colorScheme.primary;
        final strength = _passwordStrength(passCtrl.text);

        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            behavior: HitTestBehavior.opaque,
            child: GestureDetector(
              onTap: () {}, // prevent tap-through
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.15),
                              primary.withValues(alpha: 0.05)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isSignUp
                              ? Icons.person_add_rounded
                              : Icons.login_rounded,
                          color: primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        isSignUp
                            ? context.t('create_account')
                            : context.t('email_sign_in'),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSignUp
                            ? context.t('create_your_account')
                            : context.t('welcome_back'),
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) {
                          if (emailError != null) {
                            setSheetState(() => emailError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: context.t('email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: emailError,
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password Field
                      TextField(
                        controller: passCtrl,
                        obscureText: obscurePass,
                        onChanged: (v) {
                          setSheetState(() {
                            if (passError != null) passError = null;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: context.t('password'),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          errorText: passError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            onPressed: () =>
                                setSheetState(() => obscurePass = !obscurePass),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                      ),

                      // Password strength indicator (sign-up only)
                      if (isSignUp && passCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: strength / 4,
                                backgroundColor: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                    _strengthColor(strength)),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _strengthLabel(strength),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _strengthColor(strength)),
                          ),
                        ]),
                      ],

                      // Confirm Password Field (sign-up only)
                      if (isSignUp) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPassCtrl,
                          obscureText: obscureConfirm,
                          onChanged: (v) {
                            if (confirmPassError != null) {
                              setSheetState(() => confirmPassError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: context.t('confirm_password'),
                            prefixIcon: const Icon(Icons.lock_outlined),
                            errorText: confirmPassError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              onPressed: () => setSheetState(
                                  () => obscureConfirm = !obscureConfirm),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                            ),
                          ),
                        ),
                      ],

                      // Forgot Password (sign-in only)
                      if (!isSignUp) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty || !_isValidEmail(email)) {
                                _showErrorIn(ctx, context.t('invalid_email'));
                                return;
                              }
                              final successMsg = context.t('reset_link_sent');
                              AuthService().resetPassword(email).then((_) {
                                if (ctx.mounted) {
                                  _showSuccessIn(ctx, successMsg);
                                }
                              }).catchError((e) {
                                if (ctx.mounted) {
                                  _showErrorIn(ctx, '$e');
                                }
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.t('forgot_password'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  // Validation
                                  final email = emailCtrl.text.trim();
                                  final pass = passCtrl.text.trim();

                                  bool hasError = false;

                                  if (email.isEmpty) {
                                    setSheetState(() => emailError =
                                        context.t('fill_all_fields'));
                                    hasError = true;
                                  } else if (!_isValidEmail(email)) {
                                    setSheetState(() => emailError =
                                        context.t('invalid_email'));
                                    hasError = true;
                                  }

                                  if (pass.isEmpty) {
                                    setSheetState(() => passError =
                                        context.t('fill_all_fields'));
                                    hasError = true;
                                  } else if (pass.length < 6) {
                                    setSheetState(() => passError =
                                        context.t('password_too_short'));
                                    hasError = true;
                                  }

                                  if (isSignUp &&
                                      confirmPassCtrl.text.trim() != pass) {
                                    setSheetState(() => confirmPassError =
                                        context.t('passwords_dont_match'));
                                    hasError = true;
                                  }

                                  if (hasError) return;

                                  setSheetState(() => loading = true);
                                  try {
                                    if (isSignUp) {
                                      await AuthService()
                                          .signUpWithEmail(email, pass);
                                      if (ctx.mounted) {
                                        _showSuccessIn(ctx, ctx.t('email_verification_sent'));
                                        Navigator.of(ctx).pop();
                                      }
                                    } else {
                                      await AuthService()
                                          .signInWithEmail(email, pass);
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      _showErrorIn(ctx, '$e');
                                      setSheetState(() => loading = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                            shadowColor: primary.withValues(alpha: 0.3),
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        isSignUp
                                            ? Icons.person_add_rounded
                                            : Icons.login_rounded,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      isSignUp
                                          ? context.t('sign_up')
                                          : context.t('sign_in'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          isSignUp = !isSignUp;
                          emailError = null;
                          passError = null;
                          confirmPassError = null;
                        }),
                        child: Text(
                          isSignUp
                              ? context.t('already_have_account')
                              : context.t('create_new_account'),
                          style: TextStyle(
                              fontSize: 13,
                              color: primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Phone Dialog ──────────────────────────────────────────────────────
  void _showPhoneDialog() {
    // Phone auth is problematic on web due to reCAPTCHA
    if (kIsWeb) {
      _showError(context.t('phone_not_available_web'));
      return;
    }

    final phoneCtrl = TextEditingController(text: '+880');
    final otpCtrl = TextEditingController();
    String? verificationId;
    bool loading = false;
    bool otpSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final primary = theme.colorScheme.primary;
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            behavior: HitTestBehavior.opaque,
            child: GestureDetector(
              onTap: () {},
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.15),
                              const Color(0xFF10B981).withValues(alpha: 0.05)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.phone_rounded,
                            color: Color(0xFF10B981), size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(context.t('phone_sign_in'),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),
                      if (!otpSent) ...[
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: context.t('phone_number'),
                            prefixIcon: const Icon(Icons.phone_outlined),
                            hintText: '+880 1XXXXXXXXX',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                                    if (phoneCtrl.text.trim().length < 10) {
                                      _showErrorIn(
                                          ctx, context.t('enter_valid_phone'));
                                      return;
                                    }
                                    setSheetState(() => loading = true);
                                    await AuthService().sendPhoneOtp(
                                      phoneNumber: phoneCtrl.text.trim(),
                                      onCodeSent: (vId, _) {
                                        setSheetState(() {
                                          verificationId = vId;
                                          otpSent = true;
                                          loading = false;
                                        });
                                      },
                                      onError: (msg) {
                                        _showErrorIn(ctx, msg);
                                        setSheetState(() => loading = false);
                                      },
                                      onAutoVerified: (_) {
                                        /* GoRouter redirects automatically */
                                      },
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(context.t('send_otp'),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                      if (otpSent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.t('otp_sent_to',
                                    params: {'phone': phoneCtrl.text}),
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 13),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 12,
                              fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            labelText: context.t('enter_otp'),
                            counterText: '',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                                    if (otpCtrl.text.trim().length != 6) {
                                      _showErrorIn(
                                          ctx, context.t('enter_valid_otp'));
                                      return;
                                    }
                                    setSheetState(() => loading = true);
                                    try {
                                      await AuthService().verifyPhoneOtp(
                                          verificationId: verificationId!,
                                          smsCode: otpCtrl.text.trim());
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        _showErrorIn(ctx, '$e');
                                        setSheetState(() => loading = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_rounded,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(context.t('verify_otp'),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
        body: Stack(children: [
      // Background
      AnimatedBuilder(
          animation: _bgAnimCtrl,
          builder: (_, __) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment(-1 + _bgAnimCtrl.value * 0.3, -1),
                  end: Alignment(1, 1 - _bgAnimCtrl.value * 0.3),
                  colors: isDark
                      ? [
                          const Color(0xFF0A0E14),
                          const Color(0xFF111927),
                          Color.lerp(primary, const Color(0xFF0A0E14), 0.82)!,
                          const Color(0xFF0F1419)
                        ]
                      : [
                          const Color(0xFFF0F4FF),
                          Colors.white,
                          Color.lerp(primary, Colors.white, 0.92)!,
                          const Color(0xFFF8FAFF)
                        ],
                )),
              )),
      // Orbs
      ..._orbs(primary, isDark, size),
      // Content
      SafeArea(
          child: Center(
              child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 20, 28, max(bottom + 16, 24)),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.03),
                // Logo
                ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 16))
                          ]),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset('assets/images/app_icon.png',
                              fit: BoxFit.cover)),
                    )),
                const SizedBox(height: 24),
                // Title
                FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                        position: _titleSlide,
                        child: Column(children: [
                          Text('CashTrack',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 8),
                          Text(context.t('login_tagline'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  height: 1.4)),
                        ]))),
                SizedBox(height: size.height * 0.03),
                // Features
                FadeTransition(
                    opacity: _featuresFade,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : primary.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _feat(
                                Icons.trending_up_rounded,
                                context.t('login_feature_track'),
                                primary,
                                isDark),
                            _vdiv(isDark),
                            _feat(
                                Icons.savings_rounded,
                                context.t('login_feature_save'),
                                const Color(0xFF10B981),
                                isDark),
                            _vdiv(isDark),
                            _feat(
                                Icons.auto_awesome_rounded,
                                context.t('login_feature_ai'),
                                const Color(0xFF8B5CF6),
                                isDark),
                          ]),
                    )),
                SizedBox(height: size.height * 0.04),
                // Buttons
                FadeTransition(
                    opacity: _buttonsFade,
                    child: SlideTransition(
                        position: _buttonsSlide,
                        child: Column(children: [
                          // Google sign-in
                          _authBtn(
                              Icons.g_mobiledata_rounded,
                              context.t('continue_with_google'),
                              const Color(0xFF4285F4),
                              Colors.white,
                              _signInGoogle),
                          const SizedBox(height: 10),
                          // Email sign-in
                          _authBtn(
                              Icons.email_rounded,
                              context.t('continue_with_email'),
                              primary,
                              Colors.white,
                              _showEmailDialog),
                          const SizedBox(height: 10),
                          // Phone sign-in
                          _authBtn(
                              Icons.phone_rounded,
                              context.t('continue_with_phone'),
                              const Color(0xFF10B981),
                              Colors.white,
                              _showPhoneDialog),
                          const SizedBox(height: 10),
                          // Divider
                          Row(children: [
                            Expanded(
                                child: Divider(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12)),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(context.t('or'),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4)))),
                            Expanded(
                                child: Divider(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12)),
                          ]),
                          const SizedBox(height: 10),
                          // Guest
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInGuest,
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.person_outline_rounded,
                                      size: 18),
                              label: Text(context.t('continue_guest'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(context.t('login_terms_hint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                                  height: 1.5)),
                        ]))),
              ],
            )),
      ))),
    ]));
  }

  Widget _authBtn(
      IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            shadowColor: bg.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _feat(IconData icon, String label, Color color, bool isDark) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.08)
              ]),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 6),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55))),
    ]);
  }

  Widget _vdiv(bool isDark) => Container(
      width: 1,
      height: 32,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06));

  List<Widget> _orbs(Color p, bool d, Size s) => [
        _orb(-60, null, null, -40, 200, p, d ? 0.12 : 0.08),
        _orb(
            null, -80, -60, null, 260, const Color(0xFF8B5CF6), d ? 0.1 : 0.06),
        _orb(s.height * 0.35, null, null, -30, 140, const Color(0xFF10B981),
            d ? 0.08 : 0.05),
      ]
          .map((config) => AnimatedBuilder(
              animation: _bgAnimCtrl,
              builder: (_, __) {
                final c = config;
                final off = sin(_bgAnimCtrl.value * pi) * 20;
                return Positioned(
                  top: c.top != null ? c.top! + off : null,
                  bottom: c.bottom != null ? c.bottom! + off : null,
                  left: c.left != null ? c.left! + off : null,
                  right: c.right != null ? c.right! + off : null,
                  child: Container(
                      width: c.size,
                      height: c.size,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            c.color.withValues(alpha: c.alpha),
                            c.color.withValues(alpha: 0)
                          ]))),
                );
              }))
          .toList();
}

class _OrbConfig {
  final double? top, bottom, left, right, size, alpha;
  final Color color;
  const _OrbConfig(this.top, this.bottom, this.left, this.right, this.size,
      this.color, this.alpha);
}

_OrbConfig _orb(double? top, double? bottom, double? left, double? right,
        double size, Color color, double alpha) =>
    _OrbConfig(top, bottom, left, right, size, color, alpha);
