import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../place_detail/place_detail_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarksProvider);
    final savedPlaces = MockData.places
        .where((p) => bookmarkedIds.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Đã Lưu (${savedPlaces.length})'),
        centerTitle: false,
      ),
      body: savedPlaces.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        size: 32,
                        color: AppColors.neutral400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có địa điểm đã lưu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chạm vào biểu tượng bookmark ở góc thẻ quán để lưu lại khi đi hẹn hò hoặc tụ tập bạn bè.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedPlaces.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final place = savedPlaces[index];

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailScreen(place: place),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.neutral200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Cover photo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: place.coverImageUrl,
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${place.distanceKm} km · ${place.category}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    CurrencyFormatter.formatRange(
                                      place.minPrice,
                                      place.maxPrice,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Remove Bookmark action with Undo
                          Semantics(
                            button: true,
                            label: 'Bỏ lưu ${place.name}',
                            child: IconButton(
                              tooltip: 'Bỏ lưu địa điểm',
                              icon: const Icon(
                                Icons.bookmark_rounded,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                ref
                                    .read(bookmarksProvider.notifier)
                                    .toggle(place.id);

                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã bỏ lưu "${place.name}"'),
                                    duration: const Duration(seconds: 4),
                                    backgroundColor: AppColors.neutral900,
                                    action: SnackBarAction(
                                      label: 'HOÀN TÁC',
                                      textColor: AppColors.primary,
                                      onPressed: () {
                                        ref
                                            .read(bookmarksProvider.notifier)
                                            .toggle(place.id);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
