import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../auth/auth_profile_screen.dart';
import '../explore/explore_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 1; // Default to 'Khám phá' (Center Tab)

  final _screens = const [ExploreScreen(), AuthProfileScreen()];

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isMapViewProvider, (previous, next) {
      if (_currentIndex != 2) {
        setState(() {
          _currentIndex = next ? 0 : 1;
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMapActive = _currentIndex == 0;
    final isExploreActive = _currentIndex == 1;
    final isProfileActive = _currentIndex == 2;

    return Scaffold(
      body: IndexedStack(index: _currentIndex == 2 ? 1 : 0, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkPaperBorder : AppColors.neutral200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                // Tab 0: Bản đồ (Map)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: isMapActive,
                    label: 'Tab Bản đồ',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(isMapViewProvider.notifier).state = true;
                          setState(() => _currentIndex = 0);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isMapActive
                                  ? Icons.map_rounded
                                  : Icons.map_outlined,
                              size: 22,
                              color: isMapActive
                                  ? AppColors.primary
                                  : AppColors.neutral500,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Bản đồ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isMapActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isMapActive
                                    ? AppColors.primary
                                    : AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Tab 1: Khám phá (Center - Enlarged Hero Tab)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: isExploreActive,
                    label: 'Tab Khám phá',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ref.read(isMapViewProvider.notifier).state = false;
                          setState(() => _currentIndex = 1);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isExploreActive
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.darkNeutral100
                                          : AppColors.neutral100),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isExploreActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.explore_rounded,
                                size: 22,
                                color: isExploreActive
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.darkNeutral600
                                          : AppColors.neutral700),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Khám phá',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isExploreActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isExploreActive
                                    ? AppColors.primary
                                    : AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Tab 2: Cá nhân (Profile, replaces 'Tài khoản')
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: isProfileActive,
                    label: 'Tab Cá nhân',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentIndex = 2);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isProfileActive
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                              size: 22,
                              color: isProfileActive
                                  ? AppColors.primary
                                  : AppColors.neutral500,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Cá nhân',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isProfileActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isProfileActive
                                    ? AppColors.primary
                                    : AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
