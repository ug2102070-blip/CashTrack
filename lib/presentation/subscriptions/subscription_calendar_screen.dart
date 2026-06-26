import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/detected_subscription_model.dart';
import '../../data/models/transaction_model.dart';
import '../../services/subscription_detector_service.dart';
import '../providers/app_providers.dart';

class SubscriptionCalendarScreen extends ConsumerStatefulWidget {
  const SubscriptionCalendarScreen({super.key});

  @override
  ConsumerState<SubscriptionCalendarScreen> createState() =>
      _SubscriptionCalendarScreenState();
}

class _SubscriptionCalendarScreenState
    extends ConsumerState<SubscriptionCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final categoryMap = {for (final c in categories) c.id: c.name};
    final recurringTransactions = allTransactions
        .where((t) => t.isRecurring && t.recurringType != null)
        .toList();
    final detectedSubscriptions =
        SubscriptionDetectorService().detectSubscriptions(allTransactions);
    final events = _buildRecurringEvents(recurringTransactions);
    final selectedDay = _selectedDay ?? _focusedDay;
    final selectedEvents = _getEventsForDay(selectedDay, events);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('subscription_calendar')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            TableCalendar<TransactionModel>(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              eventLoader: (day) => _getEventsForDay(day, events),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('detected_subscriptions'),
                style: AppTextStyles.h5.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            if (detectedSubscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  context.t('no_detected_subscriptions'),
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  itemCount: detectedSubscriptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = detectedSubscriptions[index];
                    return Container(
                        width: 260,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.merchantName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                              '${item.amount.toStringAsFixed(2)} \u2022 ${item.frequency}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${context.t('subscription_next_expected')}: ${DateFormat('dd MMM yyyy').format(item.nextExpectedDate)}',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await _markSubscriptionRecurring(
                                          context, ref, item);
                                    },
                                    child:
                                        Text(context.t('mark_as_recurring')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('upcoming_recurring_payments'),
                style: AppTextStyles.h5.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: selectedEvents.isEmpty
                  ? Center(
                      child: Text(
                        context.t('recurring_payments_no_data'),
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: selectedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = selectedEvents[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tx.note != null && tx.note!.trim().isNotEmpty
                                          ? tx.note!.trim()
                                          : (categoryMap[tx.categoryId] ?? tx.categoryId),
                                      style: AppTextStyles.body2.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${tx.type == TransactionType.expense ? '-' : '+'}${tx.amount.toStringAsFixed(2)}',
                                    style: AppTextStyles.body2.copyWith(
                                      color: tx.type == TransactionType.expense
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                [
                                  if (tx.note != null && tx.note!.trim().isNotEmpty)
                                    categoryMap[tx.categoryId] ?? tx.categoryId,
                                  DateFormat('EEE, MMM d').format(tx.date),
                                  _recurrenceLabel(context, tx.recurringType),
                                ].join(' \u2022 '),
                                style: AppTextStyles.caption.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<TransactionModel>> _buildRecurringEvents(
      List<TransactionModel> transactions) {
    final Map<DateTime, List<TransactionModel>> data = {};
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final series = <String, TransactionModel>{};

    for (final tx in transactions) {
      final key = _recurringSeriesKey(tx);
      final existing = series[key];
      if (existing == null || tx.date.isBefore(existing.date)) {
        series[key] = tx;
      }
    }

    for (final tx in series.values) {
      final occurrences = _generateOccurrences(tx, firstDay, lastDay);
      for (final occurrence in occurrences) {
        final day = _normalizeDate(occurrence);
        data[day] = [...?data[day], tx.copyWith(date: day)];
      }
    }

    return data;
  }

  String _recurringSeriesKey(TransactionModel tx) {
    final merchant = (tx.note ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return [
      tx.recurringType?.name ?? '',
      tx.accountId,
      tx.categoryId,
      tx.amount.toStringAsFixed(2),
      merchant,
    ].join('|');
  }

  List<TransactionModel> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<TransactionModel>> events,
  ) {
    return events[_normalizeDate(day)] ?? [];
  }

  Future<void> _markSubscriptionRecurring(
    BuildContext context,
    WidgetRef ref,
    DetectedSubscription subscription,
  ) async {
    final notifier = ref.read(transactionsProvider.notifier);
    final transactions = ref
        .read(transactionsProvider)
        .where((tx) => subscription.transactionIds.contains(tx.id))
        .toList();

    for (final tx in transactions) {
      await notifier.updateTransaction(
        tx.copyWith(
          isRecurring: true,
          recurringType: RecurringType.monthly,
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${subscription.merchantName} is now recurring',
        ),
      ),
    );
  }

  List<DateTime> _generateOccurrences(
    TransactionModel transaction,
    DateTime from,
    DateTime to,
  ) {
    if (transaction.recurringType == null) return [];

    final occurrences = <DateTime>[];
    var current = _normalizeDate(transaction.date);
    final endDate = _normalizeDate(to);
    final startDate = _normalizeDate(from);

    while (current.isBefore(startDate)) {
      current = _advanceDate(
        current,
        transaction.recurringType!,
        anchorDay: transaction.date.day,
      );
    }

    while (!current.isAfter(endDate)) {
      if (!current.isBefore(startDate)) {
        occurrences.add(current);
      }
      current = _advanceDate(
        current,
        transaction.recurringType!,
        anchorDay: transaction.date.day,
      );
    }

    return occurrences;
  }

  DateTime _advanceDate(
    DateTime date,
    RecurringType type, {
    int? anchorDay,
  }) {
    switch (type) {
      case RecurringType.daily:
        return date.add(const Duration(days: 1));
      case RecurringType.weekly:
        return date.add(const Duration(days: 7));
      case RecurringType.monthly:
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        final day = anchorDay ?? date.day;
        final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final safeDay = day <= maxDay ? day : maxDay;
        return DateTime(nextMonth.year, nextMonth.month, safeDay);
      case RecurringType.yearly:
        final nextYear = DateTime(date.year + 1, date.month, 1);
        final day = anchorDay ?? date.day;
        final maxDay = DateTime(nextYear.year, nextYear.month + 1, 0).day;
        final safeDay = day <= maxDay ? day : maxDay;
        return DateTime(nextYear.year, nextYear.month, safeDay);
    }
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _recurrenceLabel(BuildContext context, RecurringType? type) {
    switch (type) {
      case RecurringType.daily:
        return context.t('daily');
      case RecurringType.weekly:
        return context.t('weekly');
      case RecurringType.monthly:
        return context.t('monthly');
      case RecurringType.yearly:
        return context.t('yearly');
      default:
        return context.t('once');
    }
  }
}
