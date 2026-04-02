import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetracker/core/constants/firestore_collections.dart';
import 'package:expensetracker/data/models/chat_message_model.dart';
import 'package:expensetracker/data/models/chat_session_model.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<String> ensureUserChat(String userId) async {
    final existing = await _firestore
        .collection(FirestoreCollections.chats)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    return createChatSession(userId: userId, title: 'Trợ lý tài chính');
  }

  Future<String> createChatSession({
    required String userId,
    String? title,
  }) async {
    final now = DateTime.now();
    final doc = await _firestore.collection(FirestoreCollections.chats).add(
          ChatSessionModel(
            id: '',
            userId: userId,
            title: title ?? 'Chat mới',
            lastMessage: '',
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );
    return doc.id;
  }

  Stream<List<ChatSessionModel>> watchChatSessions(String userId) {
    return _firestore
        .collection(FirestoreCollections.chats)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatSessionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    final query = _firestore
        .collection(FirestoreCollections.chats)
        .doc(chatId)
        .collection(FirestoreCollections.chatMessages);

    return query.snapshots().map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id, chatId))
          .toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> addMessage({
    required String chatId,
    required ChatMessageModel message,
  }) async {
    final chatDoc = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messagesRef = chatDoc.collection(FirestoreCollections.chatMessages);

    await messagesRef.add(message.toMap());
    await chatDoc.set({
      'userId': message.userId,
      'lastMessage': message.text,
      'title': 'Trợ lý tài chính',
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collection(FirestoreCollections.chats)
        .doc(chatId)
        .collection(FirestoreCollections.chatMessages)
        .doc(messageId)
        .delete();
  }

  Future<void> deleteChatSession(String chatId) async {
    await clearChatMessages(chatId);
    final chatDoc = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    await chatDoc.delete();
  }

  Future<void> clearChatMessages(String chatId) async {
    final chatDoc = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messages = await chatDoc.collection(FirestoreCollections.chatMessages).get();

    WriteBatch batch = _firestore.batch();
    var count = 0;

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    await chatDoc.set({
      'lastMessage': '',
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
