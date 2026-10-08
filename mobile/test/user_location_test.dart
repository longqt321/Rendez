import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/utils/user_location.dart';
import 'package:rendez/features/explore/widgets/map_view_widget.dart';

Position fix(double accuracy, {double latitude = 16.06}) => Position(
  latitude: latitude,
  longitude: 108.22,
  timestamp: DateTime.now(),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class LocationFake extends GeolocatorPlatform {
  Position position = fix(15000);
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    settings = locationSettings;
    return position;
  }
}

void main() {
  test(
    'Accept usable fixes and reject coarse, invalid and unknown accuracy',
    () {
      validateUserPosition(fix(20));
      validateUserPosition(fix(500));
      for (final position in [
        fix(15000),
        fix(501),
        fix(double.nan),
        fix(-1),
        fix(20, latitude: double.nan),
      ]) {
        expect(
          () => validateUserPosition(position),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );
  testWidgets(
    'Coarse location preserves camera; retry shows a distinct user dot and accuracy circle',
    (tester) async {
      final previous = GeolocatorPlatform.instance;
      final platform = LocationFake();
      GeolocatorPlatform.instance = platform;
      addTearDown(() => GeolocatorPlatform.instance = previous);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MapViewWidget(places: [])),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cameraBefore = MapCamera.of(tester.element(find.byType(TileLayer)))
          .center;
      await tester.tap(find.byTooltip('Vị trí của tôi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Vị trí chưa đủ chính xác'), findsOneWidget);
      expect(find.byKey(const ValueKey('user-position')), findsNothing);
      expect(
        MapCamera.of(tester.element(find.byType(TileLayer))).center,
        cameraBefore,
      );
      expect(platform.settings!.accuracy, LocationAccuracy.best);
      platform.position = fix(20);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('user-position')), findsOneWidget);
      expect(
        tester
            .widget<CircleLayer>(find.byType(CircleLayer))
            .circles
            .single
            .radius,
        20,
      );
      final cameraAfter = MapCamera.of(tester.element(find.byType(TileLayer)))
          .center;
      expect(cameraAfter.latitude, 16.06);
      expect(cameraAfter.longitude, 108.22);
      expect(tester.takeException(), isNull);
    },
  );
}
