import '../models/bill_item.dart';
import '../models/place.dart';
import '../models/user.dart';

class MockData {
  MockData._();

  static final List<Place> places = [
    Place(
      id: 'place_1',
      name: 'The Hideout Roastery',
      category: 'Cafe Specialty',
      vibes: ['Hẹn hò', 'Chạy deadline'],
      address: '72/24 Nguyễn Thị Minh Khai, Hải Châu, Đà Nẵng',
      city: 'Đà Nẵng & Hội An',
      distanceKm: 0.8,
      rating: 4.8,
      reviewsCount: 142,
      coverImageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&auto=format&fit=crop&q=80',
      ],
      minPrice: 38000,
      maxPrice: 68000,
      isVerified: true,
      openHours: '07:00 - 22:30',
      latitude: 16.0678,
      longitude: 108.2167,
      bills: [
        RealBill(
          id: 'bill_1',
          billPhotoUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
          date: DateTime.now().subtract(const Duration(days: 2)),
          contributorName: 'Lê Minh Khang',
          guestsCount: 2,
          items: const [
            BillItem(name: 'Cold Brew Cam Sả', price: 55000, quantity: 1),
            BillItem(name: 'Latte Hạnh Nhân Nóng', price: 48000, quantity: 1),
            BillItem(name: 'Bánh Croissant Bơ Pháp', price: 35000, quantity: 1),
          ],
          totalAmount: 138000,
        ),
      ],
      fullMenu: const [
        MenuItem(name: 'Espresso Đậm Đà', price: 35000, category: 'Cà phê'),
        MenuItem(name: 'Americano Đá', price: 38000, category: 'Cà phê'),
        MenuItem(name: 'Latte Hạnh Nhân', price: 48000, category: 'Cà phê'),
        MenuItem(name: 'Cold Brew Cam Sả', price: 55000, category: 'Đặc biệt'),
        MenuItem(name: 'Trà Đào Cam Sả', price: 45000, category: 'Trà hoa quả'),
        MenuItem(
          name: 'Croissant Bơ Pháp',
          price: 35000,
          category: 'Bánh ngọt',
        ),
      ],
    ),
    Place(
      id: 'place_2',
      name: 'Kyoto Ramen 1994',
      category: 'Ramen Nhật Bản',
      vibes: ['Hẹn hò', 'Tụ tập nhóm'],
      address: '124 Bạch Đằng, Hải Châu, Đà Nẵng',
      city: 'Đà Nẵng & Hội An',
      distanceKm: 1.2,
      rating: 4.9,
      reviewsCount: 260,
      coverImageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1552611052-33e04de081de?w=800&auto=format&fit=crop&q=80',
      ],
      minPrice: 85000,
      maxPrice: 150000,
      isVerified: true,
      openHours: '10:30 - 22:00',
      latitude: 16.0715,
      longitude: 108.2238,
      bills: [
        RealBill(
          id: 'bill_2',
          billPhotoUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
          date: DateTime.now().subtract(const Duration(days: 1)),
          contributorName: 'Trần Đức Long',
          guestsCount: 2,
          items: const [
            BillItem(
              name: 'Tonkotsu Ramen Đặc Biệt',
              price: 110000,
              quantity: 1,
            ),
            BillItem(name: 'Shoyu Ramen Cay Cấp 2', price: 105000, quantity: 1),
            BillItem(
              name: 'Gyoza Chiên Giòn (5 cái)',
              price: 55000,
              quantity: 1,
            ),
            BillItem(
              name: 'Trà Xanh Oolong Lạnh (x2)',
              price: 60000,
              quantity: 1,
            ),
          ],
          totalAmount: 330000,
        ),
      ],
      fullMenu: const [
        MenuItem(
          name: 'Tonkotsu Ramen Đặc Biệt',
          price: 110000,
          category: 'Mì Ramen',
        ),
        MenuItem(
          name: 'Shoyu Ramen Cay Cấp 2',
          price: 105000,
          category: 'Mì Ramen',
        ),
        MenuItem(
          name: 'Miso Ramen Thịt Heo',
          price: 95000,
          category: 'Mì Ramen',
        ),
        MenuItem(
          name: 'Gyoza Chiên Giòn (5 cái)',
          price: 55000,
          category: 'Món ăn kèm',
        ),
        MenuItem(name: 'Trà Xanh Oolong', price: 30000, category: 'Đồ uống'),
      ],
    ),
    Place(
      id: 'place_3',
      name: 'Trình Cà Phê - Vườn Nhà Cũ',
      category: 'Cafe Vintage & Sân Vườn',
      vibes: ['Hẹn hò', 'Tụ tập nhóm', 'Mở 24/7'],
      address: '22/4 Lê Đình Dương, Hải Châu, Đà Nẵng',
      city: 'Đà Nẵng & Hội An',
      distanceKm: 0.5,
      rating: 4.7,
      reviewsCount: 310,
      coverImageUrl: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=800&auto=format&fit=crop&q=80',
      ],
      minPrice: 28000,
      maxPrice: 49000,
      isVerified: true,
      openHours: '06:30 - 23:00 (Thứ 6-CN: 24/7)',
      latitude: 16.0610,
      longitude: 108.2195,
      bills: [
        RealBill(
          id: 'bill_3',
          billPhotoUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
          date: DateTime.now().subtract(const Duration(days: 4)),
          contributorName: 'Nguyễn Thị Thuỳ',
          guestsCount: 3,
          items: const [
            BillItem(name: 'Cà Phê Muối Trình (x2)', price: 70000, quantity: 1),
            BillItem(name: 'Trà Trái Cây Nhiệt Đới', price: 42000, quantity: 1),
            BillItem(name: 'Hạt Hướng Dương Đĩa', price: 20000, quantity: 1),
          ],
          totalAmount: 132000,
        ),
      ],
      fullMenu: const [
        MenuItem(
          name: 'Cà Phê Muối Trình',
          price: 35000,
          category: 'Best-Seller',
        ),
        MenuItem(name: 'Bạc Xỉu Sữa Tươi', price: 32000, category: 'Cà phê'),
        MenuItem(
          name: 'Trà Trái Cây Nhiệt Đới',
          price: 42000,
          category: 'Trà hoa quả',
        ),
        MenuItem(name: 'Hạt Hướng Dương', price: 20000, category: 'Ăn vặt'),
      ],
    ),
    Place(
      id: 'place_4',
      name: 'Mộc Quán Bistro & Grill',
      category: 'Ẩm thực & Nướng BBQ',
      vibes: ['Tụ tập nhóm'],
      address: '26 Tô Hiến Thành, Sơn Trà, Đà Nẵng',
      city: 'Đà Nẵng & Hội An',
      distanceKm: 2.4,
      rating: 4.6,
      reviewsCount: 195,
      coverImageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80',
      ],
      minPrice: 120000,
      maxPrice: 280000,
      isVerified: true,
      openHours: '16:00 - 23:30',
      latitude: 16.0592,
      longitude: 108.2435,
      bills: [
        RealBill(
          id: 'bill_4',
          billPhotoUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
          date: DateTime.now().subtract(const Duration(days: 3)),
          contributorName: 'Hoàng Quốc Việt',
          guestsCount: 4,
          items: const [
            BillItem(
              name: 'Bò Mỹ Nướng Đá Sốt Tiêu',
              price: 245000,
              quantity: 1,
            ),
            BillItem(
              name: 'Sườn Nướng BBQ Khổng Lồ',
              price: 290000,
              quantity: 1,
            ),
            BillItem(
              name: 'Salad Rong Biển Trứng Tôm',
              price: 75000,
              quantity: 1,
            ),
            BillItem(
              name: 'Khoai Tây Múi Cau Phô Mai',
              price: 55000,
              quantity: 1,
            ),
            BillItem(
              name: 'Bia Thủ Công Jasmine IPA (x4)',
              price: 240000,
              quantity: 1,
            ),
          ],
          totalAmount: 905000,
        ),
      ],
      fullMenu: const [
        MenuItem(
          name: 'Bò Mỹ Nướng Đá Sốt Tiêu',
          price: 245000,
          category: 'Món nướng',
        ),
        MenuItem(
          name: 'Sườn Nướng BBQ Khổng Lồ',
          price: 290000,
          category: 'Món nướng',
        ),
        MenuItem(
          name: 'Salad Rong Biển Trứng Tôm',
          price: 75000,
          category: 'Khai vị',
        ),
      ],
    ),
    Place(
      id: 'place_5',
      name: 'Nối Cafe - Góc Nhỏ Hoài Niệm',
      category: 'Cafe Cổ Điển',
      vibes: ['Hẹn hò', 'Chạy deadline'],
      address: '113/18 Nguyễn Chí Thanh, Hải Châu, Đà Nẵng',
      city: 'Đà Nẵng & Hội An',
      distanceKm: 1.1,
      rating: 4.8,
      reviewsCount: 180,
      coverImageUrl: 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&auto=format&fit=crop&q=80',
      ],
      minPrice: 25000,
      maxPrice: 45000,
      isVerified: true,
      openHours: '07:00 - 22:00',
      latitude: 16.0691,
      longitude: 108.2201,
      bills: [
        RealBill(
          id: 'bill_5',
          billPhotoUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
          date: DateTime.now().subtract(const Duration(days: 5)),
          contributorName: 'Phan Bảo Trâm',
          guestsCount: 2,
          items: const [
            BillItem(name: 'Cà Phê Trứng Béo Ngậy', price: 38000, quantity: 1),
            BillItem(name: 'Cacao Nóng Tuổi Thơ', price: 32000, quantity: 1),
          ],
          totalAmount: 70000,
        ),
      ],
      fullMenu: const [
        MenuItem(
          name: 'Cà Phê Trứng Béo Ngậy',
          price: 38000,
          category: 'Món đặc trưng',
        ),
        MenuItem(name: 'Cacao Nóng', price: 32000, category: 'Thức uống nóng'),
        MenuItem(name: 'Cà phê Đen Phin', price: 25000, category: 'Cà phê'),
      ],
    ),
  ];

  static const UserProfile mockUser = UserProfile(
    id: 'user_1',
    name: 'Trần Đức Long',
    email: 'longtran@rendez.vn',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    contributionsCount: 4,
    bookmarksCount: 6,
  );

  static final List<UserContribution> mockContributions = [
    UserContribution(
      id: 'contrib_1',
      placeName: 'Kyoto Ramen 1994',
      placeAddress: '124 Bạch Đằng, Đà Nẵng',
      date: DateTime.now().subtract(const Duration(days: 1)),
      totalAmount: 330000,
      status: ContributionStatus.approved,
    ),
    UserContribution(
      id: 'contrib_2',
      placeName: 'The Hideout Roastery',
      placeAddress: '72 Nguyễn Thị Minh Khai, Đà Nẵng',
      date: DateTime.now().subtract(const Duration(days: 3)),
      totalAmount: 138000,
      status: ContributionStatus.approved,
    ),
    UserContribution(
      id: 'contrib_3',
      placeName: 'Góc Phố Trà Sữa Oolong',
      placeAddress: '45 Phan Châu Trinh, Đà Nẵng',
      date: DateTime.now().subtract(const Duration(hours: 4)),
      totalAmount: 95000,
      status: ContributionStatus.pending,
    ),
  ];
}
