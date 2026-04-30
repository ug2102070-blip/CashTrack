import 'package:hive/hive.dart';

import '../models/category_model.dart';
import 'hive_box_recovery.dart';

class CategoryRepository {
  CategoryRepository._internal();
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;

  static const String _boxName = 'categories';
  Box<dynamic>? _box;
  bool _initialized = false;

  Box<dynamic>? _currentBoxOrNull() {
    if (_box != null) return _box;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      _initialized = true;
    }
    return _box;
  }

  Future<void> init() async {
    if (_initialized && _box == null && Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
    } else if (!_initialized || _box == null) {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await openBoxWithRecovery<dynamic>(_boxName);
      }
    }

    await _ensureDefaultCategories();
    _initialized = true;
  }

  Future<void> _ensureDefaultCategories() async {
    final box = _currentBoxOrNull();
    if (box == null) return;

    for (final category in [
      ...DefaultCategories.expenseCategories,
      ...DefaultCategories.incomeCategories,
    ]) {
      final existing = _decode(box.get(category.id));
      if (existing == null) {
        await box.put(category.id, category.toJson());
        continue;
      }

      if (existing.isDeleted || !existing.isDefault) {
        await box.put(
          category.id,
          existing
              .copyWith(
                isDeleted: false,
                isDefault: true,
                type: category.type,
                name: existing.name.isNotEmpty ? existing.name : category.name,
                nameBn: existing.nameBn.isNotEmpty
                    ? existing.nameBn
                    : category.nameBn,
                icon: existing.icon.isNotEmpty ? existing.icon : category.icon,
                colorHex: existing.colorHex.isNotEmpty
                    ? existing.colorHex
                    : category.colorHex,
              )
              .toJson(),
        );
        continue;
      }

      final needsNormalization = _needsNormalization(existing.name) ||
          _needsNormalization(existing.nameBn) ||
          _needsNormalization(existing.icon) ||
          existing.colorHex.isEmpty;

      if (needsNormalization) {
        await box.put(
          category.id,
          existing
              .copyWith(
                name: _needsNormalization(existing.name)
                    ? category.name
                    : existing.name,
                nameBn: _needsNormalization(existing.nameBn)
                    ? category.nameBn
                    : existing.nameBn,
                icon: _needsNormalization(existing.icon)
                    ? category.icon
                    : existing.icon,
                colorHex: existing.colorHex.isEmpty
                    ? category.colorHex
                    : existing.colorHex,
                type: category.type,
                isDeleted: false,
                isDefault: true,
              )
              .toJson(),
        );
      }
    }
  }

  List<CategoryModel> getAllCategories() {
    return _decodedValues().where((cat) => !cat.isDeleted).toList();
  }

  List<CategoryModel> getExpenseCategories() {
    return _decodedValues()
        .where((cat) =>
            !cat.isDeleted &&
            (cat.type == CategoryType.expense || cat.type == CategoryType.both))
        .toList();
  }

  List<CategoryModel> getIncomeCategories() {
    return _decodedValues()
        .where((cat) =>
            !cat.isDeleted &&
            (cat.type == CategoryType.income || cat.type == CategoryType.both))
        .toList();
  }

  CategoryModel? getCategoryById(String id) {
    return _decode(_currentBoxOrNull()?.get(id));
  }

  Future<void> addCategory(CategoryModel category) async {
    await init();
    await _box!.put(category.id, category.toJson());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await init();
    await _box!.put(category.id, category.toJson());
  }

  Future<void> deleteCategory(String id) async {
    await init();
    final category = _decode(_box!.get(id));
    if (category != null && !category.isDefault) {
      await _box!.put(id, category.copyWith(isDeleted: true).toJson());
    }
  }

  List<CategoryModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<CategoryModel>().toList();
  }

  CategoryModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is CategoryModel) return raw;
    if (raw is Map) {
      return CategoryModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  bool _needsNormalization(String value) {
    if (value.trim().isEmpty) return true;
    return value.contains('à') || value.contains('ðŸ') || value.contains('Ã');
  }
}
