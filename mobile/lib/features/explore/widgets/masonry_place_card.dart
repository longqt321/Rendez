import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/place.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../place_detail/place_detail_screen.dart';
import 'bouncing_heart_button.dart';

class MasonryPlaceCard extends ConsumerWidget {
  final Place place;
  final double imageHeight;

  const MasonryPlaceCard({
    super.key,
    required this.place,
    this.imageHeight = 175,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaved = ref.watch(bookmarksProvider).contains(place.id);
    final pastel = place.vibes.isNotEmpty
        ? AppColors.getEditorialPastel(place.vibes.first, isDark: isDark)
        : (
            bg: isDark ? AppColors.darkPeachPastel : AppColors.peachPastel,
            text: isDark
                ? AppColors.darkPeachPastelText
                : AppColors.peachPastelText,
          );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkPaperBorder : AppColors.paperBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF281C10)).withValues(
              alpha: isDark ? 0.25 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF281C10)).withValues(
              alpha: isDark ? 0.1 : 0.02,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(place: place),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editorial / Polaroid Image Stack
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: place.coverImageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: imageHeight,
                      color: AppColors.neutral100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
                      color: AppColors.neutral200,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ),

                  // Top Left Editorial Pastel Vibe Pill
                  if (place.vibes.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pastel.bg.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          place.vibes.first,
                          style: TextStyle(
                            color: pastel.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                  // Top Right Polaroid Tactile Bouncing Heart/Save Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: BouncingHeartButton(
                      isSaved: isSaved,
                      size: 34,
                      onTap: () {
                        ref.read(bookmarksProvider.notifier).toggle(place.id);
                      },
                    ),
                  ),

                  // Bottom Verified Bill Tag (Chic Micro Badge)
                  if (place.isVerified)
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.verified.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3.5),
                            Text(
                              'Bill thật',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Editorial Magazine Typography Body
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place Name
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkNeutral900
                            : AppColors.neutral900,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Distance & Category
                    Text(
                      '${place.distanceKm} km · ${place.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkNeutral600
                            : const Color(0xFF78716C),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Lifestyle Price & Star Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Soft Lifestyle Price Pill (non-accounting aesthetic)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              CurrencyFormatter.formatRange(
                                place.minPrice,
                                place.maxPrice,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : AppColors.primaryText,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Star rating
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 2.5),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkNeutral900
                                    : AppColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
