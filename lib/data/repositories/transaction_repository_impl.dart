import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  @override
  Stream<List<Transaction>> getTransactions(String userId) {
    // Chuyển từ users/{userId}/transactions sang collection gốc /transactions
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map((firestore.QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((firestore.QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> addTransaction(String userId, Transaction transaction) async {
    final now = DateTime.now();
    final model = TransactionModel(
      id: '',
      userId: userId,
      title: transaction.title,
      amount: transaction.amount,
      occurredAt: transaction.occurredAt,
      createdAt: now,
      updatedAt: now,
      categoryId: transaction.categoryId,
      type: transaction.type,
      note: transaction.note,
    );
    // Lưu vào collection gốc /transactions để khớp với Rules
    await _firestore
        .collection('transactions')
        .add(model.toMap());
  }

  @override
  Future<void> updateTransaction(String userId, Transaction transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      userId: userId,
      title: transaction.title,
      amount: transaction.amount,
      occurredAt: transaction.occurredAt,
      createdAt: transaction.createdAt, // Giữ nguyên ngày tạo
      updatedAt: DateTime.now(), // Cập nhật ngày sửa
      categoryId: transaction.categoryId,
      type: transaction.type,
      note: transaction.note,
    );
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(model.toMap());
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _firestore
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }
}
