# Feature Specification: Module 1 - Authentication & Account Management

**Feature Branch**: `feature/001-authentication-management`  
**Created**: 2026-09-12  
**Status**: Draft  
**SRS Reference**: FR-01, FR-02, FR-03, SEC-01 ➔ SEC-05, SEC-09  

---

## 🎯 1. Overview & Purpose

Module 1 cung cấp khả năng Xác thực & Quản lý Tài khoản cho ứng dụng Rendez. Module này chịu trách nhiệm cho các luồng Đăng ký tài khoản mới, Đăng nhập xác thực bằng Email/Mật khẩu, Cấp phát Token xác thực (JWT Access & Refresh Token), Làm mới Access Token khi hết hạn, Phân quyền người dùng (User / Admin) và Đăng xuất vô hiệu hóa phiên làm việc.

> **Lưu ý về Role "Contributor"**: Trong SRS, "Contributor" không phải một role riêng trong DB mà là **khả năng hành vi** của bất kỳ User đã đăng nhập nào. Mọi User (`role = 'user'`) đều có thể đóng góp dữ liệu. Chỉ có 2 role trong hệ thống: `user` và `admin`.

---

## 👥 2. User Stories & Acceptance Criteria

### User Story 1 - Đăng ký tài khoản mới (FR-01)
* **Là một**: Khách vãng lai (Chưa có tài khoản).
* **Tôi muốn**: Đăng ký tài khoản mới bằng Email và Mật khẩu.
* **Để**: Trở thành người dùng (User) của ứng dụng Rendez và chuẩn bị sử dụng các tính năng cá nhân hóa/đóng góp.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Input Validation**: Email đúng định dạng; Mật khẩu tối thiểu 8 ký tự; Tên hiển thị không được để trống.
2. **Duplication Check**: Hệ thống trả về lỗi hợp lệ nếu Email đã tồn tại trong cơ sở dữ liệu.
3. **Password Hashing**: Mật khẩu bắt buộc được băm bằng thuật toán an toàn (`bcrypt` với salt factor >= 10 hoặc `argon2`) trước khi lưu vào DB (`SEC-02`).
4. **Response**: Đăng ký thành công trả về thông tin tài khoản cơ bản (ID, Email, FullName, Role: `user`) kèm thông báo chào mừng.

---

### User Story 2 - Đăng nhập & Xác thực phiên làm việc (FR-02, SEC-01)
* **Là một**: Người dùng (User / Admin) đã có tài khoản.
* **Tôi muốn**: Đăng nhập bằng Email và Mật khẩu.
* **Để**: Nhận Access Token và sử dụng các chức năng yêu cầu xác thực.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Credential Verification**: Kiểm tra Email và khớp băm Mật khẩu với DB. Trả về thông báo lỗi chung *"Email hoặc mật khẩu không chính xác"* nếu thông tin không đúng (tránh để lộ sự tồn tại của Email).
2. **Token Issuance**: Khi xác thực thành công, Backend trả về cặp Token:
   - `accessToken`: JWT Token có thời hạn từ 15 đến 30 phút (`TBD-03`).
   - `refreshToken`: Token có thời hạn từ 7 đến 14 ngày (`TBD-03`).
3. **Role Claim**: JWT Access Token chứa payload bao gồm `userId`, `email`, và `role` (`user` hoặc `admin`).
4. **Mobile App Token Persistence**: Flutter App lưu trữ `accessToken` và `refreshToken` an toàn trong thiết bị (dùng `flutter_secure_storage`).

---

### User Story 3 - Đăng xuất & Vô hiệu hóa phiên (FR-03, SEC-09)
* **Là một**: Người dùng đã đăng nhập trên ứng dụng Mobile.
* **Tôi muốn**: Chọn chức năng Đăng xuất.
* **Để**: Kết thúc phiên làm việc hiện tại và bảo vệ tài khoản cá nhân.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Client Cleanup**: App Flutter xóa `accessToken` và `refreshToken` khỏi bộ lưu trữ an toàn của thiết bị.
2. **Server Invalidation**: Client gửi Yêu cầu Đăng xuất lên Backend kèm `refreshToken`. Backend đánh dấu vô hiệu hóa `refreshToken` trong Cơ sở dữ liệu/Cache để ngăn tái sử dụng.
3. **Security Audit**: Thử nghiệm gọi API cần xác thực ngay sau khi Đăng xuất phải bị từ chối với mã lỗi `HTTP 401 Unauthorized`.

---

## 📐 3. Data Schema & Requirements

### 3.1 Data Entities (Cơ sở dữ liệu)

#### `Users` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID / BIGINT | Primary Key, Auto-gen | Định danh duy nhất người dùng |
| `email` | VARCHAR(255) | Unique, Not Null | Email đăng nhập |
| `password_hash` | VARCHAR(255) | Not Null | Chuỗi mật khẩu đã hash |
| `full_name` | VARCHAR(100) | Not Null | Tên hiển thị của người dùng |
| `role` | VARCHAR(20) | Not Null, Default 'user' | Vai trò: `user`, `admin` |
| `status` | VARCHAR(20) | Not Null, Default 'active' | Trạng thái: `active`, `suspended` |
| `created_at` | TIMESTAMP | Default NOW() | Thời điểm tạo tài khoản |
| `updated_at` | TIMESTAMP | Default NOW() | Thời điểm cập nhật cuối cùng |

#### `UserSessions` / `RefreshTokens` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | Primary Key | ID phiên làm việc |
| `user_id` | UUID / BIGINT | FK -> Users(id) | ID người dùng |
| `token_hash` | VARCHAR(255) | Not Null, Unique | Hash của Refresh Token |
| `expires_at` | TIMESTAMP | Not Null | Thời điểm hết hạn Token |
| `is_revoked` | BOOLEAN | Default FALSE | Trạng thái bị thu hồi |
| `created_at` | TIMESTAMP | Default NOW() | Thời điểm đăng nhập |

---

## 🔌 4. API Endpoints Specification

### 1. `POST /api/v1/auth/register`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "StrongPassword123!",
    "full_name": "Trần Văn A"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "success": true,
    "message": "Đăng ký tài khoản thành công",
    "data": {
      "id": "usr_123456",
      "email": "user@example.com",
      "full_name": "Trần Văn A",
      "role": "user"
    }
  }
  ```

### 2. `POST /api/v1/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "StrongPassword123!"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "user": {
        "id": "usr_123456",
        "email": "user@example.com",
        "full_name": "Trần Văn A",
        "role": "user"
      },
      "tokens": {
        "access_token": "eyJhbGciOi...",
        "refresh_token": "def456...",
        "expires_in": 1800
      }
    }
  }
  ```

### 3. `POST /api/v1/auth/logout`
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "refresh_token": "def456..."
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "message": "Đăng xuất thành công"
  }
  ```

### 4. `POST /api/v1/auth/refresh`
- **Request Body**:
  ```json
  {
    "refresh_token": "def456..."
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "access_token": "eyJhbGciOi...(new)",
      "refresh_token": "ghi789...(new, rotated)",
      "expires_in": 1800
    }
  }
  ```
- **Logic**: Backend kiểm tra `refresh_token` còn hạn và chưa bị thu hồi (`is_revoked = false`). Nếu hợp lệ, cấp cặp Access + Refresh Token mới (Rotation). Refresh Token cũ bị đánh dấu `is_revoked = true` ngay lập tức để ngăn tái sử dụng.

---

## 🔒 5. Non-Functional & Security Requirements

1. **NFR-02 Compliance**: Thời gian xử lý API đăng ký/đăng nhập phía Backend < 2 giây.
2. **SEC-02 Compliance**: Không lưu trữ plain text password dưới bất kỳ hình thức nào.
3. **SEC-05 Compliance**: Token, password_hash tuyệt đối không được ghi vào file log ứng dụng.
4. **SEC-10 Compliance**: Secret key dùng để ký JWT phải được đọc từ biến môi trường (`.env`), không hard-code.

---

## 🧪 6. Edge Cases & Error Handling

| Scenario | HTTP Status | Error Code | Message Displayed |
| :--- | :--- | :--- | :--- |
| Email trùng lặp khi đăng ký | `409 Conflict` | `EMAIL_ALREADY_EXISTS` | "Email này đã được sử dụng." |
| Đăng nhập sai mật khẩu/email | `401 Unauthorized` | `INVALID_CREDENTIALS` | "Email hoặc mật khẩu không chính xác." |
| Access Token hết hạn | `401 Unauthorized` | `TOKEN_EXPIRED` | "Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại." |
| Refresh Token hết hạn hoặc đã bị thu hồi | `401 Unauthorized` | `REFRESH_TOKEN_INVALID` | "Phiên đăng nhập không còn hiệu lực. Vui lòng đăng nhập lại." |
| Refresh Token bị tái sử dụng (Replay Attack) | `401 Unauthorized` | `TOKEN_REUSE_DETECTED` | "Phát hiện bất thường bảo mật. Tất cả phiên đã bị vô hiệu hóa." |
| Thiếu trường bắt buộc khi đăng ký (email/password/name) | `422 Unprocessable Entity` | `VALIDATION_ERROR` | "Vui lòng nhập đầy đủ thông tin: [tên trường]." |
| Mật khẩu không đủ 8 ký tự | `422 Unprocessable Entity` | `WEAK_PASSWORD` | "Mật khẩu phải có ít nhất 8 ký tự." |
| Tài khoản bị khóa (`status = suspended`) | `403 Forbidden` | `ACCOUNT_SUSPENDED` | "Tài khoản của bạn đã bị khóa." |
| Lỗi mất kết nối mạng phía Client | N/A (Client) | `NETWORK_ERROR` | "Không có kết nối mạng. Vui lòng kiểm tra kết nối." |


