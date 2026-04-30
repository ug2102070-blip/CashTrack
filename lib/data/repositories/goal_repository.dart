import 'package:hive/hive.dart';

import '../models/goal_model.dart';
import 'hive_box_recovery.dart';

class GoalRepository {
  GoalRepository._internal();
  static final GoalRepository _instance = GoalRepository._internal();
  factory GoalRepository() => _instance;

  static const String _boxName = 'goals';
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

  List<GoalModel> getAllGoals() {
    return _decodedValues();
  }

  List<GoalModel> getActiveGoals() {
    return _decodedValues().where((goal) => !goal.isCompleted).toList();
  }

  GoalModel? getGoalById(String id) {
    return _decode(_currentBoxOrNull()?.get(id));
  }

  Future<void> addGoal(GoalModel goal) async {
    await init();
    await _box!.put(goal.id, goal.toJson());
  }

  Future<void> updateGoal(GoalModel goal) async {
    await init();
    await _box!.put(goal.id, goal.toJson());
  }

  Future<void> updateProgress(String goalId, double newAmount) async {
    await init();
    final goal = _decode(_box!.get(goalId));
    if (goal != null) {
      final isCompleted = newAmount >= goal.targetAmount;
      await _box!.put(
        goalId,
        goal
            .copyWith(
              currentAmount: newAmount,
              isCompleted: isCompleted,
              updatedAt: DateTime.now(),
            )
            .toJson(),
      );
    }
  }

  Future<void> deleteGoal(String id) async {
    await init();
    await _box!.delete(id);
  }

  List<GoalModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<GoalModel>().toList();
  }

  GoalModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is GoalModel) return raw;
    if (raw is Map) {
      return GoalModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
