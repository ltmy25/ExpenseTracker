import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../datasources/remote/jar_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;

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
    // Route transaction creation through JarRemoteDataSource so jars linked by categoryIds get updated.
    final jarDs = JarRemoteDataSource(FirebaseFirestore.instance);
    try {
      await jarDs.addTransactionWithJarUpdate(userId, transaction);
    } catch (e, st) {
      // Provide clearer logging for runtime errors during transaction write
      // ignore: avoid_print
      print('Error in addTransaction -> addTransactionWithJarUpdate: $e');
      // ignore: avoid_print
      print(st);
      rethrow;
    }
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
