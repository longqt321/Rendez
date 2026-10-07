import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/widgets/state_message.dart';
import 'package:rendez/features/explore/widgets/search_header.dart';
import 'package:rendez/features/explore/widgets/masonry_place_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(placesProvider);
    final places = ref.watch(filteredPlacesProvider);
    final hasFilters =
        ref.watch(searchQueryProvider).isNotEmpty ||
        ref.watch(selectedCategoryProvider) != null ||
        ref.watch(selectedBudgetRangeProvider) != 0;
    void reset() {
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
            final columns = constraints.maxWidth < 380
                ? 1
                : constraints.maxWidth < 700
                ? 2
                : 3;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(placesProvider);
                await ref.read(placesProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SearchHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _FilterPill(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              value: ref.watch(selectedCategoryProvider),
                              hint: const Text(
                                'Loại hình',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'Loại hình',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                for (final category in {
                                  ?ref.watch(selectedCategoryProvider),
                                  ...(data.valueOrNull ?? []).map(
                                    (p) => p.category,
                                  ),
                                })
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) =>
                                  ref
                                          .read(
                                            selectedCategoryProvider.notifier,
                                          )
                                          .state =
                                      v,
                            ),
                          ),
                          _FilterPill(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              value: ref.watch(selectedBudgetRangeProvider),
                              items: const [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text(
                                    'Mức giá',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text(
                                    'Dưới 50k',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text(
                                    '50k–100k',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text(
                                    '100k–200k',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text(
                                    'Từ 200k',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  ref
                                          .read(
                                            selectedBudgetRangeProvider
                                                .notifier,
                                          )
                                          .state =
                                      v!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.hasValue
                                  ? '${places.length} địa điểm dành cho bạn'
                                  : 'Khám phá địa điểm',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (hasFilters)
                            TextButton(
                              onPressed: reset,
                              child: const Text('Bỏ bộ lọc'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  data.when(
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => SliverToBoxAdapter(
                      child: StateMessage(
                        icon: Icons.wifi_off_rounded,
                        title: 'Chưa tải được địa điểm',
                        message: '$error',
                        actionLabel: 'Thử lại',
                        onAction: () => ref.invalidate(placesProvider),
                      ),
                    ),
                    data: (_) => places.isEmpty
                        ? SliverToBoxAdapter(
                            child: StateMessage(
                              icon: Icons.travel_explore_rounded,
                              title: 'Chưa tìm thấy chỗ hợp ý',
                              message: hasFilters
                                  ? 'Thử tên khác hoặc bỏ bộ lọc để khám phá thêm.'
                                  : 'Chưa có địa điểm tại thành phố này. Hãy chọn thành phố khác.',
                              actionLabel: hasFilters ? 'Bỏ bộ lọc' : null,
                              onAction: hasFilters ? reset : null,
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: columns,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 14,
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

class _FilterPill extends StatelessWidget {
  final Widget child;
  const _FilterPill({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: ((MediaQuery.sizeOf(context).width - 50) / 2).clamp(0, 240),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}
