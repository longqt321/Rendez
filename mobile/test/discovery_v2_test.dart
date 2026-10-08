import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';
import 'package:rendez/features/explore/widgets/map_view_widget.dart';

Place venue(String id, String city, {double latitude = double.nan}) => Place(
  id: id,
  name: id,
  category: 'Cà phê',
  vibes: const [],
  address: city,
  city: city,
  distanceKm: double.nan,
  rating: double.nan,
  reviewsCount: 0,
  coverImageUrl: '',
  galleryImages: const [],
  minPrice: 0,
  maxPrice: 0,
  isVerified: false,
  openHours: '',
  latitude: latitude,
  longitude: 108.22,
  bills: const [],
  fullMenu: const [],
);
void main() {
  testWidgets(
    'Feed and map retain shared query and missing-coordinate results',
    (tester) async {
      final places = [
        venue('Lorem ipsum', 'Đà Nẵng', latitude: 16.06),
        venue('Lorem ipsum dolor', 'Hà Nội'),
      ];
      final container = ProviderContainer(
        overrides: [placesProvider.overrideWith((ref) async => places)],
      );
      addTearDown(container.dispose);
      await container.read(placesProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MainScaffold()),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(filteredPlacesProvider), hasLength(2));
      await tester.enterText(find.byType(TextField).first, 'dolor');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bản đồ').last);
      await tester.pumpAndSettle();
      expect(container.read(searchQueryProvider), 'dolor');
      expect(find.text('Chưa có địa điểm có tọa độ'), findsOneWidget);
      expect(
        container.read(filteredPlacesProvider).single.id,
        'Lorem ipsum dolor',
      );
      await tester.tap(find.text('Khám phá').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'dolor',
      );
      container.read(selectedCityProvider.notifier).state = 'Hà Nội';
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Bỏ bộ lọc').first);
      await tester.pumpAndSettle();
      expect(container.read(selectedCityProvider), 'Tất cả thành phố');
      expect(container.read(searchQueryProvider), isEmpty);
      expect(container.read(filteredPlacesProvider), hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Five destinations and map fit 320dp with 1.5x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placesProvider.overrideWith(
            (ref) async => [venue('Lorem ipsum', 'Đà Nẵng', latitude: 16.06)],
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: MainScaffold(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bản đồ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lorem ipsum'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Explicit zoom enables area search and applying it hides the action',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MapViewWidget(
                places: [venue('Lorem ipsum', 'Đà Nẵng', latitude: 16.06)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tìm trong khu vực này'), findsNothing);
      await tester.tap(find.byTooltip('Phóng to'));
      await tester.pumpAndSettle();
      expect(find.text('Tìm trong khu vực này'), findsOneWidget);
      await tester.tap(find.text('Tìm trong khu vực này'));
      await tester.pumpAndSettle();
      expect(find.text('Tìm trong khu vực này'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
