# Rendez

Ứng dụng đồ án PBL6: khám phá địa điểm, minh bạch giá và đóng góp thông tin có kiểm duyệt. Repo gồm một ứng dụng Flutter và một API Go, phù hợp nhóm hai người.

## Cấu trúc

```text
backend/                 API Go và PostgreSQL local
  cmd/api/               Khởi động, health check và kiểm thử API
  internal/auth/         Session và quyền truy cập
  internal/catalog/      Địa điểm, menu và yêu thích
  internal/httpx/        JSON và lỗi HTTP dùng chung
  migrations/core/       Migration Goose được chạy
  migrations/drafts/     SQL đang thiết kế, không được chạy
mobile/                  Ứng dụng Flutter
  lib/core/              Models, API client, providers, theme và utilities
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

Từ thư mục gốc:

```sh
make demo          # Build API + OCR, DB Docker, migrate, seed, chờ API ready
make mobile-deps   # Trong terminal khác
make mobile
# Hoặc: cd mobile && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357
```

`make demo` chạy API Go và PostgreSQL trong Docker; không cần cài Tesseract trên host. API: `http://127.0.0.1:8080`. Admin local: `admin@rendez.local` / `RendezDemo123!`. Seed là dữ liệu mẫu và không ghi đè bản ghi đã chỉnh sửa.

Khi sửa Go theo cách host, dùng `make db migrate seed api`; OCR cần `tesseract` với ngôn ngữ `vie` và `eng` trên PATH. Không chạy host API và Docker API cùng cổng. Dừng stack bằng `make down`, giữ database và ảnh trong volumes. `make db-recreate` chỉ tạo lại container DB, giữ volume.


## Kiểm tra

```sh
make check        # Go vet, test normal/dev, Dart analyze và Flutter test
make format      # gofmt và dart format
make integration # Tự tạo PostgreSQL Docker mới, chạy test và dọn container
make integration-ui # Flutter client/providers gọi HTTP thật và DB Docker thật
```

GitHub Actions chạy kiểm tra Go/Flutter và integration PostgreSQL. Android/iOS cần toolchain riêng; CI chưa build hai nền tảng này.

## Luồng ứng dụng

Đã nối dữ liệu thật cho sáu module local: tài khoản; địa điểm/menu/tìm kiếm/lọc; khoảng cách và chi phí; yêu thích; đóng góp ảnh và lịch sử; Admin quản lý địa điểm, OCR và duyệt. Flutter gọi API Go, DB PostgreSQL và filesystem ảnh; không fallback sang mock khi API lỗi.

- **Khám phá:** tìm theo tên, địa chỉ, món ăn; lọc thành phố, loại hình và đơn giá. Chi tiết hiển thị menu/ảnh đã duyệt, thời điểm giá và trạng thái thiếu dữ liệu.
- **Khoảng cách/chi phí:** vị trí thiết bị hoặc tọa độ nhập tay; Haversine đường chim bay. Chọn món, số lượng và số người để tính tổng/chia đều; không suy diễn chi phí từ trung bình menu.
- **Đã lưu/Cá nhân:** đăng ký/login/logout, favorites theo tài khoản trong DB. Token giữ trong bộ nhớ; mở lại app cần login, dữ liệu tài khoản vẫn còn.
- **Đóng góp:** 1–5 JPG/PNG thật, nhỏ hơn 10 MiB/ảnh, ngày chụp, nơi có sẵn hoặc đề xuất draft. Xem lịch sử, trạng thái và lý do từ chối.
- **Quản trị:** đăng nhập Admin rồi mở nút Quản trị trong Cá nhân. Tạo/sửa/ẩn/xóa mềm địa điểm; xem ảnh cạnh dữ liệu OCR, sửa/lưu nháp, duyệt/từ chối. Admin gửi ảnh qua tab Đóng góp, chọn cả nơi nháp/ẩn.

OCR Tesseract Việt/Anh tạo bản nháp và text, không tự công khai. OCR lỗi giữ đóng góp để thử lại hoặc nhập tay. Duyệt dùng transaction và ghi người/thời điểm; click lặp lại nhận 409. Ảnh menu chỉ public sau duyệt; hóa đơn gốc chỉ owner/Admin thấy. Hóa đơn được duyệt chỉ công khai ví dụ tổng tiền/số khách/ngày, không chuyển thành menu.

Flutter web/desktop gọi `http://127.0.0.1:8080`; Android emulator gọi `http://10.0.2.2:8080`. Đổi bằng `--dart-define=API_BASE_URL=http://<host>:8080`. Docker mặc định bind loopback; điện thoại thật cần cấu hình LAN local và chính sách HTTP phù hợp. CORS chỉ cho origin localhost/127.0.0.1 ở development. GPS/camera/permissions cần nghiệm thu thêm trên Android/iOS thật.

`make check` kiểm tra Go và Flutter; `make integration-ui` chứng minh HTTP + PostgreSQL Docker + Tesseract thật, gồm màn hình Admin sửa và duyệt. `make build-web` build ứng dụng web. Kiểm thử không reset DB phát triển hoặc xóa persistent volumes.

Schema version 5 gồm đóng góp, ảnh, OCR draft và quyết định. `make demo` áp dụng migration forward; không cần reset volume. Chat, bản đồ tương tác và recommendation ngoài phạm vi local; prototype source không nằm trong navigation live.

## Tài liệu

- [Đánh giá giao diện MVP](docs/mvp-ui-review.md)
- [Nghiệm thu runtime và ảnh chụp MVP](docs/mvp-runtime-audit.md)

- [Hướng dẫn đóng góp](CONTRIBUTING.md)
- [Phạm vi hoàn thiện local hiện hành](docs/specs/000-local-completion/spec.md)
- [SRS gốc](docs/SRS_PBL6.pdf) và [đặc tả](docs/specs/)
- [Đối chiếu sản phẩm](docs/product-reconciliation.md)
- [Kiến trúc](docs/backend-architecture.md) và [kế hoạch triển khai](docs/backend-implementation-plan.md)
- [Kiểm kê skills và uv tools](docs/tooling.md)

Tài liệu kiến trúc/kế hoạch mô tả đích phát triển; không phải danh sách tính năng đã hoàn thành. README và mã đang chạy là căn cứ cho lệnh hiện tại.
