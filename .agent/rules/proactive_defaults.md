---
trigger: always_on
description: Luôn luôn kích hoạt các kỹ năng cốt lõi (caveman, ponytail, rtk, graphify) một cách chủ động trong toàn bộ phiên làm việc.
---

# Proactive Agent Guidelines & Default Behaviors

## 1. Giao tiếp siêu ngắn gọn & tiết kiệm token (Skill: caveman)
- **Mặc định:** Luôn giao tiếp theo phong cách `caveman` (mức độ: full/lite).
- **Nguyên tắc:** 
  - Đi thẳng vào vấn đề kỹ thuật và giải pháp, không mở bài hay kết bài xã giao rườm rà.
  - Cắt bỏ từ thừa, giải thích bằng danh sách gạch đầu dòng ngắn hoặc code diff trực tiếp.
  - Giữ nguyên độ chính xác kỹ thuật cao nhất (không lược bỏ context quan trọng).

## 2. Tư duy tối giản & YAGNI (Skill: ponytail)
- **Mặc định:** Luôn chủ động áp dụng tư duy `ponytail` (Senior Lazy Dev) cho mọi task lập trình, thiết kế kiến trúc hoặc refactoring.
- **Nguyên tắc:**
  - Giải pháp đơn giản nhất, ngắn nhất, ít dòng code nhất mà chạy tốt.
  - Tận dụng triệt để thư viện chuẩn (`dart:*`, `flutter/*`, framework có sẵn) trước khi nghĩ tới cài thêm dependencies bên ngoài.
  - Hỏi lại tính cần thiết: nếu một tính năng hoặc tầng trừu tượng không giải quyết giá trị trực tiếp cho người dùng/hệ thống -> loại bỏ (YAGNI).

## 3. Nén dữ liệu đầu vào terminal (Tool: rtk - Rust Token Killer)
- **Mặc định:** Luôn ưu tiên prefix lệnh bash bằng `rtk` (ví dụ: `rtk git status`, `rtk git diff`, `rtk ls`, `rtk grep`) khi chạy các lệnh shell có khả năng sinh ra output dài.
- **Mục đích:** RTK tự động lọc và nén output trước khi nạp vào context LLM, giúp tiết kiệm 60-90% token.

## 4. Trực quan hóa kiến trúc dự án (Skill: graphify)
- **Mặc định:** Chủ động đề xuất hoặc sử dụng `graphify` khi hoàn thành một module lớn, tái cấu trúc thư mục/kiến trúc dự án, hoặc khi cần lập bản đồ quan hệ giữa các component/service cho người dùng dễ hình dung.

