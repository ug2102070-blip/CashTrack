import 'package:hive/hive.dart';

Future<Box<T>> openBoxWithRecovery<T>(String boxName) async {
  try {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  } on HiveError catch (error) {
    final message = error.message.toLowerCase();
    final isUnknownType = message.contains('unknown typeid');
    final isAdapterIssue = message.contains('register an adapter');

    if (!isUnknownType && !isAdapterIssue) {
      rethrow;
    }

    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }

    await Hive.deleteBoxFromDisk(boxName);
    return Hive.openBox<T>(boxName);
  }
}
