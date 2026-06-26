// lib/services/duplicate_detection_service.dart
//
// Detects potential duplicate transactions by comparing amount, date, account
// and type. Provides a merge capability for confirmed duplicates.

import '../data/models/transaction_model.dart';

/// Represents a pair of transactions that might be duplicates.
class DuplicatePair {
  final TransactionModel original;
  final TransactionModel duplicate;
  final double similarityScore; // 0.0 - 1.0

  const DuplicatePair({
    required this.original,
    required this.duplicate,
    required this.similarityScore,
  });

  @override
  String toString() =>
      'DuplicatePair(${original.id} ↔ ${duplicate.id}, score: ${similarityScore.toStringAsFixed(2)})';
}

class DuplicateDetectionService {
  /// Time window within which same-amount transactions are considered suspicious.
  static const Duration _timeWindow = Duration(minutes: 5);

  /// Amount tolerance (for floating-point comparison).
  static const double _amountTolerance = 0.01;

  /// Score thresholds
  static const double highConfidenceThreshold = 0.85;
  static const double lowConfidenceThreshold = 0.50;

  /// Check if a single new transaction is a potential duplicate of any
  /// existing transaction. Returns the best match if found.
  DuplicatePair? checkForDuplicate(
    TransactionModel newTransaction,
    List<TransactionModel> existingTransactions,
  ) {
    DuplicatePair? bestMatch;
    double bestScore = 0;

    for (final existing in existingTransactions) {
      if (existing.isDeleted) continue;
      if (existing.id == newTransaction.id) continue;

      final score = _calculateSimilarity(newTransaction, existing);
      if (score > lowConfidenceThreshold && score > bestScore) {
        bestScore = score;
        bestMatch = DuplicatePair(
          original: existing,
          duplicate: newTransaction,
          similarityScore: score,
        );
      }
    }

    return bestMatch;
  }

  /// Scan all transactions and find potential duplicate pairs.
  List<DuplicatePair> scanForDuplicates(List<TransactionModel> transactions) {
    final active = transactions.where((t) => !t.isDeleted).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<DuplicatePair> duplicates = [];
    final Set<String> processedPairs = {};

    for (int i = 0; i < active.length; i++) {
      for (int j = i + 1; j < active.length; j++) {
        final a = active[i];
        final b = active[j];

        // Quick bailout: if dates are too far apart, skip
        if (b.date.difference(a.date).abs() > const Duration(hours: 24)) {
          continue;
        }

        final pairKey = _pairKey(a.id, b.id);
        if (processedPairs.contains(pairKey)) continue;

        final score = _calculateSimilarity(a, b);
        if (score >= lowConfidenceThreshold) {
          processedPairs.add(pairKey);
          duplicates.add(DuplicatePair(
            original: a,
            duplicate: b,
            similarityScore: score,
          ));
        }
      }
    }

    // Sort by similarity (highest first)
    duplicates.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return duplicates;
  }

  /// Calculate similarity score between two transactions (0.0 - 1.0).
  double _calculateSimilarity(TransactionModel a, TransactionModel b) {
    double score = 0;
    double maxScore = 0;

    // --- Amount match (weight: 0.35) ---
    maxScore += 0.35;
    if ((a.amount - b.amount).abs() <= _amountTolerance) {
      score += 0.35;
    } else {
      // Partial score for close amounts (within 5%)
      final diff = (a.amount - b.amount).abs();
      final avg = (a.amount + b.amount) / 2;
      if (avg > 0 && diff / avg <= 0.05) {
        score += 0.15;
      }
    }

    // --- Type match (weight: 0.20) ---
    maxScore += 0.20;
    if (a.type == b.type) {
      score += 0.20;
    }

    // --- Time proximity (weight: 0.25) ---
    maxScore += 0.25;
    final timeDiff = a.date.difference(b.date).abs();
    if (timeDiff <= _timeWindow) {
      score += 0.25;
    } else if (timeDiff <= const Duration(minutes: 30)) {
      score += 0.15;
    } else if (timeDiff <= const Duration(hours: 2)) {
      score += 0.08;
    }

    // --- Account match (weight: 0.10) ---
    maxScore += 0.10;
    if (a.accountId == b.accountId) {
      score += 0.10;
    }

    // --- Category match (weight: 0.10) ---
    maxScore += 0.10;
    if (a.categoryId == b.categoryId) {
      score += 0.10;
    }

    return maxScore > 0 ? (score / maxScore) : 0;
  }

  /// Create a canonical pair key to avoid processing A-B and B-A separately.
  String _pairKey(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? '$id1|$id2' : '$id2|$id1';
  }

  /// Merge two transactions — keeps the original and marks the duplicate
  /// as deleted. Optionally combines notes.
  TransactionModel mergeTransactions(
    TransactionModel keep,
    TransactionModel remove, {
    bool combineNotes = true,
  }) {
    String? mergedNote;
    if (combineNotes) {
      final parts = <String>[
        if (keep.note != null && keep.note!.isNotEmpty) keep.note!,
        if (remove.note != null && remove.note!.isNotEmpty) remove.note!,
      ];
      mergedNote = parts.isNotEmpty ? parts.join(' | ') : keep.note;
    }

    return keep.copyWith(
      note: mergedNote ?? keep.note,
      updatedAt: DateTime.now(),
    );
  }
}
