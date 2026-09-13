import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PriceReportSheet extends StatefulWidget {
  final String placeName;

  const PriceReportSheet({super.key, required this.placeName});

  @override
  State<PriceReportSheet> createState() => _PriceReportSheetState();
}

class _PriceReportSheetState extends State<PriceReportSheet> {
  int _selectedReason = 0;
  final TextEditingController _commentController = TextEditingController();

  final _reasons = [
    'Quán tăng giá so với hóa đơn này',
    'Menu này đã cũ / Quán đã đổi menu mới',
    'Quán đã đóng cửa hoặc chuyển địa chỉ mới',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Báo Cáo Sai Lệch Giá',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Địa điểm: ${widget.placeName}',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),

          const SizedBox(height: 16),

          Column(
            children: List.generate(_reasons.length, (idx) {
              final isSelected = _selectedReason == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReason = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySubtle
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.neutral200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutral400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _reasons[idx],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.neutral800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _commentController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12.5),
            decoration: const InputDecoration(
              hintText:
                  'Mô tả thêm (ví dụ: Ly nước cam tăng từ 35k lên 42k...)',
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cảm ơn bạn! Thông tin báo cáo sai lệch giá đã được ghi nhận.',
                    ),
                    backgroundColor: AppColors.neutral900,
                  ),
                );
              },
              child: const Text(
                'Gửi Báo Cáo Sai Lệch',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
