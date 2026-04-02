import 'package:expensetracker/domain/entities/ai_chat_response.dart';
import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/chat_session.dart';
import 'package:expensetracker/domain/entities/parsed_transaction_draft.dart';
import 'package:expensetracker/domain/entities/transaction.dart';
import 'package:expensetracker/domain/repositories/ai_repository.dart';
import 'package:expensetracker/domain/repositories/chat_repository.dart';
import 'package:expensetracker/domain/repositories/transaction_repository.dart';

class EnsureUserChatUseCase {
  const EnsureUserChatUseCase(this._repository);

  final ChatRepository _repository;

  Future<String> call(String userId) => _repository.ensureUserChat(userId);
}

class WatchChatMessagesUseCase {
  const WatchChatMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Stream<List<ChatMessage>> call(String chatId) => _repository.watchMessages(chatId);
}

class CreateChatSessionUseCase {
  const CreateChatSessionUseCase(this._repository);

  final ChatRepository _repository;

  Future<String> call({
    required String userId,
    String? title,
  }) {
    return _repository.createChatSession(userId: userId, title: title);
  }
}

class WatchChatSessionsUseCase {
  const WatchChatSessionsUseCase(this._repository);

  final ChatRepository _repository;

  Stream<List<ChatSession>> call(String userId) => _repository.watchChatSessions(userId);
}

class AddChatMessageUseCase {
  const AddChatMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({
    required String chatId,
    required ChatMessage message,
  }) {
    return _repository.addMessage(chatId: chatId, message: message);
  }
}

class DeleteChatMessageUseCase {
  const DeleteChatMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({
    required String chatId,
    required String messageId,
  }) {
    return _repository.deleteMessage(chatId: chatId, messageId: messageId);
  }
}

class DeleteChatSessionUseCase {
  const DeleteChatSessionUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String chatId) {
    return _repository.deleteChatSession(chatId);
  }
}

class ClearChatMessagesUseCase {
  const ClearChatMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String chatId) {
    return _repository.clearChatMessages(chatId);
  }
}

class GenerateAiReplyUseCase {
  const GenerateAiReplyUseCase(this._repository);

  final AiRepository _repository;

  Future<AiChatResponse> call({
    required String message,
    required String financialContext,
  }) {
    return _repository.generateReply(
      message: message,
      financialContext: financialContext,
    );
  }
}

class CreateTransactionFromDraftUseCase {
  const CreateTransactionFromDraftUseCase(this._repository);

  final TransactionRepository _repository;

  Future<void> call({
    required String userId,
    required ParsedTransactionDraft draft,
    required String categoryId,
  }) {
    final now = DateTime.now();
    final transaction = Transaction(
      id: '',
      userId: userId,
      title: draft.title,
      amount: draft.amount,
      occurredAt: draft.occurredAt,
      createdAt: now,
      updatedAt: now,
      categoryId: categoryId,
      type: draft.type,
      note: draft.note,
    );
    return _repository.addTransaction(userId, transaction);
  }
}
