import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_models.dart';

class ChatNotifier extends StateNotifier<List<ChatConversation>> {
  ChatNotifier() : super(_initialConversations);

  static final List<ChatConversation> _initialConversations = [
    ChatConversation(
      id: 'conv_1',
      friend: const ChatFriend(
        id: 'friend_1',
        name: 'Minh Anh',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        isOnline: true,
      ),
      lastMessage: 'Quán này cuối tuần đi nhé?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 1,
      messages: [
        ChatMessage(
          id: 'msg_1',
          senderId: 'friend_1',
          text: 'Hôm qua tao thấy quán cafe này view đẹp xỉu!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          isMe: false,
        ),
        ChatMessage(
          id: 'msg_2',
          senderId: 'user_me',
          text: 'Quán nào vậy mày?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          isMe: true,
        ),
        ChatMessage(
          id: 'msg_3',
          senderId: 'friend_1',
          text: 'The Hideout Roastery nè, tao vừa lên kèo:',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
          isMe: false,
          rendezPlan: const RendezPlan(
            id: 'plan_1',
            placeId: 'place_1',
            placeName: 'The Hideout Roastery',
            placeAddress: '72/24 Nguyễn Thị Minh Khai, Hải Châu, Đà Nẵng',
            placeImageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
            priceRange: '38.000đ - 68.000đ',
            meetingTime: 'Tối nay lúc 19:30',
            rsvpStatus: RsvpStatus.pending,
          ),
        ),
      ],
    ),
    ChatConversation(
      id: 'conv_2',
      friend: const ChatFriend(
        id: 'friend_2',
        name: 'Hoàng Nam',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        isOnline: false,
      ),
      lastMessage: 'Ok chốt kèo lúc 20h nhé!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'msg_201',
          senderId: 'user_me',
          text: 'Đi cafe chạy deadline không ông?',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          isMe: true,
        ),
        ChatMessage(
          id: 'msg_202',
          senderId: 'friend_2',
          text: 'Ok chốt kèo lúc 20h nhé!',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isMe: false,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv_3',
      friend: const ChatFriend(
        id: 'friend_3',
        name: 'Linh Đan',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        isOnline: true,
      ),
      lastMessage: 'Menu bên đó giá ổn không cậu?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'msg_301',
          senderId: 'friend_3',
          text: 'Menu bên đó giá ổn không cậu?',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isMe: false,
        ),
      ],
    ),
  ];

  void sendMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user_me',
      text: text.trim(),
      timestamp: DateTime.now(),
      isMe: true,
    );

    state = [
      for (final conv in state)
        if (conv.id == conversationId)
          conv.copyWith(
            lastMessage: text.trim(),
            lastMessageTime: DateTime.now(),
            messages: [...conv.messages, newMsg],
          )
        else
          conv,
    ];
  }

  void sendRendezPlan({
    required String conversationId,
    required RendezPlan plan,
  }) {
    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user_me',
      text: 'Rủ bạn đi ${plan.placeName} (${plan.meetingTime})',
      timestamp: DateTime.now(),
      isMe: true,
      rendezPlan: plan,
    );

    state = [
      for (final conv in state)
        if (conv.id == conversationId)
          conv.copyWith(
            lastMessage: 'Kèo hẹn: ${plan.placeName}',
            lastMessageTime: DateTime.now(),
            messages: [...conv.messages, newMsg],
          )
        else
          conv,
    ];
  }

  void updateRsvpStatus({
    required String conversationId,
    required String messageId,
    required RsvpStatus newStatus,
  }) {
    state = [
      for (final conv in state)
        if (conv.id == conversationId)
          conv.copyWith(
            messages: [
              for (final msg in conv.messages)
                if (msg.id == messageId && msg.rendezPlan != null)
                  msg.copyWith(
                    rendezPlan: msg.rendezPlan!.copyWith(rsvpStatus: newStatus),
                  )
                else
                  msg,
            ],
          )
        else
          conv,
    ];
  }

  void markAsRead(String conversationId) {
    state = [
      for (final conv in state)
        if (conv.id == conversationId) conv.copyWith(unreadCount: 0) else conv,
    ];
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatConversation>>((ref) {
      return ChatNotifier();
    });

final totalUnreadMessagesProvider = Provider<int>((ref) {
  final convs = ref.watch(chatProvider);
  return convs.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
});
