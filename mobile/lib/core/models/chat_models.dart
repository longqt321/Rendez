enum RsvpStatus { pending, accepted, declined }

class RendezPlan {
  final String id;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final String placeImageUrl;
  final String priceRange;
  final String meetingTime;
  final RsvpStatus rsvpStatus;

  const RendezPlan({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.placeImageUrl,
    required this.priceRange,
    required this.meetingTime,
    this.rsvpStatus = RsvpStatus.pending,
  });

  RendezPlan copyWith({
    String? id,
    String? placeId,
    String? placeName,
    String? placeAddress,
    String? placeImageUrl,
    String? priceRange,
    String? meetingTime,
    RsvpStatus? rsvpStatus,
  }) {
    return RendezPlan(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      placeImageUrl: placeImageUrl ?? this.placeImageUrl,
      priceRange: priceRange ?? this.priceRange,
      meetingTime: meetingTime ?? this.meetingTime,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final RendezPlan? rendezPlan;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.rendezPlan,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    RendezPlan? rendezPlan,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      rendezPlan: rendezPlan ?? this.rendezPlan,
    );
  }
}

class ChatFriend {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;

  const ChatFriend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isOnline = true,
  });
}

class ChatConversation {
  final String id;
  final ChatFriend friend;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.id,
    required this.friend,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.messages,
  });

  ChatConversation copyWith({
    String? id,
    ChatFriend? friend,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<ChatMessage>? messages,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      friend: friend ?? this.friend,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }
}
