import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expensetracker/core/services/receipt_ocr_service.dart';
import 'package:expensetracker/core/services/transaction_message_parser.dart';
import 'package:expensetracker/data/datasources/remote/chat_remote_datasource.dart';
import 'package:expensetracker/data/datasources/remote/gemini_remote_datasource.dart';
import 'package:expensetracker/data/repositories/ai_repository_impl.dart';
import 'package:expensetracker/data/repositories/chat_repository_impl.dart';
import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/chat_session.dart';
import 'package:expensetracker/domain/entities/category.dart';
import 'package:expensetracker/domain/entities/jar.dart';
import 'package:expensetracker/domain/entities/ai_receipt_analysis.dart';
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

final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  return ReceiptOcrService();
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

final generateAiReceiptAnalysisUseCaseProvider =
    Provider<GenerateAiReceiptAnalysisUseCase>((ref) {
  return GenerateAiReceiptAnalysisUseCase(ref.watch(aiRepositoryProvider));
});

final generateAiReceiptTextAnalysisUseCaseProvider =
    Provider<GenerateAiReceiptTextAnalysisUseCase>((ref) {
  return GenerateAiReceiptTextAnalysisUseCase(ref.watch(aiRepositoryProvider));
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

  static const Map<String, List<String>> _expenseCategoryKeywordGroups = {
    'an uong': ['an', 'uong', 'food', 'am thuc', 'do an', 'cafe', 'ca phe', 'tra sua', 'nha hang'],
    'di chuyen': ['di chuyen', 'xang', 'grab', 'taxi', 'xe', 'gui xe', 'bus', 'metro'],
    'mua sam': ['mua sam', 'shopping', 'sieu thi', 'mini mart', 'store', 'tap hoa', 'shop'],
    'hoa don': ['hoa don', 'dien', 'nuoc', 'internet', 'wifi', 'dien thoai', 'phi dich vu'],
    'suc khoe': ['suc khoe', 'benh vien', 'thuoc', 'y te', 'phong kham', 'nhathuoc'],
    'giao duc': ['giao duc', 'hoc phi', 'khoa hoc', 'sach', 'education', 'lop hoc'],
  };

  static const Map<String, List<String>> _incomeCategoryKeywordGroups = {
    'luong': ['luong', 'salary', 'payroll', 'phieu luong'],
    'thuong': ['thuong', 'bonus', 'hoa hong', 'commission'],
    'hoan tien': ['hoan tien', 'refund', 'cashback'],
    'thu nhap': ['thu nhap', 'income', 'phu cap'],
  };

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

      // Handle direct management requests (update/delete transaction or jar) before generic AI reply.
      final handledManagement = await _tryHandleManagementRequest(
        userId: user.uid,
        chatId: chatId,
        messageText: messageText,
      );
      if (handledManagement) {
        state = state.copyWith(
          isSending: false,
          isAiTyping: false,
          clearError: true,
        );
        return;
      }

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

  Future<void> sendReceiptImage(ImageSource source) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Bạn cần đăng nhập để dùng chatbot.');
      return;
    }

    state = state.copyWith(isSending: true, isAiTyping: false, clearError: true);

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (file == null) {
        state = state.copyWith(isSending: false);
        return;
      }

      final chatId = await ensureSelectedChat();
      if (chatId == null) {
        state = state.copyWith(
          isSending: false,
          errorMessage: 'Không thể khởi tạo phiên chat.',
        );
        return;
      }

      await _ref.read(addChatMessageUseCaseProvider).call(
            chatId: chatId,
            message: ChatMessage(
              id: 'u_img_${DateTime.now().microsecondsSinceEpoch}',
              chatId: chatId,
              userId: user.uid,
              sender: ChatSender.user,
              text: '[Đã gửi ảnh bill để phân tích]',
              createdAt: DateTime.now(),
            ),
          );

      state = state.copyWith(isAiTyping: true);

      final imageBytes = await file.readAsBytes();
      final aiReceipt = await _ref.read(generateAiReceiptAnalysisUseCaseProvider).call(
            imageBytes: imageBytes,
            mimeType: _guessMimeType(file.path),
            financialContext: _buildFinancialContext(),
          );

      final categories = await _ref.read(categoriesStreamProvider.future);
      final hint = [
        aiReceipt.transactionTypeHint ?? '',
        aiReceipt.categoryHint ?? '',
        aiReceipt.reply,
        ...aiReceipt.items.take(3).map((e) => e.name),
      ].join(' ');
      final transactionType = _detectTransactionTypeFromReceipt(aiReceipt, hint);

      var totalAmount = aiReceipt.totalAmount ?? aiReceipt.netAmount ?? 0;
      if (totalAmount <= 0 && aiReceipt.items.isNotEmpty) {
        totalAmount = _sumReceiptItemsByType(
          items: aiReceipt.items,
          transactionType: transactionType,
        );
      }
      if (totalAmount <= 0) {
        final totalFromOcr = await _ref.read(receiptOcrServiceProvider).extractTotalFromImagePath(file.path);
        totalAmount = totalFromOcr ?? 0;
      }

      if (totalAmount <= 0) {
        await _ref.read(addChatMessageUseCaseProvider).call(
              chatId: chatId,
              message: ChatMessage(
                id: 'a_img_${DateTime.now().microsecondsSinceEpoch}',
                chatId: chatId,
                userId: user.uid,
                sender: ChatSender.assistant,
                text: transactionType == TransactionType.income
                    ? 'Mình chưa xác định được tổng nhận cuối cùng từ phiếu lương. Bạn thử ảnh rõ hơn nhé.'
                    : 'Mình chưa đọc được tổng tiền từ ảnh bill. Bạn thử ảnh rõ hơn nhé.',
                createdAt: DateTime.now(),
              ),
            );
        state = state.copyWith(isSending: false, isAiTyping: false);
        return;
      }

      final categoryId = _pickCategoryIdFromHint(
        categories: categories,
        type: transactionType,
        hintText: hint,
      );

      if (categoryId == null) {
        state = state.copyWith(
          isSending: false,
          isAiTyping: false,
          errorMessage: transactionType == TransactionType.income
              ? 'Không tìm thấy danh mục thu nhập để lưu giao dịch.'
              : 'Không tìm thấy danh mục chi tiêu để lưu giao dịch.',
        );
        return;
      }

      final now = DateTime.now();
      final tx = Transaction(
        id: '',
        userId: user.uid,
        title: transactionType == TransactionType.income
            ? 'Thu nhập từ phiếu lương'
            : 'Chi tiêu từ hóa đơn',
        amount: totalAmount,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        categoryId: categoryId,
        type: transactionType,
        note: transactionType == TransactionType.income
            ? 'Tạo tự động từ phiếu lương trong Chat AI'
            : 'Tạo tự động từ tổng tiền hóa đơn trong Chat AI',
      );
      await _ref.read(addTransactionUseCaseProvider).call(user.uid, tx);

      var assistantText = aiReceipt.reply.trim();
      if (assistantText.isEmpty || assistantText.startsWith('{') || assistantText.startsWith('[')) {
        final aiPrompt =
            'Nguoi dung da gui anh ${transactionType == TransactionType.income ? 'phieu luong' : 'bill'}. '
            'Da tao 1 giao dich ${transactionType == TransactionType.income ? 'thu nhap' : 'chi tieu'}, tong ${totalAmount.toStringAsFixed(0)} VND. '
            'Hay tom tat ngan gon va dua 1 goi y tiet kiem.';
        final aiResponse = await _ref.read(generateAiReplyUseCaseProvider).call(
              message: aiPrompt,
              financialContext: _buildFinancialContext(),
            );
        assistantText = aiResponse.reply;
      } else {
        assistantText = 'Đã phân tích ${transactionType == TransactionType.income ? 'phiếu lương' : 'bill'} và tự tạo 1 giao dịch ${transactionType == TransactionType.income ? 'thu nhập' : 'chi tiêu'} (tổng ${totalAmount.toStringAsFixed(0)}đ).\n\n$assistantText';
      }

      await _ref.read(addChatMessageUseCaseProvider).call(
            chatId: chatId,
            message: ChatMessage(
              id: 'a_img_${DateTime.now().microsecondsSinceEpoch}',
              chatId: chatId,
              userId: user.uid,
              sender: ChatSender.assistant,
              text: assistantText,
              createdAt: DateTime.now(),
            ),
          );

      state = state.copyWith(isSending: false, isAiTyping: false, clearError: true);
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        isAiTyping: false,
        errorMessage: 'Không thể phân tích bill: $error',
      );
    }
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
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

  String? _pickCategoryIdFromHint({
    required List<Category> categories,
    required TransactionType type,
    required String hintText,
  }) {
    final filteredCategories = categories.where((c) => c.type == type).toList();

    if (filteredCategories.isEmpty) {
      return null;
    }

    final normalizedHint = _normalizeText(hintText);
    if (normalizedHint.isEmpty) {
      return filteredCategories.first.id;
    }

    Category? best;
    var bestScore = -1;

    final keywordGroups = type == TransactionType.income
        ? _incomeCategoryKeywordGroups
        : _expenseCategoryKeywordGroups;

    for (final category in filteredCategories) {
      final categoryNorm = _normalizeText(category.name);
      var score = 0;

      if (categoryNorm.isNotEmpty && normalizedHint.contains(categoryNorm)) {
        score += 10;
      }
      if (categoryNorm.isNotEmpty && categoryNorm.contains(normalizedHint)) {
        score += 6;
      }

      final words = categoryNorm.split(' ').where((w) => w.length >= 3);
      for (final word in words) {
        if (normalizedHint.contains(word)) {
          score += 2;
        }
      }

      for (final group in keywordGroups.entries) {
        if (!normalizedHint.contains(group.key)) {
          continue;
        }
        for (final keyword in group.value) {
          final normalizedKeyword = _normalizeText(keyword);
          if (categoryNorm.contains(normalizedKeyword)) {
            score += 3;
            break;
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    }

    return (best ?? filteredCategories.first).id;
  }

  TransactionType _detectTransactionTypeFromReceipt(
    AiReceiptAnalysis aiReceipt,
    String hint,
  ) {
    final hintType = (aiReceipt.transactionTypeHint ?? '').toString().toLowerCase().trim();
    if (hintType == 'income') {
      return TransactionType.income;
    }
    if (hintType == 'expense') {
      return TransactionType.expense;
    }

    final normalizedHint = _normalizeText(hint);
    if (normalizedHint.contains('luong') ||
        normalizedHint.contains('salary') ||
        normalizedHint.contains('payroll') ||
        normalizedHint.contains('thu nhap') ||
        normalizedHint.contains('bonus') ||
        normalizedHint.contains('thuong')) {
      return TransactionType.income;
    }

    return TransactionType.expense;
  }

  double _sumReceiptItemsByType({
    required List<AiReceiptItem> items,
    required TransactionType transactionType,
  }) {
    if (items.isEmpty) {
      return 0;
    }

    if (transactionType == TransactionType.expense) {
      var total = 0.0;
      for (final item in items) {
        total += item.amount;
      }
      return total;
    }

    var earnings = 0.0;
    var deductions = 0.0;
    var hasTypedItem = false;

    for (final item in items) {
      final itemType = (item.itemType ?? '').toLowerCase().trim();
      if (itemType == 'earning') {
        earnings += item.amount;
        hasTypedItem = true;
      } else if (itemType == 'deduction') {
        deductions += item.amount;
        hasTypedItem = true;
      }
    }

    if (hasTypedItem) {
      final net = earnings - deductions;
      return net > 0 ? net : 0;
    }

    var fallback = 0.0;
    for (final item in items) {
      fallback += item.amount;
    }
    return fallback;
  }

  String _normalizeText(String input) {
    var text = input.toLowerCase();
    const withAccent = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutAccent = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (var i = 0; i < withAccent.length; i++) {
      text = text.replaceAll(withAccent[i], withoutAccent[i]);
    }

    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  Future<bool> _tryHandleManagementRequest({
    required String userId,
    required String chatId,
    required String messageText,
  }) async {
    final normalized = _normalizeText(messageText);
    final isDelete = normalized.contains('xoa') || normalized.contains('remove') || normalized.contains('delete');
    final isUpdate =
        normalized.contains('sua') || normalized.contains('chinh sua') || normalized.contains('cap nhat') || normalized.contains('doi');

    if (!isDelete && !isUpdate) {
      return false;
    }

    final askTransaction =
        normalized.contains('giao dich') || normalized.contains('chi tieu') || normalized.contains('khoan chi');
    final askJar = normalized.contains('hu') || normalized.contains('ho chi tieu') || normalized.contains('jar');

    if (!askTransaction && !askJar) {
      return false;
    }

    if (askTransaction) {
      return _handleTransactionManagement(
        userId: userId,
        chatId: chatId,
        messageText: messageText,
        isDelete: isDelete,
        isUpdate: isUpdate,
      );
    }

    return _handleJarManagement(
      chatId: chatId,
      messageText: messageText,
      isDelete: isDelete,
      isUpdate: isUpdate,
    );
  }

  Future<bool> _handleTransactionManagement({
    required String userId,
    required String chatId,
    required String messageText,
    required bool isDelete,
    required bool isUpdate,
  }) async {
    final transactions = _ref.read(transactionsStreamProvider).value ?? const <Transaction>[];
    if (transactions.isEmpty) {
      await _sendAssistantMessage(
        chatId,
        userId,
        'Hiện chưa có giao dịch nào để sửa hoặc xóa.',
      );
      return true;
    }

    final target = _pickBestTransaction(transactions, messageText);
    if (target == null) {
      await _sendAssistantMessage(
        chatId,
        userId,
        'Mình chưa xác định được giao dịch bạn muốn thao tác. Hãy nêu rõ tên giao dịch.',
      );
      return true;
    }

    if (isDelete) {
      await _ref.read(deleteTransactionUseCaseProvider).call(userId, target.id);
      await _sendAssistantMessage(
        chatId,
        userId,
        'Đã xóa giao dịch "${target.title}" (${target.amount.toStringAsFixed(0)}đ).',
      );
      return true;
    }

    if (isUpdate) {
      final newAmount = _extractAmountFromText(messageText);
      final shouldRename = _hasRenameIntent(messageText);
      final newTitle = shouldRename ? _extractRenameValue(messageText) : null;

      if (newAmount == null && (newTitle == null || newTitle.isEmpty)) {
        await _sendAssistantMessage(
          chatId,
          userId,
          'Mình đã tìm thấy giao dịch "${target.title}", nhưng bạn chưa nêu giá trị cần sửa (tên hoặc số tiền).',
        );
        return true;
      }

      final updated = target.copyWith(
        title: (newTitle != null && newTitle.isNotEmpty) ? newTitle : target.title,
        amount: newAmount ?? target.amount,
        updatedAt: DateTime.now(),
      );

      await _ref.read(updateTransactionUseCaseProvider).call(userId, updated);
      await _sendAssistantMessage(
        chatId,
        userId,
        'Đã cập nhật giao dịch: ${updated.title} - ${updated.amount.toStringAsFixed(0)}đ.',
      );
      return true;
    }

    return false;
  }

  Future<bool> _handleJarManagement({
    required String chatId,
    required String messageText,
    required bool isDelete,
    required bool isUpdate,
  }) async {
    final jars = _ref.read(jarsStreamProvider).value ?? const <Jar>[];
    if (jars.isEmpty) {
      await _sendAssistantMessage(chatId, null, 'Hiện chưa có hũ chi tiêu nào để sửa hoặc xóa.');
      return true;
    }

    final target = _pickBestJar(jars, messageText);
    if (target == null) {
      await _sendAssistantMessage(chatId, null, 'Mình chưa xác định được hũ bạn muốn thao tác. Hãy nêu rõ tên hũ.');
      return true;
    }

    final jarController = _ref.read(jarControllerProvider);
    if (jarController.uid == null) {
      await _sendAssistantMessage(chatId, null, 'Bạn cần đăng nhập để sửa hoặc xóa hũ.');
      return true;
    }

    if (isDelete) {
      await jarController.deleteJar(target.id);
      await _sendAssistantMessage(chatId, null, 'Đã xóa hũ "${target.name}".');
      return true;
    }

    if (isUpdate) {
      final newBudgetLimit = _extractAmountFromText(messageText);
      final shouldRename = _hasRenameIntent(messageText);
      final newName = shouldRename ? _extractRenameValue(messageText) : null;

      if (newBudgetLimit == null && (newName == null || newName.isEmpty)) {
        await _sendAssistantMessage(
          chatId,
          null,
          'Mình đã tìm thấy hũ "${target.name}", nhưng bạn chưa nêu giá trị cần sửa (tên hoặc ngân sách).',
        );
        return true;
      }

      final updatedJar = Jar(
        id: target.id,
        name: (newName != null && newName.isNotEmpty) ? newName : target.name,
        currentBalance: target.currentBalance,
        categoryIds: target.categoryIds,
        budgetLimit: newBudgetLimit ?? target.budgetLimit,
        color: target.color,
        icon: target.icon,
        createdAt: target.createdAt,
        updatedAt: DateTime.now(),
      );

      await jarController.updateJar(updatedJar);
      await _sendAssistantMessage(
        chatId,
        null,
        'Đã cập nhật hũ "${updatedJar.name}"${updatedJar.budgetLimit == null ? '' : ' (ngân sách ${updatedJar.budgetLimit!.toStringAsFixed(0)}đ)'}.' ,
      );
      return true;
    }

    return false;
  }

  Future<void> _sendAssistantMessage(String chatId, String? userId, String content) {
    final uid = userId ?? _ref.read(authStateProvider).value?.uid ?? 'assistant';
    return _ref.read(addChatMessageUseCaseProvider).call(
          chatId: chatId,
          message: ChatMessage(
            id: 'a_${DateTime.now().microsecondsSinceEpoch}',
            chatId: chatId,
            userId: uid,
            sender: ChatSender.assistant,
            text: content,
            createdAt: DateTime.now(),
          ),
        );
  }

  Transaction? _pickBestTransaction(List<Transaction> transactions, String messageText) {
    final normalizedMessage = _normalizeText(messageText);
    final quoted = _extractQuotedValue(messageText);

    if (quoted != null && quoted.isNotEmpty) {
      final normalizedQuoted = _normalizeText(quoted);
      for (final tx in transactions) {
        final titleNorm = _normalizeText(tx.title);
        if (titleNorm.contains(normalizedQuoted) || normalizedQuoted.contains(titleNorm)) {
          return tx;
        }
      }
    }

    Transaction? best;
    var bestScore = -1;

    for (final tx in transactions) {
      final titleNorm = _normalizeText(tx.title);
      var score = 0;
      if (normalizedMessage.contains(titleNorm) && titleNorm.isNotEmpty) {
        score += 10;
      }

      final words = titleNorm.split(' ').where((w) => w.length >= 3);
      for (final word in words) {
        if (normalizedMessage.contains(word)) {
          score += 2;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = tx;
      }
    }

    if (bestScore <= 0) {
      final sorted = [...transactions]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return sorted.first;
    }

    return best;
  }

  Jar? _pickBestJar(List<Jar> jars, String messageText) {
    final normalizedMessage = _normalizeText(messageText);
    final quoted = _extractQuotedValue(messageText);

    if (quoted != null && quoted.isNotEmpty) {
      final normalizedQuoted = _normalizeText(quoted);
      for (final jar in jars) {
        final nameNorm = _normalizeText(jar.name);
        if (nameNorm.contains(normalizedQuoted) || normalizedQuoted.contains(nameNorm)) {
          return jar;
        }
      }
    }

    Jar? best;
    var bestScore = -1;

    for (final jar in jars) {
      final nameNorm = _normalizeText(jar.name);
      var score = 0;
      if (normalizedMessage.contains(nameNorm) && nameNorm.isNotEmpty) {
        score += 10;
      }

      final words = nameNorm.split(' ').where((w) => w.length >= 3);
      for (final word in words) {
        if (normalizedMessage.contains(word)) {
          score += 2;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = jar;
      }
    }

    return bestScore <= 0 ? jars.first : best;
  }

  double? _extractAmountFromText(String text) {
    final compactMillionRegex = RegExp(
      r'(\d+)\s*(tr|trieu|tri[eệ]u|m)\s*(\d{1,3})(?!\d)',
      caseSensitive: false,
    );
    final amountRegex = RegExp(
      r'((?:\d+[\d\.,]*)(?:\s*\d{3})?)\s*(k|ngan|nghin|ngh[iìíỉĩị]n|cu|c[uủ]|tr|trieu|tri[eệ]u|m|ty|t[yỷ])?',
      caseSensitive: false,
    );

    double? best;

    for (final match in compactMillionRegex.allMatches(text.toLowerCase())) {
      final major = double.tryParse(match.group(1) ?? '');
      final minorDigits = match.group(3) ?? '';
      final minor = double.tryParse('0.$minorDigits') ?? 0;
      if (major == null) {
        continue;
      }

      final value = (major + minor) * 1000000;
      if (best == null || value > best) {
        best = value;
      }
    }

    for (final match in amountRegex.allMatches(text.toLowerCase())) {
      final rawNumber = (match.group(1) ?? '').trim();
      var normalized = rawNumber.replaceAll(' ', '');
      final unit = (match.group(2) ?? '').trim();
      final hasDot = normalized.contains('.');
      final hasComma = normalized.contains(',');

      if (hasDot && hasComma) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else if (hasComma) {
        final firstComma = normalized.indexOf(',');
        final decimalDigits = normalized.length - firstComma - 1;
        if (unit.isNotEmpty && normalized.indexOf(',') == normalized.lastIndexOf(',') && decimalDigits <= 2) {
          normalized = normalized.replaceAll(',', '.');
        } else {
          normalized = normalized.replaceAll(',', '');
        }
      } else {
        final firstDot = normalized.indexOf('.');
        final decimalDigits = normalized.length - firstDot - 1;
        if (unit.isNotEmpty && normalized.indexOf('.') == normalized.lastIndexOf('.') && decimalDigits <= 2) {
          // Keep decimal separator for forms like 3.4tr.
        } else {
          normalized = normalized.replaceAll('.', '');
        }
      }

      final base = double.tryParse(normalized);
      if (base == null || base <= 0) {
        continue;
      }

      var value = base;
      if (RegExp(r'^(k|ngan|nghin|ngh[iìíỉĩị]n|cu|c[uủ])$').hasMatch(unit)) {
        value *= 1000;
      } else if (RegExp(r'^(tr|trieu|tri[eệ]u|m)$').hasMatch(unit)) {
        value *= 1000000;
      } else if (RegExp(r'^(ty|t[yỷ])$').hasMatch(unit)) {
        value *= 1000000000;
      }

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }

  String? _extractQuotedValue(String text) {
    final match = RegExp(r'''["']([^"']+)["']''').firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractRenameValue(String text) {
    final match = RegExp(r'(?:thanh|thành|la|là)\s+(.+)$', caseSensitive: false).firstMatch(text.trim());
    if (match == null) {
      return null;
    }

    final value = match.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final cleaned = value.replaceAll(RegExp(r'[\.,;:!]+$'), '').trim();
    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }

  bool _hasRenameIntent(String text) {
    final normalized = _normalizeText(text);
    return normalized.contains('doi ten') ||
        normalized.contains('sua ten') ||
        normalized.contains('cap nhat ten') ||
        normalized.contains('ten moi') ||
        normalized.contains('rename');
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref);
});
