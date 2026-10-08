import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';

class SearchHeader extends ConsumerStatefulWidget {
  const SearchHeader({super.key});
  @override
  ConsumerState<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends ConsumerState<SearchHeader> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(searchQueryProvider, (_, value) {
      if (_search.text != value) _search.text = value;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rendez',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Tooltip(
                message: 'Giá tham khảo có nguồn đóng góp',
                child: Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: ref.watch(selectedCityProvider),
                    items: [
                      for (final city in {
                        ref.watch(selectedCityProvider),
                        ...(ref.watch(placesProvider).valueOrNull ?? []).map(
                          (p) => p.city,
                        ),
                      })
                        DropdownMenuItem(
                          value: city,
                          child: Text(city, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(selectedCityProvider.notifier).state = v;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm quán, món ăn, địa chỉ…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: ref.watch(searchQueryProvider).isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          ref.read(searchQueryProvider.notifier).state = '',
                    ),
            ),
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).state = value,
          ),
        ],
      ),
    );
  }
}
