import 'bill_item.dart';

class MenuItem {
  final String name;
  final int price;
  final String category;

  const MenuItem({
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

  const Place({
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

  RealBill? get latestBill => bills.isNotEmpty ? bills.first : null;
}
