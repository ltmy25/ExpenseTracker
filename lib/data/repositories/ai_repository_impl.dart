import 'package:expensetracker/data/datasources/remote/gemini_remote_datasource.dart';
import 'package:expensetracker/domain/entities/ai_chat_response.dart';
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
}
