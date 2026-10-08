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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              labelText: 'Tìm địa điểm hoặc món ăn',
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
