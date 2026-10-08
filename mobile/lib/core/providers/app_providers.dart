import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/models/user.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';

final apiProvider = Provider<ApiClient>((ref) {
  final api = ApiClient();
  ref.onDispose(api.close);
  return api;
});
final placesProvider = FutureProvider<List<Place>>((ref) async {
  final data =
      await ref.watch(apiProvider).request('GET', '/v1/places') as List;
  return data
      .map((item) => Place.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});
final placeDetailProvider = FutureProvider.family<Place, String>((
  ref,
  id,
) async {
  final data = await ref.watch(apiProvider).request('GET', '/v1/places/$id');
  return Place.fromJson(Map<String, dynamic>.from(data));
});
final bookmarksStatusProvider = StateProvider<AsyncValue<void>>(
  (ref) => const AsyncData(null),
);

// Theme Mode Provider (System, Light, Dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// City Provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final selectedCityProvider = StateProvider<String>((ref) => 'Tất cả thành phố');

// Vibe Filter Provider (e.g. 'Hẹn hò', 'Tụ tập nhóm', 'Chạy deadline', 'Mở 24/7')
final selectedVibeFilterProvider = StateProvider<String?>((ref) => null);

// Quick Filter Provider ('all', 'near', 'student', 'checkin')
final selectedQuickFilterProvider = StateProvider<String>((ref) => 'all');

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// View Mode: Grid (false) vs Map (true)
final isMapViewProvider = StateProvider<bool>((ref) => false);

// Advanced Filter Providers
final selectedBudgetRangeProvider = StateProvider<int>((ref) => 0);
final selectedFacilitiesProvider = StateProvider<Set<String>>((ref) => {});

// Filtered Places Provider
final filteredPlacesProvider = Provider<List<Place>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final vibe = ref.watch(selectedVibeFilterProvider);
  final quick = ref.watch(selectedQuickFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final budgetIdx = ref.watch(selectedBudgetRangeProvider);
  final category = ref.watch(selectedCategoryProvider);

  return (ref.watch(placesProvider).valueOrNull ?? <Place>[]).where((place) {
    if (category != null && place.category != category) return false;
    if (budgetIdx != 0 && place.fullMenu.isEmpty) return false;
    // City filter
    if (city != 'Tất cả thành phố' && place.city != city) return false;

    // Search query filter
    if (query.isNotEmpty) {
      final matchName = place.name.toLowerCase().contains(query);
      final matchCat = place.category.toLowerCase().contains(query);
      final matchAddr = place.address.toLowerCase().contains(query);
      final matchVibe =
          place.vibes.any((v) => v.toLowerCase().contains(query)) ||
          place.fullMenu.any((item) => item.name.toLowerCase().contains(query));
      if (!matchName && !matchCat && !matchAddr && !matchVibe) return false;
    }

    // Vibe filter
    if (vibe != null && !place.vibes.contains(vibe)) {
      return false;
    }

    // Match actual item prices; min/max overlap can hide gaps in a menu.
    if (budgetIdx != 0 &&
        !place.fullMenu.any(
          (item) => switch (budgetIdx) {
            1 => item.price < 50000,
            2 => item.price >= 50000 && item.price < 100000,
            3 => item.price >= 100000 && item.price < 200000,
            4 => item.price >= 200000,
            _ => true,
          },
        )) {
      return false;
    }

    // Quick filter
    if (quick == 'student') {
      if (place.minPrice > 50000) return false;
    } else if (quick == 'near') {
      if (place.distanceKm > 1.5) return false;
    }

    return true;
  }).toList();
});

class BookmarksNotifier extends StateNotifier<Set<String>> {
  final ApiClient api;
  final Ref ref;
  BookmarksNotifier(this.api, this.ref) : super({});

  Future<void> load() async {
    final token = api.token;
    if (!mounted || token == null) return;
    ref.read(bookmarksStatusProvider.notifier).state = const AsyncLoading();
    try {
      final data = await api.request('GET', '/v1/favorites') as List;
      if (!mounted || api.token != token) return;
      state = Set<String>.from(data);
      ref.read(bookmarksStatusProvider.notifier).state = const AsyncData(null);
    } catch (error, stack) {
      if (mounted && api.token == token) {
        ref.read(bookmarksStatusProvider.notifier).state = AsyncError(
          error,
          stack,
        );
      }
    }
  }

  final Set<String> _pending = {};

  Future<void> toggle(String placeId) =>
      setSaved(placeId, !state.contains(placeId));

  Future<void> setSaved(String placeId, bool saved) async {
    final token = api.token;
    if (token == null) throw const ApiException('Đăng nhập để lưu địa điểm');
    if (!_pending.add(placeId)) {
      throw const ApiException('Đang cập nhật trạng thái lưu');
    }
    try {
      await api.request(saved ? 'PUT' : 'DELETE', '/v1/favorites/$placeId');
      if (!mounted || api.token != token) return;
      state = saved ? {...state, placeId} : ({...state}..remove(placeId));
    } finally {
      _pending.remove(placeId);
    }
  }

  bool isBookmarked(String placeId) => state.contains(placeId);
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Set<String>>(
  (ref) {
    ref.watch(authProvider);
    final notifier = BookmarksNotifier(ref.watch(apiProvider), ref);
    Future.microtask(notifier.load);
    return notifier;
  },
);

class AuthState {
  final bool isLoggedIn;
  final UserProfile? user;
  final String? role;
  const AuthState({required this.isLoggedIn, this.user, this.role});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient api;
  AuthNotifier(this.api) : super(const AuthState(isLoggedIn: false)) {
    api.onSessionExpired = () {
      api.token = null;
      if (mounted) state = const AuthState(isLoggedIn: false);
    };
  }
  @override
  void dispose() {
    api.onSessionExpired = null;
    super.dispose();
  }

  Future<void> login(String email, String password) =>
      _authenticate('/v1/auth/login', {'email': email, 'password': password});
  Future<void> register(String name, String email, String password) =>
      _authenticate('/v1/auth/register', {
        'display_name': name,
        'email': email,
        'password': password,
      });
  Future<void> _authenticate(String path, Map<String, String> body) async {
    final result = await api.request('POST', path, body);
    api.token = result['token'] as String;
    final user = result['user'];
    state = AuthState(
      isLoggedIn: true,
      role: user['role'] as String,
      user: UserProfile(
        id: user['id'] as String,
        name: user['display_name'] as String,
        email: user['email'] as String,
        avatarUrl: '',
        contributionsCount: 0,
        bookmarksCount: 0,
      ),
    );
  }

  Future<void> logout() async {
    await api.request('DELETE', '/v1/auth/session');
    api.token = null;
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(apiProvider)),
);

// Legacy prototype API is not part of the live slice yet; no fabricated submissions.
class ContributionsNotifier extends StateNotifier<List<UserContribution>> {
  ContributionsNotifier() : super([]);
  void addContribution(UserContribution contribution) {
    throw const ApiException('Đóng góp chưa được kết nối backend');
  }
}

final contributionsProvider =
    StateNotifierProvider<ContributionsNotifier, List<UserContribution>>(
      (ref) => ContributionsNotifier(),
    );

Future<void> toggleBookmark(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  if (!ref.read(authProvider).isLoggedIn) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthProfileScreen(returnToAction: true),
      ),
    );
    if (!context.mounted || !ref.read(authProvider).isLoggedIn) return;
    await ref.read(bookmarksProvider.notifier).load();
    if (!context.mounted) return;
    if (ref.read(bookmarksStatusProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được trạng thái lưu. Hãy thử lại.'),
        ),
      );
      return;
    }
    if (ref.read(bookmarksProvider).contains(id)) return;
  }
  try {
    await ref.read(bookmarksProvider.notifier).toggle(id);
    if (!context.mounted) return;
    final saved = ref.read(bookmarksProvider).contains(id);
    final owner = ref.read(authProvider).user?.id;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Đã lưu địa điểm' : 'Đã bỏ lưu'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            if (!context.mounted || ref.read(authProvider).user?.id != owner) {
              return;
            }
            try {
              await ref.read(bookmarksProvider.notifier).setSaved(id, !saved);
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Đã hoàn tác')));
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$error')));
              }
            }
          },
        ),
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

final lookupsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async => Map<String, dynamic>.from(
    await ref.watch(apiProvider).request('GET', '/v1/lookups'),
  ),
);
final liveContributionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return [];
  final data =
      await ref.watch(apiProvider).request('GET', '/v1/contributions/my')
          as List;
  return data.map((item) => Map<String, dynamic>.from(item)).toList();
});
final adminPlacesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  if (ref.watch(authProvider).role != 'admin') return [];
  final data =
      await ref.watch(apiProvider).request('GET', '/v1/admin/places') as List;
  return data.map((item) => Map<String, dynamic>.from(item)).toList();
});
final adminContributionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  if (ref.watch(authProvider).role != 'admin') return [];
  final data =
      await ref.watch(apiProvider).request('GET', '/v1/admin/contributions')
          as List;
  return data.map((item) => Map<String, dynamic>.from(item)).toList();
});
final contributionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
      ref.watch(authProvider);
      return Map<String, dynamic>.from(
        await ref.watch(apiProvider).request('GET', '/v1/contributions/$id'),
      );
    });
