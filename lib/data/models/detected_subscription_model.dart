class DetectedSubscription {
  final String merchantName;
  final double amount;
  final String frequency;
  final DateTime lastDate;
  final DateTime nextExpectedDate;
  final List<String> transactionIds;

  DetectedSubscription({
    required this.merchantName,
    required this.amount,
    required this.frequency,
    required this.lastDate,
    required this.nextExpectedDate,
    required this.transactionIds,
  });

  @override
  String toString() {
    return 'DetectedSubscription(merchantName: $merchantName, amount: $amount, frequency: $frequency, lastDate: $lastDate, nextExpectedDate: $nextExpectedDate, transactionIds: $transactionIds)';
  }
}
