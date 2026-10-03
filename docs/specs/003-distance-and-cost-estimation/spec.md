# Feature Specification: Module 3 - Distance & Cost Estimation

**Feature Branch**: `feature/003-distance-and-cost-estimation`  
**Created**: 2026-09-12  
**Status**: Draft  
**SRS Reference**: FR-08, FR-09, NFR-08, NFR-09, NFR-10  

---

## 🎯 1. Overview & Purpose

Module 3 cung cấp hai công cụ tính toán hỗ trợ ra quyết định cho Người dùng trước khi khởi hành: **Tính toán khoảng cách dự kiến** từ vị trí hiện tại của Người dùng (hoặc vị trí tự chọn) đến địa điểm, và **Ước tính tổng chi phí dự kiến** dựa trên dữ liệu giá menu đã được lưu trữ.

---

## 👥 2. User Stories & Acceptance Criteria

### User Story 1 - Hiển thị & Tính toán Khoảng cách dự kiến (FR-08, NFR-09)
* **Là một**: Người dùng ứng dụng Rendez.
* **Tôi muốn**: Xem khoảng cách ước tính từ vị trí của tôi đến địa điểm đang chọn.
* **Để**: Biết địa điểm đó xa hay gần và đưa ra quyết định di chuyển.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Location Permission**: Tiếp nhận tọa độ vị trí hiện tại từ thiết bị (GPS). Nếu người dùng từ chối cấp quyền vị trí, hiển thị ô cho phép chọn vị trí thủ công hoặc báo trạng thái không khả dụng (`NFR-11`).
2. **Haversine / Map API Calculation**: Backend hoặc Mobile Client tính toán khoảng cách theo đường chim bay (Haversine) hoặc qua Map API.
3. **Display Format**: Hiển thị định dạng thân thiện (`1.2 km`, `800 m`).
4. **Disclaimer Notice (NFR-09)**: Ghi rõ nhãn *"Khoảng cách dự kiến"* để tránh người dùng hiểu nhầm đây là tuyến đường di chuyển thực tế.

---

### User Story 2 - Ước tính Chi phí tham khảo (FR-09, NFR-08, NFR-10)
* **Là một**: Người dùng chuẩn bị đi ăn/chơi cùng bạn bè.
* **Tôi muốn**: Xem mức chi phí dự kiến trung bình cho 1 người (hoặc nhóm người) tại địa điểm.
* **Để**: Dự trù ngân sách xem địa điểm có hợp túi tiền hay không.

#### Tiêu chí chấp nhận (Acceptance Criteria):
1. **Cost Calculation**: Tính toán mức giá trung bình/khoảng giá phổ biến dựa trên menu của địa điểm (Ví dụ: `Trung bình ~45.000 VNĐ / người`).
2. **Missing Price Handling**: Nếu địa điểm chưa có dữ liệu giá, hiển thị nhãn *"Chưa có dữ liệu tính chi phí"* (`NFR-10`).
3. **Disclaimer**: Trình bày rõ giá trị chỉ mang tính chất tham khảo (`NFR-08`).

---

## 📐 3. Data Schema Dependencies

Module 3 không tạo bảng mới. Các tính toán phụ thuộc hoàn toàn vào dữ liệu từ Module 2:

| Tính toán | Bảng phụ thuộc | Cột sử dụng | Điều kiện |
| :--- | :--- | :--- | :--- |
| Khoảng cách dự kiến | `Places` | `latitude`, `longitude` | Cả hai cột phải `NOT NULL` |
| Chi phí ước tính | `MenuItems` (qua `Menus.place_id`) | `price`, `is_available` | Chỉ tính các món `is_available = true` |

---

## 🔌 4. API Endpoints Specification

### 1. `GET /api/v1/places/:id/distance`
- **Query Params**: `user_lat`, `user_lng`
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "place_id": "plc_123",
      "distance_meters": 1450,
      "distance_formatted": "1.5 km",
      "disclaimer": "Khoảng cách dự kiến theo đường chim bay."
    }
  }
  ```

### 2. `GET /api/v1/places/:id/estimated-cost`
- **Query Params**: `party_size` (Mặc định: 1)
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "place_id": "plc_123",
      "party_size": 2,
      "min_estimated_cost": 70000,
      "max_estimated_cost": 130000,
      "formatted": "70.000 - 130.000 VNĐ (cho 2 người)",
      "disclaimer": "Chi phí mang tính chất tham khảo tại thời điểm cập nhật."
    }
  }
  ```

---

## 🧪 5. Edge Cases & Error Handling

| Scenario | HTTP Status | Error Code | Message Displayed |
| :--- | :--- | :--- | :--- |
| Địa điểm không tồn tại | `404 Not Found` | `PLACE_NOT_FOUND` | "Không tìm thấy địa điểm." |
| Địa điểm thiếu tọa độ (`latitude`/`longitude` = NULL) | `200 OK` | N/A | `distance_formatted: "Không khả dụng — địa điểm chưa có tọa độ."` |
| Thiếu `user_lat` hoặc `user_lng` trong query | `422 Unprocessable Entity` | `MISSING_LOCATION` | "Vui lòng cung cấp tọa độ vị trí của bạn." |
| `user_lat`/`user_lng` nằm ngoài phạm vi hợp lệ | `422 Unprocessable Entity` | `INVALID_COORDINATES` | "Tọa độ không hợp lệ." |
| Địa điểm chưa có dữ liệu giá (không thể tính chi phí) | `200 OK` | N/A | `formatted: "Chưa có dữ liệu tính chi phí."` (`NFR-10`) |
| `party_size` ≤ 0 hoặc không phải số nguyên | `422 Unprocessable Entity` | `INVALID_PARTY_SIZE` | "Số người phải là số nguyên dương." |
| Người dùng từ chối cấp quyền GPS | N/A (Client) | `LOCATION_DENIED` | Hiển thị ô nhập vị trí thủ công hoặc ẩn mục khoảng cách. |


