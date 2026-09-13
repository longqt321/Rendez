import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/place.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../explore/widgets/bouncing_heart_button.dart';
import 'widgets/bill_breakdown_card.dart';
import 'widgets/menu_tab_view.dart';
import 'widgets/plan_invite_sheet.dart';
import 'widgets/price_report_sheet.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  int _selectedTab = 0; // 0 = Real Bill, 1 = Full Menu
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final isSaved = ref.watch(bookmarksProvider).contains(place.id);
    final allImages = [place.coverImageUrl, ...place.galleryImages];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.neutral900,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: BouncingHeartButton(
                  isSaved: isSaved,
                  size: 38,
                  onTap: () =>
                      ref.read(bookmarksProvider.notifier).toggle(place.id),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: allImages.length,
                    onPageChanged: (idx) =>
                        setState(() => _currentImageIndex = idx),
                    itemBuilder: (_, idx) => CachedNetworkImage(
                      imageUrl: allImages[idx],
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Image dots indicator
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${allImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (place.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: AppColors.verified,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hóa đơn đã kiểm duyệt',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.verified,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...place.vibes.map((v) {
                        final pastel = AppColors.getEditorialPastel(v);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pastel.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            v,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pastel.text,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.neutral900,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Address & Hours
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.neutral400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: AppColors.neutral400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Mở cửa: ${place.openHours}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price Highlight Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Khoảng chi phí theo hóa đơn:',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.neutral500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatRange(
                                  place.minPrice,
                                  place.maxPrice,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.neutral200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(
                            Icons.flag_outlined,
                            size: 14,
                            color: AppColors.destructive,
                          ),
                          label: const Text(
                            'Báo giá lệch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.destructive,
                            ),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  PriceReportSheet(placeName: place.name),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons: Lên Kèo Rủ Bạn & Chỉ Đường
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text(
                              'Lên Kèo Rủ Bạn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => PlanInviteSheet(place: place),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neutral900,
                              side: const BorderSide(
                                color: AppColors.neutral300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.directions_rounded,
                              size: 16,
                              color: AppColors.neutral800,
                            ),
                            label: const Text(
                              'Chỉ Đường',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đang mở chỉ đường tới: ${place.name}',
                                  ),
                                  backgroundColor: AppColors.neutral900,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tab switcher: Hóa đơn thực tế vs Thực đơn đầy đủ
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: _selectedTab == 0,
                            label: 'Tab Hóa đơn đối soát',
                            child: Material(
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              elevation: _selectedTab == 0 ? 1 : 0,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTab = 0);
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 15,
                                        color: _selectedTab == 0
                                            ? AppColors.primary
                                            : AppColors.neutral500,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Hóa Đơn (${place.bills.length})',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: _selectedTab == 0
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: _selectedTab == 0
                                                ? AppColors.neutral900
                                                : AppColors.neutral500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: _selectedTab == 1,
                            label: 'Tab Thực đơn đầy đủ',
                            child: Material(
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              elevation: _selectedTab == 1 ? 1 : 0,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTab = 1);
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 15,
                                        color: _selectedTab == 1
                                            ? AppColors.primary
                                            : AppColors.neutral500,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Toàn Bộ Menu (${place.fullMenu.length})',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: _selectedTab == 1
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: _selectedTab == 1
                                                ? AppColors.neutral900
                                                : AppColors.neutral500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab Content
                  if (_selectedTab == 0) ...[
                    if (place.latestBill != null)
                      BillBreakdownCard(bill: place.latestBill!)
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Chưa có hóa đơn nào được tải lên cho quán này.',
                          ),
                        ),
                      ),
                  ] else ...[
                    MenuTabView(menu: place.fullMenu),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
