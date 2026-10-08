import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/widgets/state_message.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/features/explore/widgets/masonry_place_card.dart';

class BookmarksScreen extends ConsumerWidget {
  final VoidCallback? onExplore, onSignIn;
  const BookmarksScreen({super.key, this.onExplore, this.onSignIn});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(bookmarksProvider);
    final status = ref.watch(bookmarksStatusProvider);
    void signIn() {
      if (onSignIn != null) {
        onSignIn!();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthProfileScreen()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đã lưu')),
      body: !ref.watch(authProvider).isLoggedIn
          ? StateMessage(
              icon: Icons.bookmarks_outlined,
              title: 'Đăng nhập để lưu địa điểm',
              message: 'Địa điểm đã lưu được giữ theo tài khoản.',
              actionLabel: 'Đăng nhập',
              onAction: signIn,
            )
          : status.isLoading
          ? const Center(child: CircularProgressIndicator())
          : status.hasError
          ? StateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Chưa tải được bộ sưu tập',
              message: '${status.error}',
              actionLabel: 'Thử lại',
              onAction: () => ref.read(bookmarksProvider.notifier).load(),
            )
          : ref
                .watch(placesProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => StateMessage(
                    icon: Icons.wifi_off_rounded,
                    title: 'Chưa tải được địa điểm',
                    message: '$error',
                    actionLabel: 'Thử lại',
                    onAction: () => ref.invalidate(placesProvider),
                  ),
                  data: (places) {
                    final saved = places
                        .where((place) => ids.contains(place.id))
                        .toList();
                    if (saved.isEmpty) {
                      return StateMessage(
                        icon: Icons.favorite_border_rounded,
                        title: 'Chưa có địa điểm đã lưu',
                        message: 'Chạm biểu tượng lưu trên địa điểm.',
                        actionLabel: onExplore == null ? null : 'Khám phá',
                        onAction: onExplore,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(bookmarksProvider.notifier).load();
                        ref.invalidate(placesProvider);
                        await ref.read(placesProvider.future);
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: saved.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (_, index) => MasonryPlaceCard(
                          place: saved[index],
                          imageHeight: 160,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
