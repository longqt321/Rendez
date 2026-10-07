import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/features/admin/review_screen.dart';
import 'package:rendez/features/contribute/contribute_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _showHistory = false;
  @override
  Widget build(BuildContext context) {
    if (ref.watch(authProvider).role != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Chỉ Admin được truy cập')),
      );
    }
    final theme = Theme.of(context);
    final submissions = ref.watch(adminContributionsProvider);
    final places = ref.watch(adminPlacesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Không gian quản trị'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () {
              ref.invalidate(adminPlacesProvider);
              ref.invalidate(adminContributionsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin tốt bắt đầu từ bạn',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đối chiếu ảnh gốc, sửa bản nháp rồi duyệt. Chỉ dữ liệu đã duyệt được công khai.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.fact_check_outlined, size: 18),
                      label: Text(
                        '${submissions.valueOrNull?.where((item) => item['status'] == 'pending_admin').length ?? 0} đóng góp cần duyệt',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.storefront_outlined, size: 18),
                      label: Text(
                        '${places.valueOrNull?.length ?? 0} địa điểm',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showHistory ? 'Đóng góp đã xử lý' : 'Đóng góp cần bạn xem',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Chờ duyệt'),
                selected: !_showHistory,
                onSelected: (_) => setState(() => _showHistory = false),
              ),
              ChoiceChip(
                label: const Text('Đã xử lý'),
                selected: _showHistory,
                onSelected: (_) => setState(() => _showHistory = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          submissions.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => TextButton(
              onPressed: () => ref.invalidate(adminContributionsProvider),
              child: Text('$error · Thử lại'),
            ),
            data: (data) => Column(
              children: [
                if (!data.any(
                  (item) => _showHistory
                      ? item['status'] != 'pending_admin'
                      : item['status'] == 'pending_admin',
                ))
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.task_alt_rounded),
                      title: Text(
                        _showHistory
                            ? 'Chưa có đóng góp đã xử lý'
                            : 'Đã xử lý hết đóng góp',
                      ),
                      subtitle: Text('Những đóng góp mới sẽ xuất hiện ở đây.'),
                    ),
                  ),
                for (final item in data.where(
                  (item) => _showHistory
                      ? item['status'] != 'pending_admin'
                      : item['status'] == 'pending_admin',
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          item['type'] == 'menu_photo'
                              ? Icons.restaurant_menu_rounded
                              : Icons.receipt_long_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(item['place_name']),
                        subtitle: Text(
                          '${item['type'] == 'menu_photo' ? 'Ảnh menu' : 'Ảnh hóa đơn'} · ${statusLabel(item['status'])}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(id: item['id']),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text('Quản lý địa điểm', style: theme.textTheme.titleLarge),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlaceEditor()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tạo địa điểm'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          places.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => TextButton(
              onPressed: () => ref.invalidate(adminPlacesProvider),
              child: Text('$error · Thử lại'),
            ),
            data: (data) => Column(
              children: [
                if (data.isEmpty)
                  const Text(
                    'Chưa có địa điểm. Tạo địa điểm đầu tiên để bắt đầu.',
                  ),
                for (final item in data)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(item['name']),
                        subtitle: Text(
                          '${item['address']} · ${switch (item['publication_state']) {
                            'published' => 'Công khai',
                            'hidden' => 'Đang ẩn',
                            _ => 'Bản nháp',
                          }}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceEditor(place: item),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? place;
  const PlaceEditor({super.key, this.place});
  @override
  ConsumerState<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends ConsumerState<PlaceEditor> {
  late final TextEditingController _name,
      _address,
      _description,
      _hours,
      _lat,
      _lng;
  String? _city, _category;
  String _state = 'published';
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _name = TextEditingController(text: p?['name'] ?? '');
    _address = TextEditingController(text: p?['address'] ?? '');
    _description = TextEditingController(text: p?['description'] ?? '');
    _hours = TextEditingController(text: p?['opening_hours'] ?? '');
    _lat = TextEditingController(text: '${p?['latitude'] ?? ''}');
    _lng = TextEditingController(text: '${p?['longitude'] ?? ''}');
    _city = p?['city_code'];
    _category = p?['category_code'];
    _state = p?['publication_state'] ?? 'published';
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _description, _hours, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool delete = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      if (delete) {
        await api.request('DELETE', '/v1/admin/places/${widget.place!['id']}');
      } else {
        final lat = _lat.text.isEmpty ? null : double.tryParse(_lat.text);
        final lng = _lng.text.isEmpty ? null : double.tryParse(_lng.text);
        if ((_lat.text.isNotEmpty && lat == null) ||
            (_lng.text.isNotEmpty && lng == null)) {
          throw const ApiException('Tọa độ phải là số');
        }
        await api.request(
          widget.place == null ? 'POST' : 'PUT',
          '/v1/admin/places${widget.place == null ? '' : '/${widget.place!['id']}'}',
          {
            'name': _name.text.trim(),
            'address': _address.text.trim(),
            'description': _description.text.trim(),
            'opening_hours': _hours.text.trim(),
            'city_code': _city,
            'category_code': _category,
            'latitude': lat,
            'longitude': lng,
            'publication_state': _state,
          },
        );
      }
      ref.invalidate(adminPlacesProvider);
      ref.invalidate(placesProvider);
      if (widget.place != null) {
        ref.invalidate(placeDetailProvider(widget.place!['id']));
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ref.watch(authProvider).role != 'admin'
      ? const Scaffold(body: Center(child: Text('Chỉ Admin được truy cập')))
      : Scaffold(
          appBar: AppBar(
            title: Text(widget.place == null ? 'Tạo địa điểm' : 'Sửa địa điểm'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final field in [
                (controller: _name, label: 'Tên địa điểm'),
                (controller: _address, label: 'Địa chỉ'),
                (controller: _description, label: 'Mô tả'),
                (controller: _hours, label: 'Giờ mở cửa'),
                (controller: _lat, label: 'Vĩ độ (có thể để trống)'),
                (controller: _lng, label: 'Kinh độ (có thể để trống)'),
              ])
                TextField(
                  controller: field.controller,
                  enabled: !_busy,
                  decoration: InputDecoration(labelText: field.label),
                ),
              ref
                  .watch(lookupsProvider)
                  .when(
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
                            for (final i in data['cities'])
                              DropdownMenuItem(
                                value: i['code'] as String,
                                child: Text(i['name']),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _city = v),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Loại hình',
                          ),
                          items: [
                            for (final i in data['categories'])
                              DropdownMenuItem(
                                value: i['code'] as String,
                                child: Text(i['name']),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _category = v),
                        ),
                      ],
                    ),
                  ),
              DropdownButtonFormField<String>(
                initialValue: _state,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Công khai'),
                  ),
                  DropdownMenuItem(value: 'draft', child: Text('Nháp')),
                  DropdownMenuItem(value: 'hidden', child: Text('Ẩn')),
                ],
                onChanged: _busy ? null : (v) => setState(() => _state = v!),
              ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Lưu địa điểm'),
              ),
              if (widget.place != null)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xóa địa điểm khỏi danh sách?'),
                              content: const Text(
                                'Giữ dữ liệu lịch sử và các đóng góp đã xử lý.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) _save(delete: true);
                        },
                  child: const Text('Xóa địa điểm'),
                ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
            ],
          ),
        );
}
