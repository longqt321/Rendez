import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/data/mock_data.dart';
import 'package:rendez/core/utils/estimates.dart';
import 'package:rendez/core/utils/currency_formatter.dart';
import 'package:rendez/features/place_detail/place_detail_screen.dart';

void main() {
  test(
    'Haversine handles identity, missing coordinates and long distances',
    () {
      expect(distanceKm(16, 108, 16, 108), 0);
      expect(distanceKm(0, 0, 0, 1), closeTo(111.195, 0.01));
      expect(distanceKm(0, 0, 0, 180), closeTo(20015.087, 0.01));
      expect(distanceKm(double.nan, 0, 0, 0), isNull);
      expect(distanceKm(91, 0, 0, 0), isNull);
      expect(formatDistance(0.8), '800 m');
      expect(formatDistance(1.25), '1.3 km');
    },
  );
  test('Price filter matches actual menu rows, not min/max gaps', () async {
    final place = Place.fromJson({
      'id': 'test',
      'name': 'Cafe',
      'address': 'Address',
      'category': 'Cafe',
      'city': 'Đà Nẵng & Hội An',
      'vibes': <String>[],
      'cover_image_url': '',
      'opening_hours': '',
      'latitude': null,
      'longitude': null,
      'min_price': 30000,
      'max_price': 150000,
      'full_menu': [
        {'name': 'Coffee', 'category': 'Drinks', 'price': 30000},
        {'name': 'Lunch', 'category': 'Food', 'price': 150000},
      ],
    });
    final container = ProviderContainer(
      overrides: [
        placesProvider.overrideWith((ref) async => [place]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(placesProvider.future);
    container.read(selectedBudgetRangeProvider.notifier).state = 2;
    expect(container.read(filteredPlacesProvider), isEmpty);
    container.read(selectedBudgetRangeProvider.notifier).state = 1;
    expect(container.read(filteredPlacesProvider), hasLength(1));
    container.read(selectedBudgetRangeProvider.notifier).state = 0;
    container.read(searchQueryProvider.notifier).state = 'Lunch';
    expect(container.read(filteredPlacesProvider), hasLength(1));
  });
  testWidgets('Cost uses selected quantities and divides by party size', (
    tester,
  ) async {
    final place = MockData.places.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CostPanel(place: place)),
        ),
      ),
    );
    expect(find.text('Chưa chọn món để tính chi phí'), findsOneWidget);
    final item = place.fullMenu.first;
    await tester.tap(find.byTooltip('Thêm ${item.name}'));
    await tester.pump();
    expect(
      find.text(
        'Tổng dự kiến: ${CurrencyFormatter.format(item.price)} · khoảng ${CurrencyFormatter.format(item.price)} / người',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byTooltip('Thêm người'));
    await tester.tap(find.byTooltip('Thêm người'));
    await tester.pump();
    expect(
      find.text(
        'Tổng dự kiến: ${CurrencyFormatter.format(item.price)} · khoảng ${CurrencyFormatter.format((item.price / 2).round())} / người',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
