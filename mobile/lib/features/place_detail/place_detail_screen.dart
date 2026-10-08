import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/utils/currency_formatter.dart';
import 'package:rendez/core/utils/estimates.dart';
import 'package:rendez/core/widgets/api_image.dart';
import 'package:rendez/core/widgets/state_message.dart';
import 'package:rendez/features/contribute/contribute_screen.dart';

class PlaceDetailScreen extends ConsumerWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(place.name),
      actions: [
        IconButton(
          tooltip: 'Lưu địa điểm',
          icon: Icon(
            ref.watch(bookmarksProvider).contains(place.id)
                ? Icons.favorite
                : Icons.favorite_border,
          ),
          onPressed: () => toggleBookmark(context, ref, place.id),
        ),
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => ref.invalidate(placeDetailProvider(place.id)),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ref
        .watch(placeDetailProvider(place.id))
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => StateMessage(
            icon: Icons.storefront_outlined,
            title: 'Chưa xem được địa điểm',
            message: '$error',
            actionLabel: 'Thử lại',
            onAction: () => ref.invalidate(placeDetailProvider(place.id)),
          ),
          data: (detail) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(detail.category),
                              avatar: const Icon(
                                Icons.storefront_outlined,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          detail.address,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.openHours.isEmpty
                              ? 'Chưa cập nhật giờ mở cửa'
                              : 'Giờ mở cửa: ${detail.openHours}',
                        ),
                        if (detail.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(detail.description),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  DistancePanel(place: detail),
                  const SizedBox(height: 24),
                  Text(
                    'Bảng giá',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (detail.fullMenu.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Chưa có bảng giá.'),
                      ),
                    ),
                  if (detail.fullMenu.isNotEmpty)
                    CostPanel(
                      key: ValueKey('${detail.id}:${detail.priceUpdatedAt}'),
                      place: detail,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Giá tham khảo theo nguồn đã gửi, có thể thay đổi. Không gồm phí dịch vụ và di chuyển.',
                  ),
                  if (detail.galleryImages.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Ảnh menu nguồn'),
                      children: [
                        for (final path in detail.galleryImages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ApiImage(path: path),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (buttonContext) => OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Chia sẻ địa điểm'),
                      onPressed: () async {
                        final text =
                            '${detail.name}\n${detail.address}\nRendez';
                        final box =
                            buttonContext.findRenderObject() as RenderBox;
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              text: text,
                              mailToFallbackEnabled: false,
                              sharePositionOrigin:
                                  box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        } catch (_) {
                          try {
                            await Clipboard.setData(ClipboardData(text: text));
                            if (buttonContext.mounted) {
                              ScaffoldMessenger.of(buttonContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã sao chép thông tin địa điểm',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (buttonContext.mounted) {
                              ScaffoldMessenger.of(buttonContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Chưa chia sẻ được. Hãy thử lại.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ContributeScreen(initialPlaceId: detail.id),
                      ),
                    ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Gửi menu hoặc hóa đơn'),
                  ),
                  if (detail.billExamples.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Ví dụ chi tiêu từ hóa đơn đã duyệt',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final bill in detail.billExamples)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${CurrencyFormatter.format(bill['total'] as int)} / ${bill['guests']} khách',
                        ),
                        subtitle: Text(
                          'Khoảng ${CurrencyFormatter.format(((bill['total'] as int) / (bill['guests'] as int)).round())} / người · Ảnh chụp ${DateFormat('dd/MM/yyyy').format(DateTime.parse(bill['captured_at']).toLocal())}',
                        ),
                      ),
                    const Text(
                      'Chi tiêu lịch sử, không phải đơn giá menu hoặc dự báo cho chuyến đi mới.',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
  );
}

class CostPanel extends StatefulWidget {
  final Place place;
  const CostPanel({super.key, required this.place});
  @override
  State<CostPanel> createState() => _CostPanelState();
}

class _CostPanelState extends State<CostPanel> {
  final Map<String, int> _quantities = {};
  int _party = 1;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.place.fullMenu.fold<int>(
      0,
      (sum, item) =>
          sum +
          item.price *
              (_quantities[item.id.isEmpty ? item.name : item.id] ?? 0),
    );
    final selected = _quantities.values.any((v) => v > 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn số lượng món để dự trù chi phí'),
            const SizedBox(height: 12),
            for (final item in widget.place.fullMenu) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    Text(
                      item.observedAt == null
                          ? 'Chưa có ngày ghi nhận giá'
                          : 'Ghi nhận ${item.observedAt!.toLocal().day}/${item.observedAt!.toLocal().month}/${item.observedAt!.toLocal().year}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.reviewedAt != null)
                      Text(
                        'Admin duyệt ${item.reviewedAt!.toLocal().day}/${item.reviewedAt!.toLocal().month}/${item.reviewedAt!.toLocal().year}',
                        style: theme.textTheme.bodySmall,
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(item.price),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                item.category,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Giảm ${item.name}',
                          onPressed:
                              (_quantities[item.id.isEmpty
                                          ? item.name
                                          : item.id] ??
                                      0) ==
                                  0
                              ? null
                              : () => setState(
                                  () =>
                                      _quantities[item.id.isEmpty
                                              ? item.name
                                              : item.id] =
                                          (_quantities[item.id.isEmpty
                                                  ? item.name
                                                  : item.id] ??
                                              0) -
                                          1,
                                ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${_quantities[item.id.isEmpty ? item.name : item.id] ?? 0}',
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          tooltip: 'Thêm ${item.name}',
                          onPressed:
                              (_quantities[item.id.isEmpty
                                          ? item.name
                                          : item.id] ??
                                      0) >=
                                  99
                              ? null
                              : () => setState(
                                  () =>
                                      _quantities[item.id.isEmpty
                                              ? item.name
                                              : item.id] =
                                          (_quantities[item.id.isEmpty
                                                  ? item.name
                                                  : item.id] ??
                                              0) +
                                          1,
                                ),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Số người (chia đều)')),
                IconButton(
                  tooltip: 'Giảm số người',
                  onPressed: _party > 1 ? () => setState(() => _party--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_party', style: theme.textTheme.titleMedium),
                IconButton(
                  tooltip: 'Thêm người',
                  onPressed: _party < 100
                      ? () => setState(() => _party++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                selected
                    ? 'Tổng dự kiến: ${CurrencyFormatter.format(total)} · khoảng ${CurrencyFormatter.format((total / _party).round())} / người'
                    : 'Chưa chọn món để tính chi phí',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DistancePanel extends StatefulWidget {
  final Place place;
  const DistancePanel({super.key, required this.place});
  @override
  State<DistancePanel> createState() => _DistancePanelState();
}

class _DistancePanelState extends State<DistancePanel> {
  double? _distance;
  bool _busy = false;
  String? _error;

  Future<void> _gps() async {
    setState(() {
      _busy = true;
      _error = null;
      _distance = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiException(
          'Bật vị trí trên thiết bị để xem khoảng cách từ bạn.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ApiException(
          'Cho phép Rendez dùng vị trí để xem khoảng cách từ bạn.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      final distance = distanceKm(
        position.latitude,
        position.longitude,
        widget.place.latitude,
        widget.place.longitude,
      );
      setState(() {
        _distance = distance;
        _error = distance == null
            ? 'Chưa có thông tin khoảng cách cho địa điểm này.'
            : null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa xác định được vị trí của bạn. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!validCoordinates(widget.place.latitude, widget.place.longitude)) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.near_me_outlined),
          title: Text('Chưa có thông tin khoảng cách cho địa điểm này.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.near_me_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cách bạn bao xa?',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_distance != null) ...[
              Text(
                'Khoảng ${formatDistance(_distance!)} từ bạn',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('Khoảng cách ước tính'),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _busy ? null : _gps,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(
                _busy
                    ? 'Đang tìm vị trí…'
                    : _distance == null
                    ? 'Xem khoảng cách từ bạn'
                    : 'Cập nhật khoảng cách',
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
