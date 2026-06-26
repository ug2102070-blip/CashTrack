import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/split_expense_model.dart';
import '../providers/app_providers.dart';

class SplitExpensesScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const SplitExpensesScreen({super.key, this.groupId});

  @override
  ConsumerState<SplitExpensesScreen> createState() =>
      _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends ConsumerState<SplitExpensesScreen> {
  List<SplitExpense> _expenses = [];
  bool _loadingExpenses = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void didUpdateWidget(covariant SplitExpensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupId != oldWidget.groupId) {
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
    if (widget.groupId == null) return;
    setState(() => _loadingExpenses = true);
    final repo = ref.read(splitExpenseRepositoryProvider);
    await repo.init();
    final expenses = repo.getExpensesByGroup(widget.groupId!);
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _loadingExpenses = false;
    });
  }

  Future<void> _showAddGroupDialog() async {
    final nameController = TextEditingController();
    final membersController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('create_group')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: context.t('group_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: membersController,
              decoration: InputDecoration(
                labelText: context.t('group_members'),
                hintText: context.t('members_comma_hint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final members = membersController.text
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList();

              if (name.isEmpty || members.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(context.t('enter_valid_amount'))),
                );
                return;
              }

              final group = SplitGroup(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                members: members,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await ref.read(splitGroupsProvider.notifier).addGroup(group);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: Text(context.t('add_group')),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog(SplitGroup group) async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String paidBy = group.members.first;
    final selectedMembers = <String>{...group.members};

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('add_expense')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: context.t('expense_description'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: context.t('amount'),
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paidBy,
                  decoration: InputDecoration(labelText: context.t('paid_by')),
                  items: group.members
                      .map((member) => DropdownMenuItem(
                            value: member,
                            child: Text(member),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => paidBy = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.t('split_among'),
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.members.map((member) {
                    final isSelected = selectedMembers.contains(member);
                    return ChoiceChip(
                      label: Text(member),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedMembers.add(member);
                          } else {
                            selectedMembers.remove(member);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final description = descriptionController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                if (description.isEmpty ||
                    amount == null ||
                    selectedMembers.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(context.t('enter_valid_amount'))),
                  );
                  return;
                }

                final expense = SplitExpense(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  groupId: group.id,
                  description: description,
                  amount: amount,
                  paidBy: paidBy,
                  splitAmong: selectedMembers.toList(),
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final repo = ref.read(splitExpenseRepositoryProvider);
                await repo.init();
                await repo.addExpense(expense);
                await _loadExpenses();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(context.t('add_expense')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(splitGroupsProvider);
    final profile = ref.watch(userProfileProvider);
    final selectedGroup = widget.groupId == null
        ? null
        : groups.firstWhere(
            (group) => group.id == widget.groupId,
            orElse: () => SplitGroup(
              id: widget.groupId!,
              name: context.t('split_expenses'),
              members: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId == null
            ? context.t('split_expenses')
            : selectedGroup?.name ?? context.t('split_expenses')),
        centerTitle: true,
        actions: [
          if (widget.groupId == null)
            IconButton(
              onPressed: _showAddGroupDialog,
              icon: const Icon(Icons.person_add_rounded),
            )
          else if (selectedGroup != null)
            IconButton(
              onPressed: () => _showAddExpenseDialog(selectedGroup),
              icon: const Icon(Icons.add_card_rounded),
              tooltip: context.t('add_expense'),
            ),
        ],
      ),
      floatingActionButton: null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.groupId == null
            ? _buildGroupList(context, groups, profile)
            : _buildGroupDetails(context, selectedGroup, profile),
      ),
    );
  }

  Color _getGroupColor(String name) {
    if (name.isEmpty) return AppColors.primary;
    final hash = name.codeUnits.fold<int>(0, (prev, element) => prev + element);
    final index = hash % AppColors.chartColors.length;
    return AppColors.chartColors[index];
  }

  Widget _buildOverallSummaryCard(
    BuildContext context,
    int groupCount,
    double totalOverallSpent,
    double overallNetBalance,
  ) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String statusLabel;
    final String balanceText;
    final Color balanceColor;
    final IconData statusIcon;
    final Color iconColor;
    final Color iconBgColor;

    if (overallNetBalance > 0.01) {
      statusLabel = isBn ? 'আপনি মোট পাবেন' : 'Overall, you are owed';
      balanceText = '৳${overallNetBalance.toStringAsFixed(2)}';
      balanceColor = AppColors.success;
      statusIcon = Icons.call_received_rounded;
      iconColor = AppColors.success;
      iconBgColor = AppColors.success.withValues(alpha: 0.08);
    } else if (overallNetBalance < -0.01) {
      statusLabel = isBn ? 'আপনি মোট দেবেন' : 'Overall, you owe';
      balanceText = '৳${(-overallNetBalance).toStringAsFixed(2)}';
      balanceColor = AppColors.error;
      statusIcon = Icons.arrow_outward_rounded;
      iconColor = AppColors.error;
      iconBgColor = AppColors.error.withValues(alpha: 0.08);
    } else {
      statusLabel = isBn ? 'সব হিসাব সমান রয়েছে' : 'You are all settled up!';
      balanceText = '৳0.00';
      balanceColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
      statusIcon = Icons.check_circle_outline_rounded;
      iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
      iconBgColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balanceText,
                        style: TextStyle(
                          color: balanceColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'মোট গ্রুপ খরচ' : 'Total Group Spent',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '৳${totalOverallSpent.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    SplitGroup group,
    double totalSpent,
    double yourShare,
    double userPaid,
    bool hasYou,
    bool isBn,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = _getGroupColor(group.name);
    final initial = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';
    final double netBalance = userPaid - yourShare;

    final String balanceLabel;
    final String balanceAmount;
    final Color balanceColor;

    if (!hasYou) {
      balanceLabel = isBn ? 'মেম্বার নন' : 'not a member';
      balanceAmount = '–';
      balanceColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    } else if (netBalance > 0.01) {
      balanceLabel = isBn ? 'পাবেন' : 'you get back';
      balanceAmount = '৳${netBalance.toStringAsFixed(2)}';
      balanceColor = AppColors.success;
    } else if (netBalance < -0.01) {
      balanceLabel = isBn ? 'দেবেন' : 'you owe';
      balanceAmount = '৳${(-netBalance).toStringAsFixed(2)}';
      balanceColor = AppColors.error;
    } else {
      balanceLabel = isBn ? 'সব সমান' : 'settled';
      balanceAmount = '৳0.00';
      balanceColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/split-expenses/${group.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBn ? '${group.members.length} জন সদস্য' : '${group.members.length} members',
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      balanceLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: balanceColor.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balanceAmount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: balanceColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBn ? 'মোট: ৳${totalSpent.toStringAsFixed(2)}' : 'Total: ৳${totalSpent.toStringAsFixed(2)}',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, List<SplitGroup> groups, Map<String, String> profile) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add_rounded,
                size: 42,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.t('no_split_groups'),
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('split_group_empty'),
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddGroupDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.t('create_group')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate overall metrics
    double totalOverallSpent = 0;
    double overallNetBalance = 0;
    
    final repo = ref.read(splitExpenseRepositoryProvider);

    for (final group in groups) {
      final totalExpenses = repo.getExpensesByGroup(group.id);
      final totalSpent = totalExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
      totalOverallSpent += totalSpent;
      
      final userMemberName = group.getUserMemberName(profile);
      final hasYou = group.members.contains(userMemberName);
      if (hasYou) {
        final yourShare = totalExpenses.fold<double>(0, (sum, expense) {
          final share = expense.splitAmong.isEmpty
              ? 0.0
              : expense.amount / expense.splitAmong.length;
          return expense.splitAmong.contains(userMemberName) ? sum + share : sum;
        });
        final userPaid = totalExpenses.where((e) => e.paidBy == userMemberName).fold<double>(0, (sum, e) => sum + e.amount);
        overallNetBalance += (userPaid - yourShare);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverallSummaryCard(context, groups.length, totalOverallSpent, overallNetBalance),
        const SizedBox(height: 20),
        Text(
          isBn ? 'আপনার গ্রুপসমূহ' : 'Your Groups',
          style: AppTextStyles.h5.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: groups.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final group = groups[index];
              final totalExpenses = repo.getExpensesByGroup(group.id);
              final totalSpent = totalExpenses.fold<double>(
                  0, (sum, expense) => sum + expense.amount);
              final userMemberName = group.getUserMemberName(profile);
              final hasYou = group.members.contains(userMemberName);
              final yourShare = hasYou
                  ? totalExpenses.fold<double>(0, (sum, expense) {
                      final share = expense.splitAmong.isEmpty
                          ? 0.0
                          : expense.amount / expense.splitAmong.length;
                      return expense.splitAmong.contains(userMemberName) ? sum + share : sum;
                    })
                  : 0.0;
              final userPaid = totalExpenses.where((e) => e.paidBy == userMemberName).fold<double>(0, (sum, e) => sum + e.amount);

              return _buildGroupCard(context, group, totalSpent, yourShare, userPaid, hasYou, isBn);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDetails(BuildContext context, SplitGroup? group, Map<String, String> profile) {
    if (group == null) {
      return Center(
        child: Text(context.t('no_split_groups')),
      );
    }

    if (_loadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSpent =
        _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final userMemberName = group.getUserMemberName(profile);
    final hasYou = group.members.contains(userMemberName);
    final yourShare = hasYou
        ? _expenses.fold<double>(0, (sum, expense) {
            final share = expense.splitAmong.isEmpty
                ? 0.0
                : expense.amount / expense.splitAmong.length;
            return expense.splitAmong.contains(userMemberName) ? sum + share : sum;
          })
        : 0.0;
    final settlements = SplitSettlement.calculate(_expenses, group.members);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final primary = Theme.of(context).colorScheme.primary;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Redesigned White/Surface Balance Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isBn ? 'মোট গ্রুপ খরচ' : 'Total Group Spent',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '৳${totalSpent.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('your_share'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasYou ? '৳${yourShare.toStringAsFixed(2)}' : '–',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'গ্রুপ সদস্য' : 'Group Members',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.members.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Settlement Summary Header
        Text(
          context.t('settlement_summary'),
          style: AppTextStyles.h5.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),

        // Settlements Cards
        if (settlements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'সব হিসাব সমান রয়েছে!' : 'All balances are settled!',
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...settlements.map((settlement) {
            final isFromYou = settlement.from == userMemberName;
            final isToYou = settlement.to == userMemberName;
            final String text;
            if (isFromYou) {
              text = context.t('you_owe', params: {'to': settlement.to});
            } else if (isToYou) {
              text = context.t('owes_you', params: {'from': settlement.from});
            } else {
              text = context.t('owes', params: {
                'from': settlement.from,
                'to': settlement.to,
              });
            }

            final cardColor = isFromYou
                ? AppColors.error.withValues(alpha: 0.04)
                : (isToYou
                    ? AppColors.success.withValues(alpha: 0.04)
                    : Theme.of(context).colorScheme.surface);
            final borderColor = isFromYou
                ? AppColors.error.withValues(alpha: 0.15)
                : (isToYou
                    ? AppColors.success.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5));
            final iconColor = isFromYou ? AppColors.error : (isToYou ? AppColors.success : Colors.grey);
            final iconBgColor = isFromYou
                ? AppColors.error.withValues(alpha: 0.08)
                : (isToYou
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1));

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFromYou
                          ? Icons.arrow_outward_rounded
                          : (isToYou ? Icons.call_received_rounded : Icons.swap_horiz_rounded),
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFromYou
                              ? (isBn ? 'পরিশোধ করতে হবে' : 'Pending payment')
                              : (isToYou
                                  ? (isBn ? 'পাওনা রয়েছে' : 'Pending collection')
                                  : (isBn ? 'গ্রুপ সেটেলমেন্ট' : 'Group settlement')),
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '৳${settlement.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),

        // Expenses List Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isBn ? 'গ্রুপের খরচসমূহ' : 'Group Expenses',
              style: AppTextStyles.h5.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddExpenseDialog(group),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                isBn ? 'যোগ করুন' : 'Add',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Expenses List
        Expanded(
          child: _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.t('no_transactions'),
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    final dateStr = DateFormat('d MMM y').format(expense.date);
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          expense.description,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${context.t('paid_by')}: ${expense.paidBy} • ${context.t('split_among')}: ${expense.splitAmong.length}',
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${expense.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
