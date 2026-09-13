# Feature Specification: Module 4 - Favorites Management

**Feature Branch**: `feature/004-favorites-management`  
**Created**: 2026-09-12  
**Status**: Draft  
**SRS Reference**: FR-10, FR-11, BR-09  

---

## 🎯 1. Overview & Purpose

Module 4 cho phép Người dùng đã đăng nhập lưu trữ các địa điểm ăn uống/vui chơi yêu thích vào danh sách cá nhân để nhanh chóng xem lại và theo dõi biến động giá cả mà không cần tìm kiếm lại từ đầu.

---

## 👥 2. User Stories & Acceptance Criteria

### User Story 1 - Thêm & Xóa khỏi Danh sách Yêu thích (FR-10, BR-09)
* **Là một**: Người dùng đã đăng nhập.
* **Tôi muốn**: Bấm nút icon "Yêu thích" (Trái tim) tại danh sách hoặc trang chi tiết địa điểm.
* **Để**: Lưu hoặc bỏ lưu địa điểm đó.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Login Check**: Thao tác yêu thích bắt buộc phải đăng nhập (`BR-09`). Nếu người dùng chưa đăng nhập, hiển thị thông báo/modal yêu cầu đăng nhập.
2. **Toggle Favorite**: Trạng thái thay đổi tức thì trên UI (Optimistic UI update).
3. **Database Persistence**: Backend lưu cặp `(user_id, place_id)` vào DB.

---

### User Story 2 - Xem Danh sách Địa điểm Yêu thích (FR-11)
* **Là một**: Người dùng đã đăng nhập.
* **Tôi muốn**: Mở tab "Địa điểm Yêu thích" trong ứng dụng.
* **Để**: Xem lại tất cả các địa điểm mà tôi đã lưu.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Favorites List**: Hiển thị danh sách địa điểm đã lưu kèm thông tin cập nhật giá mới nhất.
2. **Empty State**: Nếu chưa lưu địa điểm nào, hiển thị màn hình trống thân thiện *"Bạn chưa lưu địa điểm yêu thích nào"*.

---

## 📐 3. Data Schema & Requirements

### `Favorites` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `user_id` | UUID | PK, FK -> Users(id) | ID người dùng |
| `place_id` | UUID | PK, FK -> Places(id)| ID địa điểm yêu thích |
| `created_at` | TIMESTAMP | Default NOW() | Thời điểm lưu |

---

## 🔌 4. API Endpoints Specification

### 1. `POST /api/v1/favorites/:place_id`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response `201 Created`**:
  ```json
  {
    "success": true,
    "message": "Đã lưu địa điểm yêu thích."
  }
  ```

### 2. `DELETE /api/v1/favorites/:place_id`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Đã bỏ lưu địa điểm yêu thích."
  }
  ```

### 3. `GET /api/v1/favorites`
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Params**: `page` (Mặc định: 1), `limit` (Mặc định: 20)
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": [
      {
        "place_id": "plc_123",
        "name": "The Coffee House - Nguyen Hue",
        "category": "Cà phê",
        "cover_image": "https://cdn.rendez.app/places/plc_123.jpg",
        "has_price_data": true,
        "price_summary": "35.000 - 65.000 VNĐ",
        "favorited_at": "2026-09-10T14:30:00Z"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 5 }
  }
  ```

---

## 🧪 5. Edge Cases & Error Handling

| Scenario | HTTP Status | Error Code | Message Displayed |
| :--- | :--- | :--- | :--- |
| Chưa đăng nhập khi thao tác yêu thích | `401 Unauthorized` | `AUTH_REQUIRED` | "Vui lòng đăng nhập để sử dụng tính năng này." (`BR-09`) |
| Lưu địa điểm đã có trong Favorites | `409 Conflict` | `ALREADY_FAVORITED` | "Bạn đã lưu địa điểm này rồi." |
| Bỏ lưu địa điểm không có trong Favorites | `404 Not Found` | `FAVORITE_NOT_FOUND` | "Địa điểm này không có trong danh sách yêu thích." |
| Địa điểm không tồn tại (`place_id` sai) | `404 Not Found` | `PLACE_NOT_FOUND` | "Không tìm thấy địa điểm." |
| Danh sách yêu thích trống | `200 OK` (empty) | N/A | Trả `data: []` — Client hiển thị empty state. |

