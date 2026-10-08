# Đóng góp

## Quy trình nhóm hai người

Mỗi thay đổi dùng một nhánh ngắn và một PR có người còn lại review. Mô tả vấn đề, thay đổi và lệnh kiểm tra. Giữ PR nhỏ theo tính năng hoặc trách nhiệm; không trộn refactor và tính năng mới.

Chạy `make check` trước PR. Thay đổi SQL/session cần chạy `make integration` với PostgreSQL Docker tạm được tạo tự động. Dùng `make format` để định dạng; commit cả lockfile khi dependency thay đổi. Không commit secrets, file build hoặc dữ liệu người dùng.

## Ranh giới mã nguồn

- Flutter: màn hình/widgets ở `lib/features/<feature>`, phần thực sự dùng chung ở `lib/core`. Dùng import `package:rendez/...` để tránh sai đường dẫn khi di chuyển file.
- Go: `cmd/api` sở hữu lifecycle/router, `internal/<feature>` sở hữu hành vi tính năng. Dùng SQL/pgx trực tiếp; chỉ tách thêm package khi có trách nhiệm thực tế.
- `internal/httpx` chỉ chứa tiện ích HTTP dùng chung. Không dựng service/repository/interface cho lớp chỉ có một cách dùng.
- Giữ validation, xử lý lỗi, quyền truy cập, transaction/constraint cần thiết và test hành vi. Không giảm các phần này để tiết kiệm mã.

## Migration và dữ liệu

Chỉ `backend/migrations/core` được Goose chạy. `migrations/drafts` lưu SQL chưa hoàn thiện. Catalog 00003 đã chuyển vào core; API hiện yêu cầu schema 4. Khi thêm migration, cập nhật schema version và kiểm tra migration/readiness cùng nhau.

Không sửa migration đã được chia sẻ/applied; thêm forward migration. Không reset DB hoặc xóa volume trong refactor. Integration tests dùng Compose project riêng, cổng tự cấp và tmpfs; tự dọn container kể cả khi test lỗi. Không dùng PostgreSQL hệ thống hoặc `DATABASE_URL` phát triển. `/dev/login` và seed fixtures cũ chỉ có trong dev build. Seed demo catalog/tài khoản dùng build bình thường nhưng vẫn yêu cầu `APP_ENV=development`.

## Phạm vi đồ án

Giữ SRS, đặc tả và quyết định sản phẩm trong `docs`. Prototype mock phải được mô tả rõ; không tuyên bố đã tích hợp backend/OCR khi chưa có luồng thật. Triển khai từng lát tính năng theo kế hoạch hiện có.
