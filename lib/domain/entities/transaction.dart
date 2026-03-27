enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String categoryId;
  final TransactionType type;
  final String? note;

  Transaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.categoryId,
    required this.type,
    this.note,
  });
}
