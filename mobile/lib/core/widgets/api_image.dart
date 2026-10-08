import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendez/core/providers/app_providers.dart';

class ApiImage extends ConsumerStatefulWidget {
  final String path;
  const ApiImage({super.key, required this.path});
  @override
  ConsumerState<ApiImage> createState() => _ApiImageState();
}

class _ApiImageState extends ConsumerState<ApiImage> {
  late Future<Uint8List> _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bytes = ref.read(apiProvider).image(widget.path);
  }

  @override
  void didUpdateWidget(covariant ApiImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(_load),
          child: const Text('Ảnh lỗi — thử lại'),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Semantics(
        label: 'Xem ảnh nguồn',
        button: true,
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => !kIsWeb
                ? Dialog.fullscreen(
                    backgroundColor: const Color(0xFF101813),
                    child: SafeArea(
                      child: Stack(
                        children: [
                          Center(
                            child: InteractiveViewer(
                              minScale: .5,
                              maxScale: 5,
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton.filled(
                              tooltip: 'Đóng ảnh',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Dialog(
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton.filled(
                            tooltip: 'Đóng ảnh',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          child: Image.memory(snapshot.data!, height: 220, fit: BoxFit.contain),
        ),
      );
    },
  );
}
