# Food Delivery App

Ứng dụng giao đồ ăn đa vai trò gồm:

- `Buyer`: tìm món, thêm giỏ hàng, đặt đơn, thanh toán, theo dõi đơn
- `Seller`: quản lý quán, món ăn, topping, đơn hàng, mã giảm giá, chương trình hiển thị
- `Shipper`: nhận đơn theo vị trí, cập nhật trạng thái giao hàng, quản lý thu nhập và ví
- `Admin`: thống kê hệ thống, quản lý người dùng, duyệt form seller/shipper, quản lý chương trình hiển thị

Repo hiện có 2 phần chính:

- `Backend/`: FastAPI + SQLAlchemy + PostgreSQL
- `Frontend/`: Flutter mobile app

## 1. Tính năng chính

### Buyer

- Đăng ký, đăng nhập, quên mật khẩu bằng OTP email
- Xem danh mục món ăn, danh sách món, chi tiết nhà hàng/quán
- Thêm món vào giỏ hàng, cập nhật số lượng, xóa món
- Lấy vị trí hiện tại, geocoding địa chỉ giao hàng
- Áp dụng mã giảm giá khi checkout
- Thanh toán qua:
  - `SePay` bằng mã QR/chuyển khoản
  - `Stripe` cho luồng thanh toán online
- Theo dõi trạng thái đơn hàng theo từng bước
- Yêu thích món ăn
- Cập nhật hồ sơ, đổi mật khẩu
- Gửi form đăng ký trở thành seller hoặc shipper
- Xem các chương trình hiển thị và món nổi bật

### Seller

- Quản lý hồ sơ quán
- Bật/tắt trạng thái hoạt động của quán
- Quản lý danh mục món ăn
- Quản lý món ăn, mô tả, giá, hình ảnh
- Upload ảnh món ăn lên Supabase Storage
- Quản lý topping và ràng buộc topping theo món
- Xem đơn hàng theo quán
- Đánh dấu đơn hoàn tất
- Tạo và quản lý mã giảm giá
- Tham gia chương trình hiển thị do admin tạo
- Cấu hình món muốn hiển thị trong chương trình
- Theo dõi doanh thu, ví và lịch sử rút tiền

### Shipper

- Xem dashboard giao hàng
- Chuyển online/offline để nhận đơn
- Cập nhật vị trí hiện tại theo GPS
- Nhận danh sách đơn phù hợp bán kính hoạt động
- Nhận đơn theo thời gian thực qua WebSocket
- Chấp nhận đơn, xác nhận lấy hàng, giao hàng thành công
- Xem lịch sử đơn đã giao
- Xem thu nhập ngày/tuần/tháng
- Quản lý ví shipper
- Nạp tiền ví bằng SePay
- Rút tiền và xem lịch sử giao dịch
- Cập nhật hồ sơ shipper

### Admin

- Xem thống kê tổng quan:
  - tổng người dùng
  - tổng buyer/seller/shipper
  - tổng đơn hàng
  - doanh thu
  - tổng món ăn
- Quản lý người dùng
- Khóa/mở khóa tài khoản
- Đổi vai trò người dùng
- Xem danh sách đơn hàng
- Duyệt/từ chối form seller
- Duyệt/từ chối form shipper
- Quản lý chương trình hiển thị/quảng bá

## 2. Công nghệ sử dụng

### Frontend

- `Flutter`
- `Provider` để quản lý state
- `http` để gọi REST API
- `shared_preferences` và lưu cấu hình API runtime
- `geolocator`, `geocoding` cho vị trí và địa chỉ
- `google_maps_flutter`, `flutter_map`, `latlong2` cho bản đồ
- `supabase_flutter` để làm việc với Supabase
- `url_launcher` để mở liên kết ngoài
- `web_socket_channel` cho realtime shipper
- `flutter_stripe` cho thanh toán Stripe

### Backend

- `FastAPI`
- `SQLAlchemy`
- `PostgreSQL`
- `python-dotenv`
- `python-jose` để xử lý JWT
- `passlib` với `argon2/bcrypt` để hash password
- `stripe` cho thanh toán Stripe
- `supabase` cho upload/lưu trữ ảnh
- `WebSocket` để đẩy đơn realtime cho shipper

### Dịch vụ ngoài

- `Supabase`
  - lưu trữ hình ảnh món ăn
  - có thể dùng PostgreSQL Supabase thay cho PostgreSQL local
- `Stripe`
  - tạo payment intent
  - webhook xác nhận thanh toán
- `SePay`
  - tạo QR chuyển khoản
  - webhook xác nhận giao dịch
- `Google Maps`
  - hiển thị bản đồ trên Android

## 3. Kiến trúc tổng quan

```text
Flutter App
  -> gọi REST API đến FastAPI backend
  -> nhận realtime shipper qua WebSocket

FastAPI Backend
  -> lưu dữ liệu vào PostgreSQL
  -> upload ảnh lên Supabase Storage
  -> tích hợp Stripe / SePay

PostgreSQL
  -> users, sellers, shippers, dishes, toppings, cart_items, orders, payments...
```

## 4. Cấu trúc thư mục

```text
FoodDeliveryApp/
├─ Backend/
│  ├─ main.py
│  ├─ database.py
│  ├─ models.py
│  ├─ schemas.py
│  ├─ routers/
│  ├─ services/
│  └─ requirements.txt
├─ Frontend/
│  ├─ lib/
│  │  ├─ config/
│  │  ├─ models/
│  │  ├─ providers/
│  │  ├─ routes/
│  │  ├─ screen/
│  │  ├─ services/
│  │  └─ widgets/
│  └─ pubspec.yaml
└─ README.md
```

## 5. API module chính của backend

Các router đang có trong dự án:

- `/auth`: đăng ký, đăng nhập, quên mật khẩu, đổi role
- `/profile`: hồ sơ cá nhân, đổi mật khẩu
- `/api/category`: CRUD danh mục
- `/api/dish`: CRUD món ăn, upload ảnh
- `/api/topping`: CRUD topping
- `/cart`: giỏ hàng, checkout, lịch sử đơn buyer, đơn seller
- `/favorites`: danh sách yêu thích
- `/discount-codes`: mã giảm giá và validate mã
- `/seller`: hồ sơ seller, doanh thu, ví, trạng thái quán
- `/shipper`: dashboard, location, trạng thái online, nhận/giao đơn, ví
- `/admin`: dashboard admin, user management, duyệt form
- `/display`: chương trình hiển thị cho admin/seller/buyer
- `/api/sepay`: tạo thanh toán SePay, kiểm tra trạng thái, webhook
- `WebSocket /ws/orders`: realtime đơn hàng cho shipper

## 6. Yêu cầu môi trường

Nên chuẩn bị:

- `Python 3.10+`
- `PostgreSQL 14+`
- `Flutter SDK` tương thích `Dart >= 3.0.0 < 4.0.0`
- `Android Studio` hoặc `VS Code + Flutter extension`
- `JDK 21` vì Android project đang build với Java/Kotlin 21

## 7. Cài đặt backend

### Bước 1: tạo virtual environment

```powershell
cd Backend
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### Bước 2: cài thư viện Python

```powershell
pip install --upgrade pip
pip install -r requirements.txt
```

### Bước 3: cấu hình file môi trường

Tạo file `.env` từ file mẫu:

```powershell
Copy-Item .env.example .env
```

Các biến chính:

- `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_PORT`: dùng PostgreSQL local
- `DATABASE_URL` hoặc `DB_URL`: dùng connection string đầy đủ, ví dụ PostgreSQL của Supabase
- `BACKEND_HOST`, `BACKEND_PORT`, `BACKEND_RELOAD`: cấu hình server
- `CORS_ALLOWED_ORIGINS`: danh sách domain frontend được gọi API
- `STRIPE_API_KEY`, `STRIPE_ENDPOINT_SECRET`: dùng cho Stripe
- `SEPAY_*`: dùng cho thanh toán và webhook SePay

Lưu ý:

- `Backend/database.py` ưu tiên đọc `DATABASE_URL`/`DB_URL`, nếu không có mới ghép từ `DB_*`
- Khi backend khởi động, project sẽ tự tạo bảng và chạy một số hàm setup/migration cơ bản

### Bước 4: tạo database PostgreSQL

Ví dụ với PostgreSQL local:

```sql
CREATE DATABASE food_delivery_app;
```

Sau đó chỉnh `.env`:

```env
DB_HOST=localhost
DB_NAME=food_delivery_app
DB_USER=postgres
DB_PASSWORD=your_password
DB_PORT=5432
```

### Bước 5: chạy backend

```powershell
python main.py
```

Hoặc dùng uvicorn:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Bước 6: kiểm tra backend

Sau khi chạy thành công:

- API root: `http://localhost:8000/`
- Swagger docs: `http://localhost:8000/docs`

## 8. Cài đặt frontend Flutter

### Bước 1: cài package Dart/Flutter

```powershell
cd Frontend
flutter pub get
```

### Bước 2: cấu hình Google Maps cho Android

App Android đang đọc `MAPS_API_KEY` từ:

- `Frontend/android/gradle.properties`
- `Frontend/android/app/build.gradle.kts`

Bạn cần thay `MAPS_API_KEY` bằng key của dự án Google Maps của bạn.

### Bước 3: cấu hình địa chỉ backend

App dùng `Frontend/lib/config/api_config.dart`.

Các trường hợp chạy:

- Android emulator:
  - mặc định app dùng `http://10.0.2.2:8000`
- Web/iOS/desktop:
  - mặc định app dùng `http://localhost:8000`
- Android thật:
  - nên truyền `--dart-define=API_BASE_URL_ANDROID_DEVICE=http://<LAN_IP>:8000`

Ví dụ chạy trên Android thật:

```powershell
flutter run --dart-define=API_BASE_URL_ANDROID_DEVICE=http://192.168.1.10:8000
```

Ví dụ ép toàn bộ app dùng một URL cố định:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Bước 4: chạy app

```powershell
flutter run
```

## 9. Cấu hình dịch vụ ngoài

### PostgreSQL / Supabase Database

Project có thể chạy với:

- PostgreSQL local
- PostgreSQL của Supabase thông qua `DATABASE_URL`

Nếu dùng Supabase DB, chỉ cần đặt `DATABASE_URL` đúng format PostgreSQL.

### Supabase Storage

Hiện tại backend upload ảnh món ăn qua `Backend/supabase_client.py`.

Lưu ý quan trọng:

- file này đang chứa `SUPABASE_URL` và `SUPABASE_SERVICE_KEY` trực tiếp trong source
- trước khi deploy/public repo, nên thay bằng khóa của dự án riêng của bạn
- nên chuyển các giá trị này sang biến môi trường để an toàn hơn

Frontend cũng đang khởi tạo Supabase trực tiếp trong `Frontend/lib/main.dart`, vì vậy nếu đổi project Supabase bạn cần sửa lại file này.

### Stripe

Luồng Stripe được xử lý ở:

- `Backend/routers/payment_router.py`

Cần cấu hình:

- `STRIPE_API_KEY`
- `STRIPE_ENDPOINT_SECRET`

Nếu test local webhook, bạn có thể dùng Stripe CLI hoặc công cụ tunnel như `ngrok`.

### SePay

Luồng SePay được xử lý ở:

- `Backend/routers/sepay_router.py`

Cần cấu hình:

- `SEPAY_ACCOUNT_NUMBER`
- `SEPAY_BANK_CODE`
- `SEPAY_ACCOUNT_NAME`
- `SEPAY_WEBHOOK_SECRET`

Nếu test webhook local, bạn cũng cần public backend bằng tunnel.

### Email OTP

Chức năng quên mật khẩu đang gửi OTP qua `Backend/email_utils.py`.

Lưu ý:

- email SMTP hiện đang đặt trực tiếp trong source
- nếu muốn dùng tài khoản email khác, bạn cần sửa file này trước khi chạy thật
- nên chuyển thông tin SMTP sang biến môi trường nếu triển khai production

## 10. Luồng chạy đề xuất khi phát triển

### Cách 1: PostgreSQL local

1. Chạy PostgreSQL local
2. Cấu hình `.env` trong `Backend/`
3. Chạy backend ở cổng `8000`
4. Chạy Flutter app
5. Nếu dùng Android thật, truyền `API_BASE_URL_ANDROID_DEVICE`

### Cách 2: PostgreSQL qua Supabase

1. Tạo project Supabase
2. Lấy connection string PostgreSQL và gán vào `DATABASE_URL`
3. Cập nhật `supabase_client.py` và `main.dart` theo project Supabase của bạn
4. Chạy backend
5. Chạy Flutter app

## 11. Một số điểm cần lưu ý trong repo hiện tại

- Repo đang có một số cấu hình nhạy cảm nằm trực tiếp trong source/code nội bộ:
  - `Backend/.env`
  - `Backend/supabase_client.py`
  - `Backend/email_utils.py`
  - `Frontend/android/gradle.properties`
  - `Frontend/lib/main.dart`
- Nếu đưa repo lên public hoặc deploy production, nên:
  - thay toàn bộ secret/key hiện tại
  - chuyển secret sang biến môi trường hoặc secret manager
  - giữ `.env` thật ngoài git

## 12. Troubleshooting

### Android thật không gọi được backend

- Không dùng `10.0.2.2` trên máy Android thật
- Hãy chạy backend với host `0.0.0.0`
- Điện thoại và máy chạy backend phải cùng Wi-Fi/LAN
- Dùng:

```powershell
flutter run --dart-define=API_BASE_URL_ANDROID_DEVICE=http://<IP-LAN>:8000
```

### Lỗi CORS

- Kiểm tra `CORS_ALLOWED_ORIGINS` trong `.env`
- Backend hiện cho phép `localhost`/`127.0.0.1` qua regex, nhưng domain khác phải thêm thủ công

### Lỗi kết nối database

- Kiểm tra lại `DATABASE_URL` hoặc `DB_*`
- Xác nhận PostgreSQL đang chạy
- Xác nhận user/password/database đúng

### Ảnh món ăn upload lỗi

- Kiểm tra lại key Supabase trong `Backend/supabase_client.py`
- Kiểm tra bucket/quyền của Supabase Storage

### Thanh toán không tự xác nhận

- Kiểm tra webhook Stripe/SePay đã trỏ đúng vào backend chưa
- Khi test local, nên dùng tunnel public

## 13. Lệnh nhanh

### Backend

```powershell
cd Backend
.venv\Scripts\Activate.ps1
python main.py
```

### Frontend

```powershell
cd Frontend
flutter pub get
flutter run --dart-define=API_BASE_URL_ANDROID_DEVICE=http://192.168.1.10:8000
```

## 14. Gợi ý cải thiện tiếp theo

- Tách toàn bộ secret khỏi source code
- Tạo `docker-compose.yml` cho backend + PostgreSQL
- Thêm `requirements` pin version rõ ràng
- Thêm seed data và test account mẫu
- Đồng bộ cấu hình Supabase/SMTP hoàn toàn qua `.env`

