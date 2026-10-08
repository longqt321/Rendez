import 'package:flutter/material.dart';
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
}
