import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AddPlaceDialog extends StatefulWidget {
  final Function(String name, String address) onPlaceAdded;

  const AddPlaceDialog({super.key, required this.onPlaceAdded});

  @override
  State<AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<AddPlaceDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'Quán Cà phê';

  final _categories = [
    'Quán Cà phê',
    'Quán Ăn / Nhà hàng',
    'Quán Nhậu / Nướng BBQ',
    'Pub / Bar nhẹ',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đề Xuất Quán Mới',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quán của bạn chưa có trên hệ thống? Nhập thông tin bên dưới để đề xuất thêm quán:',
              style: TextStyle(fontSize: 11.5, color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),

            // Place name
            const Text(
              'Tên quán:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: An Cà Phê Mộc',
              ),
            ),
            const SizedBox(height: 12),

            // Address
            const Text(
              'Địa chỉ:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Số nhà, tên đường, quận...',
              ),
            ),
            const SizedBox(height: 12),

            // Category
            const Text(
              'Mô hình quán:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat, style: const TextStyle(fontSize: 12.5)),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => _selectedCategory = val ?? _categories.first),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.neutral300),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: AppColors.neutral700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final addr = _addressController.text.trim();
                      if (name.isNotEmpty && addr.isNotEmpty) {
                        widget.onPlaceAdded(name, addr);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
