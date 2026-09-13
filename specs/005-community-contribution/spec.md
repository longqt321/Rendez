# Feature Specification: Module 5 - Community Contribution & Moderation

**Feature Branch**: `feature/005-community-contribution`  
**Created**: 2026-09-12  
**Status**: Draft  
**SRS Reference**: FR-17 ➔ FR-20, FR-23, BR-01, BR-11 ➔ BR-14  

---

## 🎯 1. Overview & Purpose

Module 5 cung cấp cơ chế cho phép Người dùng đã đăng nhập đóng vai trò làm **Contributor** (Người đóng góp) tải lên hình ảnh bill hoặc hình ảnh menu của các địa điểm để mở rộng dữ liệu cho hệ thống. Dữ liệu đóng góp phải trải qua quy trình **Kiểm duyệt 2 lớp** (Lớp 1 Tự động ➔ Lớp 2 Admin) trước khi trở thành dữ liệu chính thức.

---

## 👥 2. User Stories & Acceptance Criteria

### User Story 1 - Tải lên Ảnh Bill/Menu đóng góp (FR-17, FR-18, BR-11, BR-12)
* **Là một**: Contributor (User đã đăng nhập).
* **Tôi muốn**: Chụp/Tải lên ảnh menu hoặc hóa đơn thanh toán kèm tên địa điểm.
* **Để**: Chia sẻ dữ liệu giá thực tế cho cộng đồng.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Upload Input**: Tải lên từ 1 đến 5 ảnh (định dạng JPG/PNG, kích thước < 10MB/ảnh), nhập tên địa điểm và thời gian chụp ảnh (đối với bill).
2. **Draft Place Creation**: Nếu địa điểm chưa có sẵn trong hệ thống, hệ thống tự động tạo một Địa điểm nháp (`status = 'draft'`). Địa điểm nháp chỉ chuyển sang chính thức khi có ít nhất 1 đóng góp được Admin duyệt (`BR-12`).
3. **Pending Status**: Dữ liệu đóng góp mới khởi tạo được lưu ở trạng thái `status = 'pending_layer_1'`.

---

### User Story 2 - Kiểm duyệt Tự động - Lớp 1 (FR-19, FR-20, BR-13)
* **Là một**: Hệ thống tự động (Backend Task / Worker).
* **Tôi muốn**: Kiểm tra định dạng ảnh và tính hợp lệ cơ bản của dữ liệu đóng góp.
* **Để**: Sàng lọc rác trước khi chuyển lên hàng chờ duyệt cho Admin.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Validation Checks**: Kiểm tra độ phân giải ảnh, tính đọc được của file, và khả năng chạy trích xuất OCR cơ bản (`FR-19`).
2. **Auto Reject (FR-20)**: Nếu ảnh bị mờ, sai định dạng hoặc không hợp lệ, hệ thống tự động cập nhật trạng thái `status = 'rejected_layer_1'` và ghi lại lý do từ chối cụ thể.
3. **Pass Layer 1**: Nếu hợp lệ, chuyển trạng thái đóng góp sang `status = 'pending_admin'` để Admin duyệt Lớp 2.

---

### User Story 3 - Theo dõi Trạng thái Đóng góp (FR-23, BR-13)
* **Là một**: Contributor đã gửi đóng góp.
* **Tôi muốn**: Xem danh sách các bài đóng góp của tôi và trạng thái xử lý hiện tại.
* **Để**: Biết đóng góp của mình đã được duyệt hay chưa.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Status Display**: Danh sách đóng góp cá nhân hiển thị rõ trạng thái: `Đang chờ duyệt`, `Đã phê duyệt`, hoặc `Bị từ chối`.
2. **Rejection Reason (BR-13)**: Nếu bị từ chối, hiển thị rõ lý do từ chối (ví dụ: *"Ảnh quá mờ không đọc được giá"*). Lý do này chỉ hiển thị riêng cho người đóng góp.

---

## 📐 3. Data Schema & Requirements

### `Contributions` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID bài đóng góp |
| `user_id` | UUID | FK -> Users(id) | ID người đóng góp |
| `place_id` | UUID | FK -> Places(id), Nullable | ID địa điểm liên quan (null nếu đề xuất nơi mới) |
| `place_name_suggestion` | VARCHAR(255) | Nullable | Tên địa điểm đề xuất (khi `place_id = null`) |
| `type` | VARCHAR(20) | Not Null | `menu_photo`, `bill_photo` |
| `status` | VARCHAR(30) | Default 'pending_layer_1'| `pending_layer_1`, `pending_admin`, `approved`, `rejected_layer_1`, `rejected` |
| `rejection_reason`| TEXT | Nullable | Lý do từ chối (nếu có) (`BR-13`) |
| `captured_at` | TIMESTAMP | Nullable | Thời gian chụp (nếu là bill) |
| `created_at` | TIMESTAMP | Default NOW() | |

### `ContributionImages` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID ảnh đóng góp |
| `contribution_id` | UUID | FK -> Contributions(id), ON DELETE CASCADE | ID bài đóng góp |
| `image_url` | VARCHAR(255) | Not Null | Đường dẫn ảnh đã upload |
| `file_size_bytes` | INT | Not Null | Kích thước file (bytes) |
| `display_order` | INT | Default 0 | Thứ tự hiển thị |
| `created_at` | TIMESTAMP | Default NOW() | |

---

## 🔌 4. API Endpoints Specification

### 1. `POST /api/v1/contributions`
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**: Multipart form data
  ```
  place_id: "plc_123" (optional — nếu null thì gửi kèm place_name_suggestion)
  place_name_suggestion: "Quán Cà Phê ABC" (optional)
  type: "menu_photo"
  captured_at: "2026-09-10T12:00:00Z" (optional)
  images[]: File (1-5 ảnh, JPG/PNG, < 10MB/ảnh)
  ```
- **Response `201 Created`**:
  ```json
  {
    "success": true,
    "data": {
      "id": "ctr_456",
      "status": "pending_layer_1",
      "message": "Đóng góp của bạn đã được gửi và đang chờ xử lý."
    }
  }
  ```

### 2. `GET /api/v1/contributions/my`
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Params**: `page` (Mặc định: 1), `limit` (Mặc định: 20), `status` (Optional filter)
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "ctr_456",
        "place_name": "The Coffee House - Nguyen Hue",
        "type": "menu_photo",
        "status": "approved",
        "rejection_reason": null,
        "image_count": 3,
        "created_at": "2026-09-10T14:30:00Z"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 8 }
  }
  ```

### 3. `GET /api/v1/contributions/:id`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "id": "ctr_456",
      "place_name": "The Coffee House - Nguyen Hue",
      "type": "menu_photo",
      "status": "rejected",
      "rejection_reason": "Ảnh quá mờ, không đọc được giá tiền.",
      "images": [
        "https://cdn.rendez.app/contributions/ctr_456_1.jpg",
        "https://cdn.rendez.app/contributions/ctr_456_2.jpg"
      ],
      "created_at": "2026-09-10T14:30:00Z"
    }
  }
  ```
- **Authorization**: Chỉ Contributor sở hữu hoặc Admin mới được xem chi tiết đóng góp.

---

## 🧪 5. Edge Cases & Error Handling

| Scenario | HTTP Status | Error Code | Message Displayed |
| :--- | :--- | :--- | :--- |
| Chưa đăng nhập khi đóng góp | `401 Unauthorized` | `AUTH_REQUIRED` | "Vui lòng đăng nhập để đóng góp." |
| Tải lên quá 5 ảnh | `422 Unprocessable Entity` | `TOO_MANY_IMAGES` | "Tối đa 5 ảnh cho mỗi lần đóng góp." |
| Ảnh vượt quá 10MB | `413 Payload Too Large` | `FILE_TOO_LARGE` | "Kích thước ảnh tối đa là 10MB." |
| Định dạng ảnh không hợp lệ (GIF, BMP...) | `422 Unprocessable Entity` | `INVALID_FILE_TYPE` | "Chỉ chấp nhận ảnh JPG và PNG." |
| Thiếu `place_id` lẫn `place_name_suggestion` | `422 Unprocessable Entity` | `PLACE_REQUIRED` | "Vui lòng chọn hoặc nhập tên địa điểm." |
| Xem đóng góp của người khác (không phải Admin) | `403 Forbidden` | `FORBIDDEN` | "Bạn không có quyền xem đóng góp này." |
| OCR Layer 1 timeout (trích xuất quá 30 giây) | N/A (Backend) | `OCR_TIMEOUT` | Đánh dấu `status = 'pending_admin'` + ghi log, chuyển sang duyệt thủ công. |


