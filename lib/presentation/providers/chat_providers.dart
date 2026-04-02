import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/core/services/transaction_message_parser.dart';
import 'package:expensetracker/data/datasources/remote/chat_remote_datasource.dart';
import 'package:expensetracker/data/datasources/remote/gemini_remote_datasource.dart';
import 'package:expensetracker/data/repositories/ai_repository_impl.dart';
import 'package:expensetracker/data/repositories/chat_repository_impl.dart';
import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/chat_session.dart';
import 'package:expensetracker/domain/entities/parsed_transaction_draft.dart';
import 'package:expensetracker/domain/entities/transaction.dart';
import 'package:expensetracker/domain/repositories/ai_repository.dart';
import 'package:expensetracker/domain/repositories/chat_repository.dart';
import 'package:expensetracker/domain/usecases/chat_usecases.dart';
import 'package:expensetracker/presentation/providers/auth_providers.dart';
import 'package:expensetracker/presentation/providers/category_providers.dart';
import 'package:expensetracker/presentation/providers/jar_providers.dart';
import 'package:expensetracker/presentation/providers/transaction_providers.dart';

final transactionMessageParserProvider = Provider<TransactionMessageParser>((ref) {
  return const TransactionMessageParser();
});

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(firestoreProvider));
});

final geminiRemoteDataSourceProvider = Provider<GeminiRemoteDataSource>((ref) {
  return const GeminiRemoteDataSource();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(ref.watch(geminiRemoteDataSourceProvider));
});

final ensureUserChatUseCaseProvider = Provider<EnsureUserChatUseCase>((ref) {
  return EnsureUserChatUseCase(ref.watch(chatRepositoryProvider));
});

final watchChatMessagesUseCaseProvider = Provider<WatchChatMessagesUseCase>((ref) {
  return WatchChatMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final createChatSessionUseCaseProvider = Provider<CreateChatSessionUseCase>((ref) {
  return CreateChatSessionUseCase(ref.watch(chatRepositoryProvider));
});

final watchChatSessionsUseCaseProvider = Provider<WatchChatSessionsUseCase>((ref) {
  return WatchChatSessionsUseCase(ref.watch(chatRepositoryProvider));
});

final addChatMessageUseCaseProvider = Provider<AddChatMessageUseCase>((ref) {
  return AddChatMessageUseCase(ref.watch(chatRepositoryProvider));
});

final deleteChatMessageUseCaseProvider = Provider<DeleteChatMessageUseCase>((ref) {
  return DeleteChatMessageUseCase(ref.watch(chatRepositoryProvider));
});

final deleteChatSessionUseCaseProvider = Provider<DeleteChatSessionUseCase>((ref) {
  return DeleteChatSessionUseCase(ref.watch(chatRepositoryProvider));
});

final clearChatMessagesUseCaseProvider = Provider<ClearChatMessagesUseCase>((ref) {
  return ClearChatMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final generateAiReplyUseCaseProvider = Provider<GenerateAiReplyUseCase>((ref) {
  return GenerateAiReplyUseCase(ref.watch(aiRepositoryProvider));
});

final createTransactionFromDraftUseCaseProvider = Provider<CreateTransactionFromDraftUseCase>((ref) {
  return CreateTransactionFromDraftUseCase(ref.watch(transactionRepositoryProvider));
});

final currentChatIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(ensureUserChatUseCaseProvider).call(user.uid);
});

final chatSessionsProvider = StreamProvider<List<ChatSession>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield const <ChatSession>[];
    return;
  }

  yield* ref.watch(watchChatSessionsUseCaseProvider).call(user.uid);
});

final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield const <ChatMessage>[];
    return;
  }

  var chatId = ref.watch(
    chatControllerProvider.select((state) => state.selectedChatId),
  );

  if (chatId == null || chatId.isEmpty) {
    final controller = ref.read(chatControllerProvider.notifier);
    chatId = await controller.ensureSelectedChat();
  }

  if (chatId == null) {
    yield const <ChatMessage>[];
    return;
  }

  yield* ref.watch(watchChatMessagesUseCaseProvider).call(chatId);
});

class ChatState {
  const ChatState({
    this.isSending = false,
    this.isAiTyping = false,
    this.selectedChatId,
    this.pendingDraft,
    this.selectedCategoryId,
    this.errorMessage,
  });

  final bool isSending;
  final bool isAiTyping;
  final String? selectedChatId;
  final ParsedTransactionDraft? pendingDraft;
  final String? selectedCategoryId;
  final String? errorMessage;

  ChatState copyWith({
    bool? isSending,
    bool? isAiTyping,
    String? selectedChatId,
    ParsedTransactionDraft? pendingDraft,
    String? selectedCategoryId,
    String? errorMessage,
    bool clearDraft = false,
    bool clearError = false,
  }) {
    return ChatState(
      isSending: isSending ?? this.isSending,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      selectedChatId: selectedChatId ?? this.selectedChatId,
      pendingDraft: clearDraft ? null : (pendingDraft ?? this.pendingDraft),
      selectedCategoryId: clearDraft
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState());

  final Ref _ref;

  Future<String?> ensureSelectedChat() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return null;

    if (state.selectedChatId != null && state.selectedChatId!.isNotEmpty) {
      return state.selectedChatId;
    }

    final chatId = await _ref.read(ensureUserChatUseCaseProvider).call(user.uid);
    state = state.copyWith(selectedChatId: chatId);
    return chatId;
  }

  Future<void> createNewChatSession() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final chatId = await _ref.read(createChatSessionUseCaseProvider).call(
          userId: user.uid,
          title: 'Chat mới',
        );

    state = state.copyWith(
      selectedChatId: chatId,
      clearDraft: true,
      clearError: true,
      isAiTyping: false,
    );
  }

  void selectChatSession(String chatId) {
    state = state.copyWith(
      selectedChatId: chatId,
      clearDraft: true,
      clearError: true,
      isAiTyping: false,
    );
  }

  Future<void> deleteChatSession(String chatId) async {
    try {
      await _ref.read(deleteChatSessionUseCaseProvider).call(chatId);

      final sessions = _ref.read(chatSessionsProvider).value ?? const <ChatSession>[];
      final fallback = sessions.where((s) => s.id != chatId).toList();

      state = state.copyWith(
        selectedChatId: fallback.isEmpty ? null : fallback.first.id,
        clearDraft: true,
        clearError: true,
        isAiTyping: false,
      );

      if (fallback.isEmpty) {
        await createNewChatSession();
      }
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final chatId = state.selectedChatId;
    if (chatId == null) return;

    try {
      await _ref.read(deleteChatMessageUseCaseProvider).call(
            chatId: chatId,
            messageId: messageId,
          );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> clearCurrentChat() async {
    final chatId = state.selectedChatId;
    if (chatId == null) return;

    try {
      await _ref.read(clearChatMessagesUseCaseProvider).call(chatId);
      state = state.copyWith(clearDraft: true, clearError: true, isAiTyping: false);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Bạn cần đăng nhập để dùng chatbot.');
      return;
    }

    state = state.copyWith(isSending: true, isAiTyping: false, clearError: true);

    try {
      final chatId = await ensureSelectedChat();
      if (chatId == null) {
        state = state.copyWith(
          isSending: false,
          errorMessage: 'Không thể khởi tạo phiên chat.',
        );
        return;
      }

      final now = DateTime.now();

      await _ref.read(addChatMessageUseCaseProvider).call(
            chatId: chatId,
            message: ChatMessage(
              id: 'u_${now.microsecondsSinceEpoch}',
              chatId: chatId,
              userId: user.uid,
              sender: ChatSender.user,
              text: messageText,
              createdAt: now,
            ),
          );

      final draft = _ref.read(transactionMessageParserProvider).parse(messageText);
      final suggestedCategoryId = _guessCategoryId(draft);
      state = state.copyWith(isAiTyping: true);

      final financialContext = _buildFinancialContext();
      final aiResponse = await _ref.read(generateAiReplyUseCaseProvider).call(
            message: messageText,
            financialContext: financialContext,
          );

      await _ref.read(addChatMessageUseCaseProvider).call(
            chatId: chatId,
            message: ChatMessage(
              id: 'a_${DateTime.now().microsecondsSinceEpoch}',
              chatId: chatId,
              userId: user.uid,
              sender: ChatSender.assistant,
              text: aiResponse.reply,
              createdAt: DateTime.now(),
              savingAdvice: aiResponse.savingAdvice,
              spendingAlerts: aiResponse.spendingAlerts,
              transactionDraft: draft,
            ),
          );

      state = state.copyWith(
        isSending: false,
        isAiTyping: false,
        pendingDraft: draft,
        selectedCategoryId: suggestedCategoryId,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        isAiTyping: false,
        errorMessage: error.toString(),
      );
    }
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  Future<void> confirmPendingDraft() async {
    final user = _ref.read(authStateProvider).value;
    final draft = state.pendingDraft;
    final categoryId = state.selectedCategoryId;

    if (user == null || draft == null) return;
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(errorMessage: 'Hãy chọn danh mục trước khi lưu giao dịch.');
      return;
    }

    try {
      await _ref.read(createTransactionFromDraftUseCaseProvider).call(
            userId: user.uid,
            draft: draft,
            categoryId: categoryId,
          );

      state = state.copyWith(clearDraft: true, clearError: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  void discardPendingDraft() {
    state = state.copyWith(clearDraft: true, clearError: true);
  }

  String _buildFinancialContext() {
    final transactions = _ref.read(transactionsStreamProvider).value ?? const <Transaction>[];
    final jars = _ref.read(jarsStreamProvider).value ?? const [];

    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }

    final overBudgetCount = jars.where((jar) {
      final limit = jar.budgetLimit ?? 0;
      if (limit <= 0) return false;
      return jar.currentBalance < 0;
    }).length;

    return 'Tong thu: ${income.toStringAsFixed(0)} VND; '
        'Tong chi: ${expense.toStringAsFixed(0)} VND; '
        'Chen lech: ${(income - expense).toStringAsFixed(0)} VND; '
        'So hu vuot muc: $overBudgetCount.';
  }

  String? _guessCategoryId(ParsedTransactionDraft? draft) {
    if (draft == null) return null;

    final categories = _ref.read(categoriesStreamProvider).value ?? const [];
    final normalizedHint = (draft.categoryHint ?? '').toLowerCase();

    for (final category in categories) {
      if (category.type != draft.type) continue;

      final name = category.name.toLowerCase();
      if (normalizedHint.isNotEmpty &&
          (name.contains(normalizedHint) || normalizedHint.contains(name))) {
        return category.id;
      }
    }

    final firstSameType = categories.where((c) => c.type == draft.type).toList();
    return firstSameType.isEmpty ? null : firstSameType.first.id;
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref);
});
