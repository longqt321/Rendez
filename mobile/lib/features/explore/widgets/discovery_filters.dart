import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';

class DiscoveryFilters extends ConsumerWidget {
  const DiscoveryFilters({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(placesProvider);
    final hasFilters =
        ref.watch(selectedCityProvider) != 'Tất cả thành phố' ||
        ref.watch(searchQueryProvider).isNotEmpty ||
        ref.watch(selectedCategoryProvider) != null ||
        ref.watch(selectedBudgetRangeProvider) != 0;
    if (!kIsWeb) return _mobileFilters(context, ref);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  ...(data.valueOrNull ?? []).map((p) => p.category),
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
                  ref.read(selectedCategoryProvider.notifier).state = v,
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
                    'Đơn giá',
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
                  ref.read(selectedBudgetRangeProvider.notifier).state = v!,
            ),
          ),
          if (hasFilters)
            TextButton(
              onPressed: () {
                ref.read(selectedCityProvider.notifier).state =
                    'Tất cả thành phố';
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(selectedCategoryProvider.notifier).state = null;
                ref.read(selectedBudgetRangeProvider.notifier).state = 0;
              },
              child: const Text('Bỏ bộ lọc'),
            ),
        ],
      ),
    );
  }

  Widget _mobileFilters(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final selected = ref.watch(selectedCategoryProvider);
    final active =
        selected != null ||
        ref.watch(selectedBudgetRangeProvider) != 0 ||
        ref.watch(selectedCityProvider) != 'Tất cả thành phố' ||
        ref.watch(searchQueryProvider).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final category in <String?>[
                null,
                ...{...places.map((p) => p.category)},
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    showCheckmark: false,
                    label: Text(category ?? 'Tất cả'),
                    selected: selected == category,
                    onSelected: (_) =>
                        ref.read(selectedCategoryProvider.notifier).state =
                            category,
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  ref.watch(selectedBudgetRangeProvider) == 0
                      ? 'Giá món'
                      : 'Đã lọc giá',
                ),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (sheetContext) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giá mỗi món',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hiển thị địa điểm có món trong khoảng giá bạn chọn.',
                          ),
                          const SizedBox(height: 12),
                          for (final entry in const {
                            0: 'Tất cả mức giá',
                            1: 'Dưới 50.000đ',
                            2: '50.000–100.000đ',
                            3: '100.000–200.000đ',
                            4: 'Từ 200.000đ',
                          }.entries)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.value),
                              trailing:
                                  ref.read(selectedBudgetRangeProvider) ==
                                      entry.key
                                  ? const Icon(Icons.check_circle_rounded)
                                  : null,
                              onTap: () {
                                ref
                                    .read(selectedBudgetRangeProvider.notifier)
                                    .state = entry
                                    .key;
                                Navigator.pop(sheetContext);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (active)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () {
                ref.read(selectedCityProvider.notifier).state =
                    'Tất cả thành phố';
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(selectedCategoryProvider.notifier).state = null;
                ref.read(selectedBudgetRangeProvider.notifier).state = 0;
              },
              child: const Text('Bỏ bộ lọc'),
            ),
          ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final Widget child;
  const _FilterPill({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.textScalerOf(context).scale(14) > 18
        ? (MediaQuery.sizeOf(context).width - 32).clamp(0, 400)
        : ((MediaQuery.sizeOf(context).width - 44) / 2).clamp(0, 240),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}
