# Feature Specification: Module 6 - Admin Management & OCR Pipeline

**Feature Branch**: `feature/006-admin-management-and-ocr`  
**Created**: 2026-09-12  
**Status**: Draft  
**SRS Reference**: FR-12 ➔ FR-16, FR-21, FR-22, BR-01, BR-04, BR-05, BR-14, SEC-03, SEC-06, TBD-02  

---

## 🎯 1. Overview & Purpose

Module 6 cung cấp giao diện và các API Quản trị dành cho tác nhân **Admin**. Module này bao gồm các chức năng Quản lý địa điểm (Tạo, Sửa, Ẩn, Xóa), Quản lý ảnh menu, Tích hợp dịch vụ OCR trích xuất tự động dữ liệu món ăn & giá tiền từ ảnh, Giao diện đối soát chỉnh sửa kết quả OCR, và Phê duyệt công bố dữ liệu chính thức (Hoàn tất Kiểm duyệt Lớp 2).

---

## 👥 2. User Stories & Acceptance Criteria

### User Story 1 - Quản lý Địa điểm chính thức (FR-12, BR-01, SEC-03)
* **Là một**: Admin hệ thống.
* **Tôi muốn**: Tạo mới, chỉnh sửa thông tin, ẩn hoặc xóa các địa điểm trong hệ thống.
* **Để**: Cập nhật thông tin địa điểm chính xác cho người dùng.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Admin Authentication**: Yêu cầu xác thực tài khoản có quyền `role = 'admin'` (`SEC-03`). Từ chối `403 Forbidden` nếu người dùng thông thường cố tình truy cập.
2. **Place CRUD**: Admin có thể tạo địa điểm mới trực tiếp ở trạng thái `published` kèm nhãn Đã xác minh `is_verified = true` (`BR-01`).
3. **Soft Delete / Hide**: Khi xóa hoặc ẩn địa điểm, dữ liệu chuyển trạng thái `status = 'hidden'` để bảo toàn lịch sử.

---

### User Story 2 - Trích xuất dữ liệu Menu bằng OCR (FR-13, FR-14, BR-05, TBD-02)
* **Là một**: Admin hệ thống.
* **Tôi muốn**: Tải ảnh menu lên và yêu cầu hệ thống trích xuất tên món và giá tiền bằng OCR.
* **Để**: Giảm thiểu công sức nhập liệu thủ công bằng tay.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **OCR Trigger**: Admin chọn ảnh menu ➔ Gửi yêu cầu trích xuất đến OCR Service (Tesseract / PaddleOCR / Cloud Vision `TBD-02`).
2. **Draft Extraction Result**: Kết quả trích xuất dạng danh sách cặp `(món ăn, giá tiền)` được lưu ở trạng thái bản nháp (`is_verified = false`) và chưa hiển thị cho User (`BR-05`).
3. **OCR Processing UI**: Hiển thị trạng thái loading/tiến trình trong khi chờ kết quả OCR (`NFR-05`).

---

### User Story 3 - Đối soát & Phê duyệt dữ liệu OCR / Đóng góp cộng đồng (FR-15, FR-16, FR-21, FR-22, BR-04)
* **Là một**: Admin hệ thống.
* **Tôi muốn**: Xem giao diện đối soát kết quả OCR (so sánh cạnh ảnh menu gốc), chỉnh sửa tên/giá bị trích xuất sai, và bấm "Xác nhận duyệt".
* **Để**: Công bố dữ liệu menu/giá chính thức cho người dùng.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Side-by-Side Verification UI**: Giao diện hiển thị 1 bên là Ảnh menu gốc, 1 bên là Bảng dữ liệu trích xuất cho phép Admin chỉnh sửa nhanh tên món, giá tiền hoặc xóa món rác.
2. **Layer 2 Approval**: Khi Admin bấm "Phê duyệt":
   - Cập nhật các món ăn/giá đã sửa thành dữ liệu chính thức (`is_verified = true`).
   - Cập nhật địa điểm nháp thành địa điểm chính thức (`status = 'published'`, `has_price_data = true`).
   - Cập nhật đóng góp của Contributor thành `status = 'approved'` (`FR-21`).
3. **Rejection Handling**: Nếu từ chối đóng góp, Admin nhập lý do từ chối ➔ Cập nhật đóng góp thành `status = 'rejected'` (`BR-13`).

---

## 📐 3. Data Schema & Requirements

### `OcrResults` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID kết quả OCR |
| `menu_image_id` | UUID | FK -> MenuImages(id), Nullable | Ảnh menu nguồn (nếu Admin upload) |
| `contribution_id` | UUID | FK -> Contributions(id), Nullable | Đóng góp nguồn (nếu từ Contributor) |
| `status` | VARCHAR(20) | Default 'draft' | `draft`, `verified`, `discarded` |
| `processed_at` | TIMESTAMP | Default NOW() | Thời điểm xử lý OCR |
| `verified_by` | UUID | FK -> Users(id), Nullable | Admin đã xác nhận |
| `verified_at` | TIMESTAMP | Nullable | Thời điểm Admin xác nhận |

### `OcrResultItems` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID item trích xuất |
| `ocr_result_id` | UUID | FK -> OcrResults(id), ON DELETE CASCADE | ID kết quả OCR |
| `extracted_name` | VARCHAR(255) | Not Null | Tên món trích xuất từ OCR |
| `extracted_price` | DECIMAL(12, 2) | Nullable | Giá trích xuất từ OCR |
| `corrected_name` | VARCHAR(255) | Nullable | Tên món sau khi Admin chỉnh sửa |
| `corrected_price` | DECIMAL(12, 2) | Nullable | Giá sau khi Admin chỉnh sửa |
| `confidence` | DECIMAL(3, 2) | Default 0.00 | Độ tin cậy OCR (0.00 - 1.00) |
| `is_discarded` | BOOLEAN | Default FALSE | Admin đánh dấu là món rác |

---

## 🔌 4. API Endpoints Specification

### 1. `POST /api/v1/admin/places`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Request Body**:
  ```json
  {
    "name": "Highland Coffee - Lê Lợi",
    "category_id": 1,
    "address": "123 Lê Lợi, Q.1, TP.HCM",
    "latitude": 10.773,
    "longitude": 106.700,
    "status": "published"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "success": true,
    "data": {
      "id": "plc_789",
      "is_verified": true,
      "status": "published"
    }
  }
  ```

### 2. `PUT /api/v1/admin/places/:id`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Request Body**: Các trường cần cập nhật (partial update).
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Cập nhật địa điểm thành công."
  }
  ```

### 3. `POST /api/v1/admin/ocr/extract`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Request Body**: Multipart form data (`image`: file ảnh menu, `place_id`: UUID)
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "ocr_result_id": "ocr_888",
      "status": "draft",
      "extracted_items": [
        { "id": "oi_1", "extracted_name": "Cà phê sữa đá", "extracted_price": 29000, "confidence": 0.95 },
        { "id": "oi_2", "extracted_name": "Bạc xỉu", "extracted_price": 32000, "confidence": 0.91 },
        { "id": "oi_3", "extracted_name": "???", "extracted_price": null, "confidence": 0.30 }
      ]
    }
  }
  ```
- **Note**: Kết quả OCR được lưu vào `OcrResults` + `OcrResultItems` ở trạng thái `draft`. Chưa hiển thị cho User (`BR-05`).

### 4. `PUT /api/v1/admin/ocr/:ocr_result_id`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Purpose**: Admin chỉnh sửa kết quả OCR (sửa tên/giá, đánh dấu món rác).
- **Request Body**:
  ```json
  {
    "items": [
      { "id": "oi_1", "corrected_name": "Cà phê sữa đá", "corrected_price": 29000 },
      { "id": "oi_3", "is_discarded": true }
    ]
  }
  ```

### 5. `POST /api/v1/admin/ocr/:ocr_result_id/verify`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Purpose**: Admin xác nhận OCR đã đối soát xong → Tạo MenuItems chính thức từ kết quả đã chỉnh sửa.
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Dữ liệu menu đã được công bố chính thức.",
    "data": {
      "menu_items_created": 2,
      "place_has_price_data": true
    }
  }
  ```

### 6. `POST /api/v1/admin/contributions/:id/approve`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Đóng góp đã được phê duyệt và dữ liệu đã công bố."
  }
  ```

### 7. `POST /api/v1/admin/contributions/:id/reject`
- **Headers**: `Authorization: Bearer <admin_access_token>`
- **Request Body**:
  ```json
  {
    "reason": "Ảnh quá mờ, không đọc được giá tiền."
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Đóng góp đã bị từ chối."
  }
  ```

---

## 🧪 5. Edge Cases & Error Handling

| Scenario | HTTP Status | Error Code | Message Displayed |
| :--- | :--- | :--- | :--- |
| User thường truy cập API Admin | `403 Forbidden` | `ADMIN_REQUIRED` | "Bạn không có quyền truy cập chức năng này." (`SEC-03`, `SEC-06`) |
| OCR Service timeout (> 30 giây) | `504 Gateway Timeout` | `OCR_SERVICE_TIMEOUT` | "Dịch vụ trích xuất ảnh tạm thời không phản hồi. Vui lòng thử lại." |
| OCR trích xuất 0 item (ảnh không chứa text giá) | `200 OK` (empty) | N/A | Trả `extracted_items: []` + cảnh báo Admin nhập thủ công. |
| Ảnh menu quá mờ/không đọc được | `200 OK` | N/A | Trả kết quả với `confidence < 0.5` + cảnh báo Admin. |
| Phê duyệt đóng góp đã bị từ chối trước đó | `409 Conflict` | `INVALID_STATUS_TRANSITION` | "Đóng góp này đã bị từ chối, không thể phê duyệt." |
| Từ chối đóng góp thiếu lý do | `422 Unprocessable Entity` | `REASON_REQUIRED` | "Vui lòng nhập lý do từ chối." |
| Xóa địa điểm đang có đóng góp chờ duyệt | `409 Conflict` | `HAS_PENDING_CONTRIBUTIONS` | "Địa điểm còn đóng góp chưa xử lý. Vui lòng duyệt/từ chối trước." |


