lib/
│
├── core/                  # Dùng chung toàn app
│   ├── constants/
│   ├── utils/
│   ├── services/         # Firebase, AI, OCR base
│   └── theme/
│
├── data/                  # Tầng data
│   ├── models/           # UserModel, TransactionModel...
│   ├── datasources/
│   │   ├── remote/       # Firebase, API
│   │   └── local/        # Cache nếu có
│   └── repositories/     # Implement logic data
│
├── domain/                # Business logic
│   ├── entities/         # User, Transaction, Jar...
│   ├── repositories/     # Abstract class
│   └── usecases/         # Login, AddTransaction...
│
├── presentation/          # UI + State
│   ├── providers/        # Riverpod
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── transaction/
│   │   ├── jar/
│   │   ├── stats/
│   │   └── chat/
│   └── widgets/
│
├── routes/               # Điều hướng
├── main.dart

# Nhiệm vụ cần làm
Hệ thống & Tài khoản (đã xong)


- Thiết lập Project Flutter và kết nối Firebase Firestore. 
 - Xây dựng chức năng Đăng ký, Đăng nhập, Đăng xuất. 
 - Quản lý hồ sơ người dùng và đổi mật khẩu. 
 - Thiết kế cấu trúc bảng dữ liệu users.


Giao dịch & Danh mục (đã xong)


- Lập trình chức năng CRUD (Thêm, sửa, xóa, xem) các khoản thu và chi. 
 - Xây dựng hệ thống quản lý danh mục (Ăn uống, học tập...). 
 - Thiết kế giao diện và quản lý dữ liệu bảng transactions, categories.


Hũ chi tiêu & Thống kê (đã xong)


- Xây dựng chức năng Quản lý hũ chi tiêu (Tạo, nạp tiền, theo dõi số dư). 
 - Lập trình biểu đồ thống kê (tròn/cột) theo ngày, tháng, năm. 
 - Xây dựng logic so sánh chi tiêu giữa các kỳ.


Chatbot AI & Tư vấn (đã xong)


- Tích hợp AI API (OpenAI / Gemini) vào ứng dụng. 
 - Lập trình logic nhận diện tin nhắn để tự động tạo giao dịch. 
 - Xây dựng tính năng tư vấn tiết kiệm và cảnh báo chi tiêu. 
 - Quản lý dữ liệu hội thoại trong bảng chats.


Tích hợp OCR & Kiểm thử (cần thực hiện)


- Lập trình chức năng quét hóa đơn (OCR) để trích xuất tên món và giá tiền. 
 - Thực hiện kiểm thử (Testing) đảm bảo hiệu năng và bảo mật. 
 - Tổng hợp báo cáo, làm slide thuyết trình và chuẩn bị tài liệu tham khảo.



