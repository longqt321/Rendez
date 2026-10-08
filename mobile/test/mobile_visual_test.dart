import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// Screenshot tooling reuses the image widget's installed cache dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/models/user.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/theme/app_theme.dart';
import 'package:rendez/features/admin/admin_screen.dart';
import 'package:rendez/features/admin/review_screen.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/features/contribute/contribute_screen.dart';
import 'package:rendez/features/explore/explore_screen.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';
import 'package:rendez/features/place_detail/place_detail_screen.dart';

const capture = bool.fromEnvironment('MOBILE_CAPTURE');
const output = String.fromEnvironment(
  'CAPTURE_DIR',
  defaultValue: '../docs/design/mobile/iteration-1',
);
final boundaryKey = GlobalKey();

final venues = [
  for (var i = 0; i < 6; i++)
    Place.fromJson({
      'id': 'visual-$i',
      'name': [
        'Tiệm cà phê Nắng',
        'Bếp nhỏ bên hiên',
        'Góc cà phê an yên',
        'Một bữa ngon',
        'Cà phê cuối tuần',
        'Quán chưa có ảnh',
      ][i],
      'address': '${24 + i * 10} Nguyễn Văn Linh, Đà Nẵng',
      'category': i.isEven ? 'Cà phê' : 'Ăn uống',
      'city': 'Đà Nẵng',
      'vibes': <String>[],
      'opening_hours': '07:00–22:00',
      'description': 'Một góc nhỏ để gặp nhau, trò chuyện và thưởng thức những món quen thuộc.',
      'cover_image_url': capture && i < 5
          ? 'https://images.unsplash.com/${['photo-1554118811-1e0d58224f24', 'photo-1569718212165-3a8278d5f624', 'photo-1501339847302-ac426a4a7cbb', 'photo-1544025162-d76694265947', 'photo-1521017432531-fbd92d768814'][i]}?w=600&auto=format&fit=crop&q=80'
          : '',
      'min_price': 35000,
      'max_price': 45000,
      'latitude': null,
      'longitude': null,
      'full_menu': i == 5
          ? []
          : [
              {
                'id': 'coffee-$i',
                'name': 'Cà phê sữa đá',
                'category': 'Đồ uống',
                'price': 35000,
                'observed_at': '2026-10-07T00:00:00Z',
              },
              {
                'id': 'tea-$i',
                'name': 'Trà đào cam sả',
                'category': 'Đồ uống',
                'price': 45000,
                'observed_at': '2026-10-07T00:00:00Z',
              },
            ],
      'bill_examples': [
        {'total': 120000, 'guests': 2, 'captured_at': '2026-10-07T00:00:00Z'},
      ],
    }),
];
Map<String, dynamic> contribution(
  String status, {
  bool bill = false,
  bool ocrError = false,
}) => {
  'id': status,
  'place_id': venues.first.id,
  'place_name': venues.first.name,
  'type': bill ? 'bill_photo' : 'menu_photo',
  'status': status,
  'captured_at': '2026-10-07T00:00:00Z',
  'created_at': '2026-10-08T00:00:00Z',
  'reviewed_at': status == 'pending_admin' ? null : '2026-10-08T00:00:00Z',
  'rejection_reason': status == 'rejected'
      ? 'Ảnh bị lóa ở phần giá. Hãy chụp rõ hơn trong lần đóng góp tiếp theo.'
      : '',
  'ocr_text': 'Cà phê sữa đá 35000\nTrà đào cam sả 45000',
  'ocr_error': ocrError ? 'OCR timeout' : '',
  'draft_items': bill
      ? []
      : [
          {'name': 'Cà phê sữa đá', 'price': 35000, 'category': 'Đồ uống'},
        ],
  'bill_total': bill ? 120000 : null,
  'guests_count': bill ? 2 : null,
  'images': <Map<String, dynamic>>[],
};
const user = UserProfile(
  id: 'visual-owner',
  name: 'Nguyễn Thảo Vy',
  email: 'thaovy@example.com',
  avatarUrl: '',
  contributionsCount: 0,
  bookmarksCount: 0,
);

class VisualApi extends ApiClient {
  final favorites = <String>{'visual-0', 'visual-1', 'visual-2'};
  @override
  Future<dynamic> request(String method, String path, [Object? body]) async {
    if (path == '/v1/favorites') return favorites.toList();
    if (path.startsWith('/v1/favorites/')) {
      final id = path.split('/').last;
      method == 'PUT' ? favorites.add(id) : favorites.remove(id);
      return null;
    }
    if (path.startsWith('/v1/auth/')) {
      if (method == 'DELETE') return null;
      throw const ApiException(
        'Email hoặc mật khẩu chưa đúng. Vui lòng thử lại.',
      );
    }
    return null;
  }
}

class VisualAuth extends AuthNotifier {
  VisualAuth(super.api, {bool admin = false, bool loggedIn = true}) {
    state = AuthState(
      isLoggedIn: loggedIn,
      user: loggedIn ? user : null,
      role: admin ? 'admin' : 'user',
    );
    api.token = loggedIn ? 'visual-test-session' : null;
  }
}

ProviderContainer container({
  bool admin = false,
  bool loggedIn = true,
  bool empty = false,
  bool error = false,
  String status = 'pending_admin',
  bool bill = false,
  bool ocrError = false,
}) => ProviderContainer(
  overrides: [
    apiProvider.overrideWith((ref) {
      final api = VisualApi();
      ref.onDispose(api.close);
      return api;
    }),
    authProvider.overrideWith(
      (ref) =>
          VisualAuth(ref.read(apiProvider), admin: admin, loggedIn: loggedIn),
    ),
    placesProvider.overrideWith((ref) async {
      if (error) throw const ApiException('Không tải được dữ liệu');
      return empty ? [] : venues;
    }),
    placeDetailProvider.overrideWith(
      (ref, id) async => venues.firstWhere((p) => p.id == id),
    ),
    lookupsProvider.overrideWith(
      (ref) async => {
        'cities': [
          {'code': 'danang', 'name': 'Đà Nẵng'},
        ],
        'categories': [
          {'code': 'cafe', 'name': 'Cà phê'},
        ],
      },
    ),
    liveContributionsProvider.overrideWith(
      (ref) async => empty
          ? []
          : [
              contribution('pending_admin'),
              contribution('approved'),
              contribution('rejected'),
            ],
    ),
    adminContributionsProvider.overrideWith(
      (ref) async => [contribution('pending_admin'), contribution('approved')],
    ),
    adminPlacesProvider.overrideWith(
      (ref) async => [
        {
          'id': 'visual-0',
          'name': venues.first.name,
          'address': venues.first.address,
          'city_code': 'danang',
          'category_code': 'cafe',
          'publication_state': 'published',
          'opening_hours': '07:00–22:00',
          'latitude': null,
          'longitude': null,
          'description': '',
        },
      ],
    ),
    contributionDetailProvider.overrideWith(
      (ref, id) async => contribution(status, bill: bill, ocrError: ocrError),
    ),
  ],
);
Future<void> mount(
  WidgetTester tester,
  ProviderContainer scope,
  Widget screen, {
  double width = 390,
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          locale: const Locale('vi'),
          home: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (capture) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
  }
}

Future<void> shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (!capture) return;
  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final pixels = await boundary.toImage(pixelRatio: 2);
    final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$output/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    pixels.dispose();
  });
}

Future<void> close(WidgetTester tester, ProviderContainer scope) async {
  await tester.pumpWidget(const SizedBox.shrink());
  scope.dispose();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => '/tmp/rendez-mobile-capture-cache',
        );
  });
  setUpAll(() async {
    if (capture) {
      HttpOverrides.global = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/rendez-mobile-capture-cache',
          );
      for (final place in venues.where((p) => p.coverImageUrl.isNotEmpty)) {
        final existing = await DefaultCacheManager().getFileFromCache(
          place.coverImageUrl,
        );
        if (existing != null && await existing.file.exists()) continue;
        final client = HttpClient();
        try {
          final response = await (await client.getUrl(
            Uri.parse(place.coverImageUrl),
          )).close();
          if (response.statusCode != 200) {
            throw StateError('Photo fixture HTTP ${response.statusCode}');
          }
          final bytes = await response.fold<List<int>>(
            [],
            (result, part) => result..addAll(part),
          );
          await DefaultCacheManager().putFile(
            place.coverImageUrl,
            Uint8List.fromList(bytes),
            fileExtension: 'jpg',
          );
        } finally {
          client.close(force: true);
        }
      }
      for (final place in venues.where((p) => p.coverImageUrl.isNotEmpty)) {
        final done = Completer<void>();
        final stream = CachedNetworkImageProvider(place.coverImageUrl)
            .resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, synchronous) {
            if (!done.isCompleted) done.complete();
          },
          onError: (Object error, StackTrace? stack) {
            if (!done.isCompleted) done.completeError(error, stack);
          },
        );
        stream.addListener(listener);
        await done.future;
        stream.removeListener(listener);
      }
      final font = FontLoader('Roboto');
      font.addFont(
        Future.value(
          ByteData.sublistView(
            await File('test/fixtures/fonts/Roboto-Regular.ttf').readAsBytes(),
          ),
        ),
      );
      font.addFont(
        Future.value(
          ByteData.sublistView(
            await File('test/fixtures/fonts/Roboto-Medium.ttf').readAsBytes(),
          ),
        ),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  testWidgets(
    'Mobile discovery saves, filters and recovers at 320dp and 200% text',
    (tester) async {
      final scope = container();
      await mount(tester, scope, const MainScaffold());
      await shot(tester, '01-explore');
      await tester.tap(find.byTooltip('Bỏ lưu địa điểm').first);
      await tester.pumpAndSettle();
      expect(scope.read(bookmarksProvider), isNot(contains('visual-0')));
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(scope.read(bookmarksProvider), contains('visual-0'));
      await tester.ensureVisible(find.text('Giá món').first);
      await tester.tap(find.text('Giá món').first);
      await tester.pumpAndSettle();
      await shot(tester, '02-price-filter');
      await tester.tap(find.text('Dưới 50.000đ'));
      await tester.pumpAndSettle();
      expect(scope.read(selectedBudgetRangeProvider), 1);
      await tester.scrollUntilVisible(find.byType(TextField), -200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'không tồn tại');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await shot(tester, '03-search-empty');
      await tester.tap(find.widgetWithText(TextButton, 'Bỏ bộ lọc').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã lưu').last);
      await tester.pumpAndSettle();
      await shot(tester, '04-saved');
      await tester.tap(find.text('Cá nhân').last);
      await tester.pumpAndSettle();
      await shot(tester, '05-profile');
      await tester.tap(find.byTooltip('Cài đặt'));
      await tester.pumpAndSettle();
      await shot(tester, '06-settings');
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await shot(tester, '07-logout-confirm');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng góp').last);
      await tester.pumpAndSettle();
      await shot(tester, '08-contribution-hub');
      await tester.tap(find.text('Ảnh menu'));
      await tester.pumpAndSettle();
      await shot(tester, '09-contribution-form');
      await tester.drag(
        find.byType(ListView).hitTestable().first,
        const Offset(0, -550),
      );
      await tester.pumpAndSettle();
      await shot(tester, '10-contribution-upload');
      await close(tester, scope);
      for (final dark in [false, true]) {
        final scope = container();
        await mount(tester, scope, const MainScaffold(), dark: dark);
        await shot(tester, dark ? '11-explore-dark' : '12-explore-light');
        await mount(
          tester,
          scope,
          const MainScaffold(),
          width: 320,
          scale: 2,
          dark: dark,
        );
        await shot(tester, dark ? '13-320-large-dark' : '14-320-large-light');
        await tester.drag(
          find.byType(CustomScrollView).hitTestable().first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        await shot(
          tester,
          dark ? '15-320-large-card-dark' : '16-320-large-card-light',
        );
        await close(tester, scope);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    },
  );
  testWidgets(
    'Mobile authentication, detail, contribution and admin screens render',
    (tester) async {
      var scope = container(loggedIn: false);
      await mount(tester, scope, const AuthProfileScreen());
      await shot(tester, '17-login');
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      await shot(tester, '18-register');
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
      await tester.pumpAndSettle();
      await shot(tester, '19-register-invalid');
      await close(tester, scope);
      scope = container();
      await mount(tester, scope, PlaceDetailScreen(place: venues.first));
      await shot(tester, '20-place-detail');
      await tester.scrollUntilVisible(
        find.text('Xem menu và tính chi phí'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Xem menu và tính chi phí'));
      await tester.pumpAndSettle();
      await shot(tester, '21-menu');
      await tester.tap(find.byTooltip('Thêm Cà phê sữa đá'));
      await tester.pumpAndSettle();
      expect(find.textContaining('35.000đ / người'), findsOneWidget);
      await shot(tester, '22-cost-selected');
      await close(tester, scope);
      for (final entry in <String, Widget>{
        '23-history': const ContributeScreen(historyOnly: true),
        '24-admin': const AdminScreen(),
        '25-place-create': const PlaceEditor(),
        '26-review-menu': const ReviewScreen(id: 'pending_admin'),
      }.entries) {
        scope = container(admin: true);
        await mount(tester, scope, entry.value);
        await shot(tester, entry.key);
        await close(tester, scope);
      }
      for (final status in ['pending_admin', 'approved', 'rejected']) {
        scope = container(status: status);
        await mount(tester, scope, ReviewScreen(id: status));
        await shot(tester, '27-contribution-$status');
        await close(tester, scope);
      }
      scope = container(admin: true, bill: true);
      await mount(tester, scope, const ReviewScreen(id: 'pending_admin'));
      await shot(tester, '28-review-bill');
      await close(tester, scope);
      scope = container(admin: true, ocrError: true);
      await mount(tester, scope, const ReviewScreen(id: 'pending_admin'));
      await shot(tester, '29-ocr-recovery');
      await close(tester, scope);
      for (final error in [false, true]) {
        scope = container(empty: !error, error: error);
        await mount(tester, scope, const ExploreScreen());
        await shot(tester, error ? '30-network-error' : '31-empty-catalog');
        await close(tester, scope);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    },
  );
}
