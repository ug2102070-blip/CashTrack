import 'package:hive/hive.dart';

import '../../services/encrypted_hive_storage.dart';

Future<Box<T>> openBoxWithRecovery<T>(String boxName) async {
  try {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await EncryptedHiveStorage.openBox<T>(boxName);
  } on HiveError catch (error) {
    final message = error.message.toLowerCase();
    final isUnknownType = message.contains('unknown typeid');
    final isAdapterIssue = message.contains('register an adapter');

    if (!isUnknownType && !isAdapterIssue) {
      rethrow;
    }
    return _wipeAndRecoverBox(boxName);
  } on TypeError {
    // Type mismatches (like double -> int during schema migration without a script)
    // will throw TypeErrors during Hive object deserialization.
    return _wipeAndRecoverBox(boxName);
  } catch (e) {
    rethrow;
  }
}

Future<Box<T>> _wipeAndRecoverBox<T>(String boxName) async {
  if (Hive.isBoxOpen(boxName)) {
    await Hive.box(boxName).close();
  }
  await Hive.deleteBoxFromDisk(boxName);
  return EncryptedHiveStorage.openBox<T>(boxName);
}
