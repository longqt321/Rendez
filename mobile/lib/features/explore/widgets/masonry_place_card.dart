import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/utils/currency_formatter.dart';
import 'package:rendez/features/place_detail/place_detail_screen.dart';
import 'package:rendez/features/explore/widgets/bouncing_heart_button.dart';

class MasonryPlaceCard extends ConsumerWidget {
  final Place place;
  final double imageHeight;
  const MasonryPlaceCard({
    super.key,
    required this.place,
    this.imageHeight = 155,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coffee =
        place.category.toLowerCase().contains('cà phê') ||
        place.category.toLowerCase().contains('cafe');
    Widget placeholder() => Container(
      height: imageHeight,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          coffee ? Icons.local_cafe_rounded : Icons.storefront_rounded,
          size: 54,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.invalidate(placeDetailProvider(place.id));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (place.coverImageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: place.coverImageUrl,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    placeholder: (_, _) => placeholder(),
                    errorWidget: (_, _, _) => placeholder(),
                  )
                else
                  placeholder(),
                Positioned(
                  right: 6,
                  top: 6,
                  child: BouncingHeartButton(
                    size: 38,
                    useHeartIcon: false,
                    isSaved: ref.watch(bookmarksProvider).contains(place.id),
                    onTap: () => toggleBookmark(context, ref, place.id),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    place.fullMenu.isEmpty
                        ? 'Chưa có bảng giá'
                        : 'Từ ${CurrencyFormatter.format(place.minPrice)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
