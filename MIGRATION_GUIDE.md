# Hướng Dẫn Migration: Phân Chia Thực Đơn Theo Seller

## Tổng Quan

Hệ thống đã được cập nhật để **mỗi seller có thực đơn riêng**. Các thay đổi chính:

### Backend:
- ✅ Thêm `seller_id` vào các bảng: `category`, `dish`, `topping`
- ✅ Tất cả API endpoints giờ yêu cầu authentication token
- ✅ API tự động filter dữ liệu theo seller đang đăng nhập
- ✅ Seller chỉ có thể CRUD danh mục/món ăn/topping của chính họ

### Frontend:
- ✅ Tất cả API calls giờ gửi authentication token
- ✅ Tự động lấy token từ secure storage
- ✅ Hiển thị lỗi khi hết phiên đăng nhập

## Các Bước Thực Hiện

### Bước 1: Chạy Migration SQL Script

**QUAN TRỌNG:** Backup database trước khi chạy migration!

#### Cách 1: Sử dụng psql (PostgreSQL CLI)
```bash
cd Backend
psql -U your_username -d your_database -f add_seller_id.sql
```

#### Cách 2: Sử dụng Supabase SQL Editor
1. Mở Supabase Dashboard
2. Vào **SQL Editor**
3. Copy nội dung file `add_seller_id.sql`
4. Paste và click **Run**

#### Cách 3: Sử dụng Database Management Tool
- Mở file `add_seller_id.sql` 
- Copy toàn bộ nội dung
- Dán vào SQL query tool của bạn (pgAdmin, DBeaver, etc.)
- Execute

**Script sẽ tự động:**
1. Kiểm tra và tạo seller mặc định nếu chưa có
2. Thêm cột `seller_id` vào các bảng `category`, `dish`, `topping`
3. Thêm cột `min`, `max` vào bảng `topping`
4. Gán tất cả dữ liệu hiện tại cho seller mặc định
5. Thêm foreign key constraints
6. Cập nhật unique constraints
7. Hiển thị kết quả kiểm tra

### Bước 2: Khởi Động Lại Backend

```bash
cd Backend
uvicorn main:app --reload
```

### Bước 3: Test Frontend

```bash
cd Frontend
flutter run
```

## Kiểm Tra Sau Migration

### 1. Kiểm tra Database
```sql
-- Kiểm tra cột seller_id đã được thêm
SELECT 
    column_name, 
    data_type, 
    is_nullable 
FROM information_schema.columns 
WHERE table_name IN ('category', 'dish', 'topping')
ORDER BY table_name, ordinal_position;

-- Kiểm tra tất cả records có seller_id
SELECT COUNT(*) as missing_category FROM category WHERE seller_id IS NULL;
SELECT COUNT(*) as missing_dish FROM dish WHERE seller_id IS NULL;
SELECT COUNT(*) as missing_topping FROM topping WHERE seller_id IS NULL;
-- (Kết quả phải = 0)

-- Kiểm tra foreign keys
SELECT
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_name IN ('category', 'dish', 'topping')
    AND tc.constraint_type = 'FOREIGN KEY';
```

### 2. Test API Endpoints

#### Test GET với token:
```bash
# Lấy token từ login trước
TOKEN="your_access_token_here"

# Test category
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/category/

# Test dish
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/dish/

# Test topping
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/topping/
```

#### Test POST với token:
```bash
curl -X POST http://localhost:8000/api/category/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Category"}'
```

### 3. Test Frontend

1. **Đăng nhập** với tài khoản seller
2. **Thêm mới** danh mục/món ăn/topping → Phải thành công
3. **Xem danh sách** → Chỉ thấy dữ liệu của seller hiện tại
4. **Đăng nhập** với seller khác → Thấy thực đơn khác hoàn toàn

## Cấu Trúc Models Mới

### Category
```python
class Category(Base):
    id: int
    name: str
    seller_id: int  # ← MỚI: Liên kết với User
```

### Dish
```python
class Dish(Base):
    id: int
    name: str
    img: str
    price: float
    category_id: int
    seller_id: int  # ← MỚI: Liên kết với User
    description: str
    group: str
```

### Topping
```python
class Topping(Base):
    id: int
    name: str
    seller_id: int  # ← MỚI: Liên kết với User
    min: int
    max: int
    items: JSON
    dish_ids: JSON
```

## Rollback (Nếu Cần)

Nếu gặp vấn đề, restore database từ backup:

```bash
# PostgreSQL
psql -U username -d database_name < backup.sql

# SQLite
cp backup.db your_database.db
```

## Troubleshooting

### Lỗi: "Đã hết phiên đăng nhập"
**Nguyên nhân:** Token hết hạn hoặc không hợp lệ  
**Giải pháp:** Đăng xuất và đăng nhập lại

### Lỗi: "Không tìm thấy danh mục/món ăn"
**Nguyên nhân:** Dữ liệu thuộc về seller khác  
**Giải pháp:** Kiểm tra seller_id trong database

### Lỗi: "Permission denied"
**Nguyên nhân:** User không phải seller  
**Giải pháp:** Login với tài khoản có `role = 'seller'`

### Migration bị lỗi
**Giải pháp:**
1. Restore backup
2. Kiểm tra kết nối database
3. Chạy lại script

## Lưu Ý Quan Trọng

1. **Authentication Token:** 
   - Frontend tự động lấy token từ secure storage
   - Token có thời hạn 24 giờ (có thể thay đổi trong `auth.py`)

2. **Data Isolation:**
   - Mỗi seller chỉ thấy dữ liệu của họ
   - Không thể truy cập hoặc sửa dữ liệu của seller khác
   - Admin có thể cần role riêng để xem tất cả (chưa implement)

3. **Thêm Seller Mới:**
   - Đăng ký tài khoản với `role = 'seller'`
   - Đăng nhập để tạo thực đơn mới

4. **Category Names:**
   - Trước: tên category phải unique toàn hệ thống
   - Sau: tên category chỉ cần unique trong phạm vi một seller

## Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. Logs backend: `uvicorn` console
2. Logs frontend: `flutter run` console
3. Database state: SQL queries ở trên
4. Token validity: Decode JWT tại jwt.io

---

**Tác giả:** Migration Script  
**Ngày:** 2026-02-28  
**Version:** 1.0.0
