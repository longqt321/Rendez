import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rendez/features/contribute/contribute_screen.dart';
import 'package:rendez/features/admin/admin_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';

class AuthProfileScreen extends ConsumerStatefulWidget {
  final bool returnToAction;
  const AuthProfileScreen({super.key, this.returnToAction = false});
  @override
  ConsumerState<AuthProfileScreen> createState() => _AuthProfileScreenState();
}

class _AuthProfileScreenState extends ConsumerState<AuthProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  bool _register = false, _busy = false, _showPassword = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({bool logout = false}) async {
    if (_busy || (!logout && !(_form.currentState?.validate() ?? false))) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      if (logout) {
        await auth.logout();
        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
      } else if (_register) {
        await auth.register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
      _password.clear();
      if (mounted && !logout) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã đăng nhập')));
        if (widget.returnToAction) Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider), theme = Theme.of(context);
    if (!kIsWeb) return _mobile(context);
    return Scaffold(
      appBar: AppBar(title: Text(auth.isLoggedIn ? 'Tài khoản' : 'Đăng nhập')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (auth.isLoggedIn) ...[
                Text(auth.user!.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(auth.user!.email),
                const SizedBox(height: 24),
              ],
              if (auth.isLoggedIn) ...[
                if (auth.role == 'admin') ...[
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Quản trị địa điểm và duyệt đóng góp'),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _submit(logout: true),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ] else ...[
                Text(
                  _register ? 'Tạo tài khoản' : 'Email và mật khẩu',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        if (_register) ...[
                          TextFormField(
                            controller: _name,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Nhập tên hiển thị'
                                : value.trim().length > 200
                                ? 'Tên tối đa 200 ký tự'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (value) =>
                              value == null ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+$')
                                      .hasMatch(value.trim())
                              ? 'Nhập email hợp lệ'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: !_showPassword,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            helperText: _register ? 'Từ 8 đến 256 ký tự' : null,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Ẩn mật khẩu'
                                  : 'Hiện mật khẩu',
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null ||
                                  value.length < 8 ||
                                  value.length > 256
                              ? 'Mật khẩu cần từ 8 đến 256 ký tự'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: Text(
                              _busy
                                  ? 'Đang xử lý…'
                                  : _register
                                  ? 'Tạo tài khoản'
                                  : 'Đăng nhập',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _register = !_register;
                                  _error = null;
                                  _form.currentState?.reset();
                                }),
                          child: Text(
                            _register
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 28),
              Text('Giao diện', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<ThemeMode>(
                isExpanded: true,
                initialValue: ref.watch(themeModeProvider),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.palette_outlined),
                  labelText: 'Chế độ hiển thị',
                ),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Theo hệ thống'),
                  ),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeModeProvider.notifier).state = mode;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cài đặt',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chế độ hiển thị',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in const {
                    ThemeMode.system: 'Theo hệ thống',
                    ThemeMode.light: 'Sáng',
                    ThemeMode.dark: 'Tối',
                  }.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.key == ThemeMode.dark
                            ? Icons.dark_mode_outlined
                            : entry.key == ThemeMode.light
                            ? Icons.light_mode_outlined
                            : Icons.brightness_auto_outlined,
                      ),
                      title: Text(entry.value),
                      trailing: ref.watch(themeModeProvider) == entry.key
                          ? const Icon(Icons.check_circle_rounded)
                          : null,
                      onTap: () => ref.read(themeModeProvider.notifier).state =
                          entry.key,
                    ),
                  const Divider(height: 32),
                  if (ref.watch(authProvider).isLoggedIn)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Đăng xuất'),
                      onTap: () async {
                        Navigator.pop(sheet);
                        final confirmed = await showDialog<bool>(
                          context: this.context,
                          builder: (dialog) => AlertDialog(
                            title: const Text('Đăng xuất khỏi Rendez?'),
                            content: const Text(
                              'Địa điểm đã lưu và đóng góp vẫn được giữ trong tài khoản.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, false),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialog, true),
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await _submit(logout: true);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    final theme = Theme.of(context), auth = ref.watch(authProvider);
    if (auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cá nhân'),
          actions: [
            IconButton(
              tooltip: 'Cài đặt',
              onPressed: _settings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  auth.user!.name.trim().isEmpty
                      ? 'R'
                      : auth.user!.name.trim().characters.first.toUpperCase(),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              auth.user!.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              auth.user!.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bookmark_outline_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Giữ lại những nơi bạn thích',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chạm biểu tượng lưu trên địa điểm. Bạn sẽ tìm lại chúng trong tab Đã lưu.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Đóng góp của tôi'),
                    subtitle: const Text('Xem kết quả và lý do kiểm duyệt'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ContributeScreen(historyOnly: true),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 18, endIndent: 18),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Cài đặt'),
                    subtitle: const Text('Giao diện và tài khoản'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _settings,
                  ),
                  if (auth.role == 'admin') ...[
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Quản trị địa điểm và duyệt đóng góp'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rendez', style: theme.textTheme.titleLarge),
                    IconButton(
                      tooltip: 'Chế độ hiển thị',
                      onPressed: _settings,
                      icon: const Icon(Icons.contrast_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.explore_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _register
                      ? 'Cuộc hẹn hay,\nbắt đầu từ đây.'
                      : 'Tìm một nơi.\nHẹn một hôm.',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  _register
                      ? 'Tạo tài khoản để lưu địa điểm và góp thêm thông tin hữu ích.'
                      : 'Khám phá địa điểm, xem giá món và lưu lại những nơi bạn muốn ghé.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _register ? 'Tạo tài khoản' : 'Email và mật khẩu',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        if (_register) ...[
                          TextFormField(
                            controller: _name,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nhập tên hiển thị'
                                : v.trim().length > 200
                                ? 'Tên tối đa 200 ký tự'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) =>
                              v == null ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+$')
                                      .hasMatch(v.trim())
                              ? 'Nhập email hợp lệ'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: !_showPassword,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            helperText: _register ? 'Từ 8 đến 256 ký tự' : null,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Ẩn mật khẩu'
                                  : 'Hiện mật khẩu',
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.length < 8 || v.length > 256
                              ? 'Mật khẩu cần từ 8 đến 256 ký tự'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _register ? 'Tạo tài khoản' : 'Đăng nhập',
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _register = !_register;
                                  _error = null;
                                  _form.currentState?.reset();
                                }),
                          child: Text(
                            _register
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                      ],
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
