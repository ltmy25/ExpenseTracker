# Đề Cương
Hệ thống quản lý chi tiêu tích hợp chatbot AI” nhằm phát triển một ứng dụng hỗ trợ người dùng theo dõi, quản lý và tối ưu hóa chi tiêu cá nhân một cách hiệu quả. Hệ thống cho phép người dùng ghi nhận các khoản thu – chi, phân loại chi tiêu theo danh mục, thống kê và trực quan hóa dữ liệu thông qua biểu đồ.
Điểm nổi bật của đề tài là tích hợp chatbot AI, giúp người dùng tương tác tự nhiên bằng ngôn ngữ, hỗ trợ nhập liệu nhanh, tư vấn quản lý tài chính, đưa ra gợi ý tiết kiệm và phân tích thói quen chi tiêu.
Hệ thống được xây dựng với mục tiêu nâng cao trải nghiệm người dùng, tăng tính tiện lợi và thông minh trong quản lý tài chính cá nhân, đồng thời ứng dụng các công nghệ hiện đại như trí tuệ nhân tạo và cơ sở dữ liệu thời gian thực.

I.	CÁC MỤC TIÊU CHÍNH

1.	Xây dựng hệ thống hỗ trợ người dùng quản lý các khoản thu – chi cá nhân một cách hiệu quả và khoa học.
2.	Cung cấp chức năng phân loại, lưu trữ và tìm kiếm các giao dịch tài chính theo danh mục.
3.	Trực quan hóa dữ liệu chi tiêu thông qua biểu đồ và thống kê để giúp người dùng dễ dàng theo dõi.
4.	Tích hợp chatbot AI nhằm hỗ trợ nhập liệu nhanh và tương tác bằng ngôn ngữ tự nhiên.
5.	Đưa ra các gợi ý, phân tích và tư vấn giúp người dùng tối ưu hóa thói quen chi tiêu.
6.	Ứng dụng công nghệ hiện đại (như AI và cơ sở dữ liệu thời gian thực) để nâng cao trải nghiệm và tính tiện lợi cho người dùng.
* Phạm vi và giới hạn
- Phạm vi:
•Phát triển ứng dụng quản lý chi tiêu cá nhân trên nền tảng di động.
•  Cho phép người dùng thực hiện các chức năng cơ bản: thêm, sửa, xóa và xem các khoản thu – chi.
•  Hỗ trợ phân loại chi tiêu theo danh mục và theo thời gian (ngày, tháng, năm).
•  Cung cấp thống kê và biểu đồ để theo dõi tình hình tài chính cá nhân.
•  Tích hợp chatbot AI hỗ trợ nhập liệu, trả lời câu hỏi và đưa ra gợi ý quản lý chi tiêu.
•  Sử dụng cơ sở dữ liệu thời gian thực (ví dụ Firebase Firestore) để lưu trữ và đồng bộ dữ liệu.
- Giới hạn:
•  Ứng dụng chỉ phục vụ quản lý chi tiêu cá nhân, chưa hỗ trợ quản lý tài chính cho doanh nghiệp hoặc tổ chức lớn.
•  Chức năng chatbot AI ở mức cơ bản, chủ yếu hỗ trợ hội thoại và gợi ý, chưa thay thế chuyên gia tài chính.
•  Chưa tích hợp trực tiếp với ngân hàng hoặc ví điện tử để tự động lấy dữ liệu giao dịch.
•  Độ chính xác của các phân tích và gợi ý phụ thuộc vào dữ liệu người dùng nhập vào.
•  Bảo mật ở mức cơ bản (đăng nhập, xác thực), chưa triển khai các cơ chế bảo mật nâng cao.
•  Hiệu năng và khả năng mở rộng hệ thống còn giới hạn trong phạm vi người dùng nhỏ đến trung bình.
II.	NỘI DUNG CHÍNH
1.	Phân tích yêu cầu hệ thống, xác định tác nhân và các chức năng cần có.
1.1. Mô tả hệ thống
Hệ thống là ứng dụng di động phát triển bằng Flutter, cho phép người dùng:
•	Quản lý các khoản thu/chi cá nhân
•	Thống kê và phân tích tài chính
•	Tương tác với chatbot AI để nhận tư vấn chi tiêu
________________________________________
1.2. Tác nhân (Actors)
👤 Người dùng (User)
•	Là người sử dụng chính của hệ thống
•	Thực hiện các thao tác quản lý chi tiêu và chat với AI
🤖 Hệ thống AI (Chatbot)
•	Nhận câu hỏi từ người dùng
•	Phân tích dữ liệu chi tiêu
•	Đưa ra phản hồi/gợi ý
________________________________________
1.3. Các chức năng chính (Use Cases)
🔐 a. Quản lý tài khoản
•	Đăng ký
•	Đăng nhập
•	Đăng xuất
________________________________________
💰 b. Quản lý chi tiêu
•	Thêm giao dịch (thu / chi)
•	Sửa giao dịch
•	Xóa giao dịch
•	Xem danh sách giao dịch
________________________________________
📊 c. Thống kê & báo cáo
•	Tổng thu / tổng chi theo:
o	ngày / tháng / năm
•	Biểu đồ chi tiêu theo danh mục
•	So sánh chi tiêu
________________________________________
🏷️ d. Quản lý danh mục
•	Thêm danh mục (ăn uống, học tập…)
•	Sửa / xóa danh mục
________________________________________
🤖 e. Chatbot AI
•	Nhận câu hỏi từ người dùng
•	Trả lời dựa trên:
o	dữ liệu chi tiêu
o	AI API (OpenAI / Gemini)
•	Gợi ý:
o	tiết kiệm
o	cảnh báo chi tiêu cao
________________________________________
⚙️ f. Cài đặt
•	Đổi thông tin cá nhân
•	Đổi mật khẩu
________________________________________
1.4. Yêu cầu chức năng (Functional Requirements)
•	Người dùng phải đăng nhập để sử dụng
•	Cho phép CRUD giao dịch
•	Tự động tính tổng chi tiêu
•	Chatbot trả lời dựa trên dữ liệu thực tế
________________________________________
1.5. Yêu cầu phi chức năng (Non-functional Requirements)
•	Giao diện thân thiện, dễ dùng
•	Phản hồi nhanh (< 2s với thao tác cơ bản)
•	Bảo mật dữ liệu người dùng
•	Có thể mở rộng (thêm AI, analytics)

2.	Thiết kế cơ sở dữ liệu.
2.1. Thiết kế cơ sở dữ liệu (Firestore)
👉 Sử dụng Firebase Firestore (NoSQL)
________________________________________



2.2.	Sơ đồ tổng quát
users (collection)
 └── userId (document)
      ├── name
      ├── email
      ├── createdAt

      ├── categories (subcollection)
      │     └── categoryId
      │           ├── name
      │           ├── type (income/expense)

      ├── transactions (subcollection)
      │     └── transactionId
      │           ├── amount
      │           ├── type (income/expense)
      │           ├── categoryId
      │           ├── note
      │           ├── date

      ├── chats (subcollection)
            └── chatId
                  ├── message
                  ├── isUser (true/false)
                  ├── timestamp
________________________________________
2.3.	Chi tiết các bảng (collections)
👤 users
Field	Type	Mô tả
userId	string	ID người dùng
name	string	Tên
email	string	Email
createdAt	timestamp	Ngày tạo
________________________________________


🏷️ categories
Field	Type	Mô tả
categoryId	string	ID danh mục
name	string	Tên danh mục
type	string	income / expense
________________________________________
💰 transactions
Field	Type	Mô tả
transactionId	string	ID
amount	number	Số tiền
type	string	income / expense
categoryId	string	Liên kết danh mục
note	string	Ghi chú
date	timestamp	Thời gian
________________________________________
🤖 chats
Field	Type	Mô tả
message	string	Nội dung
isUser	bool	Tin nhắn người dùng
timestamp	timestamp	Thời gian
________________________________________
2.3. Quan hệ dữ liệu
•	1 user → nhiều transactions
•	1 user → nhiều categories
•	1 user → nhiều chat messages
