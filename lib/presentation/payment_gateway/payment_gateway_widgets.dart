import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/account_model.dart';

// ---------------------------------------------------------
// MODEL & DATA STRUCTURE FOR PAYMENT METHODS
// ---------------------------------------------------------

enum PaymentCategory { mobileWallet, card, netBanking }

class PaymentMethod {
  final String id;
  final String name;
  final String logoPath; // Image assets
  final IconData? fallbackIcon;
  final Color brandColor;
  final double? balance;
  final String processingTime;
  final String? cashbackBadge;
  final bool isRecommended;
  final PaymentCategory category;

  const PaymentMethod({
    required this.id,
    required this.name,
    this.logoPath = '',
    this.fallbackIcon,
    required this.brandColor,
    this.balance,
    required this.processingTime,
    this.cashbackBadge,
    this.isRecommended = false,
    required this.category,
  });
}

// ---------------------------------------------------------
// GATEWAY TRANSACTION MODEL
// ---------------------------------------------------------

enum GatewayTxStatus { completed, pending, failed, refunded }

class GatewayTransaction {
  final String orderId;
  final String transactionId;
  final String merchantName;
  final String serviceName;
  final double amount;
  final double fee;
  final double vat;
  final DateTime dateTime;
  final String paymentMethodName;
  final String reference;
  final GatewayTxStatus status;
  final String? failureReason;

  double get total => amount + fee + vat;

  const GatewayTransaction({
    required this.orderId,
    required this.transactionId,
    required this.merchantName,
    required this.serviceName,
    required this.amount,
    required this.fee,
    required this.vat,
    required this.dateTime,
    required this.paymentMethodName,
    required this.reference,
    required this.status,
    this.failureReason,
  });

  GatewayTransaction copyWith({
    GatewayTxStatus? status,
    String? failureReason,
    String? paymentMethodName,
    double? amount,
    double? fee,
    double? vat,
    String? serviceName,
    String? merchantName,
    String? reference,
  }) {
    return GatewayTransaction(
      orderId: orderId,
      transactionId: transactionId,
      merchantName: merchantName ?? this.merchantName,
      serviceName: serviceName ?? this.serviceName,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      vat: vat ?? this.vat,
      dateTime: dateTime,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

// ---------------------------------------------------------
// 0. GATEWAY SETUP SCREEN (Makes Amount & Purposes Dynamic)
// ---------------------------------------------------------
class GatewaySetupWidget extends StatefulWidget {
  final List<AccountModel> accounts;
  final AccountModel? initialAccount;
  final ValueChanged<GatewayTransaction> onSetupComplete;
  final bool isDark;

  const GatewaySetupWidget({
    super.key,
    required this.accounts,
    this.initialAccount,
    required this.onSetupComplete,
    required this.isDark,
  });

  @override
  State<GatewaySetupWidget> createState() => _GatewaySetupWidgetState();
}

class _GatewaySetupWidgetState extends State<GatewaySetupWidget> {
  final _amountController = TextEditingController(text: '50.00');
  final _refController = TextEditingController(text: 'Recharge');
  String _purpose = 'Mobile Recharge'; // Utility Bill, Mobile Recharge, Merchant Pay, Add Money
  AccountModel? _selectedAccount;

  @override
  void initState() {
    super.initState();
    // Default to MFS account if possible, or fallback to first
    final mfsList = widget.accounts.where((a) => a.type == AccountType.mfs).toList();
    _selectedAccount = widget.initialAccount ?? (mfsList.isNotEmpty ? mfsList.first : (widget.accounts.isNotEmpty ? widget.accounts.first : null));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add or select a CashTrack account first.')),
      );
      return;
    }

    final isAddMoney = _purpose == 'Add Money';
    if (!isAddMoney && amount > _selectedAccount!.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance in ${_selectedAccount!.name} (Available: ৳${_selectedAccount!.balance.toStringAsFixed(2)})')),
      );
      return;
    }

    final now = DateTime.now();
    final fee = _purpose == 'Utility Bill' ? 10.00 : 0.00;
    final vat = amount * 0.05; // 5% VAT simulation

    final tx = GatewayTransaction(
      orderId: 'ORD-${1000 + now.millisecond}',
      transactionId: 'TXN-SSL-${now.millisecondsSinceEpoch ~/ 1000}',
      merchantName: isAddMoney ? 'CashTrack Wallet Deposit' : 'Software Shop Ltd',
      serviceName: _purpose,
      amount: amount,
      fee: fee,
      vat: vat,
      dateTime: now,
      paymentMethodName: _selectedAccount!.name,
      reference: _refController.text.trim().isNotEmpty ? _refController.text.trim() : 'Payment Gateway Portal',
      status: GatewayTxStatus.pending,
    );

    widget.onSetupComplete(tx);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final border = widget.isDark ? Colors.white12 : AppColors.lightBorder;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.payment_rounded, size: 48, color: Color(0xFF1F6FEB)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Finance Payment Setup',
              style: AppTextStyles.headingMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Choose payment details to dynamically initialize the SSLCommerz simulator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account selector
                const Text('Source Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<AccountModel>(
                  initialValue: _selectedAccount,
                  isExpanded: true, // Prevents right overflow by constraining dropdown text
                  dropdownColor: cardBg,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.accounts.map((acc) {
                    return DropdownMenuItem<AccountModel>(
                      value: acc,
                      child: Text(
                        '${acc.name} (Balance: ৳${acc.balance.toStringAsFixed(2)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAccount = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Payment Purpose
                const Text('Checkout Purpose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _purpose,
                  isExpanded: true, // Prevents right overflow by constraining dropdown text
                  dropdownColor: cardBg,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Utility Bill', child: Text('Utility Bill Payment (Charge ৳10)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Mobile Recharge', child: Text('Mobile Recharge', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Merchant Pay', child: Text('Merchant Checkout', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Internet Bill', child: Text('Internet & Broadband Bill', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Education Fee', child: Text('Education & Tuition Fees', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Card Bill', child: Text('Credit Card Bill Pay', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'E-Commerce Checkout', child: Text('E-Commerce Online Shopping', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Travel Ticket', child: Text('Bus / Train / Air Ticket', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Donation', child: Text('Donation & Charity', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Subscription', child: Text('Online Service Subscription', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Add Money', child: Text('Add Money / Deposit', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _purpose = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Payment Amount
                const Text('Payment Amount (BDT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                // Helper quick select chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [50, 100, 271, 500, 1000].map((amt) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _amountController.text = amt.toDouble().toStringAsFixed(2);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('৳$amt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F6FEB))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Reference Note
                const Text('Payment Note / Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _refController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6FEB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Proceed to Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. CHECKOUT SCREEN WIDGET
// ---------------------------------------------------------
class CheckoutScreenWidget extends StatelessWidget {
  final GatewayTransaction tx;
  final VoidCallback onContinue;
  final bool isDark;

  const CheckoutScreenWidget({
    super.key,
    required this.tx,
    required this.onContinue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx.merchantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingMd.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ORDER ID: ${tx.orderId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: const Color(0xFF1F6FEB),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.white10),
              ),
              _buildDetailRow('Transaction ID', tx.transactionId, isDark),
              const SizedBox(height: 12),
              _buildDetailRow('Payment Note', tx.reference, isDark),
              const SizedBox(height: 12),
              _buildDetailRow('Order Amount', '৳${tx.amount.toStringAsFixed(2)}', isDark),
              const SizedBox(height: 12),
              _buildDetailRow('Processing Fee', '৳${tx.fee.toStringAsFixed(2)}', isDark),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.white10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Payable',
                    style: AppTextStyles.headingSm.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '৳${tx.total.toStringAsFixed(2)}',
                    style: AppTextStyles.headingLg.copyWith(
                      color: const Color(0xFF1F6FEB),
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F6FEB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 20),
              const SizedBox(width: 10),
              Text(
                'Continue Payment',
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: secondaryTextColor),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by SSLCommerz',
                    style: AppTextStyles.bodySm.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: isDark ? Colors.white : AppColors.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// 2. PAYMENT METHOD SELECTION WIDGET (Teletalk Recharge Grid)
// ---------------------------------------------------------
class MethodSelectionWidget extends StatefulWidget {
  final List<PaymentMethod> methods;
  final double totalAmount;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final VoidCallback onBack;
  final bool isDark;

  const MethodSelectionWidget({
    super.key,
    required this.methods,
    required this.totalAmount,
    required this.onMethodSelected,
    required this.onBack,
    required this.isDark,
  });

  @override
  State<MethodSelectionWidget> createState() => _MethodSelectionWidgetState();
}

class _MethodSelectionWidgetState extends State<MethodSelectionWidget> {
  int _activeTabIndex = 1; // Default to Mobile Banking (Index 1)
  PaymentMethod? _tempSelected;

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF4CAF50); // Teletalk green header color
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;

    // Filter wallets by tab category
    final PaymentCategory currentCategory = _activeTabIndex == 0
        ? PaymentCategory.card
        : (_activeTabIndex == 1 ? PaymentCategory.mobileWallet : PaymentCategory.netBanking);

    // Mock net banking options if selected
    final List<dynamic> currentItems = currentCategory == PaymentCategory.netBanking
        ? [
            const _GridWalletItem(id: 'ibbl', name: 'Islami Bank', color: Color(0xFF008000)),
            const _GridWalletItem(id: 'city', name: 'City Bank', color: Color(0xFFED1C24)),
            const _GridWalletItem(id: 'dbbl', name: 'DBBL Nexus', color: Color(0xFF003893)),
            const _GridWalletItem(id: 'brac', name: 'BRAC Bank', color: Color(0xFF005A9C)),
          ]
        : (currentCategory == PaymentCategory.card
            ? [
                const _GridWalletItem(id: 'visa', name: 'Visa Card', color: Color(0xFF1A1F71), isCard: true),
                const _GridWalletItem(id: 'mastercard', name: 'Mastercard', color: Color(0xFFEB001B), isCard: true),
                const _GridWalletItem(id: 'amex', name: 'Amex Card', color: Color(0xFF007CC3), isCard: true),
              ]
            : [
                // Mobile banking options - bKash added first!
                const _GridWalletItem(id: 'bkash', name: 'bKash', color: Color(0xFFE2125A), logoPath: 'assets/images/bkash.png'),
                const _GridWalletItem(id: 'rocket', name: 'Rocket', color: Color(0xFF8C3494), logoPath: 'assets/images/rocket.png'),
                const _GridWalletItem(id: 'nagad', name: 'Nagad', color: Color(0xFFF04A23), logoPath: 'assets/images/nagad.png'),
                const _GridWalletItem(id: 'upay', name: 'Upay', color: Color(0xFF0052B4)),
                const _GridWalletItem(id: 'cellfin', name: 'CellFin', color: Color(0xFF22519E)),
                const _GridWalletItem(id: 'mcash', name: 'MCash', color: Color(0xFF1B6A47)),
                const _GridWalletItem(id: 'cashbaba', name: 'CashBaba', color: Color(0xFF008B8B)),
                const _GridWalletItem(id: 'pocket', name: 'Pocket', color: Color(0xFFFF4500)),
                const _GridWalletItem(id: 'stpay', name: 'ST Pay', color: Color(0xFF4B0082)),
                const _GridWalletItem(id: 'pathaopay', name: 'Pathao Pay', color: Color(0xFFFF5E00)),
                const _GridWalletItem(id: 'tap', name: 'Tap', color: Color(0xFF0A75BC)),
                const _GridWalletItem(id: 'okwallet', name: 'OK Wallet', color: Color(0xFF006F3C)),
                const _GridWalletItem(id: 'meghnapay', name: 'Meghna Pay', color: Color(0xFF00A2E8)),
              ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Screenshot layout header: Green "Recharge" bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                onPressed: widget.onBack,
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Recharge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balancing back button spacing
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Circle Teletalk Logo + Title info
        Center(
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'CT',
                  style: TextStyle(color: themeColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Software Shop Ltd',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Support FAQ Offers Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoundIconBtn(Icons.headset_mic_outlined, 'Support', textColor),
            _buildRoundIconBtn(Icons.help_outline_rounded, 'FAQ', textColor),
            _buildRoundIconBtn(Icons.card_giftcard_rounded, 'Offers', textColor),
            _buildRoundIconBtn(Icons.login_rounded, 'Login', textColor),
          ],
        ),
        const SizedBox(height: 16),
        // Custom Tab Segment indicators
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildTabButton(0, 'CARDS'),
              _buildTabButton(1, 'MOBILE BANKING'),
              _buildTabButton(2, 'NET BANKING'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Please choose your payment method below',
            style: TextStyle(color: secondaryTextColor, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
        // Grid of wallets
        Expanded(
          child: GridView.builder(
            itemCount: currentItems.length,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (ctx, idx) {
              final item = currentItems[idx];
              final isSelected = _tempSelected?.id == item.id;
              final borderTheme = isSelected ? themeColor : Colors.grey.shade300;

              return InkWell(
                onTap: () {
                  setState(() {
                    _tempSelected = PaymentMethod(
                      id: item.id,
                      name: item.name,
                      logoPath: item.logoPath ?? '',
                      fallbackIcon: item.isCard == true ? Icons.credit_card : Icons.wallet,
                      brandColor: item.color,
                      processingTime: 'Instant',
                      category: currentCategory,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? themeColor.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderTheme, width: isSelected ? 2.5 : 1.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.logoPath != null)
                        Image.asset(
                          item.logoPath!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Icon(Icons.wallet, color: item.color, size: 24),
                        )
                      else
                        Icon(
                          item.isCard == true ? Icons.credit_card : Icons.account_balance_rounded,
                          color: item.color,
                          size: 24,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Floating Pay grey bottom bar
        InkWell(
          onTap: _tempSelected == null
              ? null
              : () => widget.onMethodSelected(_tempSelected!),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _tempSelected == null ? Colors.grey.shade300 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: _tempSelected == null ? Colors.black26 : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'PAY ${widget.totalAmount.toStringAsFixed(2)} BDT',
                  style: TextStyle(
                    color: _tempSelected == null ? Colors.black38 : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundIconBtn(IconData icon, String label, Color textColor) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, color: Colors.blue.shade800, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isActive = _activeTabIndex == index;
    const activeBg = Color(0xFF4CAF50); // Active tab green highlight
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
            _tempSelected = null; // Reset selection
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridWalletItem {
  final String id;
  final String name;
  final Color color;
  final String? logoPath;
  final bool? isCard;

  const _GridWalletItem({
    required this.id,
    required this.name,
    required this.color,
    this.logoPath,
    this.isCard,
  });
}

// ---------------------------------------------------------
// 3. PAYMENT CONFIRMATION WIDGET
// ---------------------------------------------------------
class PaymentConfirmationWidget extends StatefulWidget {
  final GatewayTransaction tx;
  final PaymentMethod method;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final bool isDark;

  const PaymentConfirmationWidget({
    super.key,
    required this.tx,
    required this.method,
    required this.onConfirm,
    required this.onBack,
    required this.isDark,
  });

  @override
  State<PaymentConfirmationWidget> createState() => _PaymentConfirmationWidgetState();
}

class _PaymentConfirmationWidgetState extends State<PaymentConfirmationWidget> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isDark ? const Color(0xFF1E1E24) : Colors.white;
    final border = widget.isDark ? Colors.white12 : AppColors.lightBorder;
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 8),
            Text(
              'Confirm Payment',
              style: AppTextStyles.headingMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'Payable Amount',
                      style: AppTextStyles.bodySm.copyWith(color: secondaryTextColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '৳${widget.tx.total.toStringAsFixed(2)}',
                      style: AppTextStyles.displaySm.copyWith(
                        color: const Color(0xFF1F6FEB),
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'to ${widget.tx.merchantName}',
                      style: AppTextStyles.bodySm.copyWith(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1, color: Colors.white10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Method', style: TextStyle(color: secondaryTextColor)),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.method.brandColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: widget.method.logoPath.isNotEmpty
                            ? Image.asset(
                                widget.method.logoPath,
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => Icon(
                                  widget.method.fallbackIcon ?? Icons.payment,
                                  color: widget.method.brandColor,
                                  size: 14,
                                ),
                              )
                            : Icon(
                                widget.method.fallbackIcon ?? Icons.credit_card_rounded,
                                color: widget.method.brandColor,
                                size: 14,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.method.name,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBreakdownRow('Subtotal', '৳${widget.tx.amount.toStringAsFixed(2)}', secondaryTextColor, textColor),
              const SizedBox(height: 10),
              _buildBreakdownRow('Processing Fee', '৳${widget.tx.fee.toStringAsFixed(2)}', secondaryTextColor, textColor),
              const SizedBox(height: 10),
              _buildBreakdownRow('VAT (Included)', '৳${widget.tx.vat.toStringAsFixed(2)}', secondaryTextColor, textColor),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1, color: Colors.white10),
              ),
              _buildBreakdownRow(
                'Total Payable',
                '৳${widget.tx.total.toStringAsFixed(2)}',
                textColor.withValues(alpha: 0.9),
                const Color(0xFF1F6FEB),
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: _agreedToTerms,
              activeColor: const Color(0xFF1F6FEB),
              side: BorderSide(color: border),
              onChanged: (val) {
                setState(() {
                  _agreedToTerms = val ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                'I agree to the CashTrack and SSLCommerz payment terms, refund policy, and merchant rules.',
                style: AppTextStyles.bodySm.copyWith(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _agreedToTerms ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F6FEB),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Confirm & Authenticate',
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color labelColor, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 18 : 13,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// 4. LOADING SCREEN WIDGET
// ---------------------------------------------------------
class LoadingScreenWidget extends StatefulWidget {
  final VoidCallback onFinishLoading;
  final bool isDark;

  const LoadingScreenWidget({
    super.key,
    required this.onFinishLoading,
    required this.isDark,
  });

  @override
  State<LoadingScreenWidget> createState() => _LoadingScreenWidgetState();
}

class _LoadingScreenWidgetState extends State<LoadingScreenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _statusIndex = 0;
  double _progress = 0.0;
  Timer? _timer;

  final List<String> _statusMessages = [
    'Encrypting transaction...',
    'Connecting to payment gateway...',
    'Verifying merchant credibility...',
    'Securing authentication payload...',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.25;
        if (_statusIndex < _statusMessages.length - 1) {
          _statusIndex++;
        }
      });

      if (_progress >= 1.0) {
        timer.cancel();
        widget.onFinishLoading();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: RotationTransition(
                  turns: _rotationController,
                  child: CircularProgressIndicator(
                    value: 0.6,
                    strokeWidth: 4,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF1F6FEB).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 52,
                  color: Color(0xFF1F6FEB),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Text(
          'Connecting to SSLCommerz',
          style: AppTextStyles.headingMd.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessages[_statusIndex],
            key: ValueKey(_statusIndex),
            style: AppTextStyles.bodySm.copyWith(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F6FEB)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close the application.',
                style: TextStyle(
                  color: secondaryTextColor.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// ---------------------------------------------------------
// 5. WALLET PORTAL AUTHENTICATION WIDGET (Nagad/bKash/Rocket layouts)
// ---------------------------------------------------------
class WalletAuthWidget extends StatefulWidget {
  final PaymentMethod method;
  final double amount;
  final ValueChanged<Map<String, String>> onAuthCompleted; // phone, pin, otp
  final VoidCallback onBack;
  final bool isDark;

  const WalletAuthWidget({
    super.key,
    required this.method,
    required this.amount,
    required this.onAuthCompleted,
    required this.onBack,
    required this.isDark,
  });

  @override
  State<WalletAuthWidget> createState() => _WalletAuthWidgetState();
}

class _WalletAuthWidgetState extends State<WalletAuthWidget> {
  int _portalState = 0; // 0: Account Number, 1: OTP, 2: PIN
  final List<String> _phoneDigits = [];
  final List<String> _otpDigits = [];
  final List<String> _pinDigits = [];
  bool _isKeyboardVisible = false; // Controls custom keyboard visibility dynamically

  final String _mockInvoiceNo = 'NG32858260711J141844';

  void _handleDigitTap(String digit) {
    setState(() {
      if (_portalState == 0) {
        if (_phoneDigits.length < 11) {
          _phoneDigits.add(digit);
        }
      } else if (_portalState == 1) {
        // Dynamic custom verification code (OTP) set to 4 digits!
        if (_otpDigits.length < 4) {
          _otpDigits.add(digit);
        }
      } else if (_portalState == 2) {
        if (_pinDigits.length < 4) {
          _pinDigits.add(digit);
        }
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_portalState == 0) {
        if (_phoneDigits.isNotEmpty) _phoneDigits.removeLast();
      } else if (_portalState == 1) {
        if (_otpDigits.isNotEmpty) _otpDigits.removeLast();
      } else if (_portalState == 2) {
        if (_pinDigits.isNotEmpty) _pinDigits.removeLast();
      }
    });
  }

  void _handleProceed() {
    if (_portalState == 0) {
      if (_phoneDigits.length == 11) {
        setState(() {
          _portalState = 1;
          _isKeyboardVisible = false; // keyboard collapses on transition until they tap next boxes
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter 11 digit account number.')),
        );
      }
    } else if (_portalState == 1) {
      // Dynamic verification code OTP is 4 digits
      if (_otpDigits.length == 4) {
        setState(() {
          _portalState = 2;
          _isKeyboardVisible = false; // keyboard collapses on transition
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter 4 digit verification OTP.')),
        );
      }
    } else if (_portalState == 2) {
      if (_pinDigits.length == 4) {
        widget.onAuthCompleted({
          'phone': _phoneDigits.join(''),
          'otp': _otpDigits.join(''),
          'pin': _pinDigits.join(''),
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter 4 digit PIN.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Branded backgrounds: Nagad Red, bKash Pink, Rocket Violet/Purple
    Color portalBg;
    if (widget.method.id == 'nagad') {
      portalBg = const Color(0xFFA51D24);
    } else if (widget.method.id == 'bkash') {
      portalBg = const Color(0xFFE2125A);
    } else if (widget.method.id == 'rocket') {
      portalBg = const Color(0xFF8C3494);
    } else {
      portalBg = widget.method.brandColor;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isKeyboardVisible = false; // Tap outside to dismiss keyboard
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: portalBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrollable top area to avoid bottom overflows on smaller screens
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cart merchant header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Software Shop Ltd',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white70),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Eng',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    // Invoice specs card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice No: $_mockInvoiceNo', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('Total Amount: BDT ${widget.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Charge: BDT 0', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Dynamic Forms
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (_portalState == 0) _buildSegmentedPhoneEntry(portalBg),
                          if (_portalState == 1) _buildOtpEntryView(),
                          if (_portalState == 2) _buildPinEntryView(),
                          const SizedBox(height: 16),
                          // Proceed / Close Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _handleProceed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: portalBg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Proceed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: widget.onBack,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Footer Logo
                    Center(
                      child: Opacity(
                        opacity: 0.9,
                        child: Column(
                          children: [
                            if (widget.method.logoPath.isNotEmpty)
                              Image.asset(widget.method.logoPath, height: 26, errorBuilder: (c, e, s) => const SizedBox())
                            else
                              Text(
                                widget.method.name,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Custom Sliding Numeric Keyboard (Anchored, resized to be larger)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              height: _isKeyboardVisible ? 230.0 : 0.0, // Expanded height to make keys comfortable to press
              color: _isKeyboardVisible ? Colors.white : Colors.transparent, // Prevents bottom leakage
              child: ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _buildPortalKeypad(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segmented Account digits: [0][1][7]-[1][2][3][4]-[5][6][7][8]
  Widget _buildSegmentedPhoneEntry(Color themeColor) {
    return Column(
      children: [
        Text(
          'Your ${widget.method.name} Account Number',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // InkWell triggers dynamic custom keyboard sliding up on click
        GestureDetector(
          onTap: () {
            setState(() {
              _isKeyboardVisible = true;
            });
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDigitBox(0),
                _buildDigitBox(1),
                _buildDigitBox(2),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('-', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                _buildDigitBox(3),
                _buildDigitBox(4),
                _buildDigitBox(5),
                _buildDigitBox(6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('-', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                _buildDigitBox(7),
                _buildDigitBox(8),
                _buildDigitBox(9),
                _buildDigitBox(10),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'By clicking/tapping "Proceed" you are agreeing to our Terms and Conditions',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildDigitBox(int index) {
    final hasVal = _phoneDigits.length > index;
    final val = hasVal ? _phoneDigits[index] : '';
    return Container(
      width: 22,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        val,
        style: TextStyle(
          color: widget.method.brandColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // OTP Entry field: [ X X X X ] (Resized to 4 digits for Nagad/bKash standard)
  Widget _buildOtpEntryView() {
    final codeString = List.generate(4, (idx) {
      if (_otpDigits.length > idx) {
        return _otpDigits[idx];
      }
      return 'X';
    }).join(' ');

    return Column(
      children: [
        const Text(
          'Enter Verification Code [OTP]',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // Tap triggers keyboard display
        GestureDetector(
          onTap: () {
            setState(() {
              _isKeyboardVisible = true;
            });
          },
          child: Container(
            width: 160,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              codeString,
              style: TextStyle(
                color: widget.method.brandColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'By clicking/tapping "Proceed" you are agreeing to our Terms and Conditions',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    );
  }

  // PIN Entry boxes: [ • ] [ • ] [ • ] [ • ] (Explicitly 4 Digit verification pin)
  Widget _buildPinEntryView() {
    return Column(
      children: [
        const Text(
          'Enter PIN',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        // Tap triggers custom keyboard sliding
        GestureDetector(
          onTap: () {
            setState(() {
              _isKeyboardVisible = true;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (idx) {
              final hasVal = _pinDigits.length > idx;
              return Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: hasVal
                    ? Text(
                        '•',
                        style: TextStyle(
                          color: widget.method.brandColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              );
            }),
          ),
        ),
      ],
    );
  }

  // Virtual Keypad
  Widget _buildPortalKeypad() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              _buildKey('0'),
              Expanded(
                child: InkWell(
                  onTap: _handleBackspace,
                  child: Container(
                    height: 52, // Expanded keyboard row keys for comfort
                    alignment: Alignment.center,
                    child: const Icon(Icons.backspace_rounded, color: Colors.black87, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _handleDigitTap(digit);
        },
        child: Container(
          height: 52, // Expanded keyboard row keys for comfort
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20, // Enlarged font sizing
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 6. PAYMENT PROCESSING TIMELINE WIDGET
// ---------------------------------------------------------
class ProcessingTimelineWidget extends StatefulWidget {
  final VoidCallback onProcessingFinished;
  final bool isDark;

  const ProcessingTimelineWidget({
    super.key,
    required this.onProcessingFinished,
    required this.isDark,
  });

  @override
  State<ProcessingTimelineWidget> createState() => _ProcessingTimelineWidgetState();
}

class _ProcessingTimelineWidgetState extends State<ProcessingTimelineWidget> {
  int _activeTimelineIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 6;

  final List<String> _steps = [
    'Request Sent',
    'Merchant Verified',
    'Wallet Authorized',
    'Payment Processing',
    'Transaction Complete',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) return;
      setState(() {
        if (_activeTimelineIndex < _steps.length - 1) {
          _activeTimelineIndex++;
          if (_remainingSeconds > 1) {
            _remainingSeconds -= 1;
          }
        } else {
          timer.cancel();
          widget.onProcessingFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _activeTimelineIndex == _steps.length - 1
                        ? const Color(0xFF34C759)
                        : const Color(0xFF1F6FEB),
                  ),
                ),
              ),
              Icon(
                _activeTimelineIndex == _steps.length - 1
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_top_rounded,
                size: 38,
                color: _activeTimelineIndex == _steps.length - 1
                    ? const Color(0xFF34C759)
                    : const Color(0xFF1F6FEB),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Processing Payment',
          style: AppTextStyles.headingMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Estimated remaining: $_remainingSeconds seconds',
          style: TextStyle(color: secondaryTextColor, fontSize: 13),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final isDone = index < _activeTimelineIndex;
                final isActive = index == _activeTimelineIndex;
                final circleColor = isDone
                    ? const Color(0xFF34C759)
                    : (isActive ? const Color(0xFF1F6FEB) : Colors.grey.shade400);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: circleColor.withValues(alpha: 0.15),
                            border: Border.all(color: circleColor, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: isDone
                              ? const Icon(Icons.check, size: 12, color: Color(0xFF34C759))
                              : (isActive
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1F6FEB),
                                      ),
                                    )
                                  : null),
                        ),
                        if (index < _steps.length - 1)
                          Container(
                            width: 2,
                            height: 36,
                            color: isDone ? const Color(0xFF34C759) : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _steps[index],
                        style: TextStyle(
                          color: isActive ? textColor : secondaryTextColor,
                          fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// 7 & 8. STATUS RESULT WIDGET (Merchant Redirect Success / Failure)
// ---------------------------------------------------------
class StatusResultWidget extends StatefulWidget {
  final GatewayTransaction tx;
  final VoidCallback onViewTransaction;
  final VoidCallback onReturnHome;
  final VoidCallback onRetry;
  final VoidCallback onChangeMethod;
  final bool isDark;

  const StatusResultWidget({
    super.key,
    required this.tx,
    required this.onViewTransaction,
    required this.onReturnHome,
    required this.onRetry,
    required this.onChangeMethod,
    required this.isDark,
  });

  @override
  State<StatusResultWidget> createState() => _StatusResultWidgetState();
}

class _StatusResultWidgetState extends State<StatusResultWidget> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _bouncingController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _bouncingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    if (widget.tx.status == GatewayTxStatus.completed) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bouncingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.tx.status == GatewayTxStatus.completed;
    final surfaceColor = widget.isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Centered circular checkmark
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSuccess
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                              : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 58,
                          color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSuccess ? 'Thanks for your order!' : 'Payment Failed',
                      style: AppTextStyles.headingLg.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Amount specs
                    Text(
                      'Payment Amount',
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.tx.total.toStringAsFixed(2)} BDT',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSuccess)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Complete',
                              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Reference info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reference ID', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.tx.transactionId,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied reference ID!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                            child: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Redirecting details
                    if (isSuccess) ...[
                      Text(
                        'Redirecting to Merchant Site',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This may take a few seconds..',
                        style: TextStyle(color: secondaryTextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      // Animating loader dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (idx) {
                          return ScaleTransition(
                            scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _bouncingController,
                                curve: Interval(idx * 0.2, 0.6 + idx * 0.2, curve: Curves.easeInOut),
                              ),
                            ),
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Action actions
            if (isSuccess) ...[
              ElevatedButton(
                onPressed: widget.onViewTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: widget.onReturnHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: widget.isDark ? Colors.white24 : AppColors.lightBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Return Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: widget.onReturnHome,
                  child: Text(
                    'Not redirecting within 10 sec ? click here...',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: widget.onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: widget.onChangeMethod,
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: widget.isDark ? Colors.white24 : AppColors.lightBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Change Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// 9. TRANSACTION DETAILS (Invoice) WIDGET
// ---------------------------------------------------------
class InvoiceDetailsWidget extends StatelessWidget {
  final GatewayTransaction tx;
  final VoidCallback onBack;
  final bool isDark;

  const InvoiceDetailsWidget({
    super.key,
    required this.tx,
    required this.onBack,
    required this.isDark,
  });

  // Generates a real PDF file using the pdf library and opens the native sharing tray
  Future<void> _generateAndShareInvoice(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CASH TRACK RECEIPT', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Secure Finance Payment Gateway', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Text('Completed', style: pw.TextStyle(fontSize: 12, color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(tx.merchantName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(tx.serviceName, style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('DATE & TIME:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(DateFormat('dd-MMM-yyyy hh:mm a').format(tx.dateTime), style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Order ID', style: const pw.TextStyle(fontSize: 9)), pw.Text(tx.orderId, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Transaction ID', style: const pw.TextStyle(fontSize: 9)), pw.Text(tx.transactionId, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Gateway Vendor', style: const pw.TextStyle(fontSize: 9)), pw.Text('SSLCommerz (Local Host)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Payment Channel', style: const pw.TextStyle(fontSize: 9)), pw.Text(tx.paymentMethodName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.SizedBox(height: 16),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Base Amount', style: const pw.TextStyle(fontSize: 9)), pw.Text('BDT ${tx.amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Processing Fee', style: const pw.TextStyle(fontSize: 9)), pw.Text('BDT ${tx.fee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('VAT (15%)', style: const pw.TextStyle(fontSize: 9)), pw.Text('BDT ${tx.vat.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9))]),
                  pw.SizedBox(height: 12),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Paid Amount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('BDT ${tx.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                  pw.SizedBox(height: 48),
                  pw.Center(
                    child: pw.Text('Thank you for choosing CashTrack secure gateway payment.', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save to a temporary file
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/cashtrack_invoice_${tx.orderId}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Trigger native share dialog using share_plus
      final xFile = XFile(file.path);
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'CashTrack secure gateway payment receipt for Order ${tx.orderId}',
        ),
      );
    } catch (e) {
      debugPrint('Share Invoice Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share receipt: $e')),
        );
      }
    }
  }

  // Generates a real PDF file using the pdf library and downloads it to local directory
  Future<void> _downloadInvoice(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CASH TRACK RECEIPT', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Secure Finance Payment Gateway', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Text('Completed', style: pw.TextStyle(fontSize: 12, color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(tx.merchantName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(tx.serviceName, style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('DATE & TIME:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(DateFormat('dd-MMM-yyyy hh:mm a').format(tx.dateTime), style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Order ID', style: const pw.TextStyle(fontSize: 9)), pw.Text(tx.orderId, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Transaction ID', style: const pw.TextStyle(fontSize: 9)), pw.Text(tx.transactionId, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Gateway Vendor', style: const pw.TextStyle(fontSize: 9)), pw.Text('SSLCommerz (Local Host)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Payment Channel', style: const pw.TextStyle(fontSize: 9)), pw.Text(tx.paymentMethodName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))]),
                  pw.SizedBox(height: 16),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Base Amount', style: const pw.TextStyle(fontSize: 9)), pw.Text('BDT ${tx.amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Processing Fee', style: const pw.TextStyle(fontSize: 9)), pw.Text('BDT ${tx.fee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9))]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('VAT (15%)', style: const pw.TextStyle(fontSize: 9)), pw.Text('BDT ${tx.vat.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9))]),
                  pw.SizedBox(height: 12),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Paid Amount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('BDT ${tx.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                  pw.SizedBox(height: 48),
                  pw.Center(
                    child: pw.Text('Thank you for choosing CashTrack secure gateway payment.', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save to external storage or application documents
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      final path = '${directory!.path}/cashtrack_invoice_${tx.orderId}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved PDF successfully to: $path'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _generateAndShareInvoice(context),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Download Invoice Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Text(
              'Payment Invoice',
              style: AppTextStyles.headingMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scrollable region containing BOTH receipt card AND layout actions to prevent any card bottom overflows!
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RECEIPT', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text('CashTrack Finance Gateway', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                            ],
                          ),
                          _buildStatusBadge(tx.status),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BILL TO:', style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(tx.merchantName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(tx.serviceName, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('DATE & TIME:', style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd-MMM-yyyy').format(tx.dateTime), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(DateFormat('hh:mm a').format(tx.dateTime), style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInvoiceLine('Order ID', tx.orderId, isDark),
                      _buildInvoiceLine('Transaction ID', tx.transactionId, isDark),
                      _buildInvoiceLine('Gateway Vendor', 'SSLCommerz (Local Host)', isDark),
                      _buildInvoiceLine('Payment Channel', tx.paymentMethodName, isDark),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10),
                      ),
                      _buildInvoiceAmountLine('Base Amount', tx.amount, isDark),
                      const SizedBox(height: 10),
                      _buildInvoiceAmountLine('Processing Fee', tx.fee, isDark),
                      const SizedBox(height: 10),
                      _buildInvoiceAmountLine('VAT (15%)', tx.vat, isDark),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount Paid', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                          Text(
                            '৳${tx.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF1F6FEB),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'This receipt is electronically generated and digitally signed. SSLCommerz certified payment flow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadInvoice(context),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                          foregroundColor: textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generateAndShareInvoice(context),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F6FEB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceLine(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              val,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceAmountLine(String label, double val, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          '৳${val.toStringAsFixed(2)}',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightText,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(GatewayTxStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case GatewayTxStatus.completed:
        bg = const Color(0xFF34C759).withValues(alpha: 0.15);
        fg = const Color(0xFF34C759);
        label = 'Completed';
        break;
      case GatewayTxStatus.pending:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade700;
        label = 'Pending';
        break;
      case GatewayTxStatus.failed:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        label = 'Failed';
        break;
      case GatewayTxStatus.refunded:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

// ---------------------------------------------------------
// 10. SECURITY COMPLIANCE BADGE GRID WIDGET
// ---------------------------------------------------------
class SecurityInfoWidget extends StatelessWidget {
  final bool isDark;

  const SecurityInfoWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gridBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;

    final badges = [
      const _SecurityItem(Icons.lock, '256-Bit SSL', 'Encrypted connection'),
      const _SecurityItem(Icons.verified_user_rounded, 'PCI DSS Level 1', 'Compliance standard'),
      const _SecurityItem(Icons.security, 'SSLCommerz', 'Payment vendor verified'),
      const _SecurityItem(Icons.fingerprint, 'Biometric Lock', 'Touch ID authorized'),
      const _SecurityItem(Icons.phonelink_lock_rounded, 'Device Match', 'Hardware verification'),
      const _SecurityItem(Icons.verified_rounded, 'Fraud Shield', 'Active protection'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gridBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_good_rounded, color: Color(0xFF34C759)),
              const SizedBox(width: 8),
              Text(
                'Security Assurance & Compliance',
                style: AppTextStyles.bodyLg.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) {
              final item = badges[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: const Color(0xFF1F6FEB), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.subtitle,
                            style: TextStyle(color: secondaryTextColor, fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecurityItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecurityItem(this.icon, this.title, this.subtitle);
}

// ---------------------------------------------------------
// 11. TRANSACTION HISTORY WIDGET
// ---------------------------------------------------------
class TransactionHistoryWidget extends StatefulWidget {
  final List<GatewayTransaction> transactions;
  final ValueChanged<GatewayTransaction> onTapTransaction;
  final bool isDark;

  const TransactionHistoryWidget({
    super.key,
    required this.transactions,
    required this.onTapTransaction,
    required this.isDark,
  });

  @override
  State<TransactionHistoryWidget> createState() => _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String _timeFilter = 'all'; // all, today, yesterday, 30days
  String _statusFilter = 'all'; // all, completed, failed, refunded
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.lightText;
    final secondaryTextColor = widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final cardBg = widget.isDark ? const Color(0xFF1E1E24) : Colors.white;
    final border = widget.isDark ? Colors.white12 : AppColors.lightBorder;

    final filtered = widget.transactions.where((tx) {
      final matchesSearch = tx.merchantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.transactionId.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_statusFilter != 'all') {
        matchesStatus = tx.status.name == _statusFilter;
      }

      bool matchesTime = true;
      final now = DateTime.now();
      if (_timeFilter == 'today') {
        matchesTime = tx.dateTime.year == now.year && tx.dateTime.month == now.month && tx.dateTime.day == now.day;
      } else if (_timeFilter == 'yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        matchesTime = tx.dateTime.year == yesterday.year &&
            tx.dateTime.month == yesterday.month &&
            tx.dateTime.day == yesterday.day;
      } else if (_timeFilter == '30days') {
        matchesTime = tx.dateTime.isAfter(now.subtract(const Duration(days: 30)));
      }

      return matchesSearch && matchesStatus && matchesTime;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gateway Transaction Logs',
          style: AppTextStyles.headingSm.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Search merchant or ID...',
            hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search, color: secondaryTextColor),
            filled: true,
            fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All Dates', 'all', _timeFilter, (val) => setState(() => _timeFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Today', 'today', _timeFilter, (val) => setState(() => _timeFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Yesterday', 'yesterday', _timeFilter, (val) => setState(() => _timeFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Last 30 Days', '30days', _timeFilter, (val) => setState(() => _timeFilter = val)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All Statuses', 'all', _statusFilter, (val) => setState(() => _statusFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Completed', 'completed', _statusFilter, (val) => setState(() => _statusFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Failed', 'failed', _statusFilter, (val) => setState(() => _statusFilter = val)),
              const SizedBox(width: 8),
              _buildFilterChip('Refunded', 'refunded', _statusFilter, (val) => setState(() => _statusFilter = val)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No transaction matched the filters.',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    final isCompleted = tx.status == GatewayTxStatus.completed;
                    final isFailed = tx.status == GatewayTxStatus.failed;
                    final statusColor = isCompleted
                        ? const Color(0xFF34C759)
                        : (isFailed ? const Color(0xFFEF4444) : Colors.blue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: ListTile(
                        onTap: () => widget.onTapTransaction(tx),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(
                            isCompleted
                                ? Icons.done_rounded
                                : (isFailed ? Icons.close_rounded : Icons.replay_rounded),
                            color: statusColor,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tx.merchantName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            Text('৳${tx.total.toStringAsFixed(2)}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(tx.dateTime),
                              style: TextStyle(color: secondaryTextColor, fontSize: 11),
                            ),
                            Text(
                              tx.paymentMethodName,
                              style: TextStyle(color: secondaryTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_right_rounded, color: secondaryTextColor),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String currentSelected, ValueChanged<String> onSelected) {
    final isSelected = value == currentSelected;
    final bg = isSelected
        ? const Color(0xFF1F6FEB)
        : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03));
    final fg = isSelected ? Colors.white : (widget.isDark ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
