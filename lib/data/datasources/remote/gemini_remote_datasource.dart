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
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-2.5-pro',
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
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Khong goi duoc Gemini model. Loi cuoi: $lastError');
  }
}
