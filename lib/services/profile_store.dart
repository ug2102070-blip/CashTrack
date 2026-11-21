import 'package:hive/hive.dart';

/// Single owner of how the user profile is persisted in Hive.
///
/// Keys are scoped per account (`profile_<uid>_<field>`); signed-out/guest
/// data without a UID uses `profile_<field>`. The UI notifier and
/// `ProfileSyncService` both go through this class so the key scheme and the
/// "last updated" bookkeeping used for sync conflict resolution live in one
/// place.
class ProfileStore {
  ProfileStore({Future<Box> Function()? openBox})
      : _openBox = openBox ?? _defaultBox;

  static const String boxName = 'settingsBox';

  static Future<Box> _defaultBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return Hive.openBox(boxName);
  }

  final Future<Box> Function() _openBox;

  /// Profile state key → Hive key suffix.
  static const Map<String, String> storageKeys = {
    'fullName': 'full_name',
    'email': 'email',
    'phone': 'phone',
    'dob': 'dob',
    'photoBase64': 'photo_base64',
  };

  /// Max lengths for text fields. Mirrored in `firestore.rules`.
  static const Map<String, int> maxFieldLengths = {
    'fullName': 60,
    'email': 254,
    'phone': 20,
    'dob': 40,
  };

  /// Cap for the stored base64 photo. Mirrored in `firestore.rules`; keeps
  /// the photo document well under Firestore's 1 MiB limit.
  static const int maxPhotoBase64Length = 700000;

  /// Text fields synced to `users/<uid>/profile/info`. Email is not synced:
  /// for registered users it always comes from the sign-in account.
  static const List<String> syncedInfoFields = ['fullName', 'phone', 'dob'];

  /// Fields the app no longer collects (data minimisation). Any stored values
  /// are deleted so data the UI can no longer show or edit doesn't linger.
  static const List<String> retiredStorageKeys = [
    'address',
    'occupation',
    'bio',
  ];

  static const String _infoUpdatedAtKey = 'info_updated_at';
  static const String _photoUpdatedAtKey = 'photo_updated_at';

  static String hiveKey(String? uid, String suffix) =>
      (uid == null || uid.isEmpty)
          ? 'profile_$suffix'
          : 'profile_${uid}_$suffix';

  static String _suffixFor(String field) {
    final suffix = storageKeys[field];
    if (suffix == null) {
      throw ArgumentError.value(field, 'field', 'Unknown profile field');
    }
    return suffix;
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  /// Every profile field (missing values as '').
  Future<Map<String, String>> read(String? uid) async {
    final box = await _openBox();
    return {
      for (final entry in storageKeys.entries)
        entry.key:
            ((box.get(hiveKey(uid, entry.value)) as String?) ?? '').trim(),
    };
  }

  /// Writes one field and stamps the matching "updated at" marker so the next
  /// sync knows the local copy changed.
  Future<void> write(String? uid, String field, String value) async {
    final box = await _openBox();
    await box.put(hiveKey(uid, _suffixFor(field)), value);
    if (field == 'photoBase64') {
      await box.put(hiveKey(uid, _photoUpdatedAtKey), _now());
    } else if (syncedInfoFields.contains(field)) {
      await box.put(hiveKey(uid, _infoUpdatedAtKey), _now());
    }
  }

  Future<String?> infoUpdatedAt(String uid) =>
      _readString(uid, _infoUpdatedAtKey);
  Future<String?> photoUpdatedAt(String uid) =>
      _readString(uid, _photoUpdatedAtKey);

  Future<void> setInfoUpdatedAt(String uid, String value) async =>
      (await _openBox()).put(hiveKey(uid, _infoUpdatedAtKey), value);
  Future<void> setPhotoUpdatedAt(String uid, String value) async =>
      (await _openBox()).put(hiveKey(uid, _photoUpdatedAtKey), value);

  /// Applies a remote info record verbatim (including its timestamp).
  Future<void> applyRemoteInfo(
    String uid,
    Map<String, String> fields,
    String updatedAt,
  ) async {
    final box = await _openBox();
    for (final field in syncedInfoFields) {
      await box.put(hiveKey(uid, _suffixFor(field)), fields[field] ?? '');
    }
    await box.put(hiveKey(uid, _infoUpdatedAtKey), updatedAt);
  }

  Future<void> applyRemotePhoto(
    String uid,
    String photoBase64,
    String updatedAt,
  ) async {
    final box = await _openBox();
    await box.put(hiveKey(uid, _suffixFor('photoBase64')), photoBase64);
    await box.put(hiveKey(uid, _photoUpdatedAtKey), updatedAt);
  }

  /// Deletes values of retired fields for [uid] and for the UID-less scope.
  Future<void> purgeRetiredFields(String? uid) async {
    final box = await _openBox();
    final keys = <String>{
      for (final suffix in retiredStorageKeys) ...[
        hiveKey(uid, suffix),
        hiveKey(null, suffix),
      ],
    }.where(box.containsKey).toList();
    if (keys.isNotEmpty) await box.deleteAll(keys);
  }

  Future<String?> _readString(String uid, String suffix) async {
    final value = (await _openBox()).get(hiveKey(uid, suffix));
    return value is String && value.isNotEmpty ? value : null;
  }
}
