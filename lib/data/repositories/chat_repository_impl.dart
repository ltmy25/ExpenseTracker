import 'package:expensetracker/data/datasources/remote/chat_remote_datasource.dart';
import 'package:expensetracker/data/models/chat_message_model.dart';
import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/chat_session.dart';
import 'package:expensetracker/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remoteDataSource);

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<String> ensureUserChat(String userId) {
    return _remoteDataSource.ensureUserChat(userId);
  }

  @override
  Future<String> createChatSession({
    required String userId,
    String? title,
  }) {
    return _remoteDataSource.createChatSession(userId: userId, title: title);
  }

  @override
  Stream<List<ChatSession>> watchChatSessions(String userId) {
    return _remoteDataSource.watchChatSessions(userId);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _remoteDataSource.watchMessages(chatId);
  }

  @override
  Future<void> addMessage({
    required String chatId,
    required ChatMessage message,
  }) {
    final model = ChatMessageModel(
      id: message.id,
      chatId: message.chatId,
      userId: message.userId,
      sender: message.sender,
      text: message.text,
      createdAt: message.createdAt,
      savingAdvice: message.savingAdvice,
      spendingAlerts: message.spendingAlerts,
      transactionDraft: message.transactionDraft,
    );

    return _remoteDataSource.addMessage(chatId: chatId, message: model);
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) {
    return _remoteDataSource.deleteMessage(chatId: chatId, messageId: messageId);
  }

  @override
  Future<void> clearChatMessages(String chatId) {
    return _remoteDataSource.clearChatMessages(chatId);
  }

  @override
  Future<void> deleteChatSession(String chatId) {
    return _remoteDataSource.deleteChatSession(chatId);
  }
}
