import 'package:hive/hive.dart';

import '../models/asset_model.dart';
import 'hive_box_recovery.dart';

class AssetRepository {
  AssetRepository._internal();
  static final AssetRepository _instance = AssetRepository._internal();
  factory AssetRepository() => _instance;

  static const String _boxName = 'assets';
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
    if (_initialized && _box != null) return;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      _initialized = true;
      return;
    }
    _box = await openBoxWithRecovery<dynamic>(_boxName);
    _initialized = true;
  }

  List<AssetModel> getAllAssets() {
    return _decodedValues();
  }

  AssetModel? getAssetById(String id) {
    return _decode(_currentBoxOrNull()?.get(id));
  }

  Future<void> addAsset(AssetModel asset) async {
    await init();
    await _box!.put(asset.id, asset.toJson());
  }

  Future<void> updateAsset(AssetModel asset) async {
    await init();
    await _box!.put(asset.id, asset.toJson());
  }

  Future<void> updateValue(String assetId, double newValue) async {
    await init();
    final asset = _decode(_box!.get(assetId));
    if (asset != null) {
      await _box!.put(
        assetId,
        asset
            .copyWith(currentValue: newValue, updatedAt: DateTime.now())
            .toJson(),
      );
    }
  }

  Future<void> deleteAsset(String id) async {
    await init();
    await _box!.delete(id);
  }

  double getTotalAssetValue() {
    return _decodedValues()
        .fold<double>(0, (sum, asset) => sum + asset.currentValue);
  }

  List<AssetModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<AssetModel>().toList();
  }

  AssetModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is AssetModel) return raw;
    if (raw is Map) {
      return AssetModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
