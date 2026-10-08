# Kiểm chứng hoàn thiện local

Ngày kiểm chứng: 2026-10-05. Phạm vi: [sáu module local mức 2](specs/000-local-completion/spec.md).

## Kết quả đã chạy

- `make check-backend`: Go tests build bình thường/dev và `go vet` đều qua.
- `make check-mobile`: analyzer không có lỗi; 22 tests qua. Bốn live tests được skip trong suite mặc định vì cần server riêng.
- `make integration`: PostgreSQL Docker thật, migrations 1–5, quyền/session, catalog/favorites, upload/OCR/Admin đều qua.
- `make integration-ui`: bốn Flutter live tests qua HTTP thật và PostgreSQL Docker thật; gồm sửa OCR draft, lưu nháp, duyệt và thao tác nút trên màn hình Admin. Backend contribution test dùng Tesseract thật, không mock.
- `make build-web`: biên dịch frontend web thành công.
- `make demo`: build và khởi động API/OCR + DB Docker, migration forward, seed không ghi đè; `/health/ready` trả 200.
- Chrome headless với profile riêng: render khám phá từ API, đăng nhập Admin qua form web, mở Quản trị và xem đóng góp/ảnh riêng. Admin web mở rộng để đối soát cạnh nhau; navigation User giữ bố cục mobile.
- Upload ảnh mẫu trực tiếp vào API container: đọc ảnh private và OCR text `Coffee`, không có OCR error. Restart riêng API, bản ghi trong DB vẫn tồn tại và hash ảnh tải về không đổi. Đóng góp mẫu sau kiểm thử được từ chối với lý do ghi rõ kiểm thử; menu công khai không bị thay đổi. Session kiểm thử đã thu hồi.
- Graphify AST cập nhật theo AGENTS.md. Graphify chưa có parser SQL, nên không dùng graph làm bằng chứng validation migration; migration được thực thi trong integration tests thật.

## Các tình huống lỗi có bằng chứng kiểm thử

Email trùng/login sai; session bị thu hồi; User không gọi API Admin; User khác không đọc đóng góp/ảnh riêng; draft place/menu photo chưa duyệt không public; upload bytes sai/ảnh quá nhỏ/quá nhiều; failed upload không để lại file; Admin xóa nơi còn đóng góp pending nhận 409; từ chối thiếu lý do; phê duyệt đồng thời chỉ một transaction thắng; đóng góp đã quyết định không duyệt lại; bill original không public; OCR không có executable giữ pending/error và retry trả lỗi hữu hạn.

Khoảng cách Haversine có kiểm tra tọa độ thiếu/sai, điểm trùng và đường dài. Chi phí dùng số lượng chọn và chia nhóm. Bộ lọc giá dùng từng món, không lấy min/max để suy ra các giá trong khoảng trống. Tìm tên món có kiểm thử.

## Giới hạn nghiệm thu

Chưa build/chạy Android hoặc iOS trên thiết bị thật. Camera, photo picker, GPS và hộp thoại quyền native cần nghiệm thu riêng; manifest/plist đã có cấu hình. Session Flutter giữ trong bộ nhớ, mở lại app cần đăng nhập. OCR parser tối thiểu cần Admin sửa/duyệt, không cam kết mọi ảnh menu được nhận dạng chính xác. Không coi các tests local là chứng nhận hiệu năng dataset lớn hoặc production.

Database phát triển và cả hai persistent volumes được giữ nguyên; không chạy reset database hoặc xóa volume. Các integration DB dùng tmpfs và project riêng.
