import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'profile_store.dart';

enum ProfileSyncAction { none, pull, push }

/// Syncs the user profile with Firestore:
///
/// * `users/<uid>/profile/info`  — fullName, phone, dob, updatedAt
/// * `users/<uid>/profile/photo` — data (base64 JPEG, size-capped), updatedAt
///
/// The photo is kept in Firestore rather than Cloud Storage because the
/// project runs on the Spark plan (see `ClientAccountDeletionService`). Photos
/// are resized to ≤512px at pick time, so they fit well under the 1 MiB
/// document limit; `firestore.rules` enforces the cap server-side.
///
/// Conflicts are last-update-wins per document, like the rest of sync. A
/// document is only written when the local copy is newer, so repeated syncs
/// don't re-upload the photo.
class ProfileSyncService {
  ProfileSyncService({FirebaseFirestore? firestore, ProfileStore? store})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _store = store ?? ProfileStore();

  final FirebaseFirestore _firestore;
  final ProfileStore _store;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxTimestampLength = 40;

  /// Cloud path segments, also used by account deletion.
  static const String collection = 'profile';
  static const String infoDoc = 'info';
  static const String photoDoc = 'photo';

  DocumentReference<Map<String, dynamic>> _doc(String uid, String id) =>
      _firestore.collection('users').doc(uid).collection(collection).doc(id);

  /// Returns true when local data was replaced from the cloud.
  Future<bool> sync(String uid) async {
    final pulledInfo = await _syncInfo(uid);
    final pulledPhoto = await _syncPhoto(uid);
    return pulledInfo || pulledPhoto;
  }

  Future<bool> _syncInfo(String uid) async {
    final ref = _doc(uid, infoDoc);
    final snapshot = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final remote = parseRemoteInfo(snapshot.data());
    final local = await _store.read(uid);

    var localAt = await _store.infoUpdatedAt(uid);
    if (localAt == null && remote == null) {
      // Profile saved before sync existed: adopt it so it gets uploaded.
      final hasData =
          ProfileStore.syncedInfoFields.any((f) => (local[f] ?? '').isNotEmpty);
      if (!hasData) return false;
      localAt = DateTime.now().toUtc().toIso8601String();
      await _store.setInfoUpdatedAt(uid, localAt);
    }

    switch (
        decide(localUpdatedAt: localAt, remoteUpdatedAt: remote?.updatedAt)) {
      case ProfileSyncAction.none:
        return false;
      case ProfileSyncAction.pull:
        // Don't clobber an edit made while the request was in flight.
        if (await _store.infoUpdatedAt(uid) != localAt) return false;
        await _store.applyRemoteInfo(uid, remote!.fields, remote.updatedAt);
        return true;
      case ProfileSyncAction.push:
        await ref.set(<String, dynamic>{
          for (final f in ProfileStore.syncedInfoFields) f: local[f] ?? '',
          'updatedAt': localAt,
        }).timeout(_timeout);
        return false;
    }
  }

  Future<bool> _syncPhoto(String uid) async {
    final ref = _doc(uid, photoDoc);
    final snapshot = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final remote = parseRemotePhoto(snapshot.data());
    final localPhoto = (await _store.read(uid))['photoBase64'] ?? '';

    var localAt = await _store.photoUpdatedAt(uid);
    if (localAt == null && remote == null) {
      if (localPhoto.isEmpty) return false;
      localAt = DateTime.now().toUtc().toIso8601String();
      await _store.setPhotoUpdatedAt(uid, localAt);
    }

    switch (
        decide(localUpdatedAt: localAt, remoteUpdatedAt: remote?.updatedAt)) {
      case ProfileSyncAction.none:
        return false;
      case ProfileSyncAction.pull:
        if (await _store.photoUpdatedAt(uid) != localAt) return false;
        await _store.applyRemotePhoto(uid, remote!.data, remote.updatedAt);
        return true;
      case ProfileSyncAction.push:
        if (localPhoto.length > ProfileStore.maxPhotoBase64Length) {
          // Legacy oversized photo (picked before resizing existed); the
          // rules would reject it. Keep it local until the user replaces it.
          return false;
        }
        // An empty `data` is a deliberate removal and must propagate.
        await ref.set(<String, dynamic>{
          'data': localPhoto,
          'updatedAt': localAt,
        }).timeout(_timeout);
        return false;
    }
  }

  /// Last-update-wins. Equal timestamps mean both sides already agree.
  @visibleForTesting
  static ProfileSyncAction decide({
    required String? localUpdatedAt,
    required String? remoteUpdatedAt,
  }) {
    final local =
        localUpdatedAt == null ? null : DateTime.tryParse(localUpdatedAt);
    final remote =
        remoteUpdatedAt == null ? null : DateTime.tryParse(remoteUpdatedAt);
    if (remote == null) {
      return local == null ? ProfileSyncAction.none : ProfileSyncAction.push;
    }
    if (local == null) return ProfileSyncAction.pull;
    if (remote.isAtSameMomentAs(local)) return ProfileSyncAction.none;
    return remote.isAfter(local)
        ? ProfileSyncAction.pull
        : ProfileSyncAction.push;
  }

  /// Validates an untrusted remote info document; null if missing/invalid.
  @visibleForTesting
  static ({Map<String, String> fields, String updatedAt})? parseRemoteInfo(
      Map<String, dynamic>? data) {
    if (data == null) return null;
    final updatedAt = _validTimestamp(data['updatedAt']);
    if (updatedAt == null) return null;
    final fields = <String, String>{};
    for (final field in ProfileStore.syncedInfoFields) {
      final value = data[field] ?? '';
      final max = ProfileStore.maxFieldLengths[field]!;
      if (value is! String || value.length > max) return null;
      fields[field] = value.trim();
    }
    return (fields: fields, updatedAt: updatedAt);
  }

  @visibleForTesting
  static ({String data, String updatedAt})? parseRemotePhoto(
      Map<String, dynamic>? data) {
    if (data == null) return null;
    final updatedAt = _validTimestamp(data['updatedAt']);
    final photo = data['data'] ?? '';
    if (updatedAt == null ||
        photo is! String ||
        photo.length > ProfileStore.maxPhotoBase64Length) {
      return null;
    }
    return (data: photo, updatedAt: updatedAt);
  }

  static String? _validTimestamp(dynamic value) {
    if (value is! String || value.length > _maxTimestampLength) return null;
    return DateTime.tryParse(value) == null ? null : value;
  }
}
