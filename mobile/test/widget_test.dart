import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/data/mock_data.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/utils/currency_formatter.dart';
import 'package:rendez/core/models/chat_models.dart';
import 'package:rendez/core/providers/chat_providers.dart';
import 'package:rendez/core/constants/app_colors.dart';
import 'package:rendez/features/chat/chat_conversation_screen.dart';
import 'package:rendez/features/chat/chat_list_screen.dart';
import 'package:rendez/features/explore/widgets/bouncing_heart_button.dart';
import 'package:rendez/features/explore/widgets/filter_chips_bar.dart';
import 'package:rendez/features/explore/widgets/search_header.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';
import 'package:rendez/features/place_detail/place_detail_screen.dart';
import 'package:rendez/main.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats VND currency accurately', () {
      expect(CurrencyFormatter.format(45000), '45.000đ');
      expect(CurrencyFormatter.format(1200000), '1.200.000đ');
    });

    test('formats compact amounts correctly', () {
      expect(CurrencyFormatter.formatCompact(45000), '45k');
      expect(CurrencyFormatter.formatCompact(1500000), '1.5tr');
      expect(CurrencyFormatter.formatCompact(2000000), '2tr');
    });

    test('formats range correctly', () {
      expect(CurrencyFormatter.formatRange(35000, 68000), '~35k - 68k/người');
    });
  });

  group('MockData Tests', () {
    test('has valid initial places', () {
      expect(MockData.places.length, greaterThanOrEqualTo(5));
      for (final place in MockData.places) {
        expect(place.name.isNotEmpty, true);
        expect(place.bills.isNotEmpty, true);
        expect(place.minPrice, lessThanOrEqualTo(place.maxPrice));
      }
    });

    test('has verified bills with items', () {
      for (final place in MockData.places) {
        final bill = place.latestBill;
        expect(bill, isNotNull);
        expect(bill!.items.isNotEmpty, true);
        expect(bill.totalAmount, greaterThan(0));
        expect(bill.costPerPerson, greaterThan(0));
      }
    });
  });

  group('Riverpod State Providers Tests', () {
    test('bookmarks provider toggles place id correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bookmarksProvider.notifier);
      expect(notifier.isBookmarked('test_place'), false);

      notifier.toggle('test_place');
      expect(container.read(bookmarksProvider).contains('test_place'), true);

      notifier.toggle('test_place');
      expect(container.read(bookmarksProvider).contains('test_place'), false);
    });

    test('auth provider login and logout work as expected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authProvider).isLoggedIn, true);

      container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).isLoggedIn, false);
      expect(container.read(authProvider).user, isNull);

      container.read(authProvider.notifier).login('test@rendez.vn', 'pass');
      expect(container.read(authProvider).isLoggedIn, true);
      expect(container.read(authProvider).user, isNotNull);
    });

    test('filteredPlacesProvider filters by city and vibe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default city: Đà Nẵng & Hội An
      final allPlaces = container.read(filteredPlacesProvider);
      expect(allPlaces.isNotEmpty, true);

      // Set vibe to 'Mở 24/7'
      container.read(selectedVibeFilterProvider.notifier).state = 'Mở 24/7';
      final lateNightPlaces = container.read(filteredPlacesProvider);
      expect(lateNightPlaces.every((p) => p.vibes.contains('Mở 24/7')), true);
    });

    test('filteredPlacesProvider filters by budget range', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set budget to < 50k (index 1)
      container.read(selectedBudgetRangeProvider.notifier).state = 1;
      final budgetPlaces = container.read(filteredPlacesProvider);
      expect(budgetPlaces.every((p) => p.minPrice <= 50000), true);
    });
  });

  group('Widget Tests', () {
    testWidgets('SearchHeader renders search input and city selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SearchHeader())),
        ),
      );

      expect(find.text('Rendez'), findsOneWidget);
      expect(find.text('Đà Nẵng & Hội An'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('FilterChipsBar renders vibe chips with vector icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: FilterChipsBar())),
        ),
      );

      expect(find.text('Hẹn hò / Date'), findsOneWidget);
      expect(find.text('Tụ tập nhóm'), findsOneWidget);
      expect(find.text('Chạy deadline'), findsOneWidget);
      expect(find.text('Mở 24/7'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    });

    testWidgets('MainScaffold renders 3 bottom tabs with Khám phá in center', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MainScaffold())),
      );

      expect(find.text('Bản đồ'), findsOneWidget);
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);
    });

    testWidgets('PlaceDetailScreen renders without overflow on narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final place = MockData.places.first;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: PlaceDetailScreen(place: place)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(place.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChatListScreen renders conversations and friends', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ChatListScreen())),
      );

      expect(find.text('Hộp Thư & Kèo Hẹn'), findsOneWidget);
      expect(find.text('Minh Anh'), findsWidgets);
      expect(find.text('Hoàng Nam'), findsWidgets);
    });

    testWidgets('ChatConversationScreen renders messages and plan bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatConversationScreen(conversationId: 'conv_1'),
          ),
        ),
      );

      expect(find.text('Minh Anh'), findsOneWidget);
      expect(find.text('KÈO HẸN RENDEZ'), findsOneWidget);
      expect(find.text('The Hideout Roastery'), findsOneWidget);
      expect(find.text('Đi luôn! 🚀'), findsOneWidget);
    });
  });

  group('Chat Providers Logic Tests', () {
    test('chatProvider sends message and updates last message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(chatProvider.notifier)
          .sendMessage('conv_1', 'Alo đi cafe không?');

      final convs = container.read(chatProvider);
      final conv1 = convs.firstWhere((c) => c.id == 'conv_1');
      expect(conv1.lastMessage, 'Alo đi cafe không?');
      expect(conv1.messages.last.text, 'Alo đi cafe không?');
    });

    test('chatProvider sends RendezPlan and updates RSVP status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const plan = RendezPlan(
        id: 'plan_test',
        placeId: 'place_1',
        placeName: 'Test Cafe',
        placeAddress: '123 Test St',
        placeImageUrl: 'https://test.com/img.jpg',
        priceRange: '30k - 50k',
        meetingTime: 'Tối nay',
      );

      container
          .read(chatProvider.notifier)
          .sendRendezPlan(conversationId: 'conv_2', plan: plan);

      var convs = container.read(chatProvider);
      var conv2 = convs.firstWhere((c) => c.id == 'conv_2');
      final planMsg = conv2.messages.last;
      expect(planMsg.rendezPlan?.placeName, 'Test Cafe');
      expect(planMsg.rendezPlan?.rsvpStatus, RsvpStatus.pending);

      // Accept RSVP
      container
          .read(chatProvider.notifier)
          .updateRsvpStatus(
            conversationId: 'conv_2',
            messageId: planMsg.id,
            newStatus: RsvpStatus.accepted,
          );

      convs = container.read(chatProvider);
      conv2 = convs.firstWhere((c) => c.id == 'conv_2');
      expect(conv2.messages.last.rendezPlan?.rsvpStatus, RsvpStatus.accepted);
    });
  });

  group('Editorial Visual & Micro-Interaction Tests', () {
    test('AppColors.getEditorialPastel maps vibes to harmonious pastels', () {
      final datePastel = AppColors.getEditorialPastel('Hẹn hò');
      expect(datePastel.bg, AppColors.peachPastel);
      expect(datePastel.text, AppColors.peachPastelText);

      final studyPastel = AppColors.getEditorialPastel('Chạy deadline');
      expect(studyPastel.bg, AppColors.sagePastel);
      expect(studyPastel.text, AppColors.sagePastelText);

      final nightPastel = AppColors.getEditorialPastel('Mở 24/7');
      expect(nightPastel.bg, AppColors.lilacPastel);
      expect(nightPastel.text, AppColors.lilacPastelText);
    });

    testWidgets(
      'BouncingHeartButton renders and triggers callback with tactile feedback',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BouncingHeartButton(
                isSaved: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

        await tester.tap(find.byType(BouncingHeartButton));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );

    test('AppColors.getEditorialPastel maps vibes to dark pastels when isDark is true', () {
      final datePastel = AppColors.getEditorialPastel('Hẹn hò', isDark: true);
      expect(datePastel.bg, AppColors.darkPeachPastel);
      expect(datePastel.text, AppColors.darkPeachPastelText);

      final studyPastel = AppColors.getEditorialPastel(
        'Chạy deadline',
        isDark: true,
      );
      expect(studyPastel.bg, AppColors.darkSagePastel);
      expect(studyPastel.text, AppColors.darkSagePastelText);

      final nightPastel = AppColors.getEditorialPastel('Mở 24/7', isDark: true);
      expect(nightPastel.bg, AppColors.darkLilacPastel);
      expect(nightPastel.text, AppColors.darkLilacPastelText);
    });

    test('themeModeProvider toggles between system, dark, and light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    testWidgets('RendezApp renders in Dark Mode correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [themeModeProvider.overrideWith((ref) => ThemeMode.dark)],
          child: const RendezApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(RendezApp), findsOneWidget);
    });
  });
}
