---
name: flutter
description: "Expert Flutter and Dart development skill for building high-performance, maintainable cross-platform mobile apps. Covers Dart 3 modern features (records, patterns, sealed classes), Clean Architecture, Riverpod 2.x, Flutter best practices, performance optimization, and testing."
---

# Flutter & Dart Expert Skill

Comprehensive toolkit and guidelines for developing, architecting, and optimizing Flutter & Dart applications.

## 1. System & Tooling Reference

- **Flutter SDK**: 3.47.x (Stable)
- **Dart SDK**: 3.13.x
- **Token-optimized CLI**: Always prefix shell commands with `rtk`:
  - `rtk flutter analyze mobile`
  - `rtk flutter test mobile`
  - `rtk flutter pub get` (inside `mobile/`)
  - `rtk flutter run`
- **MCP Server**: `dart-mcp-server` for package lookup (`pub_dev_search`, `rip_grep_packages`, `pub`).

---

## 2. Modern Dart 3 Standards

1. **Records & Pattern Matching**:
   - Use records for multiple return values instead of ad-hoc tuple classes:
     ```dart
     (String name, double price) getPlaceSummary() => ('An Cà Phê', 45000);
     ```
   - Use exhaustive `switch` expressions on `sealed` classes:
     ```dart
     sealed class AuthState {}
     class AuthInitial extends AuthState {}
     class AuthLoading extends AuthState {}
     class Authenticated extends AuthState { final User user; Authenticated(this.user); }
     class AuthError extends AuthState { final String message; AuthError(this.message); }

     Widget build(BuildContext context, AuthState state) => switch (state) {
       AuthInitial() => const SizedBox.shrink(),
       AuthLoading() => const Center(child: CircularProgressIndicator()),
       Authenticated(:final user) => UserProfileView(user: user),
       AuthError(:final message) => ErrorBanner(message: message),
     };
     ```

2. **Null Safety & Immutability**:
   - Prefer `final` and `const` everywhere.
   - Use `const` constructors on stateless widgets to minimize rebuild costs.

---

## 3. Architecture & State Management (Clean + Riverpod)

Directory layout for `mobile/lib/`:
```
lib/
├── core/
│   ├── constants/       # App colors, styles, assets
│   ├── network/         # Dio client, interceptors
│   ├── theme/           # AppTheme, ColorScheme
│   └── utils/           # Formatters (VND currency, distance)
├── features/
│   ├── auth/            # Presentation, domain, data
│   ├── explore/         # Place discovery, masonry grid, map
│   ├── place_detail/    # Detail view, bill breakdown
│   ├── contribute/      # Bill upload, OCR review
│   └── profile/         # Bookmarks, user settings
└── main.dart
```

### Riverpod 2.x Patterns:
- Use `AsyncNotifierProvider` / `NotifierProvider` for state mutation.
- Use `ref.watch()` for reactive UI rebuilds, `ref.read()` only in callbacks.
- Always handle `AsyncValue` gracefully:
  ```dart
  asyncValue.when(
    data: (data) => DataView(data),
    loading: () => const LoadingSpinner(),
    error: (err, stack) => ErrorWidget(err),
  );
  ```

---

## 4. UI & Widget Performance Rules

1. **Keep `build()` Pure & Shallow**:
   - Never perform side effects, async calls, or heavy allocations inside `build()`.
   - Break large widget trees (>80 lines) into small, focused `StatelessWidget` classes.

2. **Lists & Grids**:
   - Always use `ListView.builder` or `SliverList` / `SliverMasonryGrid`.
   - Provide `ValueKey` for dynamic or re-orderable items.
   - Use `cached_network_image` with proper `memCacheWidth` / `memCacheHeight` to prevent OOM.

3. **Touch Targets & Accessibility**:
   - Minimum 48×48dp touch targets for interactive elements.
   - Adequate spacing (>= 8dp) between adjacent buttons.
   - Ensure text contrast >= 4.5:1.

