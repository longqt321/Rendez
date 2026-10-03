# Feature Specification: Module 2 - Places & Menu Display

**Feature Branch**: `feature/002-places-and-menu-display`  
**Created**: 2026-09-12  
**Status**: Draft  
**SRS Reference**: FR-04, FR-05, FR-06, FR-07, NFR-01, NFR-03, NFR-08, NFR-10, NFR-14, NFR-16, BR-02 ➔ BR-08  

---

## 🎯 1. Overview & Purpose

Module 2 cung cấp các chức năng phục vụ luồng nghiệp vụ cốt lõi dành cho Người dùng (User): Xem danh sách địa điểm, Xem chi tiết địa điểm, Xem hình ảnh menu thực tế kèm bảng giá món ăn/dịch vụ, và Tìm kiếm/Lọc địa điểm theo từ khóa, loại hình và mức giá. Module này đóng vai trò quyết định trong việc đem lại giá trị **Minh bạch giá cả** của ứng dụng Rendez.

---

## 👥 2. User Stories & Acceptance Criteria

### User Story 1 - Xem danh sách & chi tiết địa điểm (FR-04, BR-02, BR-03, BR-06)
* **Là một**: Người dùng (Khách vãng lai hoặc đã đăng nhập).
* **Tôi muốn**: Xem danh sách các địa điểm ăn uống/vui chơi và bấm vào xem chi tiết thông tin địa điểm.
* **Để**: Khảo sát thông tin cơ bản về địa điểm trước khi đưa ra quyết định đi.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Place Item Card**: Mỗi item trong danh sách hiển thị: Tên địa điểm, Loại hình (Cà phê, Quán ăn, Trà sữa...), Địa chỉ, Ảnh đại diện, Nhãn trạng thái dữ liệu giá (Có bảng giá / Thiếu dữ liệu giá `BR-03`), và Huy hiệu Xác minh (`BR-06`).
2. **Place Detail View**: Màn hình chi tiết hiển thị đầy đủ: Tên, Địa chỉ chi tiết, Loại hình, Mô tả, Trạng thái dữ liệu giá, Mốc thời gian cập nhật giá gần nhất (`BR-07`).
3. **Empty Data Handling**: Địa điểm chưa có dữ liệu giá vẫn được hiển thị nhưng phải có thông báo rõ ràng *"Chưa có dữ liệu bảng giá chính thức"* (`BR-03`, `NFR-10`).

---

### User Story 2 - Xem Menu & Bảng giá thực tế (FR-05, BR-04, BR-07, NFR-08)
* **Là một**: Người dùng đang xem chi tiết một địa điểm.
* **Tôi muốn**: Xem danh sách món ăn/dịch vụ kèm giá tiền cụ thể và hình ảnh menu thực tế.
* **Để**: Biết trước giá từng món và dự trù ngân sách.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Real Menu Photos**: Hiển thị danh sách hình ảnh menu thực tế đã được Admin xác nhận (`BR-04`). Cho phép bấm phóng to/xem ảnh full-screen.
2. **Itemized Price List**: Danh sách món ăn/dịch vụ phân theo nhóm (Đồ ăn, Đồ uống, Món phụ...), hiển thị Tên món + Giá tiền (định dạng VNĐ, ví dụ `45.000 VNĐ`).
3. **Price Disclaimer**: Đính kèm thông báo *"Giá hiển thị mang tính chất tham khảo tại thời điểm cập nhật [Ngày/Tháng/Năm]"* (`BR-07`, `NFR-08`).

---

### User Story 3 - Tìm kiếm & Lọc địa điểm (FR-06, FR-07, BR-08, NFR-03)
* **Là một**: Người dùng muốn tìm địa điểm phù hợp với nhu cầu cụ thể.
* **Tôi muốn**: Nhập từ khóa tìm kiếm hoặc chọn bộ lọc (Loại hình, Mức giá).
* **Để**: Nhanh chóng thu hẹp danh sách địa điểm mong muốn.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Keyword Search**: Tìm kiếm theo tên địa điểm, địa chỉ hoặc tên món ăn. Trả về kết quả trong thời gian < 2 giây (`NFR-03`).
2. **Category & Price Filter**: Lọc theo Loại hình (Quán ăn, Cà phê, Trà sữa, Nhà hàng...) và Khung giá (Dưới 50k, 50k - 100k, Trên 100k).
3. **Transparent Price Ranking**: Hệ thống tự động ưu tiên xếp các địa điểm **có thông tin giá minh bạch** lên trên các địa điểm thiếu dữ liệu giá (`BR-08`).

---

## 📐 3. Data Schema & Requirements

### 3.1 Data Entities (Cơ sở dữ liệu)

#### `Categories` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | Primary Key | ID loại hình |
| `name` | VARCHAR(100) | Not Null, Unique | Tên loại hình (Cà phê, Quán ăn...) |
| `icon_url` | VARCHAR(255) | Nullable | Ảnh icon biểu trưng |

#### `Places` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID địa điểm |
| `category_id` | INT | FK -> Categories(id) | Loại hình địa điểm |
| `name` | VARCHAR(255) | Not Null | Tên địa điểm |
| `address` | TEXT | Not Null | Địa chỉ chi tiết |
| `latitude` | DECIMAL(10, 8)| Nullable | Tọa độ Vĩ độ |
| `longitude` | DECIMAL(11, 8)| Nullable | Tọa độ Kinh độ |
| `cover_image` | VARCHAR(255) | Nullable | Ảnh đại diện địa điểm |
| `is_verified` | BOOLEAN | Default FALSE | Đã xác minh bởi Admin (`BR-06`) |
| `has_price_data`| BOOLEAN | Default FALSE | Đã có dữ liệu giá chính thức (`BR-03`)|
| `status` | VARCHAR(20) | Default 'published' | `published`, `draft`, `hidden` |
| `created_by` | UUID | FK -> Users(id), Nullable | Admin đã tạo địa điểm (audit trail) |
| `created_at` | TIMESTAMP | Default NOW() | |
| `updated_at` | TIMESTAMP | Default NOW() | |

#### `Menus` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID menu |
| `place_id` | UUID | FK -> Places(id) | Địa điểm sở hữu menu |
| `title` | VARCHAR(100) | Default 'Menu chính'| Tiêu đề (Menu đồ uống, Menu mùa hè)|
| `created_at` | TIMESTAMP | Default NOW() | Thời điểm tạo menu |
| `updated_at` | TIMESTAMP | Default NOW() | Mốc thời gian cập nhật giá (`BR-07`)|

#### `MenuImages` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID ảnh menu |
| `menu_id` | UUID | FK -> Menus(id) | ID Menu |
| `image_url` | VARCHAR(255) | Not Null | Đường dẫn ảnh menu |
| `display_order` | INT | Default 0 | Thứ tự hiển thị |

#### `MenuItems` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID món/dịch vụ |
| `menu_id` | UUID | FK -> Menus(id) | ID Menu |
| `category_name`| VARCHAR(100) | Default 'Món chung'| Nhóm món (Đồ uống, Món chính)|
| `name` | VARCHAR(255) | Not Null | Tên món ăn / dịch vụ |
| `price` | DECIMAL(12, 2)| Not Null | Giá tiền (VNĐ) |
| `description` | TEXT | Nullable | Mô tả thành phần món |
| `is_available` | BOOLEAN | Default TRUE | Còn phục vụ hay không |

---

## 🔌 4. API Endpoints Specification

### 1. `GET /api/v1/places`
- **Query Params**: `page`, `limit`, `category_id`, `price_range`, `search`, `sort_by` (mặc định: `price_transparency_desc`).
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "plc_123",
        "name": "The Coffee House - Nguyen Hue",
        "category": "Cà phê",
        "address": "99 Nguyễn Huệ, Q.1, TP.HCM",
        "cover_image": "https://cdn.rendez.app/places/plc_123.jpg",
        "is_verified": true,
        "has_price_data": true,
        "price_summary": "35.000 - 65.000 VNĐ"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 150 }
  }
  ```

### 2. `GET /api/v1/places/:id`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "id": "plc_123",
      "name": "The Coffee House - Nguyen Hue",
      "category": "Cà phê",
      "address": "99 Nguyễn Huệ, Q.1, TP.HCM",
      "latitude": 10.774,
      "longitude": 106.703,
      "is_verified": true,
      "has_price_data": true,
      "price_last_updated": "2026-09-01T10:00:00Z"
    }
  }
  ```

### 3. `GET /api/v1/places/:id/menu`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "place_id": "plc_123",
      "menu_images": [
        "https://cdn.rendez.app/menus/m1.jpg",
        "https://cdn.rendez.app/menus/m2.jpg"
      ],
      "sections": [
        {
          "category": "Cà phê máy",
          "items": [
            { "id": "itm_1", "name": "Espresso", "price": 35000, "price_formatted": "35.000 VNĐ" },
            { "id": "itm_2", "name": "Americano", "price": 40000, "price_formatted": "40.000 VNĐ" }
          ]
        }
      ],
      "disclaimer": "Giá hiển thị mang tính chất tham khảo tại thời điểm cập nhật 01/09/2026."
    }
  }
  ```

---

## 🔒 5. Non-Functional & Business Rules

1. **BR-08 Priority Enforcement**: Truy vấn danh sách địa điểm phải sử dụng thuật toán sắp xếp ưu tiên `has_price_data DESC, is_verified DESC`.
2. **NFR-03 Compliance**: API Tìm kiếm & Lọc phải có index phù hợp (`FULLTEXT` index hoặc PostgreSQL `pg_trgm`) để trả kết quả dưới 2 giây.
3. **NFR-14 & NFR-25 Format**: Giá tiền bắt buộc hiển thị định dạng chuẩn tiền tệ Việt Nam (ví dụ: `45.000 VNĐ`).

---

## 🧪 6. Edge Cases & Error Handling

| Scenario | HTTP Status | Error Code | Message Displayed |
| :--- | :--- | :--- | :--- |
| Địa điểm không tồn tại (ID sai) | `404 Not Found` | `PLACE_NOT_FOUND` | "Không tìm thấy địa điểm." |
| Địa điểm ở trạng thái `hidden` hoặc `draft` (User truy cập) | `404 Not Found` | `PLACE_NOT_FOUND` | "Không tìm thấy địa điểm." |
| Địa điểm chưa có dữ liệu menu | `200 OK` (empty) | N/A | Trả `sections: []` + `disclaimer: "Chưa có dữ liệu bảng giá."` |
| Từ khóa tìm kiếm quá ngắn (< 2 ký tự) | `422 Unprocessable Entity` | `SEARCH_TOO_SHORT` | "Vui lòng nhập ít nhất 2 ký tự để tìm kiếm." |
| `page` hoặc `limit` không hợp lệ | `422 Unprocessable Entity` | `INVALID_PAGINATION` | "Tham số phân trang không hợp lệ." |
| Ảnh menu không tải được (URL lỗi/CDN timeout) | N/A (Client) | `IMAGE_LOAD_ERROR` | Hiển thị placeholder ảnh mặc định. |


