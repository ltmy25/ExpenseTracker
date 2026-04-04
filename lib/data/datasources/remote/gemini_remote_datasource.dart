import 'package:expensetracker/core/config/ai_local_config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiRemoteDataSource {
  const GeminiRemoteDataSource();

  Future<String> generateReply({
    required String message,
    required String financialContext,
  }) async {
    if (!AiLocalConfig.hasValidKey) {
      throw Exception('Gemini API key chua duoc cau hinh trong ai_local_config.dart');
    }

    final prompt = '''
Ban la tro ly quan ly chi tieu cho nguoi dung Viet Nam.
- Tra loi ngan gon, ro rang, toi da 6 dong.
- Neu co, dua 1-2 goi y tiet kiem cu the.
- Neu thay chi tieu co dau hieu vuot muc, canh bao lich su.

Tin nhan nguoi dung:
$message

Bo canh tai chinh:
$financialContext
''';

    const candidateModels = <String>[
      'gemini-2.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemma-3-12b-it',
    ];

    Object? lastError;

    for (final modelName in candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: AiLocalConfig.geminiApiKey,
        );

        final response = await model.generateContent(<Content>[Content.text(prompt)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }

        // Empty response is treated as non-fatal and can try next candidate.
        lastError = 'Model $modelName returned empty text.';
      } catch (error) {
        lastError = error;
        final errorText = error.toString().toLowerCase();

        if (_isQuotaError(errorText)) {
          throw Exception(
            'Bạn đã vượt hạn mức Gemini API (quota). Vui lòng chờ reset quota hoặc dùng API key/project khác.',
          );
        }

        if (_isAuthOrPermissionError(errorText)) {
          throw Exception(
            'API key Gemini không hợp lệ hoặc không có quyền. Vui lòng kiểm tra lại key/project.',
          );
        }

        // Only fallback to next model for unsupported/not-found model issues.
        if (!_isModelCompatibilityError(errorText)) {
          throw Exception('Không gọi được model $modelName: $error');
        }
      }
    }

    throw Exception('Không gọi được Gemini model. Lỗi cuối: $lastError');
  }

  bool _isQuotaError(String errorText) {
    return errorText.contains('quota') ||
        errorText.contains('resource_exhausted') ||
        errorText.contains('429');
  }

  bool _isAuthOrPermissionError(String errorText) {
    return errorText.contains('api key not valid') ||
        errorText.contains('permission denied') ||
        errorText.contains('unauthorized') ||
        errorText.contains('403') ||
        errorText.contains('401');
  }

  bool _isModelCompatibilityError(String errorText) {
    return errorText.contains('not found') ||
        errorText.contains('is not supported for generatecontent') ||
        errorText.contains('unknown model') ||
        errorText.contains('404');
  }
}
