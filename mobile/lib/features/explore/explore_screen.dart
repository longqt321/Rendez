import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../contribute/contribute_screen.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/map_view_widget.dart';
import 'widgets/masonry_place_card.dart';
import 'widgets/search_header.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(filteredPlacesProvider);
    final isMapView = ref.watch(isMapViewProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Search Header
                const SearchHeader(),

                // Horizontal Filters
                const FilterChipsBar(),

                // Content View (Grid or Map)
                Expanded(
                  child: isMapView
                      ? MapViewWidget(places: places)
                      : places.isEmpty
                      ? _buildEmptyState(context, ref)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth <= 0) {
                              return const SizedBox.shrink();
                            }
                            return RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: MasonryGridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  16,
                                ),
                                itemCount: places.isEmpty
                                    ? 0
                                    : places.length * 50,
                                itemBuilder: (context, index) {
                                  final place = places[index % places.length];
                                  final double height = index.isEven
                                      ? 165
                                      : 195;
                                  return MasonryPlaceCard(
                                    place: place,
                                    imageHeight: height,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
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
                Icons.search_off_rounded,
                size: 32,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy địa điểm phù hợp',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử tìm từ khóa khác hoặc xóa bớt tiêu chí lọc vibe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySubtle,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(selectedVibeFilterProvider.notifier).state = null;
                ref.read(selectedQuickFilterProvider.notifier).state = 'all';
              },
              child: const Text(
                'Xóa toàn bộ bộ lọc',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(
                Icons.add_location_alt_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Đóng góp quán này cho Rendez',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContributeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
