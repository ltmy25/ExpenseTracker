import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/parsed_transaction_draft.dart';
import 'package:expensetracker/domain/entities/transaction.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.userId,
    required super.sender,
    required super.text,
    required super.createdAt,
    super.savingAdvice,
    super.spendingAlerts,
    super.transactionDraft,
  });

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String chatId,
  ) {
    final draftMap = map['transactionDraft'] as Map<String, dynamic>?;
    final typeString = draftMap?['type'] as String?;

    return ChatMessageModel(
      id: id,
      chatId: chatId,
      userId: map['userId'] as String? ?? '',
      sender: (map['sender'] as String? ?? 'assistant') == 'user'
          ? ChatSender.user
          : ChatSender.assistant,
      text: map['text'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      savingAdvice: map['savingAdvice'] as String?,
      spendingAlerts: (map['spendingAlerts'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      transactionDraft: draftMap == null
          ? null
          : ParsedTransactionDraft(
              title: draftMap['title'] as String? ?? 'Giao dịch từ chat',
              amount: (draftMap['amount'] as num?)?.toDouble() ?? 0,
              type: typeString == 'income'
                  ? TransactionType.income
                  : TransactionType.expense,
              occurredAt: (draftMap['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              categoryHint: draftMap['categoryHint'] as String?,
              note: draftMap['note'] as String?,
              confidence: (draftMap['confidence'] as num?)?.toDouble() ?? 0,
            ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userId': userId,
      'sender': sender == ChatSender.user ? 'user' : 'assistant',
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      if (savingAdvice != null && savingAdvice!.isNotEmpty) 'savingAdvice': savingAdvice,
      if (spendingAlerts.isNotEmpty) 'spendingAlerts': spendingAlerts,
      if (transactionDraft != null)
        'transactionDraft': {
          'title': transactionDraft!.title,
          'amount': transactionDraft!.amount,
          'type': transactionDraft!.type.name,
          'occurredAt': Timestamp.fromDate(transactionDraft!.occurredAt),
          'categoryHint': transactionDraft!.categoryHint,
          'note': transactionDraft!.note,
          'confidence': transactionDraft!.confidence,
        },
    };
  }
}
