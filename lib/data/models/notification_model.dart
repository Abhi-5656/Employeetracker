// lib/data/models/notification_model.dart
import 'dart:convert';

// 1. DTO for the individual notification item
class AppNotification {
  final int id;
  final String userId;
  final String title;
  final String messageBody;
  final bool isRead; // Non-nullable bool
  final DateTime createdAt;
  final String? actionUrl;
  final String? priority;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.messageBody,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
    this.priority,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['userId'] as String,
      title: json['title'] as String,
      messageBody: json['messageBody'] as String,

      // 🎯 FIX: Use type checking and null-aware operator to safely handle 'isRead'
      isRead: (json['isRead'] is bool) ? json['isRead'] as bool : false,

      // Parse ISO 8601 string to DateTime
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      actionUrl: json['actionUrl'] as String?,
      priority: json['priority'] as String?,
    );
  }
}

// 2. DTO for the paginated response (Page<AppNotification>)
class NotificationPage {
  final List<AppNotification> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number; // Current page number

  NotificationPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];

    return NotificationPage(
      content: contentList
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      size: json['size'] as int,
      number: json['number'] as int,
    );
  }
}

// 3. DTO for the unread count
class UnreadCountResponse {
  final int unreadCount;
  final String userId;

  UnreadCountResponse({required this.unreadCount, required this.userId});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unreadCount'] as int,
      userId: json['userId'] as String,
    );
  }
}