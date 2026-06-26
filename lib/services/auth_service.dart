import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

class AuthService {
  AuthService._internal() {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      _localSessionSignedIn = Hive.box(_settingsBoxName)
          .get(_localSessionKey, defaultValue: false) as bool;
    }

    try {
      _firebaseAuthSubscription = _auth.authStateChanges().listen((_) {
        _authEvents.add(null);
      });
    } catch (_) {
      // Firebase not initialized in unit tests
    }
  }

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const String _settingsBoxName = 'settingsBox';
  static const String _localSessionKey = 'local_auth_session';

  FirebaseAuth? _customAuth;

  // Allow setting a mock for unit testing
  set mockAuth(FirebaseAuth mock) {
    _customAuth = mock;
    _firebaseAuthSubscription?.cancel();
    try {
      _firebaseAuthSubscription = _auth.authStateChanges().listen((_) {
        _authEvents.add(null);
      });
    } catch (_) {}
  }

  FirebaseAuth get _auth {
    if (_customAuth != null) return _customAuth!;
    return FirebaseAuth.instance;
  }

  final StreamController<void> _authEvents = StreamController<void>.broadcast();
  StreamSubscription<User?>? _firebaseAuthSubscription;
  bool _localSessionSignedIn = false;

  Stream<void> get authStateChanges => _authEvents.stream;

  void refresh() {
    _authEvents.add(null);
  }

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

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
    } catch (e) {
      // On web, Firebase errors may come as generic exceptions
      if (_shouldUseLocalFallbackMessage('$e')) {
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
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await user.sendEmailVerification();
    }
    _localSessionSignedIn = false;
    await _persistLocalSession(false);
    _authEvents.add(null);
  }

  // ── Email/Password Sign-In ─────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    // If anonymous, sign out first so email account gets its own fresh UID
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      await _auth.signOut();
    }
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
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
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

  // ── Google Sign-In ─────────────────────────────────────────────────────
  // NOTE: For web, this method should only be called from a user gesture context.
  // On web, prefer using GoogleIdentityServices.renderButton() for better UX.
  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = _createGoogleSignIn();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled - not an error, just return
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verify we have both tokens
      if (googleAuth.accessToken == null) {
        throw Exception(
          'Failed to get access token from Google Sign-In. '
          'This may occur if the OAuth client ID is not configured correctly.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // If currently anonymous, sign out first so Google gets its own fresh UID
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        await _auth.signOut();
      }

      await _auth.signInWithCredential(credential);
      _localSessionSignedIn = false;
      await _persistLocalSession(false);
    } on PlatformException catch (e) {
      // Handle common platform exceptions
      _handleGoogleSignInPlatformException(e);
    } catch (e) {
      // On web, Google Sign-In errors come as generic exceptions
      final msg = '$e'.toLowerCase();
      // User cancelled the popup — not an error, just return
      if (msg.contains('popup_closed') || 
          msg.contains('unknown_reason') || 
          msg.contains('sign_in_canceled') ||
          msg.contains('sign_in_failed')) {
        return;
      }
      rethrow;
    }
    _authEvents.add(null);
  }

  GoogleSignIn _createGoogleSignIn() {
    const webClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );

    if (kIsWeb) {
      return GoogleSignIn(
        clientId: webClientId.isEmpty ? null : webClientId,
        scopes: [
          'email',
          'profile',
        ],
      );
    }

    return GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
  }

  void _handleGoogleSignInPlatformException(PlatformException e) {
    // ApiException: 7 = NETWORK_ERROR (often SHA-1 misconfiguration or no internet)
    if (e.code == 'network_error' ||
        (e.message?.contains('ApiException: 7') ?? false)) {
      throw Exception(
        'Google Sign-In failed: Network error detected. '
        'Please check your internet connection. '
        'If on Android, verify SHA-1 fingerprint in Firebase Console.',
      );
    }

    // sign_in_canceled — user pressed back or closed dialog
    if (e.code == 'sign_in_canceled') {
      throw Exception('Google Sign-In was cancelled.');
    }

    // Web-specific: invalid_client_id means OAuth not configured
    if (e.code == 'invalid_client_id' ||
        (e.message?.contains('invalid_client') ?? false)) {
      throw Exception(
        'Google OAuth client ID is not configured correctly. '
        'On web: Update web/index.html with your Web Client ID. '
        'Check Firebase Console > Project Settings > Service Accounts > Web Client ID.',
      );
    }

    // Generic fallback
    throw Exception(
      'Google Sign-In error: ${e.message ?? e.code}',
    );
  }

  // ── Password Reset ─────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ───────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore sign out errors from Firebase; local session still must be cleared.
    }
    // Profile data is now stored per-user using UID-based keys in the profile
    // provider, so we don't need to clear it here. Guest sessions won't see
    // authenticated users' data because the UID won't match.
    _localSessionSignedIn = false;
    await _persistLocalSession(false);
    _authEvents.add(null);
  }

  bool _shouldUseLocalFallback(FirebaseAuthException e) {
    return _shouldUseLocalFallbackCode(e.code);
  }

  bool _shouldUseLocalFallbackCode(String code) {
    final c = code.toLowerCase();
    return c == 'configuration-not-found' ||
        c == 'operation-not-allowed' ||
        c == 'app-not-authorized' ||
        c == 'no-app' ||
        c == 'admin-restricted-operation' ||
        c == 'internal-error' ||
        c.contains('api-key-expired') ||
        c.contains('api-key-not-valid') ||
        c == 'auth/operation-not-allowed' ||
        c == 'auth/configuration-not-found' ||
        c == 'auth/admin-restricted-operation';
  }

  /// Check for firebase config errors in generic exception messages (web).
  bool _shouldUseLocalFallbackMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('configuration-not-found') ||
        lower.contains('operation-not-allowed') ||
        lower.contains('app-not-authorized') ||
        lower.contains('no-app') ||
        lower.contains('auth/configuration-not-found') ||
        lower.contains('auth/operation-not-allowed') ||
        lower.contains('admin-restricted-operation') ||
        lower.contains('auth/admin-restricted-operation') ||
        lower.contains('internal-error') ||
        lower.contains('identity provider configuration') ||
        lower.contains('api-key-expired') ||
        lower.contains('api-key-not-valid') ||
        lower.contains('api_key_expired');
  }

  Future<void> _persistLocalSession(bool value) async {
    final box = Hive.isBoxOpen(_settingsBoxName)
        ? Hive.box(_settingsBoxName)
        : await Hive.openBox(_settingsBoxName);
    await box.put(_localSessionKey, value);
  }

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authEvents.close();
  }
}
