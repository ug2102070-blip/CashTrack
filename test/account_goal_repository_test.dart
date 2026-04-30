import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/models/account_model.dart';
import 'package:cashtrack/data/models/goal_model.dart';
import 'package:cashtrack/data/repositories/account_repository.dart';
import 'package:cashtrack/data/repositories/goal_repository.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForTests();
  });

  setUp(() async {
    await AccountRepository().init();
    await GoalRepository().init();
    await Hive.box('accounts').clear();
    await Hive.box('goals').clear();
  });

  test('account repository keeps default accounts and saves custom accounts',
      () async {
    final repo = AccountRepository();
    await repo.init();

    await repo.addAccount(
      AccountModel(
        id: 'custom_acc',
        name: 'Savings',
        nameBn: 'Savings',
        type: AccountType.bank,
        balance: 1500,
        createdAt: DateTime(2026, 4, 25),
      ),
    );

    final allAccounts = repo.getAllAccounts();

    expect(allAccounts.any((a) => a.id == 'acc_cash'), isTrue);
    expect(allAccounts.any((a) => a.id == 'acc_online'), isTrue);
    expect(allAccounts.any((a) => a.id == 'custom_acc'), isTrue);
  });

  test('goal repository can save and read back goals', () async {
    final repo = GoalRepository();

    await repo.addGoal(
      GoalModel(
        id: 'goal_trip',
        name: 'Trip Fund',
        targetAmount: 20000,
        currentAmount: 5000,
        createdAt: DateTime(2026, 4, 25),
      ),
    );

    final goal = repo.getGoalById('goal_trip');

    expect(goal, isNotNull);
    expect(goal!.name, 'Trip Fund');
    expect(goal.currentAmount, 5000);
  });
}
