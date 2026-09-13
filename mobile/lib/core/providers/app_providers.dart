import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/place.dart';
import '../models/user.dart';

// Theme Mode Provider (System, Light, Dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// City Provider
final selectedCityProvider = StateProvider<String>((ref) => 'Đà Nẵng & Hội An');

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

  return MockData.places.where((place) {
    // City filter
    if (place.city != city) return false;

    // Search query filter
    if (query.isNotEmpty) {
      final matchName = place.name.toLowerCase().contains(query);
      final matchCat = place.category.toLowerCase().contains(query);
      final matchAddr = place.address.toLowerCase().contains(query);
      final matchVibe = place.vibes.any((v) => v.toLowerCase().contains(query));
      if (!matchName && !matchCat && !matchAddr && !matchVibe) return false;
    }

    // Vibe filter
    if (vibe != null && !place.vibes.contains(vibe)) {
      return false;
    }

    // Budget range filter
    if (budgetIdx == 1 && place.minPrice > 50000) {
      return false;
    }
    if (budgetIdx == 2 && (place.minPrice > 100000 || place.maxPrice < 50000)) {
      return false;
    }
    if (budgetIdx == 3 &&
        (place.minPrice > 200000 || place.maxPrice < 100000)) {
      return false;
    }
    if (budgetIdx == 4 && place.maxPrice < 200000) {
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

// Bookmarks Notifier
class BookmarksNotifier extends StateNotifier<Set<String>> {
  BookmarksNotifier() : super({'place_1', 'place_3'});

  void toggle(String placeId) {
    if (state.contains(placeId)) {
      state = {...state}..remove(placeId);
    } else {
      state = {...state, placeId};
    }
  }

  bool isBookmarked(String placeId) => state.contains(placeId);
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Set<String>>(
  (ref) {
    return BookmarksNotifier();
  },
);

// Auth State
class AuthState {
  final bool isLoggedIn;
  final UserProfile? user;

  const AuthState({required this.isLoggedIn, this.user});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
    : super(const AuthState(isLoggedIn: true, user: MockData.mockUser));

  void login(String email, String password) {
    state = const AuthState(isLoggedIn: true, user: MockData.mockUser);
  }

  void logout() {
    state = const AuthState(isLoggedIn: false, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// User Contributions Notifier
class ContributionsNotifier extends StateNotifier<List<UserContribution>> {
  ContributionsNotifier() : super(MockData.mockContributions);

  void addContribution(UserContribution contrib) {
    state = [contrib, ...state];
  }
}

final contributionsProvider =
    StateNotifierProvider<ContributionsNotifier, List<UserContribution>>((ref) {
      return ContributionsNotifier();
    });
