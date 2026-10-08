import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rendez/core/models/place.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/utils/user_location.dart';
import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/utils/currency_formatter.dart';
import 'package:rendez/core/utils/estimates.dart';
import 'package:rendez/features/place_detail/place_detail_screen.dart';

class MapViewWidget extends ConsumerStatefulWidget {
  final List<Place> places;
  const MapViewWidget({super.key, required this.places});
  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> {
  final _controller = MapController();
  String? _selectedId;
  Position? _userPosition;
  LatLngBounds? _bounds;
  bool _dirty = false, _tileError = false, _locating = false;
  int _tileVersion = 0;
  List<Place> get _candidates => widget.places
      .where((p) => validCoordinates(p.latitude, p.longitude))
      .toList();
  LatLng _point(Place p) => LatLng(p.latitude, p.longitude);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.places.any((p) => p.id == _selectedId)) _selectedId = null;
  }

  void _zoom(double delta) {
    _controller.move(
      _controller.camera.center,
      (_controller.camera.zoom + delta).clamp(2, 19),
    );
    setState(() => _dirty = true);
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _userPosition = null;
    });
    try {
      final position = await getCurrentUserPosition();
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _bounds = null;
        _selectedId = null;
        _dirty = true;
      });
      _controller.move(LatLng(position.latitude, position.longitude), 15);
    } catch (error) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không lấy được vị trí. Kiểm tra quyền vị trí rồi thử lại.',
            ),
            action: SnackBarAction(label: 'Thử lại', onPressed: _locate),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    final visible = candidates
        .where((p) => _bounds == null || _bounds!.contains(_point(p)))
        .toList();
    final selected = candidates.where((p) => p.id == _selectedId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: scheme.surface,
          child: TextButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: const Text('© OpenStreetMap contributors'),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              return Stack(
                children: [
                  FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      // World view is the fallback; no inferred venue coordinates.
                      initialCenter: candidates.isEmpty
                          ? const LatLng(0, 0)
                          : _point(candidates.first),
                      initialZoom: candidates.isEmpty ? 2 : 13,
                      initialCameraFit: candidates.length > 1
                          ? CameraFit.bounds(
                              bounds: LatLngBounds.fromPoints(
                                candidates.map(_point).toList(),
                              ),
                              padding: const EdgeInsets.all(64),
                              maxZoom: 15,
                            )
                          : null,
                      maxZoom: 19,
                      onTap: (_, _) => setState(() => _selectedId = null),
                      onPositionChanged: (_, gesture) {
                        if (gesture && !_dirty) setState(() => _dirty = true);
                      },
                      onMapEvent: (event) {
                        if (event is MapEventMoveEnd ||
                            event is MapEventScrollWheelZoom) {
                          if (mounted && !_dirty) setState(() => _dirty = true);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(_tileVersion),
                        urlTemplate: const String.fromEnvironment(
                          'MAP_TILE_URL',
                          defaultValue:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        userAgentPackageName: 'vn.rendez.app',
                        errorTileCallback: (_, _, _) {
                          if (!_tileError) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _tileError = true);
                            });
                          }
                        },
                      ),
                      if (_userPosition != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                _userPosition!.latitude,
                                _userPosition!.longitude,
                              ),
                              radius: _userPosition!.accuracy,
                              useRadiusInMeter: true,
                              color: scheme.primary.withValues(alpha: .15),
                              borderColor: scheme.primary.withValues(alpha: .5),
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 60,
                          size: const Size(48, 48),
                          padding: const EdgeInsets.all(64),
                          markers: [
                            for (final place in visible)
                              Marker(
                                key: ValueKey(place.id),
                                point: _point(place),
                                width: 48,
                                height: 48,
                                child: IconButton.filled(
                                  tooltip: place.name,
                                  style: IconButton.styleFrom(
                                    backgroundColor: place.id == _selectedId
                                        ? scheme.primary
                                        : scheme.surface,
                                    foregroundColor: place.id == _selectedId
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
                                    side: BorderSide(
                                      color: scheme.primary,
                                      width: place.id == _selectedId ? 3 : 1,
                                    ),
                                  ),
                                  onPressed: () =>
                                      setState(() => _selectedId = place.id),
                                  icon: Icon(
                                    place.id == _selectedId
                                        ? Icons.location_on
                                        : Icons.location_on_outlined,
                                  ),
                                ),
                              ),
                          ],
                          builder: (_, markers) => Semantics(
                            label: '${markers.length} địa điểm',
                            button: true,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.onPrimary,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${markers.length}',
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_userPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              key: const ValueKey('user-position'),
                              point: LatLng(
                                _userPosition!.latitude,
                                _userPosition!.longitude,
                              ),
                              width: 48,
                              height: 48,
                              child: Tooltip(
                                message:
                                    'Vị trí của bạn, sai số khoảng ${formatDistance(_userPosition!.accuracy / 1000)}',
                                child: Semantics(
                                  label: 'Vị trí của bạn',
                                  child: Center(
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: scheme.surface,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      children: [
                        IconButton.filled(
                          tooltip: 'Vị trí của tôi',
                          onPressed: _locating ? null : _locate,
                          icon: _locating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : const Icon(Icons.my_location),
                        ),
                        IconButton.filled(
                          tooltip: 'Phóng to',
                          onPressed: () => _zoom(1),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton.filled(
                          tooltip: 'Thu nhỏ',
                          onPressed: () => _zoom(-1),
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                  if (_dirty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: FilledButton(
                        onPressed: () => setState(() {
                          _bounds = _controller.camera.visibleBounds;
                          _dirty = false;
                          _selectedId = null;
                        }),
                        child: const Text('Tìm trong khu vực này'),
                      ),
                    ),
                  if (visible.isEmpty)
                    Positioned(
                      left: 8,
                      right: 64,
                      top: _dirty ? 64 : 8,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            candidates.isEmpty
                                ? 'Chưa có địa điểm có tọa độ'
                                : 'Không có địa điểm trong khu vực này',
                          ),
                        ),
                      ),
                    ),
                  if (_tileError)
                    Positioned(
                      left: 8,
                      top: 112,
                      right: 64,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Không tải được bản đồ.'),
                              TextButton(
                                onPressed: () => setState(() {
                                  _tileError = false;
                                  _tileVersion++;
                                }),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (selected != null)
                    Positioned(
                      bottom: 56,
                      right: 12,
                      left: wide ? null : 12,
                      width: wide ? 350 : null,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * .55,
                        ),
                        child: Card(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selected.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Đóng',
                                        onPressed: () =>
                                            setState(() => _selectedId = null),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  Text(selected.category),
                                  Text(selected.address),
                                  Text(
                                    selected.fullMenu.isEmpty
                                        ? 'Chưa có bảng giá'
                                        : 'Từ ${CurrencyFormatter.format(selected.minPrice)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      FilledButton(
                                        onPressed: () {
                                          ref.invalidate(
                                            placeDetailProvider(selected.id),
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PlaceDetailScreen(
                                                place: selected,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Chi tiết'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => toggleBookmark(
                                          context,
                                          ref,
                                          selected.id,
                                        ),
                                        child: Text(
                                          ref
                                                  .watch(bookmarksProvider)
                                                  .contains(selected.id)
                                              ? 'Bỏ lưu'
                                              : 'Lưu',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
