import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/contribute/contribute_screen.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/features/bookmarks/bookmarks_screen.dart';
import 'package:rendez/features/explore/explore_screen.dart';
import 'package:rendez/features/explore/map_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});
  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _index = 0;
  int? _afterSignIn;
  final _screensKey = GlobalKey();
  static const _icons = [
    Icons.explore_outlined,
    Icons.map_outlined,
    Icons.bookmark_outline,
    Icons.add_photo_alternate_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.explore_rounded,
    Icons.map_rounded,
    Icons.bookmark_rounded,
    Icons.add_photo_alternate_rounded,
    Icons.person_rounded,
  ];
  static const _labels = [
    'Khám phá',
    'Bản đồ',
    'Đã lưu',
    'Đóng góp',
    'Cá nhân',
  ];
  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _index = index;
      if (index != 4) _afterSignIn = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isLoggedIn &&
          previous?.isLoggedIn != true &&
          _afterSignIn != null) {
        _select(_afterSignIn!);
      }
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final screens = IndexedStack(
          key: _screensKey,
          index: _index,
          children: [
            const _Content(child: ExploreScreen()),
            const MapScreen(),
            _Content(
              child: BookmarksScreen(
                onExplore: () => _select(0),
                onSignIn: () {
                  _select(4);
                  _afterSignIn = 2;
                },
              ),
            ),
            _Content(
              child: ContributeScreen(
                key: ValueKey(ref.watch(authProvider).user?.id),
                onSignIn: () {
                  _select(4);
                  _afterSignIn = 3;
                },
              ),
            ),
            const _Content(child: AuthProfileScreen()),
          ],
        );
        return Scaffold(
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      labelType: NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Icon(
                          Icons.explore_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      destinations: [
                        for (var i = 0; i < _labels.length; i++)
                          NavigationRailDestination(
                            icon: Icon(_icons[i]),
                            selectedIcon: Icon(_selectedIcons[i]),
                            label: Text(_labels[i]),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: screens),
                  ],
                )
              : screens,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  height: !kIsWeb
                      ? 72 +
                            (MediaQuery.textScalerOf(context).scale(14) / 14 -
                                        1)
                                    .clamp(0, 1) *
                                48
                      : null,
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: [
                    for (var i = 0; i < _labels.length; i++)
                      NavigationDestination(
                        icon: Icon(_icons[i]),
                        selectedIcon: Icon(_selectedIcons[i]),
                        label: _labels[i],
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  final Widget child;
  const _Content({required this.child});
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: child,
    ),
  );
}
