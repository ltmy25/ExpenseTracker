import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.amount,
    required super.occurredAt,
    required super.createdAt,
    required super.updatedAt,
    required super.categoryId,
    required super.type,
    super.note,
  });

  Map<String, dynamic> toMap() => {
    // 7 trường bắt buộc trong hasAll
    'userId': userId,
    'type': type.name,
    'amount': amount,
    'categoryId': categoryId,
    'occurredAt': firestore.Timestamp.fromDate(occurredAt),
    'createdAt': firestore.Timestamp.fromDate(createdAt),
    'updatedAt': firestore.Timestamp.fromDate(updatedAt),

    // 5 trường bổ sung trong hasOnly
    'title': title ?? '',
    'note': note ?? '',
    'jarId': null,
    'source': 'mobile_app',
    'currency': 'VND',
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime getDateTime(dynamic value) {
      if (value is firestore.Timestamp) return value.toDate();
      return DateTime.now();
    }

    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      occurredAt: getDateTime(map['occurredAt']),
      createdAt: getDateTime(map['createdAt']),
      updatedAt: getDateTime(map['updatedAt']),
      categoryId: map['categoryId'] ?? '',
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      note: map['note'],
    );
  }
}
