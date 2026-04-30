// lib/presentation/goals/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/goal_model.dart';
import '../providers/app_providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();
    final settings = ref.watch(settingsProvider);
    final currency = settings['currency'] ?? '৳';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.t('savings_goals')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context, ref),
          ),
        ],
      ),
      body: activeGoals.isEmpty && completedGoals.isEmpty
          ? _buildEmptyState(context, ref)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeGoals.isNotEmpty) ...[
                    _buildSummaryCard(activeGoals, currency, context),
                    _buildSectionHeader(context.t('active_goals')),
                    ...activeGoals
                        .map((goal) => _buildGoalCard(context, ref, goal)),
                  ],
                  if (completedGoals.isNotEmpty) ...[
                    _buildSectionHeader(context.t('completed_goals')),
                    ...completedGoals
                        .map((goal) => _buildGoalCard(context, ref, goal)),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
      List<GoalModel> goals, String currency, BuildContext context) {
    final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final percentage = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('total_progress'),
                    style: AppTextStyles.body2.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.amountLarge.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.track_changes,
                    color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    context, currency, context.t('saved'), totalSaved),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                    context, currency, context.t('target'), totalTarget),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _buildStatItem(context, currency, context.t('goals'),
                    goals.length.toDouble()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String currency, String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          label == context.t('goals')
              ? value.toStringAsFixed(0)
              : '$currency${value.toStringAsFixed(0)}',
          style: AppTextStyles.h5.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: AppTextStyles.h5),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, GoalModel goal) {
    final percentage =
        goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;
    final daysLeft = goal.deadline?.difference(DateTime.now()).inDays;
    final currency = ref.read(settingsProvider)['currency'] ?? '৳';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: goal.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: goal.isCompleted
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      goal.icon ?? '🎯',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTextStyles.h5.copyWith(
                          decoration: goal.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (daysLeft != null && daysLeft > 0 && !goal.isCompleted)
                        Text(
                          context.t('days_left',
                              params: {'count': daysLeft.toString()}),
                          style: AppTextStyles.caption.copyWith(
                            color: daysLeft < 30
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (goal.isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          context.t('completed'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currency${goal.currentAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$currency${goal.targetAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t('percent_completed', params: {
                        'value': (percentage * 100).toStringAsFixed(0)
                      }),
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      context.t('to_go_amount', params: {
                        'amount': '$currency${remaining.toStringAsFixed(0)}'
                      }),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!goal.isCompleted) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddMoneyDialog(context, ref, goal),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.t('add_money')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showGoalDetails(context, ref, goal),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(context.t('details')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('no_savings_goals'),
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('set_first_goal'),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddGoalDialog(context, ref),
            icon: const Icon(Icons.add),
            label: Text(context.t('create_goal')),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final currency = ref.read(settingsProvider)['currency'] ?? '৳';
    String selectedIcon = '🎯';
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('create_savings_goal')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Selector
                Wrap(
                  spacing: 8,
                  children: ['🎯', '🏠', '🚗', '✈️', '💍', '📱', '🎓', '💰']
                      .map((icon) => InkWell(
                            onTap: () => setState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedIcon == icon
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedIcon == icon
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.t('goal_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.t('target_amount'),
                    prefixText: '$currency ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => deadline = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    deadline != null
                        ? DateFormat('MMM dd, yyyy').format(deadline!)
                        : context.t('set_deadline_optional'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final targetAmount =
                    double.tryParse(amountController.text.trim());
                if (name.isNotEmpty &&
                    targetAmount != null &&
                    targetAmount > 0) {
                  final goal = GoalModel(
                    id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    targetAmount: targetAmount,
                    icon: selectedIcon,
                    deadline: deadline,
                    createdAt: DateTime.now(),
                  );
                  await ref.read(goalsProvider.notifier).addGoal(goal);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('goal_created_success'))),
                  );
                }
              },
              child: Text(context.t('create')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(
      BuildContext context, WidgetRef ref, GoalModel goal) {
    final nameController = TextEditingController(text: goal.name);
    final amountController =
        TextEditingController(text: goal.targetAmount.toString());
    final currency = ref.read(settingsProvider)['currency'] ?? '৳';
    String selectedIcon = goal.icon ?? '🎯';
    DateTime? deadline = goal.deadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('edit_savings_goal')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Selector
                Wrap(
                  spacing: 8,
                  children: ['🎯', '🏠', '🚗', '✈️', '💍', '📱', '🎓', '💰']
                      .map((icon) => InkWell(
                            onTap: () => setState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedIcon == icon
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedIcon == icon
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.t('goal_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.t('target_amount'),
                    prefixText: '$currency ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => deadline = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    deadline != null
                        ? DateFormat('MMM dd, yyyy').format(deadline!)
                        : context.t('set_deadline_optional'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final targetAmount =
                    double.tryParse(amountController.text.trim());
                if (name.isNotEmpty &&
                    targetAmount != null &&
                    targetAmount > 0) {
                  final updatedGoal = goal.copyWith(
                    name: name,
                    targetAmount: targetAmount,
                    icon: selectedIcon,
                    deadline: deadline,
                  );
                  await ref
                      .read(goalsProvider.notifier)
                      .updateGoal(updatedGoal);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('goal_updated_success'))),
                  );
                }
              },
              child: Text(context.t('update')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(
      BuildContext context, WidgetRef ref, GoalModel goal) {
    final amountController = TextEditingController();
    final currency = ref.read(settingsProvider)['currency'] ?? '৳';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('add_money_to', params: {'name': goal.name})),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.t('amount'),
            prefixText: '$currency ',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount != null && amount > 0) {
                final newAmount = goal.currentAmount + amount;
                await ref
                    .read(goalsProvider.notifier)
                    .updateProgress(goal.id, newAmount);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.t('added_amount_to_goal', params: {
                        'amount': '$currency${amount.toStringAsFixed(0)}',
                        'name': goal.name,
                      }),
                    ),
                  ),
                );
              }
            },
            child: Text(context.t('add')),
          ),
        ],
      ),
    );
  }

  void _showGoalDetails(BuildContext context, WidgetRef ref, GoalModel goal) {
    final currency = ref.read(settingsProvider)['currency'] ?? '৳';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goal.name, style: AppTextStyles.h3),
            const SizedBox(height: 24),
            _buildDetailRow(context.t('target'),
                '$currency${goal.targetAmount.toStringAsFixed(0)}'),
            _buildDetailRow(context.t('saved'),
                '$currency${goal.currentAmount.toStringAsFixed(0)}'),
            _buildDetailRow(
              context.t('remaining'),
              '$currency${(goal.targetAmount - goal.currentAmount).toStringAsFixed(0)}',
            ),
            if (goal.deadline != null)
              _buildDetailRow(
                context.t('deadline'),
                DateFormat('MMM dd, yyyy').format(goal.deadline!),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditGoalDialog(context, ref, goal);
              },
              icon: const Icon(Icons.edit),
              label: Text(context.t('edit_goal')),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
