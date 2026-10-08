# Rendez — phạm vi hoàn thiện local

Ngày: 2026-10-05. Quyết định: hoàn thiện đủ sáu module nghiệp vụ theo mức 2, với kiến trúc phù hợp nhóm hai người.

Tài liệu này là hợp đồng triển khai local hiện hành. Khi khác biệt với cơ chế kỹ thuật trong các specs 001–006 còn ở trạng thái Draft, dùng các quyết định dưới đây. SRS và specs gốc vẫn được giữ để truy vết; đây không phải cam kết triển khai production hoặc chứng nhận Android/iOS đã nghiệm thu trên thiết bị.

## Kiến trúc và hợp đồng

- Một API Go/Chi, truy vấn SQL trực tiếp bằng pgx; một app Flutter/Riverpod; PostgreSQL Docker. Không thêm lớp repository/service/interface, Redis, broker hay microservices.
- `make demo` build API có Tesseract tiếng Việt/Anh, khởi động DB, migrate/seed và chạy API trong Docker. DB và ảnh dùng hai named volumes; restart và `make down` giữ cả hai.
- API `/v1`, JSON payload trực tiếp; lỗi `{ "error": { "code", "message", "retryable" } }`. Không duy trì thêm `/api/v1` hay envelope `success/data`.
- Schema version 5. Chỉ `backend/migrations/core` được Goose thực thi. Nâng database hiện có bằng migration forward; không reset DB.

## 1. Tài khoản

Email/mật khẩu và tên hiển thị; đăng ký luôn tạo User. Giữ password hashing PBKDF2-SHA256 có salt, opaque session lưu hash trong DB, hết hạn sau 7 ngày và thu hồi khi logout. Không cần JWT/refresh hoặc Google/Apple cho local.

Flutter giữ token trong bộ nhớ, không ghi token ra storage thường. Mở lại app cần đăng nhập lại; tài khoản, yêu thích và đóng góp vẫn nằm trong DB. User không tự cấp quyền Admin. Tài khoản Admin mẫu chỉ dùng local.

## 2. Địa điểm, menu và tìm kiếm

Chỉ `published` và chưa xóa được hiển thị công khai. Các trường gồm tên, địa chỉ, thành phố, loại hình, mô tả, giờ mở cửa, tọa độ, xác nhận Admin và thời điểm cập nhật giá. Nguồn thiếu giá hoặc tọa độ phải hiển thị là thiếu dữ liệu.

Dataset đồ án nhỏ: Flutter tìm trên dữ liệu API theo tên, địa chỉ, loại hình, món ăn và vibe; lọc thành phố, loại hình và khoảng đơn giá. Backend ưu tiên có menu, sau đó xác nhận Admin và tên. Chưa cần search engine/index tìm kiếm riêng hoặc phân trang nhiều tầng.

Menu công khai gồm đơn giá và ảnh menu đã duyệt, có phóng to và ngày cập nhật. Hóa đơn gốc không công khai. MenuItems lưu nguồn đóng góp và thời điểm cập nhật. Seed chỉ là dữ liệu minh họa, không phải giá đã xác minh ngoài thực tế.

## 3. Khoảng cách và chi phí

Flutter lấy vị trí thiết bị khi người dùng chọn xem khoảng cách và cho phép truy cập. Dùng Haversine nội bộ; UI chỉ hiển thị khoảng cách ước tính, không giải thích thuật toán hoặc yêu cầu nhập tọa độ. Thiếu dữ liệu/không cấp quyền/timeout phải có thông báo dễ hiểu, không được bịa khoảng cách. Quyết định UI này thay thế phương án nhập tọa độ thủ công trước đây.

Chi phí = tổng `(đơn giá × số lượng món chọn)`; chi phí mỗi người là tổng chia đều số người. Không lấy trung bình mọi món rồi gọi là chi tiêu dự kiến. Giới hạn số lượng mỗi món 0–99, nhóm 1–100 người. Chưa chọn món khác với tổng tiền 0 của món miễn phí.

Hóa đơn được Admin duyệt hiển thị ví dụ lịch sử: tổng tiền, số khách, ngày ảnh và số tiền chia đều; không biến hóa đơn thành menu hoặc dự báo mới. Giá tham khảo không gồm phí dịch vụ/di chuyển.

## 4. Yêu thích

Thêm/bỏ lưu idempotent, owner-scoped và DB persistence, khóa duy nhất `(user_id,place_id)`. Đợi API thành công rồi cập nhật UI. Đổi tài khoản không giữ yêu thích của tài khoản trước. Địa điểm ẩn không xuất hiện trong danh sách đã lưu công khai.

## 5. Đóng góp và kiểm tra tự động

User/Admin chọn địa điểm hoặc đề xuất nơi mới với tên, địa chỉ, thành phố và loại hình. Admin có thể chọn cả địa điểm nháp/ẩn. Nơi mới bắt đầu `draft`.

Upload 1–5 JPG/PNG thật, mỗi ảnh nhỏ hơn 10 MiB, ngày chụp hợp lệ. Kiểm tra file đọc được, kích thước từ 100×100 và tối đa 20 triệu pixel; giải mã và mã hóa lại để loại metadata. Ảnh lưu filesystem bằng tên ngẫu nhiên, metadata có FK trong DB. Lỗi trước commit chỉ xóa file do thao tác vừa tạo.

Ảnh không hợp lệ bị từ chối ngay bằng 422/413, không tạo bản ghi gửi thành công. Không dùng AI đo độ mờ hoặc ngưỡng confidence giả. Ảnh hợp lệ chạy OCR trong request, tổng ngân sách 25 giây cho cả bộ ảnh; dữ liệu chỉ là nháp. Timeout/lỗi kỹ thuật giữ `pending_admin` kèm `ocr_error` để thử lại hoặc nhập thủ công, không tự coi là đóng góp sai.

Trạng thái tối thiểu: `pending_admin`, `approved`, `rejected`. Lịch sử và ảnh gốc chỉ owner/Admin được xem; user khác nhận 404, tránh lộ sự tồn tại của đóng góp. Lịch sử có trạng thái, ngày và lý do từ chối. Không có dữ liệu mock/fallback trong luồng live.

## 6. Admin và OCR

Admin tạo/sửa/ẩn địa điểm; xóa mềm giữ lịch sử. Xóa bị từ chối khi còn đóng góp chờ duyệt. Các API đều kiểm tra quyền ở backend.

Một Tesseract engine, Việt/Anh, timeout hữu hạn. Parser tối thiểu đọc dòng tên–giá, trả text thô và danh sách nháp; không có kết quả vẫn cho Admin nhập tay. Không có tự động approve. Admin xem ảnh cạnh bản nháp trên màn hình rộng; màn hình hẹp xếp dọc. Có thêm/bỏ dòng, sửa tên/giá/nhóm, lưu nháp DB và chạy lại OCR.

Phê duyệt/từ chối trong transaction, khóa đóng góp và địa điểm. Menu duyệt upsert các tên đã kiểm tra, giữ món không liên quan. Hóa đơn cần tổng tiền và số khách hợp lệ. Duyệt đưa `draft` thành `published`, nhưng không tự bỏ quyết định `hidden` của Admin. Lưu người/thời điểm quyết định; từ chối cần lý do. Quyết định cuối không được đảo ngược hoặc áp dụng lần hai; trả 409. OCR lỗi không xóa bản nháp đã sửa.

Menu image endpoint chỉ công khai ảnh `menu_photo` đã duyệt của địa điểm công khai; ảnh bill luôn riêng. Không cần trang Admin riêng, workflow engine, worker phân tán hay confidence tự chế.

## API bổ sung

| API | Quyền và mục đích |
| --- | --- |
| GET /v1/lookups | Public: thành phố/loại hình |
| GET/POST /v1/admin/places | Admin: danh sách/tạo |
| PUT/DELETE /v1/admin/places/{id} | Admin: sửa toàn bộ trường/xóa mềm |
| POST /v1/contributions | User/Admin: multipart `images`, `type`, `captured_at`, `place_id` hoặc thông tin nơi mới |
| GET /v1/contributions/my | User: lịch sử riêng |
| GET /v1/contributions/{id} | Owner/Admin: chi tiết |
| GET /v1/contributions/{id}/images/{imageID} | Owner/Admin: ảnh riêng |
| GET /v1/menu-images/{imageID} | Public chỉ với menu đã duyệt |
| GET /v1/admin/contributions | Admin: lịch sử/hàng chờ |
| POST /v1/admin/contributions/{id}/ocr | Admin: chạy lại OCR |
| PUT /v1/admin/contributions/{id}/draft | Admin: lưu `items` hoặc `bill_total`, `guests_count` |
| POST /v1/admin/contributions/{id}/review | Admin: `decision`, `reason`, `items` hoặc thông tin bill |

## Nghiệm thu

1. Đăng ký User, tìm/lọc địa điểm, xem menu, tính khoảng cách/chi phí, lưu và đăng nhập lại thấy dữ liệu.
2. Gửi ảnh menu cho nơi mới; nơi nháp và ảnh chưa public.
3. Admin xem OCR thật, sửa/lưu nháp, duyệt; User thấy trạng thái, nơi công khai, giá và ảnh mới.
4. Gửi hóa đơn, Admin sửa tổng/số khách, duyệt; chỉ ví dụ chi tiêu được public, ảnh gốc giữ riêng.
5. Lỗi: tài khoản trùng, login sai, quyền Admin/owner, ảnh sai/quá lớn/quá nhiều, OCR lỗi, không có giá/tọa độ, từ chối thiếu lý do, approve đồng thời.
6. Restart API không mất dữ liệu PostgreSQL hoặc filesystem volume.

Chạy `make check`, `make integration`, `make integration-ui`. Kiểm thử live dùng HTTP, PostgreSQL Docker và Tesseract thật. Test storage DB là tmpfs riêng, không dùng hoặc reset dev DB. GPS/camera/native photo picker cần kiểm tra thêm trên Android/iOS thật; web build và widget tests không chứng nhận quyền thiết bị.

Chat, presence, RSVP, bản đồ tương tác, recommendation và hạ tầng production ngoài phạm vi sáu module. Prototype source có thể giữ để tham khảo; không đưa dữ liệu mock vào navigation live.
