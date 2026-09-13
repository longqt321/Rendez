import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/chat_providers.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../chat/chat_list_screen.dart';
import '../contribute/contribute_screen.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/contribution_history_sheet.dart';

class AuthProfileScreen extends ConsumerStatefulWidget {
  const AuthProfileScreen({super.key});

  @override
  ConsumerState<AuthProfileScreen> createState() => _AuthProfileScreenState();
}

class _AuthProfileScreenState extends ConsumerState<AuthProfileScreen> {
  int _authTabIndex = 0; // 0 = Login, 1 = Register

  final _loginEmailController = TextEditingController(
    text: 'longtran@rendez.vn',
  );
  final _loginPasswordController = TextEditingController(text: '12345678');

  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(authState.isLoggedIn ? 'Cá nhân' : 'Đăng Nhập / Đăng Ký'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: authState.isLoggedIn
            ? _buildLoggedInView(context)
            : _buildLoggedOutView(context),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final bookmarks = ref.watch(bookmarksProvider);
    final contributions = ref.watch(contributionsProvider);
    final unreadCount = ref.watch(totalUnreadMessagesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      children: [
        // Profile Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkPaperBorder : AppColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      user?.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Người Dùng Rendez',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkNeutral900
                            : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkNeutral500
                            : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Stats Counters (Interactive)
        Row(
          children: [
            Expanded(
              child: Material(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ContributionHistorySheet(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkPaperBorder
                            : AppColors.neutral200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${contributions.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đã đóng góp',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkNeutral500
                                : AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BookmarksScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkPaperBorder
                            : AppColors.neutral200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${bookmarks.length}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.darkNeutral900
                                : AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Địa điểm đã lưu',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkNeutral500
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

        const SizedBox(height: 16),

        // Menu actions
        Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.darkPaperBorder : AppColors.neutral200,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.bookmark_outline_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Địa điểm đã lưu',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${bookmarks.length} quán trong danh sách',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral400,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Hộp thư & Kèo hẹn',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  unreadCount > 0
                      ? '$unreadCount tin nhắn chưa đọc'
                      : 'Trò chuyện & rủ bạn đi quán',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral400,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              ListTile(
                leading: const Icon(
                  Icons.add_location_alt_outlined,
                  size: 22,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Đóng góp quán mới',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Chia sẻ menu & hóa đơn cho Rendez',
                  style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral400,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContributeScreen()),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              ListTile(
                leading: const Icon(
                  Icons.history_edu_rounded,
                  size: 22,
                  color: AppColors.neutral700,
                ),
                title: const Text(
                  'Lịch sử đóng góp & Trạng thái duyệt',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral400,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ContributionHistorySheet(),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline_rounded,
                  size: 22,
                  color: AppColors.neutral700,
                ),
                title: const Text(
                  'Đổi mật khẩu tài khoản',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral400,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (_) => const ChangePasswordDialog(),
                  );
                },
              ),
              Divider(
                height: 1,
                color: isDark
                    ? AppColors.darkPaperBorder
                    : AppColors.neutral200,
              ),
              ListTile(
                leading: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : (themeMode == ThemeMode.light
                            ? Icons.light_mode_rounded
                            : Icons.brightness_auto_rounded),
                  size: 22,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Giao diện ứng dụng (Dark Mode)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  themeMode == ThemeMode.system
                      ? 'Tự động theo hệ điều hành'
                      : (themeMode == ThemeMode.dark
                            ? 'Giao diện Tối (Espresso Noir)'
                            : 'Giao diện Sáng (Tạp chí ngà ấm)'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkNeutral500
                        : AppColors.neutral500,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? AppColors.darkNeutral500
                      : AppColors.neutral400,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showThemeModeSheet(context, ref, themeMode);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.destructiveLight),
              backgroundColor: AppColors.destructiveLight.withValues(
                alpha: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'Đăng Xuất Khỏi Tài Khoản',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Column(
      children: [
        // Tab switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _authTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _authTabIndex == 0
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Đăng Nhập',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _authTabIndex == 0
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _authTabIndex == 0
                            ? AppColors.neutral900
                            : AppColors.neutral500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _authTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _authTabIndex == 1
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Đăng Ký Mới',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _authTabIndex == 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _authTabIndex == 1
                            ? AppColors.neutral900
                            : AppColors.neutral500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_authTabIndex == 0) ...[
          // Login Form
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email đăng nhập',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginEmailController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'email@domain.com',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mật khẩu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(hintText: '••••••••'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(authProvider.notifier)
                          .login(
                            _loginEmailController.text,
                            _loginPasswordController.text,
                          );
                    },
                    child: const Text(
                      'Đăng Nhập Ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Register Form
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Họ và tên',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _regNameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Nguyễn Văn A'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _regEmailController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'email@domain.com',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mật khẩu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _regPasswordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Tối thiểu 8 ký tự',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(authProvider.notifier)
                          .login('new@user.com', 'password');
                    },
                    child: const Text(
                      'Tạo Tài Khoản Rendez',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = [
          (
            mode: ThemeMode.system,
            title: 'Theo cài đặt hệ thống',
            subtitle: 'Tự động đồng bộ với chế độ Sáng / Tối của điện thoại',
            icon: Icons.brightness_auto_rounded,
          ),
          (
            mode: ThemeMode.light,
            title: 'Giao diện Sáng (Tạp chí ngà ấm)',
            subtitle: 'Phong cách Editorial Lifestyle với nền giấy ấm',
            icon: Icons.light_mode_rounded,
          ),
          (
            mode: ThemeMode.dark,
            title: 'Giao diện Tối (Espresso Noir)',
            subtitle: 'Tông than ấm dịu mắt ban đêm, tiết kiệm pin OLED',
            icon: Icons.dark_mode_rounded,
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkNeutral500
                          : AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chế Độ Hiển Thị',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkNeutral900
                        : AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final isSelected = opt.mode == currentMode;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: isSelected
                          ? (isDark
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.primarySubtle)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.darkNeutral100
                                      : AppColors.neutral100),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            opt.icon,
                            size: 20,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkNeutral600
                                      : AppColors.neutral600),
                          ),
                        ),
                        title: Text(
                          opt.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xFFFBBF24)
                                      : AppColors.primaryText)
                                : (isDark
                                      ? AppColors.darkNeutral900
                                      : AppColors.neutral900),
                          ),
                        ),
                        subtitle: Text(
                          opt.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkNeutral500
                                : AppColors.neutral500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          SystemSound.play(SystemSoundType.click);
                          ref.read(themeModeProvider.notifier).state = opt.mode;
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
