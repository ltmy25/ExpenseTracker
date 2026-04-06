import '../entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> getTransactions(String userId);
  Future<void> addTransaction(String userId, Transaction transaction);
  Future<void> updateTransaction(String userId, Transaction transaction);
  Future<void> deleteTransaction(String userId, String transactionId);
}
