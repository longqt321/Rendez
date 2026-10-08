import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/explore/widgets/search_header.dart';
import 'package:rendez/features/explore/widgets/discovery_filters.dart';
import 'package:rendez/features/explore/widgets/map_view_widget.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const SearchHeader(),
          const DiscoveryFilters(),
          const SizedBox(height: 8),
          Expanded(
            child: ref
                .watch(placesProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Không tải được địa điểm.'),
                        TextButton(
                          onPressed: () => ref.invalidate(placesProvider),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                  data: (_) =>
                      MapViewWidget(places: ref.watch(filteredPlacesProvider)),
                ),
          ),
        ],
      ),
    ),
  );
}
