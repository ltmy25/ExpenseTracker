import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/transaction.dart';
import 'package:expensetracker/presentation/providers/category_providers.dart';
import 'package:expensetracker/presentation/providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _showSessionActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Xóa chat hiện tại (giữ phiên)'),
                onTap: () => Navigator.pop(context, 'clear_chat'),
              ),
              ListTile(
                leading: const Icon(Icons.add_comment_outlined),
                title: const Text('Tạo phiên chat mới'),
                onTap: () => Navigator.pop(context, 'new'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa phiên chat hiện tại'),
                onTap: () => Navigator.pop(context, 'delete_session'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'clear_chat') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa chat hiện tại?'),
          content: const Text('Toàn bộ tin nhắn trong phiên hiện tại sẽ bị xóa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(chatControllerProvider.notifier).clearCurrentChat();
      }
      return;
    }

    if (action == 'new') {
      await ref.read(chatControllerProvider.notifier).createNewChatSession();
      return;
    }

    if (action == 'delete_session') {
      final selectedChatId = ref.read(chatControllerProvider).selectedChatId;
      if (selectedChatId == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa phiên chat?'),
          content: const Text('Toàn bộ tin nhắn trong phiên này sẽ bị xóa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(chatControllerProvider.notifier).deleteChatSession(selectedChatId);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
    await ref.read(chatControllerProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chatbot AI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            fontSize: 20,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        centerTitle: false,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF74C69D),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x26000000),
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF52B788), Color(0xFF40916C), Color(0xFF2D6A4F)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showSessionActions,
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Quản lý phiên chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final sessionsAsync = ref.watch(chatSessionsProvider);
              final selectedChatId = ref.watch(
                chatControllerProvider.select((state) => state.selectedChatId),
              );

              return sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    height: 52,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final selected = session.id == selectedChatId;

                        return ChoiceChip(
                          selected: selected,
                          onSelected: (_) {
                            ref.read(chatControllerProvider.notifier).selectChatSession(session.id);
                          },
                          label: Text(
                            session.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 6),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final messagesAsync = ref.watch(chatMessagesProvider);
                final isAiTyping = ref.watch(
                  chatControllerProvider.select((state) => state.isAiTyping),
                );

                return messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Hãy gửi tin nhắn để bắt đầu tư vấn chi tiêu.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      itemCount: messages.length + (isAiTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isAiTyping && index == messages.length) {
                          return const _TypingBubble();
                        }

                        final item = messages[index];
                        return _MessageBubble(
                          message: item,
                          onDelete: () async {
                            await ref.read(chatControllerProvider.notifier).deleteMessage(item.id);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Lỗi tải chat: $error')),
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final chatState = ref.watch(chatControllerProvider);
              if (chatState.pendingDraft == null) {
                return const SizedBox.shrink();
              }

              final categoriesAsync = ref.watch(categoriesStreamProvider);
              return categoriesAsync.when(
                data: (categories) {
                  final filtered = categories
                      .where((c) => c.type == chatState.pendingDraft!.type)
                      .toList();

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã nhận diện giao dịch từ tin nhắn',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Tiêu đề: ${chatState.pendingDraft!.title}'),
                        Text('Số tiền: ${currency.format(chatState.pendingDraft!.amount)}'),
                        Text(
                          'Loại: ${chatState.pendingDraft!.type == TransactionType.income ? 'Thu nhập' : 'Chi tiêu'}',
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: chatState.selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Chọn danh mục',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: filtered
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            ref.read(chatControllerProvider.notifier).selectCategory(value);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ref.read(chatControllerProvider.notifier).discardPendingDraft();
                                },
                                child: const Text('Bỏ qua'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await ref.read(chatControllerProvider.notifier).confirmPendingDraft();
                                },
                                child: const Text('Xác nhận lưu'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final errorMessage = ref.watch(
                chatControllerProvider.select((state) => state.errorMessage),
              );
              if (errorMessage == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat_input_field'),
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Hôm nay ăn trưa 45k',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final isSending = ref.watch(
                        chatControllerProvider.select((state) => state.isSending),
                      );
                      return IconButton.filled(
                        onPressed: isSending ? null : _send,
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onDelete,
  });

  final ChatMessage message;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    final bgColor = isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () async {
            await onDelete();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text),
                if (message.savingAdvice != null && message.savingAdvice!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Gợi ý: ${message.savingAdvice}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (message.spendingAlerts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final alert in message.spendingAlerts)
                    Text(
                      'Cảnh báo: $alert',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('AI đang trả lời...'),
          ],
        ),
      ),
    );
  }
}
