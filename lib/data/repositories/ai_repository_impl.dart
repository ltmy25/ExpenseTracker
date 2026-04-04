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

    try {
      final normalized = _extractJsonPayload(raw);
      final decoded = jsonDecode(normalized) as Map<String, dynamic>;

      final summary = (decoded['summary'] as String?)?.trim() ?? '';
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

          if (name.isEmpty || amount == null || amount <= 0) {
            continue;
          }

          items.add(AiReceiptItem(name: name, amount: amount));
        }
      }

      return AiReceiptAnalysis(reply: summary, items: items);
    } catch (_) {
      return AiReceiptAnalysis(reply: raw, items: const <AiReceiptItem>[]);
    }
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
