import 'package:flutter/foundation.dart';

// 1. DTO for the individual notification item
class AppNotification {
  final int id;
  final String userId;
  final String title;
  final String messageBody;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final String? priority;
  final String? type;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.messageBody,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
    this.priority,
    this.type,
    required this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Robust Data Parsing: Merge all potential payload locations
    Map<String, dynamic> robustData = {};

    // 1. Root level keys
    robustData.addAll(json);

    // 2. 'payload' key
    if (json['payload'] != null && json['payload'] is Map) {
      robustData.addAll(Map<String, dynamic>.from(json['payload']));
    }

    // 3. 'data' key
    if (json['data'] != null && json['data'] is Map) {
      robustData.addAll(Map<String, dynamic>.from(json['data']));
    }

    // 🟢 4. 'additionalData' key (Found in your logs!)
    if (json['additionalData'] != null && json['additionalData'] is Map) {
      robustData.addAll(Map<String, dynamic>.from(json['additionalData']));
    }

    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      messageBody: json['messageBody']?.toString() ?? json['body']?.toString() ?? '',
      isRead: (json['isRead'] is bool) ? json['isRead'] : false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
      actionUrl: json['actionUrl']?.toString(),
      priority: json['priority']?.toString(),
      type: json['type']?.toString(), // e.g. "LEAVE_APPROVAL_PENDING"
      data: robustData,
    );
  }

  /// Smart Getter for Leave/Approval ID
  String? get leaveApprovalId {
    // List of keys to check in order of priority
    final candidateKeys = [
      'approvalId',
      'leaveId',
      'requestId',
      'entityId',
      'referenceId'
    ];

    for (var key in candidateKeys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key].toString();
      }
    }

    // Safety check: If we only found 'id', verify it's NOT the notification ID
    if (data.containsKey('id') && data['id'] != null) {
      final potentialId = data['id'].toString();
      if (potentialId != id.toString()) {
        return potentialId;
      }
    }

    return null;
  }
}

// ... (NotificationPage and UnreadCountResponse remain unchanged)
class NotificationPage {
  final List<AppNotification> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

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
      totalElements: json['totalElements'] is int ? json['totalElements'] : 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] : 0,
      size: json['size'] is int ? json['size'] : 20,
      number: json['number'] is int ? json['number'] : 0,
    );
  }
}

class UnreadCountResponse {
  final int unreadCount;
  final String userId;

  UnreadCountResponse({required this.unreadCount, required this.userId});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : 0,
      userId: json['userId']?.toString() ?? '',
    );
  }
}



// // lib/data/models/notification_model.dart
// import 'dart:convert';
//
// // 1. DTO for the individual notification item
// class AppNotification {
//   final int id;
//   final String userId;
//   final String title;
//   final String messageBody;
//   final bool isRead; // Non-nullable bool
//   final DateTime createdAt;
//   final String? actionUrl;
//   final String? priority;
//
//   AppNotification({
//     required this.id,
//     required this.userId,
//     required this.title,
//     required this.messageBody,
//     required this.isRead,
//     required this.createdAt,
//     this.actionUrl,
//     this.priority,
//   });
//
//   factory AppNotification.fromJson(Map<String, dynamic> json) {
//     return AppNotification(
//       id: json['id'] as int,
//       userId: json['userId'] as String,
//       title: json['title'] as String,
//       messageBody: json['messageBody'] as String,
//
//       // 🎯 FIX: Use type checking and null-aware operator to safely handle 'isRead'
//       isRead: (json['isRead'] is bool) ? json['isRead'] as bool : false,
//
//       // Parse ISO 8601 string to DateTime
//       createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
//       actionUrl: json['actionUrl'] as String?,
//       priority: json['priority'] as String?,
//     );
//   }
// }
//
// // 2. DTO for the paginated response (Page<AppNotification>)
// class NotificationPage {
//   final List<AppNotification> content;
//   final int totalElements;
//   final int totalPages;
//   final int size;
//   final int number; // Current page number
//
//   NotificationPage({
//     required this.content,
//     required this.totalElements,
//     required this.totalPages,
//     required this.size,
//     required this.number,
//   });
//
//   factory NotificationPage.fromJson(Map<String, dynamic> json) {
//     final contentList = json['content'] as List<dynamic>? ?? [];
//
//     return NotificationPage(
//       content: contentList
//           .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       totalElements: json['totalElements'] as int,
//       totalPages: json['totalPages'] as int,
//       size: json['size'] as int,
//       number: json['number'] as int,
//     );
//   }
// }
//
// // 3. DTO for the unread count
// class UnreadCountResponse {
//   final int unreadCount;
//   final String userId;
//
//   UnreadCountResponse({required this.unreadCount, required this.userId});
//
//   factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
//     return UnreadCountResponse(
//       unreadCount: json['unreadCount'] as int,
//       userId: json['userId'] as String,
//     );
//   }
// }