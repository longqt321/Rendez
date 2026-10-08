import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/widgets/state_message.dart';
import 'package:rendez/features/explore/widgets/search_header.dart';
import 'package:rendez/features/explore/widgets/discovery_filters.dart';
import 'package:rendez/features/explore/widgets/masonry_place_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(placesProvider);
    final places = ref.watch(filteredPlacesProvider);
    final hasFilters =
        ref.watch(selectedCityProvider) != 'Tất cả thành phố' ||
        ref.watch(searchQueryProvider).isNotEmpty ||
        ref.watch(selectedCategoryProvider) != null ||
        ref.watch(selectedBudgetRangeProvider) != 0;
    void reset() {
      ref.read(selectedCityProvider.notifier).state = 'Tất cả thành phố';
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(selectedCategoryProvider.notifier).state = null;
      ref.read(selectedBudgetRangeProvider.notifier).state = 0;
      ref.read(selectedVibeFilterProvider.notifier).state = null;
      ref.read(selectedQuickFilterProvider.notifier).state = 'all';
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 360 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18
                ? 1
                : constraints.maxWidth < 840
                ? 2
                : constraints.maxWidth < 1100
                ? 3
                : 4;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(placesProvider);
                await ref.read(placesProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SearchHeader()),
                  const SliverToBoxAdapter(child: DiscoveryFilters()),
                  if (data.hasValue)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          !kIsWeb
                              ? (hasFilters
                                    ? '${places.length} địa điểm phù hợp'
                                    : 'Khám phá địa điểm')
                              : '${places.length} địa điểm',
                          style: !kIsWeb
                              ? Theme.of(context).textTheme.titleMedium
                              : null,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  data.when(
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => SliverToBoxAdapter(
                      child: StateMessage(
                        icon: Icons.wifi_off_rounded,
                        title: 'Chưa tải được địa điểm',
                        message: 'Không tải được địa điểm.',
                        actionLabel: 'Thử lại',
                        onAction: () => ref.invalidate(placesProvider),
                      ),
                    ),
                    data: (_) => places.isEmpty
                        ? SliverToBoxAdapter(
                            child: StateMessage(
                              icon: Icons.travel_explore_rounded,
                              title: 'Không tìm thấy địa điểm',
                              message: hasFilters
                                  ? 'Thử thay đổi bộ lọc.'
                                  : 'Chưa có địa điểm tại thành phố này.',
                              actionLabel: hasFilters ? 'Bỏ bộ lọc' : null,
                              onAction: hasFilters ? reset : null,
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: columns,
                              mainAxisSpacing: kIsWeb ? 16 : 24,
                              crossAxisSpacing: 12,
                              childCount: places.length,
                              itemBuilder: (_, index) =>
                                  MasonryPlaceCard(place: places[index]),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
