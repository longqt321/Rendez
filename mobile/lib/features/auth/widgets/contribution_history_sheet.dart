import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';

class ContributionHistorySheet extends ConsumerWidget {
  const ContributionHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(contributionsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
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
                'Lịch Sử Đóng Góp Hóa Đơn',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              itemCount: contributions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = contributions[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c.placeName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                          _buildStatusBadge(c.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.neutral500,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              c.placeAddress,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(c.date),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.neutral400,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(c.totalAmount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                      if (c.rejectionReason != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.destructiveLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lý do từ chối: ${c.rejectionReason}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.destructive,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.verifiedLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 12,
                color: AppColors.verified,
              ),
              SizedBox(width: 3),
              Text(
                'Đã duyệt',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.verified,
                ),
              ),
            ],
          ),
        );
      case ContributionStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: AppColors.primaryText,
              ),
              SizedBox(width: 3),
              Text(
                'Chờ duyệt',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        );
      case ContributionStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.destructiveLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cancel_rounded,
                size: 12,
                color: AppColors.destructive,
              ),
              SizedBox(width: 3),
              Text(
                'Từ chối',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        );
    }
  }
}
