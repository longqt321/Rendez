import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/admin/review_screen.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/core/widgets/state_message.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSignIn;
  final String? initialPlaceId;
  const ContributeScreen({super.key, this.onSignIn, this.initialPlaceId});
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
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _placeId = widget.initialPlaceId;
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
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
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
      if (mounted) setState(() => _message = '$error');
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
          title: 'Giúp mọi người biết giá trước khi đi',
          message: 'Chia sẻ ảnh menu hoặc hóa đơn. Đóng góp được kiểm tra trước khi công khai; ảnh hóa đơn luôn giữ riêng.',
          actionLabel: 'Đăng nhập để đóng góp',
          onAction:
              widget.onSignIn ??
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthProfileScreen()),
              ),
        ),
      );
    }
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
      appBar: AppBar(title: const Text('Chia sẻ giá, giúp cả cộng đồng')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Một tấm ảnh, nhiều lựa chọn tốt hơn',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ảnh menu đã duyệt giúp mọi người tham khảo giá. Ảnh hóa đơn giữ riêng; hãy che thông tin cá nhân trước khi gửi.',
                      ),
                    ],
                  ),
                ),
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
                  initialValue: _placeId ?? '',
                  decoration: const InputDecoration(labelText: 'Địa điểm'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Đề xuất địa điểm mới'),
                    ),
                    if (_placeId != null && !data.any((p) => p.id == _placeId))
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
                      : (v) => setState(() => _placeId = v == '' ? null : v),
                ),
              ),
              if (_placeId == null) ...[
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
              const Text(
                '1–5 ảnh JPG/PNG, mỗi ảnh dưới 10MB. Chụp trọn bảng giá, tránh lóa và mờ.',
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
                                : () => setState(() => _images.removeAt(index)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Đang xử lý ảnh…' : 'Gửi đóng góp'),
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
              const Divider(height: 32),
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
                              '${statusLabel(item['status'])}${item['rejection_reason'] == '' ? '' : '\n${item['rejection_reason']}'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewScreen(id: item['id']),
                              ),
                            ),
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
}

String statusLabel(String status) => switch (status) {
  'approved' => 'Đã duyệt',
  'rejected' => 'Bị từ chối',
  _ => 'Chờ Admin duyệt',
};
