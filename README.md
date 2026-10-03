# Rendez

Ứng dụng đồ án PBL6: khám phá địa điểm, minh bạch giá và đóng góp thông tin có kiểm duyệt. Repo gồm một ứng dụng Flutter và một API Go, phù hợp nhóm hai người.

## Cấu trúc

```text
backend/                 API Go và PostgreSQL local
  cmd/api/               Khởi động, health check và kiểm thử API
  internal/auth/         Session và quyền truy cập
  internal/httpx/        JSON và lỗi HTTP dùng chung
  migrations/core/       Migration Goose được chạy
  migrations/drafts/     SQL đang thiết kế, không được chạy
mobile/                  Ứng dụng Flutter
  lib/core/              Models, dữ liệu mock, providers, theme và utilities
  lib/features/          Màn hình và widgets theo tính năng
  test/                  Kiểm thử Flutter
  android/, ios/, web/   Cấu hình build nền tảng
docs/                   SRS, đặc tả, kiến trúc và kế hoạch
  specs/                 Đặc tả từng tính năng
  archive/               Checkpoint lịch sử
```

## Yêu cầu

- Go 1.26 trở lên, theo `backend/go.mod`.
- Flutter 3.47.3 / Dart 3.13.3 (bộ SDK dùng để kiểm tra repo), theo `mobile/pubspec.yaml`.
- Docker Compose để chạy PostgreSQL local.
- Make để dùng các lệnh chung. Không cần Python hoặc uv.

## Chạy local

Từ thư mục gốc, khởi động backend:

```sh
make db
make migrate
make seed
make api-dev
```

Trong terminal khác, chạy ứng dụng:

```sh
make mobile-deps
make mobile
# Hoặc: cd mobile && flutter run -d chrome
```

`make api` chạy build bình thường, không có `/dev/login`. `make down` dừng PostgreSQL và giữ volume. Biến `DATABASE_URL`, `APP_ENV`, `HTTP_ADDR` được cấu hình qua môi trường; `backend/.env.example` là tài liệu mẫu, không tự nạp. Chi tiết endpoint và phiên đăng nhập: [backend/README.md](backend/README.md).

## Kiểm tra

```sh
make check        # Go vet, test normal/dev, Dart analyze và Flutter test
make format      # gofmt và dart format
make integration # DB phải chạy; test tạo và xóa DB tạm, giữ rendez_core
```

GitHub Actions chạy kiểm tra Go/Flutter và integration PostgreSQL. Android/iOS cần toolchain riêng; CI chưa build hai nền tảng này.

## Trạng thái hiện tại

Flutter là prototype: dữ liệu mock, đăng nhập/chat/yêu thích trong bộ nhớ, bản đồ minh họa; chưa gọi API. Backend có health check, opaque session thật, quyền Admin và dev fixtures. Catalog, giá, yêu thích và duyệt đóng góp qua API vẫn là công việc tiếp theo. Refactor cấu trúc không thay đổi phạm vi sản phẩm hoặc xóa tính năng UI.

SQL catalog `00003_catalog.sql` là bản nháp, được giữ ngoài `migrations/core` để không nâng schema ngoài khả năng của API version 2. Nếu bản nháp đã được áp dụng ở máy khác, cần xử lý tương thích bằng migration và code tiếp theo; không reset dữ liệu.

## Tài liệu

- [Hướng dẫn đóng góp](CONTRIBUTING.md)
- [SRS gốc](docs/SRS_PBL6.pdf) và [đặc tả](docs/specs/)
- [Đối chiếu sản phẩm](docs/product-reconciliation.md)
- [Kiến trúc](docs/backend-architecture.md) và [kế hoạch triển khai](docs/backend-implementation-plan.md)
- [Kiểm kê skills và uv tools](docs/tooling.md)

Tài liệu kiến trúc/kế hoạch mô tả đích phát triển; không phải danh sách tính năng đã hoàn thành. README và mã đang chạy là căn cứ cho lệnh hiện tại.
