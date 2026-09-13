import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/chat_providers.dart';
import '../../chat/chat_list_screen.dart';
import '../../contribute/contribute_screen.dart';
import 'advanced_filter_sheet.dart';

class SearchHeader extends ConsumerWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCity = ref.watch(selectedCityProvider);
    final isMapView = ref.watch(isMapViewProvider);
    final unreadCount = ref.watch(totalUnreadMessagesProvider);

    return Container(
      color: isDark ? AppColors.darkScaffoldBackground : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Top Row: Logo & City Selector + Contribute Action + Chat Button
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rendez',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkNeutral900
                          : AppColors.neutral900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Quick Contribute Button
              Material(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ContributeScreen(),
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_location_alt_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đóng góp',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // City Dropdown Pill (Flexible to avoid overflow on narrow screens)
              Flexible(
                child: Material(
                  color: isDark
                      ? AppColors.darkNeutral100
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showCityPicker(context, ref, currentCity);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkPaperBorder
                              : AppColors.neutral200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              currentCity,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkNeutral800
                                    : AppColors.neutral800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: isDark
                                ? AppColors.darkNeutral500
                                : AppColors.neutral600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // In-App Chat Button with Unread Badge
              Semantics(
                button: true,
                label: 'Hộp thư Rendez ($unreadCount tin chưa đọc)',
                child: Material(
                  color: isDark
                      ? AppColors.darkNeutral100
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChatListScreen(),
                        ),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 38,
                        minWidth: 38,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkPaperBorder
                              : AppColors.neutral200,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                            color: isDark
                                ? AppColors.darkNeutral800
                                : AppColors.neutral800,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search Bar + Filter Button + View Mode Toggle
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) =>
                      ref.read(searchQueryProvider.notifier).state = val,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm chỗ hẹn hò, view sông, cafe...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.neutral400,
                    ),
                    suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 16,
                              color: AppColors.neutral400,
                            ),
                            onPressed: () =>
                                ref.read(searchQueryProvider.notifier).state =
                                    '',
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Action Button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkNeutral100
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkPaperBorder
                        : AppColors.neutral200,
                  ),
                ),
                child: IconButton(
                  tooltip: 'Bộ lọc nâng cao',
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.darkNeutral800
                        : AppColors.neutral800,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AdvancedFilterSheet(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // View Toggle: Map vs Grid
              Semantics(
                button: true,
                label: isMapView ? 'Chuyển xem danh sách' : 'Chuyển xem bản đồ',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isMapView
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkNeutral100
                              : AppColors.neutral100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMapView
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkPaperBorder
                                : AppColors.neutral200),
                    ),
                  ),
                  child: IconButton(
                    tooltip: isMapView ? 'Xem danh sách' : 'Xem bản đồ',
                    icon: Icon(
                      isMapView ? Icons.grid_view_rounded : Icons.map_outlined,
                      size: 18,
                      color: isMapView
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkNeutral800
                                : AppColors.neutral800),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(isMapViewProvider.notifier).state = !isMapView;
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCityPicker(
    BuildContext context,
    WidgetRef ref,
    String currentCity,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cities = ['Đà Nẵng & Hội An', 'TP. Hồ Chí Minh', 'Hà Nội'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn Thành Phố',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...cities.map(
                  (c) => ListTile(
                    title: Text(
                      c,
                      style: TextStyle(
                        fontWeight: c == currentCity
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: c == currentCity
                            ? AppColors.primary
                            : AppColors.neutral900,
                      ),
                    ),
                    trailing: c == currentCity
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      ref.read(selectedCityProvider.notifier).state = c;
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
