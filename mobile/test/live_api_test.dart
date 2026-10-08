import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';
import 'package:rendez/features/admin/review_screen.dart';
import 'package:rendez/core/utils/estimates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/providers/app_providers.dart';

void main() {
  test('Flutter providers use real HTTP and PostgreSQL', () async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final places = await container.read(placesProvider.future);
    expect(places, hasLength(2));
    expect(places.first.fullMenu, isNotEmpty);
    final detail = await container.read(
      placeDetailProvider(places.first.id).future,
    );
    expect(detail.name, places.first.name);
    final auth = container.read(authProvider.notifier);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final email = 'flutter-$stamp@example.com';
    await auth.register('Flutter User', email, 'FlutterPass123!');
    expect(container.read(authProvider).user!.email, email);
    final bookmarks = container.read(bookmarksProvider.notifier);
    await bookmarks.load();
    await bookmarks.toggle(places.first.id);
    expect(container.read(bookmarksProvider), contains(places.first.id));
    // Undo restores a known state; repeated requests must remain idempotent.
    await bookmarks.setSaved(places.first.id, false);
    await bookmarks.setSaved(places.first.id, false);
    expect(container.read(bookmarksProvider), isEmpty);
    await bookmarks.setSaved(places.first.id, true);
    await bookmarks.setSaved(places.first.id, true);
    expect(container.read(bookmarksProvider), contains(places.first.id));
    await auth.logout();
    expect(container.read(bookmarksProvider), isEmpty);
    await auth.login(email, 'FlutterPass123!');
    await container.read(bookmarksProvider.notifier).load();
    expect(container.read(bookmarksProvider), contains(places.first.id));
    await auth.logout();
    await auth.register(
      'Other User',
      'flutter-other-$stamp@example.com',
      'FlutterPass123!',
    );
    await container.read(bookmarksProvider.notifier).load();
    expect(container.read(bookmarksProvider), isEmpty);
    final api = container.read(apiProvider);
    await api.request('DELETE', '/v1/auth/session');
    await expectLater(
      api.request('GET', '/v1/me'),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(authProvider).isLoggedIn, isFalse);
    expect(api.token, isNull);
    expect(container.read(bookmarksProvider), isEmpty);
    await expectLater(
      auth.login(email, 'WrongPass123!'),
      throwsA(isA<ApiException>()),
    );
  }, skip: !const bool.fromEnvironment('LIVE_API_TEST'));
  testWidgets('Live API data renders in exploration, favorites and menu', (
    tester,
  ) async {
    // Flutter widget tests block network by default; this test deliberately uses real HTTP.
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final places = await container.read(placesProvider.future);
      await container.read(placeDetailProvider(places.first.id).future);
      await container
          .read(authProvider.notifier)
          .register(
            'UI User',
            'ui-${DateTime.now().microsecondsSinceEpoch}@example.com',
            'FlutterPass123!',
          );
      await container.read(bookmarksProvider.notifier).load();
      await container.read(bookmarksProvider.notifier).toggle(places.first.id);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MainScaffold()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rendez Demo Café'), findsWidgets);
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Rendez Demo Café').hitTestable().first);
      final places = await container.read(placesProvider.future);
      final cafe = places.firstWhere(
        (place) => place.name == 'Rendez Demo Café',
      );
      await container.read(placeDetailProvider(cafe.id).future);
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Xem menu và tính chi phí'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Xem menu và tính chi phí'));
    await tester.pumpAndSettle();
    expect(find.text('Cà phê sữa'), findsOneWidget);
    expect(find.textContaining('35.000đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !const bool.fromEnvironment('LIVE_API_TEST'));
  test('Full contribution/OCR/Admin flow persists through real HTTP', () async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    final user = ProviderContainer();
    final admin = ProviderContainer();
    addTearDown(user.dispose);
    addTearDown(admin.dispose);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await user
        .read(authProvider.notifier)
        .register(
          'Contributor',
          'level2-$stamp@example.com',
          'FlutterPass123!',
        );
    await admin
        .read(authProvider.notifier)
        .login('admin@rendez.local', 'RendezDemo123!');
    final places = await user.read(placesProvider.future);
    final place = places.first;
    expect(
      distanceKm(
        place.latitude,
        place.longitude,
        place.latitude,
        place.longitude,
      ),
      0,
    );
    final bytes = await File('../backend/internal/catalog/testdata/menu.png')
        .readAsBytes();
    final submitted = await user
        .read(apiProvider)
        .upload(
          {
            'place_id': place.id,
            'type': 'menu_photo',
            'captured_at': DateTime.now().toUtc().toIso8601String(),
          },
          [(name: 'menu.png', bytes: bytes)],
        );
    final id = submitted['id'] as String;
    final history = await user.read(liveContributionsProvider.future);
    expect(
      history.any(
        (item) => item['id'] == id && item['status'] == 'pending_admin',
      ),
      isTrue,
    );
    final pending = await admin.read(contributionDetailProvider(id).future);
    expect(pending['ocr_error'], '');
    expect(pending['ocr_text'], contains('Coffee'));
    expect(pending['draft_items'], isNotEmpty);
    final imagePath = pending['images'][0]['url'] as String;
    expect(await user.read(apiProvider).image(imagePath), isNotEmpty);
    final userApi = user.read(apiProvider);
    await expectLater(
      userApi.request('GET', '/v1/admin/contributions'),
      throwsA(isA<ApiException>()),
    );
    await admin.read(apiProvider).request(
      'PUT',
      '/v1/admin/contributions/$id/draft',
      {
        'items': [
          {
            'name': 'Flutter OCR verified',
            'price': 47000,
            'category': 'Drinks',
          },
        ],
      },
    );
    admin.invalidate(contributionDetailProvider(id));
    expect(
      (await admin.read(
        contributionDetailProvider(id).future,
      ))['draft_items'][0]['price'],
      47000,
    );
    await admin.read(apiProvider).request(
      'POST',
      '/v1/admin/contributions/$id/review',
      {
        'decision': 'approved',
        'reason': '',
        'items': [
          {
            'name': 'Flutter OCR verified',
            'price': 47000,
            'category': 'Drinks',
          },
        ],
      },
    );
    user.invalidate(placeDetailProvider(place.id));
    final updated = await user.read(placeDetailProvider(place.id).future);
    expect(
      updated.fullMenu.any(
        (item) => item.name == 'Flutter OCR verified' && item.price == 47000,
      ),
      isTrue,
    );
    expect(updated.galleryImages, isNotEmpty);
    expect(updated.isVerified, isTrue);
    final anonymous = ApiClient();
    addTearDown(anonymous.close);
    expect(await anonymous.image(updated.galleryImages.last), isNotEmpty);
    user.invalidate(liveContributionsProvider);
    expect(
      (await user.read(liveContributionsProvider.future))
          .firstWhere((item) => item['id'] == id)['status'],
      'approved',
    );
    await user.read(authProvider.notifier).logout();
    await user
        .read(authProvider.notifier)
        .login('level2-$stamp@example.com', 'FlutterPass123!');
    expect(
      (await user.read(liveContributionsProvider.future))
          .any((item) => item['id'] == id),
      isTrue,
    );
  }, skip: !const bool.fromEnvironment('LIVE_API_TEST'));

  testWidgets('Admin review shows the server result after competing approval', (
    tester,
  ) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previous);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late String id;
    await tester.runAsync(() async {
      await container
          .read(authProvider.notifier)
          .login('admin@rendez.local', 'RendezDemo123!');
      final places = await container.read(placesProvider.future);
      final raw = await File('../backend/internal/catalog/testdata/menu.png')
          .readAsBytes();
      final submitted = await container
          .read(apiProvider)
          .upload(
            {
              'place_id': places.first.id,
              'type': 'menu_photo',
              'captured_at': DateTime.now().toUtc().toIso8601String(),
            },
            [(name: 'menu.png', bytes: raw)],
          );
      id = submitted['id'];
      await container.read(contributionDetailProvider(id).future);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ReviewScreen(id: id)),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đóng góp'), findsOneWidget);
    expect(find.text('Phê duyệt'), findsOneWidget);
    final name = find.widgetWithText(TextField, 'Tên món').first;
    await tester.ensureVisible(name);
    await tester.enterText(name, 'UI verified coffee');
    await tester.pumpAndSettle();
    final approve = find.widgetWithText(FilledButton, 'Phê duyệt');
    await tester.ensureVisible(approve);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(approve).onPressed, isNotNull);
    // Dispatch in the real async zone: fake widget timers must not time out HTTP.
    await tester.runAsync(() async {
      // Another client finishes review while this screen retains unsaved edits.
      await container.read(apiProvider).request(
        'POST',
        '/v1/admin/contributions/$id/review',
        {
          'decision': 'approved',
          'items': [
            {
              'name': 'Server confirmed coffee',
              'price': 35000,
              'category': 'Drinks',
            },
          ],
        },
      );
      await tester.tap(approve);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await container.read(contributionDetailProvider(id).future);
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final detail = await container
          .read(apiProvider)
          .request('GET', '/v1/contributions/$id');
      expect(
        detail['status'],
        'approved',
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      await container.read(contributionDetailProvider(id).future);
    });
    await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Đã duyệt'), findsOneWidget);
    expect(find.text('Server confirmed coffee'), findsOneWidget);
    expect(find.text('UI verified coffee'), findsNothing);
    expect(find.text('Đóng góp đã được xử lý'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.read(apiProvider).close();
    await tester.pump();
  }, skip: !const bool.fromEnvironment('LIVE_API_TEST'));
}
