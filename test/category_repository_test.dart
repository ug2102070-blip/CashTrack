import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/models/category_model.dart';
import 'package:cashtrack/data/repositories/category_repository.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForTests();
  });

  setUp(() async {
    if (Hive.isBoxOpen('categories')) {
      await Hive.box('categories').clear();
    }
  });

  test('CategoryRepository seeds expanded default categories', () async {
    await CategoryRepository().init();

    final categories = CategoryRepository().getAllCategories();
    final ids = categories.map((category) => category.id).toSet();

    expect(ids, contains('cat_rent'));
    expect(ids, contains('cat_utilities'));
    expect(ids, contains('cat_freelance'));
    expect(ids, contains('cat_others'));
  });

  test('CategoryRepository normalizes malformed default category data', () async {
    final box = await Hive.openBox('categories');
    await box.put(
      'cat_food',
      CategoryModel(
        id: 'cat_food',
        name: 'Food',
        nameBn: 'à¦–à¦¾à¦¬à¦¾à¦°',
        icon: 'ðŸ½ï¸',
        colorHex: '',
        type: CategoryType.expense,
        isDefault: true,
      ).toJson(),
    );

    await CategoryRepository().init();

    final category = CategoryRepository().getCategoryById('cat_food');
    expect(category, isNotNull);
    expect(category!.nameBn, 'খাবার');
    expect(category.icon, '🍽️');
    expect(category.colorHex, '#FF9066');
  });
}
