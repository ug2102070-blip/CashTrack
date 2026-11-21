import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/logger.dart';
import 'sync_service.dart';

/// Deletes the signed-in user's cloud data and Auth account directly from the
/// client — works on the Firebase Spark (free) plan, where Cloud Functions
/// can't be deployed.
///
/// Firestore rules already allow an owner to delete any document under
/// `users/{uid}`. Receipts are stored on-device only, so there is no Storage
/// data to remove.
///
/// Once the project is on the Blaze plan, prefer the server-side
/// `deleteAccount` Cloud Function (functions/src/index.js): it runs as one
/// trusted operation and also removes Admin-only data such as
/// `_ai_rate_limits/{uid}`. Switch by passing the callable to
/// `AccountSessionService(deleteAccountCall: ...)`.
class ClientAccountDeletionService {
  ClientAccountDeletionService(
      {FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Firestore batch limit is 500; stay well below it.
  static const int _batchSize = 400;

  /// Bounds every network step so an offline device fails fast instead of
  /// queueing writes that would never be confirmed.
  static const Duration _stepTimeout = Duration(seconds: 30);

  /// Deletes all cloud data, then the Auth user.
  ///
  /// Order matters: data first, Auth user last. If anything fails, the user is
  /// still signed in and can retry — every step is idempotent.
  ///
  /// Throws [FirebaseAuthException] with code `requires-recent-login` when a
  /// registered user must re-authenticate, or [FirebaseException] /
  /// [TimeoutException]-like errors on network failure.
  Future<void> deleteCurrentAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final userDoc = _firestore.collection('users').doc(user.uid);

    for (final collection in SyncService.syncedCollections) {
      await _deleteCollection(userDoc.collection(collection));
    }

    // Known single documents + the profile doc itself (deleted by path, so no
    // read permission is needed).
    final batch = _firestore.batch()
      ..delete(userDoc.collection('sync').doc('meta'))
      ..delete(userDoc.collection('app_data').doc('snapshot'))
      ..delete(userDoc);
    await batch.commit().timeout(_stepTimeout);

    try {
      await user.delete().timeout(_stepTimeout);
    } on FirebaseAuthException catch (e) {
      // Guests can't re-authenticate. Their cloud data is already gone; the
      // remaining empty anonymous record is orphaned once they sign out.
      if (user.isAnonymous && e.code == 'requires-recent-login') {
        AppLogger.w('Anonymous user record kept (requires-recent-login); '
            'cloud data deleted');
        return;
      }
      rethrow;
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    while (true) {
      // Source.server: never "succeed" against an offline cache.
      final snapshot = await ref
          .limit(_batchSize)
          .get(const GetOptions(source: Source.server))
          .timeout(_stepTimeout);
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(_stepTimeout);
      if (snapshot.docs.length < _batchSize) return;
    }
  }
}
