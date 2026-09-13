import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';

class AdvancedFilterSheet extends ConsumerStatefulWidget {
  const AdvancedFilterSheet({super.key});

  @override
  ConsumerState<AdvancedFilterSheet> createState() =>
      _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
  late int _selectedBudgetIndex;
  late Set<String> _selectedFacilities;

  final _budgetRanges = [
    'Tất cả',
    '< 50.000đ',
    '50k - 100k',
    '100k - 200k',
    '> 200k',
  ];
  final _facilities = [
    'Máy lạnh',
    'Wifi mạnh chạy deadline',
    'Bãi giữ xe rộng / Free',
    'Không gian sân vườn ngoài trời',
    'Thanh toán thẻ / Chuyển khoản',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBudgetIndex = ref.read(selectedBudgetRangeProvider);
    _selectedFacilities = Set.from(ref.read(selectedFacilitiesProvider));
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
          // Drag handle
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ Lọc Nâng Cao',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedBudgetIndex = 0;
                    _selectedFacilities.clear();
                  });
                },
                child: const Text(
                  'Đặt lại',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Budget Filter
          const Text(
            'Ngân Sách Dự Kiến / Người',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_budgetRanges.length, (idx) {
              final isSelected = _selectedBudgetIndex == idx;
              return Semantics(
                button: true,
                selected: isSelected,
                label: 'Mức ngân sách ${_budgetRanges[idx]}',
                child: Material(
                  color: isSelected
                      ? AppColors.primarySubtle
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBudgetIndex = idx);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _budgetRanges[idx],
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryText
                              : AppColors.neutral700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Facilities Filter
          const Text(
            'Tiện Ích & Không Gian',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: _facilities.map((fac) {
              final isChecked = _selectedFacilities.contains(fac);
              return CheckboxListTile(
                value: isChecked,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.primary,
                title: Text(
                  fac,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral800,
                  ),
                ),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (val == true) {
                      _selectedFacilities.add(fac);
                    } else {
                      _selectedFacilities.remove(fac);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(selectedBudgetRangeProvider.notifier).state =
                    _selectedBudgetIndex;
                ref.read(selectedFacilitiesProvider.notifier).state = Set.from(
                  _selectedFacilities,
                );
                Navigator.pop(context);
              },
              child: const Text(
                'Áp Dụng Bộ Lọc',
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
