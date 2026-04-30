// lib/presentation/auth/login_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/l10n/app_l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _bgAnimCtrl, _contentAnimCtrl;
  late Animation<double> _logoScale, _titleFade, _featuresFade, _buttonsFade;
  late Animation<Offset> _titleSlide, _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _contentAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _logoScale = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _contentAnimCtrl, curve: const Interval(0, 0.35, curve: Curves.elasticOut)));
    _titleFade = CurvedAnimation(parent: _contentAnimCtrl, curve: const Interval(0.15, 0.45, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _contentAnimCtrl, curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic)));
    _featuresFade = CurvedAnimation(parent: _contentAnimCtrl, curve: const Interval(0.35, 0.65, curve: Curves.easeOut));
    _buttonsFade = CurvedAnimation(parent: _contentAnimCtrl, curve: const Interval(0.5, 0.85, curve: Curves.easeOut));
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _contentAnimCtrl, curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic)));
    _contentAnimCtrl.forward();
  }

  @override
  void dispose() { _bgAnimCtrl.dispose(); _contentAnimCtrl.dispose(); super.dispose(); }

  Future<void> _signInGuest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try { await AuthService().signInAnonymously(); }
    catch (e) { if (mounted) _showError('$e'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showError(String msg) {
    // Parse Firebase error codes to user-friendly messages
    final friendly = _friendlyError(msg);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(friendly), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('billing_not_enabled') || lower.contains('billing-not-enabled')) {
      return 'Phone auth requires Firebase Blaze plan. Use Email or Guest sign-in instead.';
    }
    if (lower.contains('email-already-in-use')) return 'This email is already registered. Try signing in.';
    if (lower.contains('wrong-password') || lower.contains('invalid-credential')) return 'Incorrect email or password.';
    if (lower.contains('user-not-found')) return 'No account found with this email.';
    if (lower.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (lower.contains('invalid-email')) return 'Please enter a valid email address.';
    if (lower.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (lower.contains('network-request-failed')) return 'No internet connection. Please check your network.';
    if (lower.contains('operation-not-allowed')) return 'This sign-in method is not enabled. Please use Guest sign-in.';
    if (lower.contains('configuration-not-found')) return 'Firebase is not configured yet. Using local session.';
    // Strip Firebase exception wrapper for cleaner display
    final match = RegExp(r'\] (.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  void _showEmailDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isSignUp = false;
    bool loading = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(isSignUp ? context.t('create_account') : context.t('email_sign_in'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: context.t('email'), prefixIcon: const Icon(Icons.email_outlined))),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true,
              decoration: InputDecoration(labelText: context.t('password'), prefixIcon: const Icon(Icons.lock_outlined))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : () async {
                  if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                    _showError(context.t('fill_all_fields')); return;
                  }
                  setSheetState(() => loading = true);
                  try {
                    if (isSignUp) {
                      await AuthService().signUpWithEmail(emailCtrl.text.trim(), passCtrl.text.trim());
                    } else {
                      await AuthService().signInWithEmail(emailCtrl.text.trim(), passCtrl.text.trim());
                    }
                    // Auth state change triggers GoRouter redirect automatically.
                    // Don't pop — the whole login screen will be replaced.
                  } catch (e) {
                    _showError('$e');
                    if (ctx.mounted) setSheetState(() => loading = false);
                  }
                },
                child: loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isSignUp ? context.t('sign_up') : context.t('sign_in')),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setSheetState(() => isSignUp = !isSignUp),
              child: Text(isSignUp ? context.t('already_have_account') : context.t('create_new_account')),
            ),
          ]),
        );
      }),
    );
  }

  void _showPhoneDialog() {
    final phoneCtrl = TextEditingController(text: '+880');
    final otpCtrl = TextEditingController();
    String? verificationId;
    bool loading = false;
    bool otpSent = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(context.t('phone_sign_in'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            if (!otpSent) ...[
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: context.t('phone_number'), prefixIcon: const Icon(Icons.phone_outlined), hintText: '+880 1XXXXXXXXX')),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (phoneCtrl.text.trim().length < 10) { _showError(context.t('enter_valid_phone')); return; }
                    setSheetState(() => loading = true);
                    await AuthService().sendPhoneOtp(
                      phoneNumber: phoneCtrl.text.trim(),
                      onCodeSent: (vId, _) { setSheetState(() { verificationId = vId; otpSent = true; loading = false; }); },
                      onError: (msg) { _showError(msg); setSheetState(() => loading = false); },
                      onAutoVerified: (_) { /* GoRouter redirects automatically */ },
                    );
                  },
                  child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.t('send_otp')),
                ),
              ),
            ],
            if (otpSent) ...[
              Text(context.t('otp_sent_to', params: {'phone': phoneCtrl.text}), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              TextField(controller: otpCtrl, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: InputDecoration(labelText: context.t('enter_otp'), counterText: '')),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (otpCtrl.text.trim().length != 6) { _showError(context.t('enter_valid_otp')); return; }
                    setSheetState(() => loading = true);
                    try {
                      await AuthService().verifyPhoneOtp(verificationId: verificationId!, smsCode: otpCtrl.text.trim());
                      // GoRouter redirects automatically
                    } catch (e) { _showError('$e'); if (ctx.mounted) setSheetState(() => loading = false); }
                  },
                  child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.t('verify_otp')),
                ),
              ),
            ],
          ]),
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

    return Scaffold(body: Stack(children: [
      // Background
      AnimatedBuilder(animation: _bgAnimCtrl, builder: (_, __) => Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment(-1 + _bgAnimCtrl.value * 0.3, -1), end: Alignment(1, 1 - _bgAnimCtrl.value * 0.3),
          colors: isDark
            ? [const Color(0xFF0A0E14), const Color(0xFF111927), Color.lerp(primary, const Color(0xFF0A0E14), 0.82)!, const Color(0xFF0F1419)]
            : [const Color(0xFFF0F4FF), Colors.white, Color.lerp(primary, Colors.white, 0.92)!, const Color(0xFFF8FAFF)],
        )),
      )),
      // Orbs
      ..._orbs(primary, isDark, size),
      // Content
      SafeArea(child: Center(child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 20, 28, max(bottom + 16, 24)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(height: size.height * 0.03),
            // Logo
            ScaleTransition(scale: _logoScale, child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 16))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover)),
            )),
            const SizedBox(height: 24),
            // Title
            FadeTransition(opacity: _titleFade, child: SlideTransition(position: _titleSlide, child: Column(children: [
              Text('CashTrack', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(context.t('login_tagline'), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), height: 1.4)),
            ]))),
            SizedBox(height: size.height * 0.03),
            // Features
            FadeTransition(opacity: _featuresFade, child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : primary.withValues(alpha: 0.08)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _feat(Icons.trending_up_rounded, context.t('login_feature_track'), primary, isDark),
                _vdiv(isDark),
                _feat(Icons.savings_rounded, context.t('login_feature_save'), const Color(0xFF10B981), isDark),
                _vdiv(isDark),
                _feat(Icons.auto_awesome_rounded, context.t('login_feature_ai'), const Color(0xFF8B5CF6), isDark),
              ]),
            )),
            SizedBox(height: size.height * 0.04),
            // Buttons
            FadeTransition(opacity: _buttonsFade, child: SlideTransition(position: _buttonsSlide, child: Column(children: [
              // Email sign-in
              _authBtn(Icons.email_rounded, context.t('continue_with_email'), primary, Colors.white, _showEmailDialog),
              const SizedBox(height: 10),
              // Phone sign-in
              _authBtn(Icons.phone_rounded, context.t('continue_with_phone'), const Color(0xFF10B981), Colors.white, _showPhoneDialog),
              const SizedBox(height: 10),
              // Divider
              Row(children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(context.t('or'), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              ]),
              const SizedBox(height: 10),
              // Guest
              SizedBox(width: double.infinity, height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInGuest,
                  icon: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text(context.t('continue_guest'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(context.t('login_terms_hint'), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), height: 1.5)),
            ]))),
          ],
        )),
      ))),
    ]));
  }

  Widget _authBtn(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap, icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4, shadowColor: bg.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _feat(IconData icon, String label, Color color, bool isDark) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08)]), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
    ]);
  }

  Widget _vdiv(bool isDark) => Container(width: 1, height: 32, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06));

  List<Widget> _orbs(Color p, bool d, Size s) => [
    _orb(-60, null, null, -40, 200, p, d ? 0.12 : 0.08),
    _orb(null, -80, -60, null, 260, const Color(0xFF8B5CF6), d ? 0.1 : 0.06),
    _orb(s.height * 0.35, null, null, -30, 140, const Color(0xFF10B981), d ? 0.08 : 0.05),
  ].map((config) => AnimatedBuilder(animation: _bgAnimCtrl, builder: (_, __) {
    final c = config;
    final off = sin(_bgAnimCtrl.value * pi) * 20;
    return Positioned(
      top: c.top != null ? c.top! + off : null, bottom: c.bottom != null ? c.bottom! + off : null,
      left: c.left != null ? c.left! + off : null, right: c.right != null ? c.right! + off : null,
      child: Container(width: c.size, height: c.size, decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c.color.withValues(alpha: c.alpha), c.color.withValues(alpha: 0)]))),
    );
  })).toList();
}

class _OrbConfig {
  final double? top, bottom, left, right, size, alpha;
  final Color color;
  const _OrbConfig(this.top, this.bottom, this.left, this.right, this.size, this.color, this.alpha);
}

_OrbConfig _orb(double? top, double? bottom, double? left, double? right, double size, Color color, double alpha) =>
    _OrbConfig(top, bottom, left, right, size, color, alpha);
