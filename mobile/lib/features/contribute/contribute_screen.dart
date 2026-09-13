import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import 'widgets/add_place_dialog.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeItem {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _ContributeItem({String name = '', String price = ''})
    : nameController = TextEditingController(text: name),
      priceController = TextEditingController(text: price);

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  String _selectedPlaceName = 'The Hideout Roastery';
  String _selectedPlaceAddress =
      '72/24 Nguyễn Thị Minh Khai, Hải Châu, Đà Nẵng';
  int _guestsCount = 2;
  bool _hasBillPhoto = true;

  final List<_ContributeItem> _items = [
    _ContributeItem(name: 'Cold Brew Cam Sả', price: '55000'),
    _ContributeItem(name: 'Latte Hạnh Nhân Nóng', price: '48000'),
    _ContributeItem(name: 'Bánh Croissant Bơ Pháp', price: '35000'),
  ];

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _totalAmount {
    int sum = 0;
    for (final item in _items) {
      final p =
          int.tryParse(
            item.priceController.text
                .replaceAll('.', '')
                .replaceAll('đ', '')
                .trim(),
          ) ??
          0;
      sum += p;
    }
    return sum;
  }

  int get _costPerPerson =>
      _guestsCount > 0 ? (_totalAmount / _guestsCount).round() : _totalAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Đóng Góp Hóa Đơn & Giá'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Place Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ĐỊA ĐIỂM BẠN ĐÃ TRẢI NGHIỆM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neutral500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddPlaceDialog(
                              onPlaceAdded: (name, addr) {
                                setState(() {
                                  _selectedPlaceName = name;
                                  _selectedPlaceAddress = addr;
                                });
                              },
                            ),
                          );
                        },
                        child: const Text(
                          '+ Thêm quán mới',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue:
                        MockData.places.any((p) => p.name == _selectedPlaceName)
                        ? _selectedPlaceName
                        : null,
                    hint: Text(
                      _selectedPlaceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral900,
                      ),
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    items: MockData.places.map((p) {
                      return DropdownMenuItem(
                        value: p.name,
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = MockData.places.firstWhere(
                          (p) => p.name == val,
                        );
                        setState(() {
                          _selectedPlaceName = found.name;
                          _selectedPlaceAddress = found.address;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.neutral500,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _selectedPlaceAddress,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bill Photo Uploader
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ẢNH CHỤP HÓA ĐƠN GỐC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() => _hasBillPhoto = !_hasBillPhoto);
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasBillPhoto
                              ? AppColors.verified
                              : AppColors.neutral300,
                          width: _hasBillPhoto ? 2 : 1,
                        ),
                      ),
                      child: _hasBillPhoto
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=600&auto=format&fit=crop&q=80',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Chạm để đổi ảnh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: AppColors.neutral400,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Chụp hoặc tải ảnh hóa đơn rõ ràng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                                Text(
                                  'OCR sẽ tự động đọc món và giá tiền',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.neutral400,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Number of guests counter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số người cùng đi trải nghiệm',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral900,
                        ),
                      ),
                      Text(
                        'Dùng để tính mức chi phí trung bình / người',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.neutral100,
                        ),
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () {
                          if (_guestsCount > 1) {
                            setState(() => _guestsCount--);
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_guestsCount',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.neutral100,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => setState(() => _guestsCount++),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Items breakdown editor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BẢNG MÓN ĂN & GIÁ TIỀN BÓC TÁCH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neutral500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _items.add(_ContributeItem());
                          });
                        },
                        child: const Text(
                          '+ Thêm món',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: item.nameController,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Tên món...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: item.priceController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Giá (VNĐ)',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.neutral400,
                              ),
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(idx);
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Realtime calculation box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chi phí / người:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.neutral600,
                              ),
                            ),
                            Text(
                              '~${CurrencyFormatter.format(_costPerPerson)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Tổng cộng hóa đơn:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.neutral600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(_totalAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final newContrib = UserContribution(
                    id: 'contrib_${DateTime.now().millisecondsSinceEpoch}',
                    placeName: _selectedPlaceName,
                    placeAddress: _selectedPlaceAddress,
                    date: DateTime.now(),
                    totalAmount: _totalAmount,
                    status: ContributionStatus.pending,
                  );

                  ref
                      .read(contributionsProvider.notifier)
                      .addContribution(newContrib);

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.verified,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đóng Góp Thành Công!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Hóa đơn quán "$_selectedPlaceName" với số tiền ${CurrencyFormatter.format(_totalAmount)} đã được gửi lên hệ thống. Dữ liệu sẽ xuất hiện chính thức sau khi đối soát xong.',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Đồng ý',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Gửi Đóng Góp Lên Hệ Thống',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
