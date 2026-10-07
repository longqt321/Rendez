import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/widgets/api_image.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String id;
  const ReviewScreen({super.key, required this.id});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _reason = TextEditingController();
  final _total = TextEditingController();
  final _guests = TextEditingController(text: '1');
  final List<
    ({
      TextEditingController name,
      TextEditingController price,
      TextEditingController category,
    })
  >
  _items = [];
  bool _loaded = false, _busy = false;
  String? _error;
  void _clearItems() {
    for (final row in _items) {
      row.name.dispose();
      row.price.dispose();
      row.category.dispose();
    }
    _items.clear();
  }

  void _add([Map<String, dynamic>? item]) {
    _items.add((
      name: TextEditingController(text: item?['name'] ?? ''),
      price: TextEditingController(text: '${item?['price'] ?? ''}'),
      category: TextEditingController(text: item?['category'] ?? 'Menu'),
    ));
  }

  @override
  void dispose() {
    _clearItems();
    _reason.dispose();
    _total.dispose();
    _guests.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _menu() => _items.map((row) {
    final price = int.tryParse(row.price.text);
    if (row.name.text.trim().isEmpty || price == null || price < 0) {
      throw const ApiException('Mỗi món cần tên và giá hợp lệ');
    }
    return {
      'name': row.name.text.trim(),
      'price': price,
      'category': row.category.text.trim(),
    };
  }).toList();
  Future<void> _action(String action, Map<String, dynamic> data) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      if (action == 'ocr') {
        await api.request('POST', '/v1/admin/contributions/${widget.id}/ocr');
        _loaded = false;
      } else {
        if (action == 'approved' &&
            data['type'] == 'menu_photo' &&
            _items.isEmpty) {
          throw const ApiException('Thêm ít nhất một món trước khi duyệt');
        }
        await api.request(
          action == 'draft' ? 'PUT' : 'POST',
          '/v1/admin/contributions/${widget.id}/${action == 'draft' ? 'draft' : 'review'}',
          {
            if (action != 'draft') 'decision': action,
            if (action != 'draft') 'reason': _reason.text.trim(),
            'items': action != 'rejected' && data['type'] == 'menu_photo'
                ? _menu()
                : <Map<String, dynamic>>[],
            if (action != 'rejected' && data['type'] == 'bill_photo') ...{
              'bill_total': int.tryParse(_total.text),
              'guests_count': int.tryParse(_guests.text),
            },
          },
        );
      }
      ref.invalidate(contributionDetailProvider(widget.id));
      ref.invalidate(adminContributionsProvider);
      ref.invalidate(liveContributionsProvider);
      ref.invalidate(adminPlacesProvider);
      ref.invalidate(placesProvider);
      ref.invalidate(placeDetailProvider(data['place_id'] as String));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'draft'
                  ? 'Đã lưu bản nháp'
                  : action == 'ocr'
                  ? 'Đã đọc lại nội dung ảnh'
                  : 'Đã lưu quyết định',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
      ref.invalidate(contributionDetailProvider(widget.id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Đăng nhập để xem đóng góp')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đóng góp')),
      body: ref
          .watch(contributionDetailProvider(widget.id))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(contributionDetailProvider(widget.id)),
                child: Text('$e — thử lại'),
              ),
            ),
            data: (data) {
              if (!_loaded) {
                _clearItems();
                for (final item in data['draft_items'] as List) {
                  _add(Map<String, dynamic>.from(item));
                }
                _total.text = '${data['bill_total'] ?? ''}';
                _guests.text = '${data['guests_count'] ?? 1}';
                _loaded = true;
              }
              final canReview =
                  auth.role == 'admin' && data['status'] == 'pending_admin';
              final images = Column(
                children: [
                  for (final image in data['images'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ApiImage(path: image['url']),
                    ),
                ],
              );
              final editor = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nội dung được đọc từ ảnh có thể chưa chính xác. Đối chiếu và sửa trước khi duyệt.',
                  ),
                  if ((data['ocr_error'] as String).isNotEmpty)
                    Text(
                      'Chưa đọc được nội dung ảnh. Bạn có thể nhập nội dung hoặc thử đọc lại.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ExpansionTile(
                    title: const Text('Nội dung đọc từ ảnh'),
                    children: [SelectableText(data['ocr_text'] as String)],
                  ),
                  if (canReview)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _action('ocr', data),
                      child: const Text('Đọc lại ảnh (thay nội dung đang sửa)'),
                    ),
                  if (data['type'] == 'menu_photo') ...[
                    for (var index = 0; index < _items.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _items[index].name,
                              enabled: canReview && !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Tên món',
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _items[index].price,
                                    enabled: canReview && !_busy,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Giá VNĐ',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _items[index].category,
                                    enabled: canReview && !_busy,
                                    decoration: const InputDecoration(
                                      labelText: 'Nhóm',
                                    ),
                                  ),
                                ),
                                if (canReview)
                                  IconButton(
                                    tooltip: 'Bỏ dòng',
                                    onPressed: _busy
                                        ? null
                                        : () => setState(() {
                                            final row = _items.removeAt(index);
                                            row.name.dispose();
                                            row.price.dispose();
                                            row.category.dispose();
                                          }),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (canReview)
                      TextButton.icon(
                        onPressed: _busy ? null : () => setState(() => _add()),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm món'),
                      ),
                  ] else ...[
                    TextField(
                      controller: _total,
                      enabled: canReview && !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tổng tiền hóa đơn (VNĐ)',
                      ),
                    ),
                    TextField(
                      controller: _guests,
                      enabled: canReview && !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số khách'),
                    ),
                    const Text(
                      'Hóa đơn là ví dụ chi tiêu lịch sử; không biến tổng tiền thành đơn giá menu.',
                    ),
                  ],
                  if (canReview) ...[
                    TextField(
                      controller: _reason,
                      enabled: !_busy,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Lý do từ chối (bắt buộc nếu từ chối)',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _action('draft', data),
                          child: const Text('Lưu bản nháp'),
                        ),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _action('approved', data),
                          child: const Text('Phê duyệt'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _action('rejected', data),
                          child: const Text('Từ chối'),
                        ),
                      ],
                    ),
                  ],
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              );
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    data['place_name'],
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Trạng thái: ${switch (data['status']) {
                      'approved' => 'Đã duyệt',
                      'rejected' => 'Bị từ chối',
                      _ => 'Chờ Admin duyệt',
                    }}',
                  ),
                  Text(
                    'Ngày chụp: ${DateTime.parse(data['captured_at']).toLocal().toString().split(' ').first}',
                  ),
                  if ((data['rejection_reason'] as String).isNotEmpty)
                    Text('Lý do: ${data['rejection_reason']}'),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth > 700
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: images),
                              const SizedBox(width: 24),
                              Expanded(child: editor),
                            ],
                          )
                        : Column(children: [images, editor]),
                  ),
                ],
              );
            },
          ),
    );
  }
}
