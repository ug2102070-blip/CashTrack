import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/models/asset_model.dart';
import 'package:cashtrack/data/models/investment_model.dart';
import 'package:cashtrack/data/repositories/asset_repository.dart';
import 'package:cashtrack/data/repositories/investment_repository.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForTests();
  });

  setUp(() async {
    await AssetRepository().init();
    await InvestmentRepository().init();
    await Hive.box('assets').clear();
    await Hive.box('investments').clear();
  });

  test('asset repository saves, updates, and totals assets correctly',
      () async {
    final repo = AssetRepository();

    await repo.addAsset(
      AssetModel(
        id: 'asset_laptop',
        name: 'Laptop',
        purchasePrice: 90000,
        currentValue: 70000,
        purchaseDate: DateTime(2026, 4, 1),
        category: 'Electronics',
        createdAt: DateTime(2026, 4, 1),
      ),
    );

    await repo.updateValue('asset_laptop', 65000);

    final asset = repo.getAssetById('asset_laptop');

    expect(asset, isNotNull);
    expect(asset!.currentValue, 65000);
    expect(repo.getTotalAssetValue(), 65000);
  });

  test('investment repository saves, updates, and computes returns correctly',
      () async {
    final repo = InvestmentRepository();

    await repo.addInvestment(
      InvestmentModel(
        id: 'inv_fd',
        name: 'Fixed Deposit',
        type: InvestmentType.fixedDeposit,
        investedAmount: 100000,
        currentValue: 108000,
        expectedReturn: 8,
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await repo.updateCurrentValue('inv_fd', 110000);

    final investment = repo.getInvestmentById('inv_fd');

    expect(investment, isNotNull);
    expect(investment!.currentValue, 110000);
    expect(repo.getTotalInvested(), 100000);
    expect(repo.getTotalCurrentValue(), 110000);
    expect(repo.getTotalReturns(), 10000);
    expect(repo.getReturnPercentage(), 10);
  });
}
