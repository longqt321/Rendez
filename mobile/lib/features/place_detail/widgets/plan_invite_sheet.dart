import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/models/place.dart';
import '../../../../core/providers/chat_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../chat/chat_conversation_screen.dart';

class PlanInviteSheet extends ConsumerStatefulWidget {
  final Place place;

  const PlanInviteSheet({super.key, required this.place});

  @override
  ConsumerState<PlanInviteSheet> createState() => _PlanInviteSheetState();
}

class _PlanInviteSheetState extends ConsumerState<PlanInviteSheet> {
  String? _selectedConversationId;
  int _selectedTimeIndex = 0;

  final List<String> _timeOptions = [
    'Tối nay lúc 19:30',
    'Trưa mai lúc 12:00',
    'Cuối tuần này (Thứ 7)',
    'Cuối tuần này (Chủ Nhật)',
  ];

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(chatProvider);
    _selectedConversationId ??= conversations.isNotEmpty
        ? conversations.first.id
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lên Kèo Hẹn Rendez',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                    Text(
                      'Rủ bạn bè đi ${widget.place.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 1. Choose Friend to Invite
          const Text(
            'CHỌN BẠN BÈ ĐỂ RỦ:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final isSelected = conv.id == _selectedConversationId;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedConversationId = conv.id);
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: CachedNetworkImageProvider(
                                conv.friend.avatarUrl,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 52,
                        child: Text(
                          conv.friend.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.neutral800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 2. Choose Meeting Time
          const Text(
            'THỜI GIAN HẸN:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_timeOptions.length, (idx) {
              final isSelected = _selectedTimeIndex == idx;
              return ChoiceChip(
                label: Text(
                  _timeOptions[idx],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.neutral800,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.neutral100,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTimeIndex = idx);
                },
              );
            }),
          ),

          const SizedBox(height: 24),

          // 3. Action Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _selectedConversationId == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      final plan = RendezPlan(
                        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
                        placeId: widget.place.id,
                        placeName: widget.place.name,
                        placeAddress: widget.place.address,
                        placeImageUrl: widget.place.coverImageUrl,
                        priceRange: CurrencyFormatter.formatRange(
                          widget.place.minPrice,
                          widget.place.maxPrice,
                        ),
                        meetingTime: _timeOptions[_selectedTimeIndex],
                        rsvpStatus: RsvpStatus.pending,
                      );

                      ref
                          .read(chatProvider.notifier)
                          .sendRendezPlan(
                            conversationId: _selectedConversationId!,
                            plan: plan,
                          );

                      Navigator.pop(context); // Close bottom sheet
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            conversationId: _selectedConversationId!,
                          ),
                        ),
                      );
                    },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Gửi Kèo Hẹn Vào Hộp Thư 🚀',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
