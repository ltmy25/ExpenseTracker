# Expense Tracker

Ứng dụng Flutter quản lý tài chính cá nhân, hỗ trợ ghi chép thu/chi, hũ chi tiêu, thống kê trực quan, chatbot AI tư vấn tài chính và OCR hóa đơn.

## Tính năng chính

- Xác thực người dùng với Firebase Auth:
	- Đăng ký, đăng nhập email/password.
	- Đăng nhập Google.
	- Quên mật khẩu qua email reset.
- Quản lý hồ sơ:
	- Cập nhật tên hiển thị.
	- Cập nhật/xóa ảnh đại diện.
	- Đổi mật khẩu.
- Quản lý giao dịch:
	- CRUD giao dịch thu/chi.
	- Quản lý danh mục cá nhân + danh mục mặc định.
	- Tạo giao dịch từ OCR hóa đơn.
- Dashboard thống kê:
	- Tổng thu, tổng chi, thay đổi ròng.
	- Biểu đồ tròn theo danh mục.
	- Biểu đồ xu hướng chi tiêu theo tháng.
	- Lọc theo ngày/tháng/năm/toàn thời gian/khoảng ngày tùy chỉnh.
- Hũ chi tiêu (Jars):
	- Tạo/sửa/xóa hũ.
	- Theo dõi phần trăm sử dụng ngân sách.
	- Cảnh báo vượt hạn mức.
- Chatbot AI:
	- Tư vấn chi tiêu và gợi ý tiết kiệm.
	- Phân tích nội dung tin nhắn để tạo nháp giao dịch.
	- Quản lý nhiều phiên chat.
- OCR hóa đơn:
	- Native: Google ML Kit Text Recognition.
	- Web: Tesseract.js.
	- Kết hợp Gemini để phân tích nội dung hóa đơn và tổng tiền.

## Công nghệ sử dụng

- Flutter + Dart
- State management: Riverpod
- Backend/BaaS: Firebase
	- Firebase Auth
	- Cloud Firestore
- AI: Google Gemini (`google_generative_ai`)
- OCR: `google_mlkit_text_recognition` + Tesseract.js (web)
- Chart: `fl_chart`

## Cấu trúc thư mục

```text
lib/
├── core/
│   ├── config/         # Cấu hình cục bộ (AI key)
│   ├── constants/      # Hằng số Firestore collections
│   ├── services/       # Firebase init, OCR, parser...
│   └── theme/
├── data/
│   ├── datasources/remote/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── providers/
│   └── screens/
│       ├── auth/
│       ├── home/
│       ├── transaction/
│       ├── jar/
│       └── chat/
├── routes/
└── main.dart
```

## Yêu cầu môi trường

- Flutter SDK 3.x
- Dart SDK tương thích (`sdk: ^3.10.7`)
- Firebase project đã cấu hình cho nền tảng bạn chạy

## Hướng dẫn chạy dự án

### 1) Cài dependency

```bash
flutter pub get
```

### 2) Cấu hình Firebase

Project đã có file cấu hình sẵn cho Android/iOS và `firebase_options.dart`.

Nếu bạn dùng Firebase project khác:

1. Chạy FlutterFire CLI để generate lại cấu hình.
2. Cập nhật các file `google-services.json` / `GoogleService-Info.plist` tương ứng.

### 3) Cấu hình Gemini API key

Mở file:

`lib/core/config/ai_local_config.dart`

Thay giá trị:

```dart
static const String geminiApiKey = 'GEMINI_API_KEY';
```

bằng API key thật của bạn.

### 4) Chạy app

```bash
flutter run
```

Ví dụ chạy Android emulator:

```bash
flutter emulators --launch <emulator_id>
flutter run
```

## Firestore collections đang dùng

- `users`
- `transactions`
- `categories`
- `jars`
- `chats`
	- subcollection: `messages`

Các collection constants được định nghĩa tại `lib/core/constants/firestore_collections.dart`.

## Security rules

File rules hiện tại: `firestore.rules`

Nguyên tắc chính:

- Người dùng chỉ đọc/ghi dữ liệu của chính mình (`userId == request.auth.uid`).
- Danh mục mặc định (`isDefault == true`) cho phép đọc chung.
- Tin nhắn chat chỉ cho phép truy cập nếu là chủ chat.

Triển khai rules:

```bash
firebase deploy --only firestore:rules
```

## OCR và AI trong dự án

- `ReceiptOcrService` trích xuất text/tổng tiền/mặt hàng từ ảnh hóa đơn.
- `TransactionMessageParser` phân tích tin nhắn tự nhiên thành nháp giao dịch (số tiền, loại giao dịch, gợi ý danh mục).
- `GeminiRemoteDataSource` dùng Gemini để:
	- trả lời tư vấn chi tiêu,
	- phân tích OCR text/ảnh hóa đơn thành JSON có cấu trúc.

## App icon

Dự án dùng `flutter_launcher_icons` với nguồn icon hiện tại là:

- `icon.png`

Generate lại icon:

```bash
dart run flutter_launcher_icons
```

## Kiểm tra chất lượng mã

```bash
flutter analyze
```

## Lưu ý

- Một số file trong `linux/flutter/` và tương tự là file generated, không chỉnh sửa thủ công.
- Chat AI phụ thuộc trực tiếp vào API key Gemini cục bộ.
- Khi đổi Firebase project, cần đồng bộ lại toàn bộ cấu hình đa nền tảng.

## Định hướng mở rộng

- Đồng bộ ngân sách theo chu kỳ nâng cao (tuần/quý).
- Xuất báo cáo PDF/CSV.
- Unit test và integration test cho parser/OCR/chat flows.
- CI/CD cho build và kiểm thử tự động.



