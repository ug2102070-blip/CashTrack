import 'package:flutter/material.dart';

import 'transactions_screen.dart';

// Legacy alias kept for backward compatibility.
// Use TransactionsScreen as the single implementation.
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionsScreen();
  }
}
