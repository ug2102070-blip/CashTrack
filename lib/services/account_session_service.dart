import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/logger.dart';
import 'account_deletion_service.dart';
import 'auth_service.dart';
import 'local_user_data_service.dart';
import 'sync_service.dart';

/// What kind of session is signed in. Determines whether local data has a
/// recoverable cloud copy.
enum AccountKind {
  /// Google / email account: data can be backed up and restored later.
  registered,

  /// Firebase anonymous (guest): once signed out the UID is unrecoverable, so
  /// local data is effectively the only copy.
  guest,

  /// Offline fallback session with no Firebase user: data is local-only.
  localOnly,
}

enum SignOutBackupResult { backedUp, failed, notAvailable }

enum DeleteAccountResult {
  deleted,

  /// Server rejected because the last sign-in is too old; re-authenticate.
  requiresRecentLogin,

  /// Network / server failure. Nothing was deleted locally; safe to retry.
  failed,
}

/// Deletes the account's cloud data and Auth user. Abstracted so the
/// implementation can be swapped (and faked in tests).
typedef DeleteAccountCall = Future<void> Function();

/// Default: client-side deletion (works on the free Spark plan).
Future<void> _deleteAccountClientSide() =>
    ClientAccountDeletionService().deleteCurrentAccount();

/// Server-side deletion via the `deleteAccount` Cloud Function. Requires the
/// Blaze plan. To switch once deployed, make this the default
/// `deleteAccountCall` in [AccountSessionService].
Future<void> deleteAccountViaCloudFunction() async {
  await FirebaseFunctions.instanceFor(region: 'us-central1')
      .httpsCallable(
        'deleteAccount',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      )
      .call<void>();
}

/// Orchestrates sign-out so that the next person to use the device never sees
/// (or syncs) the previous user's financial data.
///
/// UI is responsible for confirmation dialogs; this class only sequences the
/// data operations.
class AccountSessionService {
  AccountSessionService({
    AuthService? auth,
    SyncService? sync,
    LocalUserDataService? localData,
    DeleteAccountCall? deleteAccountCall,
  })  : _auth = auth ?? AuthService(),
        _sync = sync,
        _localData = localData ?? LocalUserDataService.instance,
        _deleteAccountCall = deleteAccountCall ?? _deleteAccountClientSide;

  final AuthService _auth;
  final DeleteAccountCall _deleteAccountCall;
  final SyncService? _sync;
  final LocalUserDataService _localData;

  SyncService get _syncService => _sync ?? SyncService();

  AccountKind get currentKind {
    final user = _auth.currentUser;
    if (user == null) return AccountKind.localOnly;
    if (user.isAnonymous) return AccountKind.guest;
    return AccountKind.registered;
  }

  /// Pushes local changes to the cloud for registered accounts.
  Future<SignOutBackupResult> backupBeforeSignOut() async {
    if (currentKind != AccountKind.registered) {
      return SignOutBackupResult.notAvailable;
    }
    final result = await _syncService.backupToCloud();
    if (result == SyncService.syncCompleteMessage) {
      return SignOutBackupResult.backedUp;
    }
    AppLogger.w('Pre-sign-out backup failed: $result');
    return SignOutBackupResult.failed;
  }

  /// Erases user-scoped local data, then signs out.
  ///
  /// Erase runs first so the data is never visible after the session ends.
  /// If sign-out then fails, the user is still signed in and a later sync
  /// restores their (backed-up) data; local data never outlives the session.
  Future<void> eraseLocalDataAndSignOut() async {
    await _localData.eraseUserData();
    await _auth.signOut();
  }

  /// Permanently deletes the account: cloud data + Auth user, then this
  /// device's copy, then the session.
  ///
  /// Server first: if it fails, nothing local is touched and the user can
  /// retry. Registered users must re-authenticate in the UI beforehand.
  Future<DeleteAccountResult> deleteAccount() async {
    try {
      // Re-auth updates `auth_time`; make sure the callable carries it.
      await _auth.currentUser?.getIdToken(true);
      await _deleteAccountCall();
    } on FirebaseAuthException catch (e) {
      AppLogger.w('deleteAccount auth error: ${e.code}');
      if (e.code == 'requires-recent-login') {
        return DeleteAccountResult.requiresRecentLogin;
      }
      return DeleteAccountResult.failed;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.w('deleteAccount rejected: ${e.code}');
      if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('requires-recent-login')) {
        return DeleteAccountResult.requiresRecentLogin;
      }
      return DeleteAccountResult.failed;
    } catch (e) {
      AppLogger.w('deleteAccount failed: $e');
      return DeleteAccountResult.failed;
    }

    try {
      await eraseLocalDataAndSignOut();
    } catch (e) {
      // The account is already gone server-side; a sign-out hiccup must not
      // be reported as a failed deletion.
      AppLogger.w('Post-deletion cleanup failed: $e');
    }
    return DeleteAccountResult.deleted;
  }
}
