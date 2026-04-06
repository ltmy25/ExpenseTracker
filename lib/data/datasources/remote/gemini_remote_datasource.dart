import 'dart:typed_data';

import 'package:expensetracker/core/config/ai_local_config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiRemoteDataSource {
  const GeminiRemoteDataSource();

  Future<String> analyzeReceiptText({
    required String ocrText,
    required String financialContext,
  }) async {
    if (!AiLocalConfig.hasValidKey) {
      throw Exception('Gemini API key chua duoc cau hinh trong ai_local_config.dart');
    }

    final prompt = '''
Ban la tro ly quan ly chi tieu cho nguoi dung Viet Nam.
Duoi day la van ban OCR lay tu hoa don. Hay phan tich va tra ve JSON hop le DUY NHAT theo dung schema:
{
  "summary": "string",
  "totalAmount": 12345,
  "netAmount": 12345,
  "transactionTypeHint": "income|expense",
  "categoryHint": "an uong|di chuyen|mua sam|hoa don|suc khoe|giao duc|khac",
  "items": [
    {"name": "string", "amount": 12345, "itemType": "earning|deduction|other"}
  ]
}

Quy tac:
- Chi tra ve JSON, khong markdown, khong giai thich.
- totalAmount la tong thanh toan cuoi cung can tra (VND chi so).
- Neu khong chac chan totalAmount thi de null.
- netAmount la so tien NHAN CUOI CUNG. Neu transactionTypeHint=income va khong co dong tong nhan, tu tinh: tong earning - tong deduction.
- transactionTypeHint: income neu day la phieu luong/thu nhap/hoa hong/hoan tien; expense neu la hoa don chi tieu.
- categoryHint la nhom chi tieu phu hop nhat, uu tien gia tri ngan gon khong dau.
- items co the rong neu OCR khong ro.

Bo canh tai chinh:
$financialContext

OCR text:
$ocrText
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

    throw Exception('Khong goi duoc Gemini model (ocr text). Loi cuoi: $lastError');
  }

  Future<String> analyzeReceiptImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String financialContext,
  }) async {
    if (!AiLocalConfig.hasValidKey) {
      throw Exception('Gemini API key chua duoc cau hinh trong ai_local_config.dart');
    }

    final prompt = '''
Ban la tro ly quan ly chi tieu cho nguoi dung Viet Nam.
Hay phan tich anh bill va tra ve JSON hop le DUY NHAT theo dung schema:
{
  "summary": "string",
  "totalAmount": 12345,
  "netAmount": 12345,
  "transactionTypeHint": "income|expense",
  "categoryHint": "an uong|di chuyen|mua sam|hoa don|suc khoe|giao duc|khac",
  "items": [
    {"name": "string", "amount": 12345, "itemType": "earning|deduction|other"}
  ]
}

Quy tac:
- Chi tra ve JSON, khong them markdown, khong them giai thich.
- "items" chi gom cac dong mua hang co ten + don gia.
- Bo qua tong tien, VAT, discount, service charge, thong tin cua hang, thoi gian.
- totalAmount la tong thanh toan cuoi cung (neu xac dinh duoc), khong thi de null.
- netAmount la so tien NHAN CUOI CUNG. Neu transactionTypeHint=income va khong co dong tong nhan, tu tinh: tong earning - tong deduction.
- transactionTypeHint: income neu day la phieu luong/thu nhap/hoa hong/hoan tien; expense neu la hoa don chi tieu.
- amount la so VND (chi so, khong dau phay).
- itemType: earning cho khoan cong, deduction cho khoan tru, other neu khong ro.
- categoryHint la nhom chi tieu phu hop nhat, uu tien gia tri ngan gon khong dau.
- summary toi da 2 cau, ngan gon, huu ich.

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

        final response = await model.generateContent(<Content>[
          Content.multi(<Part>[
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        ]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Khong goi duoc Gemini model (image). Loi cuoi: $lastError');
  }

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
      'gemini-2.5-flash-lite',
      'gemini-3.1-flash-lite',
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
