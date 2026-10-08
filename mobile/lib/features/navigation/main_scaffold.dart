import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/contribute/contribute_screen.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/features/bookmarks/bookmarks_screen.dart';
import 'package:rendez/features/explore/explore_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});
  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _index = 1;
  int? _afterSignIn;
  final _screensKey = GlobalKey();
  static const _icons = [
    Icons.bookmark_outline,
    Icons.explore_outlined,
    Icons.add_photo_alternate_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.bookmark_rounded,
    Icons.explore_rounded,
    Icons.add_photo_alternate_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ['Đã lưu', 'Khám phá', 'Đóng góp', 'Cá nhân'];
  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _index = index;
      if (index != 3) _afterSignIn = null;
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
        final wide = constraints.maxWidth >= 760;
        final screens = IndexedStack(
          key: _screensKey,
          index: _index,
          children: [
            BookmarksScreen(
              onExplore: () => _select(1),
              onSignIn: () {
                _select(3);
                _afterSignIn = 0;
              },
            ),
            const ExploreScreen(),
            ContributeScreen(
              key: ValueKey(ref.watch(authProvider).user?.id),
              onSignIn: () {
                _select(3);
                _afterSignIn = 2;
              },
            ),
            const AuthProfileScreen(),
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
