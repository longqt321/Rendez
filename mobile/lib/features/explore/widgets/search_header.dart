import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    if (!kIsWeb) return _mobileHeader(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!kIsWeb) ...[
            Text('Rendez', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Một nơi hay cho cuộc hẹn tới.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                        'Tất cả thành phố',
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
              border: !kIsWeb
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(28))
                  : null,
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

  Widget _mobileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cities = {
      'Tất cả thành phố',
      ref.watch(selectedCityProvider),
      ...(ref.watch(placesProvider).valueOrNull ?? []).map((p) => p.city),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.textScalerOf(context).scale(14) > 18) ...[
            Text('Rendez', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: ref.watch(selectedCityProvider),
                      items: [
                        for (final city in cities)
                          DropdownMenuItem(
                            value: city,
                            child: Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (city) {
                        if (city != null) {
                          ref.read(selectedCityProvider.notifier).state = city;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text('Rendez', style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: ref.watch(selectedCityProvider),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      items: [
                        for (final city in cities)
                          DropdownMenuItem(
                            value: city,
                            child: Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (city) {
                        if (city != null) {
                          ref.read(selectedCityProvider.notifier).state = city;
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
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
