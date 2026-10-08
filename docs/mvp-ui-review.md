# Đánh giá giao diện MVP

Ngày 2026-10-07. Phạm vi: sáu module local trong [đặc tả hiện hành](specs/000-local-completion/spec.md). Phong cách được chọn: trẻ trung, nhiều màu.

## Câu hỏi bắt buộc

“Liệu thiết kế ứng dụng như thế này thì người dùng có muốn sử dụng ứng dụng này hay không?”

Mỗi thiết kế phải có lý do cụ thể để người dùng tiếp tục: thấy ngay lợi ích, đọc được thông tin, thao tác đúng và biết bước tiếp theo khi gặp lỗi. Nếu chưa có lý do đó, sửa thiết kế rồi kiểm tra lại. Đây là đánh giá thiết kế theo nhiệm vụ; cần thử với người dùng thật trước khi kết luận về mức độ yêu thích.

## Quyết định theo luồng

| Luồng | Vấn đề trước | Thiết kế lại và lợi ích |
|---|---|---|
| Khám phá | Danh sách giống dữ liệu thô; giá ít nổi bật | Header có lợi ích rõ, màu tím/đào/xanh, thẻ giá tham khảo, bộ lọc gọn, xóa tìm kiếm và bỏ bộ lọc |
| Chi tiết | Thông tin nối thành đoạn dài, cần nhập tọa độ ngay | Nhóm thông tin địa điểm, menu chọn số lượng, tổng chi phí nổi bật; một nút xem khoảng cách từ bạn; chỉ hiển thị kết quả ước tính và hướng dẫn quyền vị trí dễ hiểu |
| Đã lưu | Chỉ nói cần đăng nhập hoặc danh sách trống | Giải thích vì sao nên lưu, nút đăng nhập/khám phá ngay; xử lý lỗi có thử lại |
| Tài khoản | Các ô nhập dính nhau, ít hướng dẫn | Hero có lợi ích, form kiểm tra tại chỗ, autofill, hiện/ẩn mật khẩu, nút chờ xử lý và theme selector |
| Đóng góp | Form dài và khó biết ảnh sẽ đi đâu | Chia bước, nói rõ quyền riêng tư, cho bỏ từng ảnh; đi từ chi tiết sẽ chọn sẵn địa điểm |
| Admin | Công việc chờ duyệt nằm sau danh sách địa điểm | Hàng chờ chỉ đếm đóng góp chưa duyệt, có mục lịch sử đã xử lý; phân biệt menu/hóa đơn và trạng thái bằng tiếng Việt; giữ đối soát OCR/ảnh thật |
| Desktop/mobile | Web User bị bó thành viewport 450px | Web tối đa 1100px, navigation rail trên desktop, bottom navigation trên mobile; danh sách một cột khi màn hình quá hẹp |

Không thêm đánh giá sao, khoảng cách giả, ảnh địa điểm giả hoặc social mock vào luồng MVP. Ảnh thiếu dùng minh họa icon; giá thiếu vẫn ghi rõ chưa có bảng giá. Màu và icon không thay thế nhãn trạng thái.

## Kiểm chứng

Kiểm thử bổ sung trong `mobile/test/mvp_usability_test.dart`: màn hình 320px với chữ 1.5x, bỏ bộ lọc đồng bộ ô tìm kiếm, CTA đăng nhập từ mục đã lưu/đóng góp, validation form, mật khẩu hiện/ẩn, món miễn phí và navigation desktop.

Các kiểm tra layout đã phát hiện tràn ở bộ lọc, header và trạng thái trống; các phần này được thiết kế lại trước nghiệm thu. Kiểm tra live dùng PostgreSQL Docker, HTTP và OCR thật; giữ nguyên dữ liệu phát triển.

Kết quả: Go test/vet đạt; Flutter analyzer sạch, 29 test đạt, bốn live test qua HTTP/PostgreSQL/OCR thật đạt; web build thành công. Chrome headless đã chụp và kiểm tra desktop 1280px, mobile 390px, tài khoản và chi tiết/menu với dữ liệu API thật; không có JavaScript exception. Sau ảnh chụp đầu, bộ lọc mobile được thu gọn thành một hàng để giá xuất hiện trong màn hình đầu. Sáu test usability bảo vệ các hành vi mới, bao gồm tách hàng chờ Admin khỏi lịch sử.

Knowledge graph được cập nhật bằng AST; parser SQL vẫn chưa cài, nên graph không được dùng làm bằng chứng nghiệm thu migration.

Chạy lại: `make check`, `make integration-ui`, `make build-web`. Khởi động: `make demo`, sau đó `make mobile` hoặc chạy web trong thư mục mobile.

## Giới hạn

Chưa nghiệm thu GPS/camera/photo picker trên Android/iOS thật. Phiên đăng nhập vẫn giữ trong bộ nhớ theo đặc tả local. Không coi kiểm thử kỹ thuật hoặc đánh giá thiết kế là khảo sát người dùng.

## Điều chỉnh theo phản hồi

Bỏ hoàn toàn form nhập tọa độ và thuật ngữ “đường chim bay” khỏi luồng người dùng. Người dùng chỉ cần biết địa điểm cách mình khoảng bao xa; thuật toán giữ ở lớp tính toán. Lỗi quyền/vị trí có hướng dẫn ngắn, không đưa exception kỹ thuật lên giao diện.

Kiểm tra sau điều chỉnh: analyzer sạch, 29 test đạt, web build thành công. Test mới xác nhận không có ô tọa độ và lỗi vị trí được chuyển thành thông báo dễ hiểu.
