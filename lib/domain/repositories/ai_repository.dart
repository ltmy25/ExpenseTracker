import 'dart:typed_data';

import 'package:expensetracker/domain/entities/ai_chat_response.dart';
import 'package:expensetracker/domain/entities/ai_receipt_analysis.dart';

abstract class AiRepository {
  Future<AiChatResponse> generateReply({
    required String message,
    required String financialContext,
  });

  Future<AiReceiptAnalysis> analyzeReceiptImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String financialContext,
  });
}
