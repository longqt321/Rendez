import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';

class VibeFilterItem {
  final String key;
  final String label;
  final IconData icon;

  const VibeFilterItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class QuickFilterItem {
  final String key;
  final String label;
  final IconData icon;

  const QuickFilterItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class FilterChipsBar extends ConsumerWidget {
  const FilterChipsBar({super.key});

  static const vibes = [
    VibeFilterItem(
      key: 'Hẹn hò',
      label: 'Hẹn hò / Date',
      icon: Icons.favorite_rounded,
    ),
    VibeFilterItem(
      key: 'Tụ tập nhóm',
      label: 'Tụ tập nhóm',
      icon: Icons.groups_rounded,
    ),
    VibeFilterItem(
      key: 'Chạy deadline',
      label: 'Chạy deadline',
      icon: Icons.laptop_mac_rounded,
    ),
    VibeFilterItem(
      key: 'Mở 24/7',
      label: 'Mở 24/7',
      icon: Icons.nightlight_round,
    ),
  ];

  static const quicks = [
    QuickFilterItem(
      key: 'all',
      label: 'Tất cả',
      icon: Icons.auto_awesome_rounded,
    ),
    QuickFilterItem(
      key: 'near',
      label: 'Gần nhất',
      icon: Icons.near_me_rounded,
    ),
    QuickFilterItem(
      key: 'student',
      label: 'Giá sinh viên',
      icon: Icons.school_rounded,
    ),
    QuickFilterItem(
      key: 'checkin',
      label: 'Check-in đẹp',
      icon: Icons.camera_alt_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedVibe = ref.watch(selectedVibeFilterProvider);
    final selectedQuick = ref.watch(selectedQuickFilterProvider);

    return Container(
      color: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Vibe Filters (Editorial Pastel Pebbles)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: vibes.map((v) {
                final isSelected = selectedVibe == v.key;
                final pastel = AppColors.getEditorialPastel(
                  v.key,
                  isDark: isDark,
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Bộ lọc ${v.label}',
                    child: Material(
                      color: isSelected
                          ? pastel.bg
                          : (isDark
                                ? AppColors.darkNeutral100
                                : const Color(0xFFF2ECE4)),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          HapticFeedback.lightImpact();
                          ref.read(selectedVibeFilterProvider.notifier).state =
                              isSelected ? null : v.key;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          constraints: const BoxConstraints(minHeight: 38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7.5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? pastel.text.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: pastel.text.withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                v.icon,
                                size: 14,
                                color: isSelected
                                    ? pastel.text
                                    : (isDark
                                          ? AppColors.darkNeutral500
                                          : AppColors.neutral600),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                v.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? pastel.text
                                      : (isDark
                                            ? AppColors.darkNeutral800
                                            : AppColors.neutral800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Row 2: Quick Filters (Editorial Minimalist Pebbles)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: quicks.map((q) {
                final isSelected = selectedQuick == q.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Lọc nhanh ${q.label}',
                    child: Material(
                      color: isSelected
                          ? (isDark ? AppColors.primary : AppColors.neutral900)
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          HapticFeedback.lightImpact();
                          ref.read(selectedQuickFilterProvider.notifier).state =
                              q.key;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          constraints: const BoxConstraints(minHeight: 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6.5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                        ? AppColors.darkPaperBorder
                                        : AppColors.paperBorder),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                q.icon,
                                size: 12.5,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.darkNeutral500
                                          : AppColors.neutral500),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                q.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkNeutral700
                                            : AppColors.neutral700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
