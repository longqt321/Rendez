# Rendez Constitution

## Core Principles

### I. Price Transparency & Data Authenticity First
- **Core Value**: Minh bạch giá cả là giá trị cốt lõi hàng đầu của Rendez. Mọi dữ liệu giá và menu hiển thị cho người dùng phải có nguồn gốc từ ảnh menu thực tế hoặc dữ liệu đã được xác minh.
- **Data Integrity**: Dữ liệu giá/menu chưa qua kiểm duyệt Admin tuyệt đối không được hiển thị như dữ liệu chính thức. Kết quả OCR và dữ liệu đóng góp từ cộng đồng chỉ có giá trị tham khảo/nháp cho đến khi Admin xác nhận (`BR-04`, `BR-05`, `BR-07`).
- **No Speculation**: Khi không có dữ liệu giá hoặc vị trí hợp lệ, hệ thống phải hiển thị trạng thái thiếu dữ liệu thay vì tự suy đoán hoặc hiển thị giá trị giả (`NFR-10`).

### II. Client-Backend Separation & Clean Architecture
- **Layering**: Ứng dụng di động (Flutter) tuyệt đối không truy cập trực tiếp vào Cơ sở dữ liệu hoặc các Dịch vụ bên ngoài (OCR Service, Map Service). Tất cả mọi thao tác đọc/ghi đều phải thông qua Backend REST API Gateway (`Section 2.5.2`, `Section 3.3`).
- **Modularity**: Mã nguồn Mobile App và Backend phải được tổ chức thành các module/package theo chức năng nghiệp vụ độc lập, dễ kiểm thử và bảo trì (`NFR-20`).
- **Config Separation**: Mọi thông tin cấu hình môi trường, thông số kết nối DB và API keys tuyệt đối không hard-code trong mã nguồn (`SEC-10`, `NFR-21`).

### III. 2-Layer Moderation Pipeline (Kiểm duyệt 2 lớp)
- **Layer 1 (Tự động)**: Kiểm tra định dạng ảnh, tính hợp lệ của dữ liệu đầu vào và khả năng trích xuất OCR (`FR-19`).
- **Layer 2 (Thủ công)**: Admin kiểm tra, chỉnh sửa thông tin trích xuất và quyết định Phê duyệt (Duyệt) hoặc Từ chối kèm lý do (`FR-21`, `FR-22`).
- **Contributor Protection**: Lý do từ chối chỉ hiển thị cho chính Contributor đã gửi đóng góp đó, không công khai cho người dùng khác (`BR-13`). Dữ liệu bị từ chối được lưu trữ để phục vụ cải thiện chất lượng nhưng không hiển thị trên app (`Section 2.5.3`).

### IV. Performance & User Experience Standards
- **UI Responsiveness**: Giao diện chính phải hiển thị nội dung trong vòng 3 giây (`NFR-01`). Các request kéo dài trên 500ms phải hiển thị trạng thái đang xử lý (`NFR-04`).
- **API Performance**: Các API đọc dữ liệu thông thường và API tìm kiếm/lọc phải có thời gian phản hồi dưới 2 giây trong điều kiện tiêu chuẩn (`NFR-02`, `NFR-03`).
- **Graceful Failure**: Lỗi mạng, lỗi API hoặc lỗi dịch vụ OCR không được làm ứng dụng bị crash hay làm mất dữ liệu đã lưu trước đó (`NFR-05`, `NFR-12`, `NFR-18`).

### V. Security & Privacy Non-Negotiables
- **Authentication**: Mật khẩu người dùng phải được mã hóa dạng hash an toàn (bcrypt/argon2), không lưu dạng plain text (`SEC-02`). Tất cả endpoint nghiệp vụ bảo mật phải xác thực qua JWT token (`SEC-01`, `SEC-09`).
- **Authorization**: Backend phải thực hiện kiểm tra quyền Admin trên từng API quản trị, không phụ thuộc vào kiểm tra phía Mobile App (`SEC-03`, `SEC-06`).
- **Data Minimization**: Thông tin cá nhân của người dùng được thu thập ở mức tối thiểu cần thiết (`Section 2.5.4`).

## Technology Stack & Constraints

- **Repository Model**: Monorepo quản lý chung cho cả 2 thành viên (Mobile App + Backend Server + Shared Specs).
  - `mobile/` (hoặc Flutter client tại root): Ứng dụng di động Flutter (Android 10.0+ & iOS 15.0+).
  - `backend/`: RESTful API Gateway, Dockerfile, Database Migrations, OCR Pipeline.
  - `specs/`: Đặc tả kỹ thuật & Hợp đồng API (API Contracts) dùng chung cho cả 2 thành viên đối soát.
- **Mobile Client**: Flutter Framework.
- **Backend API**: RESTful API (Triển khai bằng Docker trên Linux Ubuntu 22.04 LTS, kết nối HTTPS).
- **Database**: Relational DB (PostgreSQL / MySQL) chạy containerized qua `docker-compose`.
- **Integrations**: OCR Service (Tesseract / PaddleOCR / Cloud Vision) & Map API (Tính khoảng cách dự kiến).

## Scope & Priority Rules

- **MVP Priority**: Ưu tiên hoàn thành 100% các chức năng mức độ **Must (M)** thuộc Phiên bản 1 (v1.0) trước khi làm các tính năng Should (S).
- **Out of Scope for v1**: Không triển khai các tính năng v2/v3 trong phiên bản v1 (Gợi ý theo sở thích, Đánh giá review địa điểm, Bản đồ tương tác, Chia tiền nhóm, Tim kiếm bằng giọng nói/AI) (`BR-10`, `Section 2.5.5`).

## Governance

- Tất cả đặc tả tính năng (`/speckit.specify`), kế hoạch kỹ thuật (`/speckit.plan`) và danh sách task (`/speckit.tasks`) phải tuân thủ nghiêm ngặt Hiến pháp này.
- Mọi thay đổi thuộc về Hiến pháp phải được sự đồng ý của nhóm phát triển dự án Rendez.

---
**Version**: 1.0.0 | **Ratified**: 2026-09-12 | **Last Amended**: 2026-09-12
