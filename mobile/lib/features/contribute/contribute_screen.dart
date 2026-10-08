import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/admin/review_screen.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/core/widgets/state_message.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSignIn;
  final String? initialPlaceId;
  final bool historyOnly;
  const ContributeScreen({
    super.key,
    this.onSignIn,
    this.initialPlaceId,
    this.historyOnly = false,
  });
  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  String? _placeId, _city, _category;
  String _kind = 'menu_photo';
  DateTime _captured = DateTime.now();
  List<({String name, Uint8List bytes})> _images = [];
  bool _busy = false, _formOpen = false, _newPlace = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _placeId = widget.initialPlaceId;
    _formOpen = widget.initialPlaceId != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pick({bool camera = false}) async {
    try {
      final picker = ImagePicker();
      final List<XFile> files;
      if (camera) {
        final file = await picker.pickImage(source: ImageSource.camera);
        files = file == null ? [] : [file];
      } else {
        files = await picker.pickMultiImage();
      }
      if (files.isEmpty) return;
      if (files.length > 5) throw const ApiException('Chọn tối đa 5 ảnh');
      final images = <({String name, Uint8List bytes})>[];
      for (final file in files) {
        if (await file.length() >= 10 * 1024 * 1024) {
          throw const ApiException('Mỗi ảnh phải nhỏ hơn 10MB');
        }
        images.add((name: file.name, bytes: await file.readAsBytes()));
      }
      if (mounted) {
        setState(() {
          _images = images;
          _message = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = camera
              ? 'Không mở được máy ảnh. Kiểm tra quyền truy cập rồi thử lại.'
              : 'Không mở được ảnh. Kiểm tra quyền truy cập rồi thử lại.',
        );
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_images.isEmpty) {
        throw const ApiException('Chọn ảnh menu hoặc hóa đơn');
      }
      if (_placeId == null &&
          (_name.text.trim().isEmpty ||
              _address.text.trim().isEmpty ||
              _city == null ||
              _category == null)) {
        throw const ApiException('Nhập đủ thông tin địa điểm mới');
      }
      await ref.read(apiProvider).upload({
        'type': _kind,
        'captured_at': _captured.toUtc().toIso8601String(),
        'place_id': ?_placeId,
        if (_placeId == null) ...{
          'place_name': _name.text.trim(),
          'address': _address.text.trim(),
          'city_code': _city!,
          'category_code': _category!,
        },
      }, _images);
      ref.invalidate(liveContributionsProvider);
      ref.invalidate(adminContributionsProvider);
      if (mounted) {
        setState(() {
          _images = [];
          _message = 'Đã lưu đóng góp, đang chờ Admin duyệt';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(authProvider).isLoggedIn) {
      return Scaffold(
        body: StateMessage(
          icon: Icons.add_photo_alternate_outlined,
          title: 'Đăng nhập để đóng góp',
          message: 'Gửi ảnh menu hoặc hóa đơn để Admin duyệt.',
          actionLabel: 'Đăng nhập để đóng góp',
          onAction:
              widget.onSignIn ??
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthProfileScreen(returnToAction: true),
                ),
              ),
        ),
      );
    }
    if (!kIsWeb && !_formOpen && !widget.historyOnly) return _hub(context);
    final isAdmin = ref.watch(authProvider).role == 'admin';
    final places = isAdmin
        ? ref
              .watch(adminPlacesProvider)
              .whenData(
                (items) => items
                    .map(
                      (p) => (
                        id: p['id'] as String,
                        name:
                            '${p['name']} (${switch (p['publication_state']) {
                              'published' => 'Công khai',
                              'hidden' => 'Đang ẩn',
                              _ => 'Bản nháp',
                            }})',
                      ),
                    )
                    .toList(),
              )
        : ref
              .watch(placesProvider)
              .whenData(
                (items) => items.map((p) => (id: p.id, name: p.name)).toList(),
              );
    final lookups = ref.watch(lookupsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.historyOnly ? 'Đóng góp của tôi' : 'Gửi đóng góp'),
        leading: !kIsWeb && _formOpen && widget.initialPlaceId == null
            ? IconButton(
                tooltip: 'Về Đóng góp',
                icon: const Icon(Icons.arrow_back),
                onPressed: _busy
                    ? null
                    : () => setState(() => _formOpen = false),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!widget.historyOnly) ...[
                const Text(
                  'Ảnh menu chỉ công khai sau khi duyệt. Ảnh hóa đơn giữ riêng; che thông tin cá nhân trước khi gửi.',
                ),
                const SizedBox(height: 24),
                Text(
                  '1. Chọn địa điểm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                places.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => TextButton(
                    onPressed: () {
                      if (isAdmin) {
                        ref.invalidate(adminPlacesProvider);
                      } else {
                        ref.invalidate(placesProvider);
                      }
                    },
                    child: Text('$e — thử lại'),
                  ),
                  data: (data) => DropdownButtonFormField<String>(
                    initialValue:
                        _placeId ?? (kIsWeb || _newPlace ? '' : '__choose__'),
                    decoration: const InputDecoration(labelText: 'Địa điểm'),
                    items: [
                      if (!kIsWeb)
                        const DropdownMenuItem(
                          value: '__choose__',
                          enabled: false,
                          child: Text('Chọn địa điểm'),
                        ),
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Đề xuất địa điểm mới'),
                      ),
                      if (_placeId != null &&
                          !data.any((p) => p.id == _placeId))
                        DropdownMenuItem(
                          value: _placeId,
                          enabled: false,
                          child: const Text('Địa điểm không còn khả dụng'),
                        ),
                      ...data.map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    isExpanded: true,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _placeId = v == '' ? null : v;
                            _newPlace = v == '';
                          }),
                  ),
                ),
                if (_placeId == null && (kIsWeb || _newPlace)) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Tên địa điểm mới',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _address,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  ),
                  const SizedBox(height: 12),
                  lookups.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => TextButton(
                      onPressed: () => ref.invalidate(lookupsProvider),
                      child: Text('$e — thử lại'),
                    ),
                    data: (data) => Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _city,
                          decoration: const InputDecoration(
                            labelText: 'Thành phố',
                          ),
                          items: [
                            for (final item in data['cities'])
                              DropdownMenuItem(
                                value: item['code'] as String,
                                child: Text(item['name'] as String),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _city = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Loại hình',
                          ),
                          items: [
                            for (final item in data['categories'])
                              DropdownMenuItem(
                                value: item['code'] as String,
                                child: Text(item['name'] as String),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _category = v),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Loại ảnh'),
                  items: const [
                    DropdownMenuItem(
                      value: 'menu_photo',
                      child: Text('Ảnh menu'),
                    ),
                    DropdownMenuItem(
                      value: 'bill_photo',
                      child: Text('Ảnh hóa đơn'),
                    ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _kind = v!),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Ngày chụp: ${_captured.day}/${_captured.month}/${_captured.year}',
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _busy
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _captured,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            setState(() => _captured = date);
                          }
                        },
                ),
                const SizedBox(height: 20),
                Text(
                  '2. Thêm ảnh rõ nét',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _kind == 'bill_photo'
                      ? '1–5 ảnh JPG/PNG, mỗi ảnh dưới 10MB. Chụp rõ các khoản và tổng tiền.'
                      : '1–5 ảnh JPG/PNG, mỗi ảnh dưới 10MB. Chụp trọn bảng giá, tránh lóa và mờ.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(camera: true),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  ],
                ),
                for (var index = 0; index < _images.length; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(
                              _images[index].bytes,
                              height: 160,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Không đọc được ảnh. Chọn ảnh JPG/PNG khác.',
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              _images[index].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: 'Bỏ ảnh ${index + 1}',
                              onPressed: _busy
                                  ? null
                                  : () =>
                                        setState(() => _images.removeAt(index)),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : (kIsWeb ? _submit : _reviewSubmission),
                  child: Text(
                    _busy
                        ? 'Đang xử lý ảnh…'
                        : kIsWeb
                        ? 'Gửi đóng góp'
                        : 'Kiểm tra và gửi',
                  ),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _message!,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
              ],
              if (!widget.historyOnly) const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lịch sử đóng góp',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại lịch sử',
                    onPressed: () => ref.invalidate(liveContributionsProvider),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              ref
                  .watch(liveContributionsProvider)
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (data) => Column(
                      children: [
                        if (data.isEmpty) const Text('Chưa có đóng góp'),
                        for (final item in data)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['place_name']),
                            subtitle: Text(
                              '${item['type'] == 'bill_photo' ? 'Ảnh hóa đơn' : 'Ảnh menu'} · ${statusLabel(item['status'])}\nGửi ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['created_at']).toLocal())}${item['rejection_reason'] == '' ? '' : '\n${item['rejection_reason']}'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ref.invalidate(
                                contributionDetailProvider(item['id']),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(id: item['id']),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewSubmission() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_placeId == null && !_newPlace) {
      setState(
        () => _message = 'Chọn địa điểm hoặc đề xuất nơi mới trước khi gửi.',
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message!)));
      return;
    }
    if (_images.isEmpty ||
        (_placeId == null &&
            (_name.text.trim().isEmpty ||
                _address.text.trim().isEmpty ||
                _city == null ||
                _category == null))) {
      setState(
        () => _message = _images.isEmpty
            ? 'Chọn ít nhất một ảnh menu hoặc hóa đơn.'
            : 'Nhập đủ thông tin địa điểm mới.',
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message!)));
      return;
    }
    final knownPlaces = ref.read(placesProvider).valueOrNull ?? [];
    final name = _placeId == null
        ? _name.text.trim()
        : knownPlaces.where((p) => p.id == _placeId).firstOrNull?.name ??
              'Địa điểm đã chọn';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiểm tra trước khi gửi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '${_kind == 'menu_photo' ? 'Ảnh menu' : 'Ảnh hóa đơn'} · ${DateFormat('dd/MM/yyyy').format(_captured)} · ${_images.length} ảnh',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final image in _images)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          image.bytes,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ảnh menu chỉ công khai sau khi duyệt. Hóa đơn gốc chỉ bạn và Admin được xem.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheet, true),
                    child: const Text('Gửi đóng góp'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheet, false),
                    child: const Text('Tiếp tục chỉnh sửa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _submit();
    }
  }

  Widget _hub(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đóng góp')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Một tấm ảnh.\nThêm thông tin hay.',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chia sẻ menu hoặc hóa đơn để mọi người dễ chọn nơi ghé hơn.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Bạn muốn chia sẻ gì?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final kind in ['menu_photo', 'bill_photo']) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                leading: Icon(
                  kind == 'menu_photo'
                      ? Icons.restaurant_menu_rounded
                      : Icons.receipt_long_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                title: Text(
                  kind == 'menu_photo' ? 'Ảnh menu' : 'Ảnh hóa đơn',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    kind == 'menu_photo'
                        ? 'Bổ sung món và giá tham khảo'
                        : 'Góp một ví dụ chi tiêu thực tế',
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () => setState(() {
                  _kind = kind;
                  _formOpen = true;
                }),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: const Icon(Icons.history_rounded),
              title: const Text('Đóng góp của tôi'),
              subtitle: const Text('Theo dõi kết quả kiểm duyệt'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContributeScreen(historyOnly: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ảnh menu chỉ công khai sau khi duyệt. Hóa đơn gốc chỉ bạn và Admin được xem.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String statusLabel(String status) => switch (status) {
  'approved' => 'Đã duyệt',
  'rejected' => 'Bị từ chối',
  _ => 'Chờ Admin duyệt',
};
