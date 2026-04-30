import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

class AuthService {
  AuthService._internal() {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      _localSessionSignedIn = Hive.box(_settingsBoxName)
          .get(_localSessionKey, defaultValue: false) as bool;
    }

    _firebaseAuthSubscription = _auth.authStateChanges().listen((_) {
      _authEvents.add(null);
    });
  }

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const String _settingsBoxName = 'settingsBox';
  static const String _localSessionKey = 'local_auth_session';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamController<void> _authEvents = StreamController<void>.broadcast();
  late final StreamSubscription<User?> _firebaseAuthSubscription;
  bool _localSessionSignedIn = false;

  Stream<void> get authStateChanges => _authEvents.stream;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null || _localSessionSignedIn;

  // ── Anonymous Sign-In ──────────────────────────────────────────────────
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      _localSessionSignedIn = false;
      await _persistLocalSession(false);
    } on FirebaseAuthException catch (e) {
      if (_shouldUseLocalFallback(e)) {
        _localSessionSignedIn = true;
        await _persistLocalSession(true);
      } else {
        rethrow;
      }
    } on FirebaseException catch (e) {
      if (_shouldUseLocalFallbackCode(e.code)) {
        _localSessionSignedIn = true;
        await _persistLocalSession(true);
      } else {
        rethrow;
      }
    }
    _authEvents.add(null);
  }

  // ── Email/Password Sign-Up ─────────────────────────────────────────────
  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _localSessionSignedIn = false;
    await _persistLocalSession(false);
    _authEvents.add(null);
  }

  // ── Email/Password Sign-In ─────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _localSessionSignedIn = false;
    await _persistLocalSession(false);
    _authEvents.add(null);
  }

  // ── Phone Auth: Send OTP ───────────────────────────────────────────────
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken)
        onCodeSent,
    required void Function(String errorMessage) onError,
    required void Function(PhoneAuthCredential credential)
        onAutoVerified,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _auth.signInWithCredential(credential);
          _localSessionSignedIn = false;
          await _persistLocalSession(false);
          _authEvents.add(null);
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? e.code);
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      onError('$e');
    }
  }

  // ── Phone Auth: Verify OTP ─────────────────────────────────────────────
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
    _localSessionSignedIn = false;
    await _persistLocalSession(false);
    _authEvents.add(null);
  }

  // ── Password Reset ─────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ───────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore sign out errors from Firebase; local session still must be cleared.
    }
    _localSessionSignedIn = false;
    await _persistLocalSession(false);
    _authEvents.add(null);
  }

  bool _shouldUseLocalFallback(FirebaseAuthException e) {
    return _shouldUseLocalFallbackCode(e.code);
  }

  bool _shouldUseLocalFallbackCode(String code) {
    return code == 'configuration-not-found' ||
        code == 'operation-not-allowed' ||
        code == 'app-not-authorized' ||
        code == 'no-app';
  }

  Future<void> _persistLocalSession(bool value) async {
    final box = Hive.isBoxOpen(_settingsBoxName)
        ? Hive.box(_settingsBoxName)
        : await Hive.openBox(_settingsBoxName);
    await box.put(_localSessionKey, value);
  }

  void dispose() {
    _firebaseAuthSubscription.cancel();
    _authEvents.close();
  }
}
