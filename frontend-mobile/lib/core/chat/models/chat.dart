class ChatConversation {
  final String id;
  final String solarSurveyId;
  final String propertyAddress;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.solarSurveyId,
    required this.propertyAddress,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id']?.toString() ?? '',
        solarSurveyId: json['solarSurveyId']?.toString() ?? '',
        propertyAddress: json['propertyAddress']?.toString() ?? '',
        otherParticipantId: json['otherParticipantId']?.toString() ?? '',
        otherParticipantName:
            json['otherParticipantName']?.toString() ?? 'Solar support',
        lastMessage: json['lastMessage']?.toString(),
        lastMessageAt:
            DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ??
                DateTime.now(),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    required this.readAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        conversationId: json['conversationId']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
        isMine: json['isMine'] == true,
      );
}
