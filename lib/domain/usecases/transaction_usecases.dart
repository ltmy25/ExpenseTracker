import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;
  GetTransactionsUseCase(this.repository);
  Stream<List<Transaction>> call(String userId) => repository.getTransactions(userId);
}

class AddTransactionUseCase {
  final TransactionRepository repository;
  AddTransactionUseCase(this.repository);
  Future<void> call(String userId, Transaction transaction) => repository.addTransaction(userId, transaction);
}

class UpdateTransactionUseCase {
  final TransactionRepository repository;
  UpdateTransactionUseCase(this.repository);
  Future<void> call(String userId, Transaction transaction) => repository.updateTransaction(userId, transaction);
}

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);
  Future<void> call(String userId, String transactionId) => repository.deleteTransaction(userId, transactionId);
}
