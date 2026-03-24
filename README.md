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