class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? actionUrl;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification(
      {required this.id,
      required this.type,
      required this.title,
      required this.message,
      required this.actionUrl,
      required this.entityType,
      required this.entityId,
      required this.isRead,
      required this.createdAt});

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
          id: json['id']?.toString() ?? '',
          type: json['type']?.toString() ?? '',
          title: json['title']?.toString() ?? 'Notification',
          message: json['message']?.toString() ?? '',
          actionUrl: json['actionUrl']?.toString(),
          entityType: json['entityType']?.toString(),
          entityId: json['entityId']?.toString(),
          isRead: json['isRead'] == true,
          createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now());
}
