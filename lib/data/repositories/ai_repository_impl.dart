import 'dart:convert';
import 'dart:typed_data';

import 'package:expensetracker/data/datasources/remote/gemini_remote_datasource.dart';
import 'package:expensetracker/domain/entities/ai_chat_response.dart';
import 'package:expensetracker/domain/entities/ai_receipt_analysis.dart';
import 'package:expensetracker/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._remoteDataSource);

  final GeminiRemoteDataSource _remoteDataSource;

  @override
  Future<AiChatResponse> generateReply({
    required String message,
    required String financialContext,
  }) async {
    final reply = await _remoteDataSource.generateReply(
      message: message,
      financialContext: financialContext,
    );

    final alerts = <String>[];
    final lower = reply.toLowerCase();
    if (lower.contains('vuot') || lower.contains('canh bao') || lower.contains('rui ro')) {
      alerts.add('Chi tieu co dau hieu can theo doi sat hon.');
    }

    return AiChatResponse(
      reply: reply,
      savingAdvice: lower.contains('tiet kiem') ? reply : null,
      spendingAlerts: alerts,
    );
  }

  @override
  Future<AiReceiptAnalysis> analyzeReceiptImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String financialContext,
  }) async {
    final raw = await _remoteDataSource.analyzeReceiptImage(
      imageBytes: imageBytes,
      mimeType: mimeType,
      financialContext: financialContext,
    );

    return _parseReceiptAnalysis(raw);
  }

  @override
  Future<AiReceiptAnalysis> analyzeReceiptText({
    required String ocrText,
    required String financialContext,
  }) async {
    final raw = await _remoteDataSource.analyzeReceiptText(
      ocrText: ocrText,
      financialContext: financialContext,
    );

    return _parseReceiptAnalysis(raw);
  }

  AiReceiptAnalysis _parseReceiptAnalysis(String raw) {
    try {
      final normalized = _extractJsonPayload(raw);
      final decoded = jsonDecode(normalized) as Map<String, dynamic>;

      final summary = (decoded['summary'] as String?)?.trim() ?? '';
      final totalValue = decoded['totalAmount'];
        final parsedTotalAmount = totalValue is num
          ? totalValue.toDouble()
          : double.tryParse((totalValue ?? '').toString());
        final netValue = decoded['netAmount'];
        final parsedNetAmount = netValue is num
          ? netValue.toDouble()
          : double.tryParse((netValue ?? '').toString());
      final categoryHint = (decoded['categoryHint'] as String?)?.trim();
      final transactionTypeHint = (decoded['transactionTypeHint'] as String?)?.trim();
      final rawItems = decoded['items'];
      final items = <AiReceiptItem>[];

      if (rawItems is List) {
        for (final entry in rawItems) {
          if (entry is! Map) continue;
          final name = (entry['name'] ?? '').toString().trim();
          final amountValue = entry['amount'];
          final amount = amountValue is num
              ? amountValue.toDouble()
              : double.tryParse(amountValue.toString());
          final itemType = (entry['itemType'] as String?)?.trim();

          if (name.isEmpty || amount == null || amount <= 0) {
            continue;
          }

          items.add(AiReceiptItem(name: name, amount: amount, itemType: itemType));
        }
      }

      final totalAmount = _resolveFinalTotalAmount(
        parsedTotalAmount: parsedTotalAmount,
        parsedNetAmount: parsedNetAmount,
        transactionTypeHint: transactionTypeHint,
        items: items,
      );

      return AiReceiptAnalysis(
        reply: summary,
        totalAmount: totalAmount,
        netAmount: parsedNetAmount,
        categoryHint: categoryHint,
        transactionTypeHint: transactionTypeHint,
        items: items,
      );
    } catch (_) {
      return AiReceiptAnalysis(reply: raw, items: const <AiReceiptItem>[]);
    }
  }

  double? _resolveFinalTotalAmount({
    required double? parsedTotalAmount,
    required double? parsedNetAmount,
    required String? transactionTypeHint,
    required List<AiReceiptItem> items,
  }) {
    if (parsedNetAmount != null && parsedNetAmount > 0) {
      return parsedNetAmount;
    }

    if (parsedTotalAmount != null && parsedTotalAmount > 0) {
      return parsedTotalAmount;
    }

    final typeHint = (transactionTypeHint ?? '').toLowerCase();
    if (typeHint != 'income') {
      return null;
    }

    var earnings = 0.0;
    var deductions = 0.0;
    var hasTypedItem = false;

    for (final item in items) {
      final itemType = (item.itemType ?? '').toLowerCase();
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
      return net > 0 ? net : null;
    }

    if (items.isEmpty) {
      return null;
    }

    var fallback = 0.0;
    for (final item in items) {
      fallback += item.amount;
    }
    return fallback > 0 ? fallback : null;
  }

  String _extractJsonPayload(String raw) {
    final cleaned = raw.trim();
    if (!cleaned.startsWith('```')) {
      return cleaned;
    }

    final noFenceStart = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
    return noFenceStart.replaceFirst(RegExp(r'\s*```$'), '').trim();
  }
}
