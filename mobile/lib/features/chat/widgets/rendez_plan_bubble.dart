import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/providers/chat_providers.dart';
import '../../place_detail/place_detail_screen.dart';

class RendezPlanBubble extends ConsumerWidget {
  final String conversationId;
  final String messageId;
  final RendezPlan plan;
  final bool isMe;

  const RendezPlanBubble({
    super.key,
    required this.conversationId,
    required this.messageId,
    required this.plan,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasResponded = plan.rsvpStatus != RsvpStatus.pending;
    final isAccepted = plan.rsvpStatus == RsvpStatus.accepted;

    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAccepted
              ? AppColors.verified.withValues(alpha: 0.5)
              : AppColors.neutral200,
          width: isAccepted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place Cover Image Header
          GestureDetector(
            onTap: () => _openPlaceDetail(context),
            child: Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: plan.placeImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_cafe_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'KÈO HẸN RENDEZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    plan.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Plan Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meeting Time Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 13,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          plan.meetingTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Address & Price
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        plan.placeAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_outlined,
                      size: 13,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dự kiến: ${plan.priceRange}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.neutral200),
                const SizedBox(height: 10),

                // Interactive RSVP Section
                if (hasResponded) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAccepted
                          ? AppColors.verifiedLight
                          : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAccepted
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 16,
                          color: isAccepted
                              ? AppColors.verified
                              : AppColors.neutral500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAccepted
                              ? 'Đã chốt kèo đi quán! 🎉'
                              : 'Bạn bận rồi, hẹn dịp khác',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isAccepted
                                ? AppColors.verified
                                : AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(chatProvider.notifier)
                                .updateRsvpStatus(
                                  conversationId: conversationId,
                                  messageId: messageId,
                                  newStatus: RsvpStatus.accepted,
                                );
                          },
                          child: const Text(
                            'Đi luôn! 🚀',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.neutral600,
                            side: const BorderSide(color: AppColors.neutral300),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(chatProvider.notifier)
                                .updateRsvpStatus(
                                  conversationId: conversationId,
                                  messageId: messageId,
                                  newStatus: RsvpStatus.declined,
                                );
                          },
                          child: const Text(
                            'Bận rồi 🥲',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPlaceDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    // Find place or fallback to first place
    final place = MockData.places.firstWhere(
      (p) => p.id == plan.placeId,
      orElse: () => MockData.places.first,
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)));
  }
}
