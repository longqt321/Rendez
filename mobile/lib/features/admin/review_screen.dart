import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/utils/currency_formatter.dart';
import 'package:rendez/core/widgets/api_image.dart';
import 'package:rendez/core/widgets/state_message.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String id;
  const ReviewScreen({super.key, required this.id});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _reason = TextEditingController();
  final _total = TextEditingController();
  final _guests = TextEditingController();
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
      if (mounted) {
        setState(
          () => _error = !kIsWeb && error is ApiException && error.status == 409
              ? 'Đóng góp này đã được xử lý. Tải lại dữ liệu trước khi tiếp tục.'
              : '$error',
        );
      }
      ref.invalidate(contributionDetailProvider(widget.id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(String action, Map<String, dynamic> data) async {
    if (kIsWeb || action == 'draft') {
      await _action(action, data);
      return;
    }
    if (action == 'rejected' && _reason.text.trim().isEmpty) {
      setState(
        () => _error = 'Nhập lý do để người gửi biết cần cải thiện điều gì.',
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          action == 'approved'
              ? 'Duyệt đóng góp này?'
              : action == 'rejected'
              ? 'Từ chối đóng góp?'
              : 'Đọc lại nội dung ảnh?',
        ),
        content: Text(
          action == 'approved'
              ? 'Dữ liệu được phép sẽ công khai. Quyết định này không thể đảo ngược.'
              : action == 'rejected'
              ? 'Người gửi sẽ nhận lý do từ chối. Quyết định này không thể đảo ngược.'
              : 'Kết quả đọc lại sẽ thay nội dung đang sửa. Lưu bản nháp trước nếu cần giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: action == 'rejected'
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(
              action == 'approved'
                  ? 'Phê duyệt'
                  : action == 'rejected'
                  ? 'Từ chối'
                  : 'Đọc lại ảnh',
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _action(action, data);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) _loaded = false;
    });
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(),
        body: StateMessage(
          icon: Icons.receipt_long_outlined,
          title: 'Đăng nhập để xem đóng góp',
          message: '',
          actionLabel: 'Đăng nhập',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AuthProfileScreen(returnToAction: true),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đóng góp')),
      body: ref
          .watch(contributionDetailProvider(widget.id))
          .when(
            skipLoadingOnRefresh: false,
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
                _guests.text = '${data['guests_count'] ?? ''}';
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
                      onPressed: _busy ? null : () => _confirm('ocr', data),
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
                            const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reason,
                      enabled: !_busy,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Lý do từ chối (bắt buộc nếu từ chối)',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              : () => _confirm('approved', data),
                          child: const Text('Phê duyệt'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _confirm('rejected', data),
                          style: !kIsWeb
                              ? OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .error,
                                )
                              : null,
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
              final content = canReview
                  ? editor
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['status'] == 'approved'
                              ? 'Nội dung đã duyệt'
                              : 'Bản đọc từ ảnh · chưa duyệt',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (data['type'] == 'menu_photo') ...[
                          if ((data['draft_items'] as List).isEmpty)
                            const Text('Chưa đọc được bảng giá từ ảnh'),
                          for (final row in data['draft_items'])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(row['name']),
                              subtitle: Text(
                                '${CurrencyFormatter.format(row['price'] as int)} · ${row['category']}',
                              ),
                            ),
                        ] else ...[
                          Text(
                            data['bill_total'] == null
                                ? 'Chưa có tổng tiền'
                                : 'Tổng hóa đơn: ${CurrencyFormatter.format(data['bill_total'] as int)}',
                          ),
                          Text(
                            data['guests_count'] == null
                                ? 'Chưa có số khách'
                                : 'Số khách: ${data['guests_count']}',
                          ),
                        ],
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if ((data['ocr_error'] as String).isNotEmpty)
                          const Text(
                            'Chưa đọc được ảnh. Admin sẽ kiểm tra thủ công.',
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
                    'Ngày chụp: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(data['captured_at']).toLocal())}',
                  ),
                  if (data['reviewed_at'] != null)
                    Text(
                      'Admin xử lý: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(data['reviewed_at']).toLocal())}',
                    ),
                  if ((data['rejection_reason'] as String).isNotEmpty)
                    Text('Lý do: ${data['rejection_reason']}'),
                  if (!kIsWeb) ...[const SizedBox(height: 12), const Divider()],
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth > 700
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: images),
                              const SizedBox(width: 24),
                              Expanded(child: content),
                            ],
                          )
                        : Column(children: [images, content]),
                  ),
                ],
              );
            },
          ),
    );
  }
}
