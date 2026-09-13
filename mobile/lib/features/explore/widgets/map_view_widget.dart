import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/place.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../place_detail/place_detail_screen.dart';

class MapViewWidget extends ConsumerStatefulWidget {
  final List<Place> places;

  const MapViewWidget({super.key, required this.places});

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty) {
      return const Center(child: Text('Không có địa điểm nào trên bản đồ'));
    }

    return Stack(
      children: [
        // Stylized Map Background Canvas
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE5E3DF), // Map tone
          child: CustomPaint(painter: _MapGridPainter()),
        ),

        // Map Pins Positioned
        ...List.generate(widget.places.length, (index) {
          final place = widget.places[index];
          final isSelected = index == _selectedIndex;

          // Compute pseudo coordinates on screen
          final double left = 60.0 + (index * 75.0) % 240.0;
          final double top = 100.0 + (index * 95.0) % 360.0;

          return Positioned(
            left: left,
            top: top,
            child: Semantics(
              button: true,
              label:
                  'Chọn quán ${place.name}, giá từ ${CurrencyFormatter.formatCompact(place.minPrice)}',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedIndex = index);
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price tag pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : AppColors.neutral200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (place.isVerified)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 11,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.verified,
                              ),
                            ),
                          Text(
                            CurrencyFormatter.formatCompact(place.minPrice),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pin point
                    Icon(
                      Icons.location_on,
                      size: isSelected ? 26 : 20,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.neutral800,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Top Status Bar Overlay on Map
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${widget.places.length} địa điểm minh bạch giá',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Place Preview Carousel
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.places.length,
            onPageChanged: (idx) => setState(() => _selectedIndex = idx),
            itemBuilder: (ctx, idx) {
              final p = widget.places[idx];
              final isSaved = ref.watch(bookmarksProvider).contains(p.id);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: p),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neutral200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: p.coverImageUrl,
                          width: 100,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.distanceKm} km · ${p.category}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.neutral500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                CurrencyFormatter.formatRange(
                                  p.minPrice,
                                  p.maxPrice,
                                ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bookmark button with accessible target
                      Semantics(
                        button: true,
                        label: isSaved ? 'Bỏ lưu ${p.name}' : 'Lưu ${p.name}',
                        child: IconButton(
                          tooltip: 'Lưu địa điểm',
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved
                                ? AppColors.primary
                                : AppColors.neutral500,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            ref.read(bookmarksProvider.notifier).toggle(p.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFF4F3F0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0xFFA5D8F0)
      ..style = PaintingStyle.fill;

    // Draw stylized river (Han river in Danang)
    final path = Path()
      ..moveTo(size.width * 0.75, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.4,
        size.width * 0.85,
        size.height * 0.7,
        size.width * 0.7,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, waterPaint);

    // Draw road grids
    for (double y = 40; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }
    for (double x = 40; x < size.width; x += 90) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // Main thoroughfare
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.35, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
