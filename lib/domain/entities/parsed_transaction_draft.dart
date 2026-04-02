import 'package:expensetracker/domain/entities/transaction.dart';

class ParsedTransactionDraft {
  const ParsedTransactionDraft({
    required this.title,
    required this.amount,
    required this.type,
    required this.occurredAt,
    this.categoryHint,
    this.note,
    this.confidence = 0.0,
  });

  final String title;
  final double amount;
  final TransactionType type;
  final DateTime occurredAt;
  final String? categoryHint;
  final String? note;
  final double confidence;
}
