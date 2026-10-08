import 'package:rendez/core/models/bill_item.dart';

class MenuItem {
  final String id;
  final String name;
  final int price;
  final String category;
  final DateTime? observedAt, reviewedAt;

  const MenuItem({
    this.id = '',
    this.observedAt,
    this.reviewedAt,
    required this.name,
    required this.price,
    required this.category,
  });
}

class Place {
  final String id;
  final String name;
  final String category; // 'Cafe', 'Ramen', 'Nhà hàng', 'Pub'
  final List<String>
  vibes; // ['Hẹn hò', 'Tụ tập nhóm', 'Chạy deadline', 'Mở 24/7']
  final String address;
  final String city; // 'Đà Nẵng & Hội An', 'TP. Hồ Chí Minh', 'Hà Nội'
  final double distanceKm;
  final double rating;
  final int reviewsCount;
  final String coverImageUrl;
  final List<String> galleryImages;
  final int minPrice;
  final int maxPrice;
  final bool isVerified;
  final String openHours;
  final double latitude;
  final double longitude;
  final List<RealBill> bills;
  final List<MenuItem> fullMenu;
  final String description;
  final DateTime? priceUpdatedAt;
  final List<Map<String, dynamic>> billExamples;

  const Place({
    this.description = '',
    this.priceUpdatedAt,
    this.billExamples = const [],
    required this.id,
    required this.name,
    required this.category,
    required this.vibes,
    required this.address,
    required this.city,
    required this.distanceKm,
    required this.rating,
    required this.reviewsCount,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.minPrice,
    required this.maxPrice,
    required this.isVerified,
    required this.openHours,
    required this.latitude,
    required this.longitude,
    required this.bills,
    required this.fullMenu,
  });

  factory Place.fromJson(Map<String, dynamic> data) {
    return Place(
      id: data['id'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      category: data['category'] as String,
      city: data['city'] as String,
      vibes: List<String>.from(data['vibes'] as List),
      coverImageUrl: data['cover_image_url'] as String,
      galleryImages: List<String>.from(data['menu_images'] ?? []),
      description: data['description'] as String? ?? '',
      priceUpdatedAt: DateTime.tryParse(
        data['price_updated_at'] as String? ?? '',
      ),
      billExamples: (data['bill_examples'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      openHours: data['opening_hours'] as String,
      latitude: (data['latitude'] as num?)?.toDouble() ?? double.nan,
      longitude: (data['longitude'] as num?)?.toDouble() ?? double.nan,
      distanceKm: double.nan,
      rating: double.nan,
      reviewsCount: 0,
      isVerified: data['is_verified'] as bool? ?? false,
      minPrice: (data['min_price'] as num).toInt(),
      maxPrice: (data['max_price'] as num).toInt(),
      bills: const [],
      fullMenu: (data['full_menu'] as List)
          .map(
            (item) => MenuItem(
              id: item['id'] as String? ?? '',
              name: item['name'] as String,
              category: item['category'] as String,
              price: (item['price'] as num).toInt(),
              observedAt: DateTime.tryParse(
                item['observed_at'] as String? ?? '',
              ),
              reviewedAt: DateTime.tryParse(
                item['reviewed_at'] as String? ?? '',
              ),
            ),
          )
          .toList(),
    );
  }

  RealBill? get latestBill => bills.isNotEmpty ? bills.first : null;
}
