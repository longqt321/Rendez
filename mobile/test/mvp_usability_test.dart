import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/data/mock_data.dart';
import 'package:rendez/features/admin/admin_screen.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/theme/app_theme.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/features/bookmarks/bookmarks_screen.dart';
import 'package:rendez/features/explore/explore_screen.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';
import 'package:rendez/features/place_detail/place_detail_screen.dart';

final place = Place.fromJson({
  'id': 'mvp-place',
  'name': 'Quán có tên dài để kiểm tra màn hình hẹp',
  'address': '12 Nguyễn Văn Linh, Đà Nẵng',
  'category': 'Cafe',
  'city': 'Đà Nẵng & Hội An',
  'vibes': <String>[],
  'cover_image_url': '',
  'opening_hours': '07:00–22:00',
  'latitude': 16.0,
  'longitude': 108.0,
  'min_price': 0,
  'max_price': 35000,
  'full_menu': [
    {'id': 'water', 'name': 'Nước lọc', 'category': 'Đồ uống', 'price': 0},
    {
      'id': 'coffee',
      'name': 'Cà phê sữa đá đặc biệt có tên dài',
      'category': 'Đồ uống',
      'price': 35000,
      'observed_at': '2024-01-15T00:00:00Z',
      'reviewed_at': '2026-10-07T00:00:00Z',
    },
  ],
});

Widget app(Widget child, {ThemeMode mode = ThemeMode.light}) => ProviderScope(
  overrides: [
    placesProvider.overrideWith((ref) async => [place]),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: mode,
    home: child,
  ),
);

class _AdminAuth extends AuthNotifier {
  _AdminAuth(super.api) {
    state = const AuthState(
      isLoggedIn: true,
      user: MockData.mockUser,
      role: 'admin',
    );
  }
}

void main() {
  testWidgets(
    'Narrow discovery remains scrollable with large text and can clear filters',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            placesProvider.overrideWith((ref) async => [place]),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.5),
              ),
              child: const ExploreScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'không tồn tại');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Không tìm thấy địa điểm'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy địa điểm'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Bỏ bộ lọc'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Bỏ bộ lọc'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('1 địa điểm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Saved places gives guests a direct sign-in action', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      app(BookmarksScreen(onSignIn: () => tapped = true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    expect(tapped, isTrue);
  });

  testWidgets(
    'Login validates missing inputs and supports password visibility',
    (tester) async {
      await tester.pumpWidget(app(const AuthProfileScreen()));
      await tester.pumpAndSettle();
      final login = find.widgetWithText(FilledButton, 'Đăng nhập');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ'), findsOneWidget);
      expect(find.text('Mật khẩu cần từ 8 đến 256 ký tự'), findsOneWidget);
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    },
  );

  testWidgets(
    'Free items are selected costs rather than unknown prices on narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(child: CostPanel(place: place)),
          ),
          mode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thêm Nước lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Tổng dự kiến: 0đ · khoảng 0đ / người'), findsOneWidget);
      expect(find.text('Ghi nhận 15/1/2024'), findsOneWidget);
      expect(find.text('Admin duyệt 7/10/2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Desktop uses navigation rail and retains all main destinations',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const MainScaffold()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.text('Đóng góp'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Đăng nhập để đóng góp'),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Contribution inputs survive switching between phone and desktop',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _AdminAuth(ref.watch(apiProvider)),
            ),
            placesProvider.overrideWith((ref) async => [place]),
            adminPlacesProvider.overrideWith((ref) async => []),
            lookupsProvider.overrideWith(
              (ref) async => {'cities': [], 'categories': []},
            ),
            liveContributionsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainScaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng góp'));
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextField, 'Tên địa điểm mới');
      await tester.enterText(name, 'Tên địa điểm đang nhập');
      tester.testTextInput.hide();
      for (final width in [1100.0, 390.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(name).controller!.text,
          'Tên địa điểm đang nhập',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Admin separates pending work from reviewed history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _AdminAuth(ref.watch(apiProvider)),
          ),
          adminPlacesProvider.overrideWith((ref) async => []),
          adminContributionsProvider.overrideWith(
            (ref) async => [
              {
                'id': 'pending',
                'place_name': 'Cần xem',
                'status': 'pending_admin',
                'type': 'menu_photo',
              },
              {
                'id': 'approved',
                'place_name': 'Đã xem',
                'status': 'approved',
                'type': 'menu_photo',
              },
            ],
          ),
          // Keep account/bookmark loading offline in this layout test.
          apiProvider.overrideWith((ref) {
            final api = ApiClient();
            ref.onDispose(api.close);
            return api;
          }),
        ],
        child: const MaterialApp(home: AdminScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 đóng góp cần duyệt'), findsOneWidget);
    expect(find.text('Cần xem'), findsOneWidget);
    expect(find.text('Đã xem'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Đã xử lý'));
    await tester.pumpAndSettle();
    expect(find.text('Đã xem'), findsOneWidget);
    expect(find.text('Cần xem'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Distance is one action without technical fields or raw location errors',
    (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(
          code: 'location_error',
          message: 'Technical location failure',
        ),
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(app(Scaffold(body: DistancePanel(place: place))));
      await tester.pumpAndSettle();
      expect(find.text('Cách bạn bao xa?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ExpansionTile), findsNothing);
      await tester.tap(find.text('Xem khoảng cách từ bạn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa xác định được vị trí của bạn. Hãy thử lại.'),
        findsOneWidget,
      );
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ');
      expect(labels, isNot(contains('chim bay')));
      expect(labels, isNot(contains('tọa độ')));
      expect(labels, isNot(contains('Exception')));
      expect(tester.takeException(), isNull);
    },
  );
}
