enum TransactionType { income, expense, transfer }

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
  final String? jarId;
  final String? toJarId;

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
    this.jarId,
    this.toJarId,
  });

  Transaction copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    TransactionType? type,
    String? note,
    String? jarId,
    String? toJarId,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      note: note ?? this.note,
      jarId: jarId ?? this.jarId,
      toJarId: toJarId ?? this.toJarId,
    );
  }
}
