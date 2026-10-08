# Rà soát phạm vi Rendez cho demo local

Ngày rà soát: 2026-10-03. Bối cảnh: đồ án nhóm hai người, chạy local, tập trung tính năng và luồng xử lý; giữ đăng ký, đăng nhập và đăng xuất.

Đây là đề xuất giản lược, chưa thay thế SRS hoặc sáu specs hiện hành. Không thay đổi mã nguồn hoặc tiêu chí nghiệm thu trong lần rà soát này.

## Căn cứ và kết luận

Đã đọc sáu [specs](specs/), các phần yêu cầu FR/NFR/SEC/BR trong [SRS gốc](SRS_PBL6.pdf), các quyết định sản phẩm trong [product reconciliation](product-reconciliation.md), kế hoạch và các cơ chế kiến trúc liên quan. Đối chiếu với routes, migration, dev login, Flutter providers/models và Compose hiện tại. PDF được trích xuất văn bản; không đánh giá lại các sơ đồ đồ họa trong lần này.

SRS gốc đã giới hạn hiệu năng theo dataset và môi trường đồ án. Bài toán không cần hạ tầng thương mại. Phần có thể giảm mạnh nhất là cơ chế kỹ thuật và các mở rộng trong tài liệu kiến trúc/prototype, không phải toàn bộ nghiệp vụ.

Giữ luồng xuyên suốt: đăng ký/đăng nhập → khám phá và xem giá → khoảng cách/chi phí → lưu yêu thích → gửi ảnh cho địa điểm cũ hoặc đề xuất mới → kiểm tra tự động/OCR → Admin sửa và duyệt/từ chối → User thấy kết quả → dữ liệu được duyệt xuất hiện công khai.

OCR là FR-14 mức Must; kiểm tra tự động là FR-19 mức Must. Không thể tuyên bố đáp ứng toàn bộ SRS nếu bỏ OCR hoặc thay toàn bộ lớp tự động bằng nhập liệu thủ công. Có thể làm luồng thủ công trước để phát triển, nhưng đó là mốc trung gian.

## 1. Tài khoản — spec 001

**Giữ:** đăng ký tài khoản vào DB, email duy nhất, đăng nhập kiểm tra thông tin, đăng xuất, User/Admin, quyền sở hữu. Nếu nhận mật khẩu thật, giữ password hashing; dùng thư viện có sẵn, không lưu plaintext. Đăng ký luôn tạo User; Admin được seed, không nhận role Admin từ form đăng ký.

**Giản lược:** một cơ chế nhận diện thống nhất, không JWT access/refresh pair, rotation, replay detection, đa thiết bị hoặc khôi phục phiên nâng cao. Opaque session hiện tại là phương án ít thay đổi nhất: một token, một bảng, login/logout. Có thể chỉ giữ trạng thái đăng nhập trên Flutter trong lần chạy và yêu cầu đăng nhập lại sau khi mở app.

**Nếu nhất quyết không token/session:** có thể dùng định danh User gửi theo request trong demo localhost. Backend vẫn tra role và owner từ DB. Đây là giả lập danh tính, không phải xác thực thật; phải sửa tiêu chí SEC-01/FR-02 và ghi rõ giới hạn. UI đăng ký/login vẫn có thể hoạt động, nhưng header tự nhận danh tính không chứng minh quyền truy cập sau login. Không xem phương án này là đáp ứng SRS nguyên trạng.

**Không làm:** Google/Apple OAuth, MFA, email/SMS xác minh, quên mật khẩu, account linking, quản lý credential của provider. OAuth xuất hiện trong tài liệu reconciliation/architecture, không phải điều kiện bắt buộc của FR-01–03 trong SRS gốc.

**Cập nhật kiểm tra nguồn:** workspace hiện có `accounts.go` cho đăng ký/login email-password, password hashing và Flutter API client/providers gọi API. Đây là mã đang thay đổi, chưa được nghiệm thu trong lần nghiên cứu này. Session vẫn là opaque token đơn giản; nhận định trước rằng chỉ có fixture login không còn phản ánh workspace hiện tại.

## 2. Địa điểm, menu, tìm kiếm — spec 002

**Giữ:** danh sách/chi tiết, loại hình, tìm kiếm, lọc giá, ảnh menu và dữ liệu giá đã duyệt, ngày quan sát/cập nhật, draft/published/hidden, trạng thái thiếu dữ liệu. Guest không xem draft/hidden.

**Giản lược:** một khu vực demo, vài loại địa điểm, bộ seed nhỏ; truy vấn SQL đơn giản cho tìm tên/địa chỉ và tên món nếu giữ yêu cầu đó. Dùng thứ tự ổn định và quy tắc ưu tiên dữ liệu giá đơn giản; không dựng Transparency Score, recommendation engine hoặc full-text search chuyên dụng. Không bắt buộc pg_trgm chỉ vì muốn đạt dưới hai giây; đo trên dataset demo trước. Phân trang nếu giữ chỉ cần page/limit có giới hạn; không cursor hoặc infinite-scroll phức tạp.

Ảnh menu lưu trên filesystem local có thư mục dữ liệu cấu hình; không CDN/S3/presigned URL. Một menu chính cho mỗi địa điểm nếu dữ liệu demo đủ; không cần hệ thống nhiều menu theo mùa và revision nhiều tầng. Giá VND có thể lưu số nguyên, kèm đơn vị hàng hóa/dịch vụ khi cần.

`has_price_data` có thể suy ra từ dữ liệu đã duyệt, không cần một cờ được cập nhật thủ công ở nhiều nơi. Trạng thái công bố của địa điểm phải khác trạng thái duyệt của đóng góp. Ngày Admin duyệt không thay thế ngày ảnh/giá được quan sát.

**Không làm:** đa vùng phức tạp, Elasticsearch, vector search, thuật toán gợi ý, cache Redis, điểm độ tin cậy, tự hết hạn dữ liệu theo thời gian.

## 3. Khoảng cách và chi phí — spec 003

**Giữ:** tọa độ hợp lệ, khoảng cách thực sự tính được, chi phí có công thức rõ, trường hợp thiếu tọa độ/giá và nhãn tham khảo.

**Giản lược:** Haversine với vị trí nhập/chọn thủ công. FR-08 trong SRS cho phép vị trí chọn trước; không cần GPS để chứng minh phép tính. Không cần Map API, geocoding, chỉ đường hoặc bản đồ tương tác. Tính trên Flutter từ tọa độ đã có cũng đủ, không bắt buộc endpoint khoảng cách riêng.

Chi phí: tổng các món đã chọn × số lượng là một ví dụ ước tính dễ kiểm chứng. Hóa đơn dùng tổng tiền/số khách hợp lệ để cho ví dụ chi tiêu lịch sử. Nếu giữ đơn giá/giờ của dịch vụ thì phải có thời lượng. Không lấy giá trung bình của mọi món trên menu rồi tự gọi là chi phí một người. Nếu dùng công thức khác phải mô tả giả định.

**Không làm:** dự đoán chi tiêu bằng AI, tối ưu lịch trình, giá vận chuyển, realtime location. Giá chưa biết là không khả dụng, không phải 0.

## 4. Yêu thích — spec 004

**Giữ:** thêm/bỏ lưu, danh sách riêng theo User, DB persistence, UNIQUE(user_id, place_id), danh sách trống và địa điểm không còn công khai. Đổi tài khoản không được thấy danh sách của tài khoản trước.

**Giản lược:** chờ API thành công rồi cập nhật UI; không cần optimistic update/rollback/Undo nhiều tầng. Lưu/bỏ lưu lặp lại có thể trả thành công để tránh xử lý lỗi trùng không cần thiết. Danh sách demo nhỏ không cần một cơ chế phân trang riêng phức tạp.

**Không làm:** thông báo biến động giá, đồng bộ offline, tổ chức nhiều bộ sưu tập, chia sẻ bộ sưu tập. Mô tả “theo dõi biến động giá” trong overview không tự tạo nghĩa vụ notification.

## 5. Đóng góp — spec 005

**Giữ:** upload ảnh thật, loại/kích thước/số lượng hợp lệ, ghi nhận người gửi và ngày ảnh; chọn địa điểm hoặc tạo đề xuất draft; lịch sử cá nhân, trạng thái và lý do từ chối; không công khai dữ liệu chưa duyệt.

**Giản lược:** lớp tự động kiểm tra file thực sự đọc được, giới hạn kích thước/độ phân giải, chạy OCR và kiểm tra dữ liệu giá cơ bản. Không cần mô hình AI đánh giá ảnh mờ, chống gian lận hoặc dò ảnh trùng. Nếu giữ giới hạn 1–5 ảnh theo spec thì kiểm tra ngay trong request; giảm còn một ảnh là thay đổi acceptance criteria, không chỉ thay đổi kiến trúc.

Lưu file ở filesystem local, metadata trong DB. Giữ xử lý lỗi để không báo gửi thành công khi chưa lưu đủ dữ liệu. Chưa cần upload resumable, asset reservation state machine, idempotency key framework hoặc hệ thống reconciliation nền. Sau lỗi ghi DB có thể xóa file vừa tạo; chỉ xóa file của thao tác đang xử lý.

Trạng thái tối thiểu: processing, pending_admin, approved, rejected; OCR lỗi kỹ thuật lưu thông tin lỗi và cho thử lại/duyệt thủ công. Không đánh đồng timeout dịch vụ với đóng góp sai. Tên trạng thái hiện có có thể giữ để tránh đổi giao diện/API không cần thiết.

**Không làm:** worker phân tán, broker, notification realtime, lịch sử mọi lần sửa bản nháp, chain thay thế evidence. Giữ nguyên nội dung ảnh đã gửi và một kết quả duyệt cuối cùng có người duyệt/thời gian; không cần version graph.

## 6. Admin và OCR — spec 006

**Giữ:** Admin tạo/sửa/ẩn địa điểm; upload ảnh; OCR thật trả dữ liệu nháp; Admin xem ảnh cạnh dữ liệu, sửa tên/giá, loại dòng rác; approve/reject có lý do; chỉ dữ liệu duyệt được hiển thị công khai.

**Giản lược:** màn hình Admin trong cùng Flutter app. Một OCR engine, một cách gọi, timeout hữu hạn, loading và thử lại thủ công. Nếu thời gian xử lý bộ ảnh demo nằm trong ngân sách request, chạy trực tiếp trong request là đủ; điều chỉnh timeout OCR nhất quán với timeout HTTP hiện tại. Chỉ cần background job nhỏ khi đo thực tế chứng minh request không đáp ứng; không mặc định dựng queue/lease/fencing/multi-worker.

OCR có thể trả dòng text thô và parser tối thiểu; Admin sửa các trường còn thiếu. Không bịa confidence số khi engine không cung cấp. Không tự từ chối bằng ngưỡng 0.5 nếu chưa có căn cứ.

Phê duyệt dùng một transaction để cập nhật quyết định, dữ liệu giá và công bố địa điểm liên quan; kiểm tra trạng thái trong transaction để click hai lần không công bố hai lần. Không cần workflow engine, event sourcing hoặc snapshot nhiều tầng. Giữ người duyệt/thời gian/lý do/nguồn ảnh để truy vết đơn giản.

**Không làm:** trang Admin riêng, nhiều nhà cung cấp OCR và failover, dashboard vận hành, retry tự động nhiều tầng, khóa cộng tác giữa nhiều Admin. Không xóa việc kiểm tra quyền Admin ở backend.

## Những phần ngoài sáu specs có thể loại khỏi phạm vi demo

- Chat, bạn bè, presence, lời mời, RSVP, rating/review và bản đồ tương tác. Chúng đã có một phần UI mock, nhưng không phải backend phải hoàn thiện theo sáu specs. Không cần xóa UI để giảm việc; có thể ẩn khỏi luồng nghiệm thu.
- Transparency Score, freshness decay, đề xuất thông minh, lịch sử giá và withdrawal có version graph. Giữ ngày/nguồn và tránh ghi đè dữ liệu đã duyệt bằng đóng góp chưa duyệt; không cần triển khai tất cả cơ chế lịch sử tương lai.
- Provider identity lifecycle, privacy-erasure orchestration, backup scheduling/restore drill, RPO/RTO, secret manager, TLS proxy, multi-host storage, metrics/tracing stack, deploy production.
- Redis, message broker, microservices, repository/interface/service nhiều tầng, code generation hoặc sqlc nếu SQL trực tiếp đủ rõ. sqlc/OpenAPI không phải runtime hiện tại; không có module đó để “xóa”. Có thể giữ bảng mô tả API ngắn và test API thay vì hợp đồng/codegen phức tạp.

Chỉ dùng dữ liệu và ảnh mẫu không nhạy cảm cho demo. Giữ kiểm tra owner cho ảnh đóng góp; không công khai ảnh hóa đơn gốc. Không cần một pipeline che thông tin tự động nếu ảnh demo đã được chuẩn bị trước.

## Những thứ không nên cắt

- DB persistence thật cho các tính năng nghiệm thu; không chuyển tất cả thành Riverpod mock.
- Role/ownership, kiểm tra dữ liệu đầu vào, hash mật khẩu nếu có mật khẩu thật.
- Loading/error/empty/unavailable, timeout hữu hạn; request lỗi không khiến app treo.
- Constraint, FK và transaction cho thao tác ghi nhiều bảng.
- Chưa duyệt không public; draft/hidden không hiện trong khám phá.
- Menu price khác receipt total và spending per person; thiếu dữ liệu không bịa số.
- Test luồng chính, lỗi và quyền cơ bản; Compose PostgreSQL test tách biệt và migrations thật.

## Các mâu thuẫn cần thống nhất trước khi sửa specs

1. **Auth:** spec 001 bắt JWT/refresh và email-password; reconciliation §13.9 hướng Google/Apple; backend hiện tại dùng dev fixtures/opaque session. Chọn rõ email-password đơn giản + một session cho local nếu vẫn nghiệm thu đăng ký/login thật.
2. **OCR:** specs/SRS bắt OCR; implementation plan M0–M6 cho phép local core chưa OCR. Mốc local core chỉ là trung gian, không phải hoàn thành toàn bộ SRS.
3. **Chi phí:** spec 003 gợi ý giá trung bình menu; reconciliation §13.2 ưu tiên ví dụ hóa đơn. Chốt UI/công thức để hai khái niệm không lẫn nhau.
4. **Verification:** specs dùng một is_verified; reconciliation tách công bố địa điểm, duyệt nguồn và thời điểm. Không cần schema phức tạp, nhưng vẫn cần trạng thái riêng đúng ý nghĩa.
5. **Ranking:** spec 002 chốt has_price_data DESC/is_verified DESC và yêu cầu index trước; reconciliation chưa chốt Transparency Score. Demo dùng sắp xếp đơn giản, có mô tả; bỏ yêu cầu bắt buộc thuật toán/index cụ thể.
6. **API:** specs dùng /api/v1 và success/data, backend dùng /v1 với payload/error trực tiếp. Chốt một contract thực tế trước khi tích hợp Flutter, không duy trì hai dạng.
7. **Phạm vi triển khai:** workspace đã có API catalog/menu/favorites và Flutter providers gọi API; schema version đã lên 4 trong mã đang thay đổi. Đóng góp hiện báo chưa kết nối backend; chưa tìm thấy API upload/OCR/Admin moderation. README vẫn mô tả snapshot cũ. Không xem sự hiện diện của mã mới là bằng chứng nghiệm thu; ưu tiên nối đủ sáu module trước social.
8. **Nền tảng:** SRS yêu cầu Android/iOS; demo chỉ web hoặc một nền tảng là giảm phạm vi nghiệm thu, không tự coi là hoàn thành NFR-24. Có thể chọn một nền tảng trình diễn trước, giữ cấu hình của các nền tảng khác.

## Thứ tự triển khai và kịch bản chứng minh

1. Chốt phạm vi demo và thống nhất sáu specs với quyết định auth/OCR/cost/API ở trên.
2. Đăng ký/login/logout thật và Admin seed; reuse session gọn hiện tại.
3. Catalog, menu/giá, tìm kiếm/lọc, khoảng cách và chi phí; Flutter đọc API thật.
4. Favorites lưu DB theo tài khoản.
5. Upload và lịch sử đóng góp, draft place, Admin duyệt thủ công như mốc trung gian.
6. OCR thật tối thiểu và lớp kiểm tra tự động; nối vào màn hình sửa/duyệt có sẵn.
7. Chạy kịch bản: đăng ký User → tìm địa điểm → xem giá/khoảng cách/chi phí → lưu → gửi ảnh → đổi Admin → chạy OCR/sửa/duyệt → đổi User → thấy trạng thái và giá mới → restart API → dữ liệu vẫn còn.
8. Chứng minh lỗi: email trùng, login sai, User không gọi API Admin/không xem đóng góp người khác, ảnh sai/quá lớn, OCR timeout, địa điểm thiếu giá/tọa độ, từ chối có lý do, duyệt hai lần không tạo dữ liệu trùng.

Test DB dùng `make integration`: PostgreSQL Docker mới mỗi lần, dọn tự động. DB phát triển giữ volume. Tài liệu này chỉ rà soát nguồn và phạm vi, không phải bằng chứng chạy lại toàn bộ các chức năng chưa triển khai.

## Kết luận theo loại cắt giảm

- Không đổi nghiệp vụ: bỏ JWT/refresh, dịch vụ bản đồ, CDN, worker phân tán, score/recommendation và hạ tầng production; thay bằng cơ chế local đơn giản.
- Đổi tiêu chí cụ thể: một ảnh thay vì 1–5 ảnh, chờ API thay vì optimistic UI, chỉ demo một nền tảng thay vì Android/iOS; phải ghi nhận rõ trong specs.
- Đổi chức năng lõi: bỏ đăng ký, OCR, kiểm duyệt hai lớp, quyền sở hữu hoặc DB persistence. Các phần này không nên bị loại chỉ vì chạy local.

Ưu tiên triển khai tiếp là đóng góp + Admin + OCR tối thiểu, sau khi xác nhận phần tài khoản/catalog/favorites mới hoạt động đúng. Không tự sửa hoặc xóa mã đang thay đổi trong lần nghiên cứu này.
