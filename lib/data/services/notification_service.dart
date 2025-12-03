import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';
import 'http_client.dart';
import 'routes.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Listens to the list of notifications for the UI
  final ValueNotifier<List<AppNotification>> notificationsNotifier = ValueNotifier([]);

  /// Listens to the unread count for the badge
  final ValueNotifier<int> badgeNotifier = ValueNotifier<int>(0);

  String _requireUserId() {
    final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: userId (employeeId) not available.');
    }
    return id;
  }

  /// Called by InboxScreen to load the list and update the UI
  Future<void> fetchNotifications({int page = 0, int size = 20}) async {
    try {
      final pageData = await fetchInbox(page: page, size: size);
      // 🟢 CRITICAL: Update the notifier so the UI rebuilds
      notificationsNotifier.value = pageData.content;
    } catch (e) {
      debugPrint('Error loading notifications for UI: $e');
      notificationsNotifier.value = [];
    }
  }

  /// Internal fetch method
  Future<NotificationPage> fetchInbox({int page = 0, int size = 20}) async {
    final userId = _requireUserId();

    // Ensure Routes.notificationsAll exists in your Routes file.
    final path = Routes.notificationsAll(userId, page: page, size: size);

    final json = await ApiClient.instance.getJson(path);

    // Safety check: if API returns list, wrap it
    // if (json is List) {
    //   return NotificationPage(
    //     content: json.map((e) => AppNotification.fromJson(e)).toList(),
    //     totalElements: json.length,
    //     totalPages: 1,
    //     size: size,
    //     number: page,
    //   );
    // }

    return NotificationPage.fromJson(json);
  }

  Future<int> fetchUnreadCount() async {
    try {
      final userId = _requireUserId();
      final path = Routes.notificationsUnreadCount(userId);
      final json = await ApiClient.instance.getJson(path);

      int count = 0;
      if (json.containsKey('unreadCount')) {
        count = json['unreadCount'] as int;
      } else if (json.containsKey('count')) {
        count = json['count'] as int;
      }

      badgeNotifier.value = count;
      return count;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = _requireUserId();
      final path = '/api/notifications/targeted/user/$userId/mark-all-read';

      await ApiClient.instance.postJson(path, body: {});

      badgeNotifier.value = 0;

      if (notificationsNotifier.value.isNotEmpty) {
        notificationsNotifier.value = notificationsNotifier.value.map((n) {
          // Re-create the object with isRead=true
          // We must manually construct it since AppNotification is immutable
          // and we want to preserve all data.
          return AppNotification(
            id: n.id,
            userId: n.userId,
            title: n.title,
            messageBody: n.messageBody,
            isRead: true,
            createdAt: n.createdAt,
            actionUrl: n.actionUrl,
            priority: n.priority,
            type: n.type,
            data: n.data,
          );
        }).toList();
      } else {
        await fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}



// // lib/data/services/notification_service.dart
//
// import '../models/notification_model.dart';
// import 'package:flutter/foundation.dart'; // 🎯 NEW IMPORT
// import 'auth_service.dart';
// import 'http_client.dart';
// import 'routes.dart';
//
// class NotificationService {
//   NotificationService._();
//   static final NotificationService instance = NotificationService._();
//
//   // 🎯 NEW: Notifier to signal when badges need to be reloaded
//   final ValueNotifier<int> badgeNotifier = ValueNotifier<int>(0);
//
//   String _requireUserId() {
//     final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
//     if (id == null || id.isEmpty) {
//       throw StateError('Not signed in: userId (employeeId) not available.');
//     }
//     return id;
//   }
//
//   /// Fetches a paginated list of all notifications for the logged-in user.
//   Future<NotificationPage> fetchInbox({int page = 0, int size = 20}) async {
//     final userId = _requireUserId();
//     final path = Routes.notificationsAll(userId, page: page, size: size);
//
//     // ApiClient.getJson returns Map<String, dynamic> which matches the Page structure
//     final json = await ApiClient.instance.getJson(path);
//
//     return NotificationPage.fromJson(json);
//   }
//
//   /// Fetches the current count of unread notifications for the badge.
//   Future<int> fetchUnreadCount() async {
//     final userId = _requireUserId();
//     final path = Routes.notificationsUnreadCount(userId);
//
//     final json = await ApiClient.instance.getJson(path);
//
//     final count = json['unreadCount'] as int;
//
//     // 🎯 UPDATE NOTIFIER VALUE
//     badgeNotifier.value = count;
//
//     return count;
//   }
//
//   // 🎯 NEW: Method to mark all notifications as read
//   Future<void> markAllAsRead() async {
//     final userId = _requireUserId();
//     // Assuming a POST endpoint for marking all notifications as read
//     final path = '/api/notifications/targeted/user/$userId/mark-all-read';
//
//     // Use postJson with an empty body to trigger the server action
//     await ApiClient.instance.postJson(path, body: {});
//
//     // 🎯 CRITICAL: Signal the UI immediately after API success
//     badgeNotifier.value = 0; // Optimistically set to 0, or trigger a re-fetch if necessary
//   }
//
//   /// Marks a specific notification as read.
//   Future<void> markAsRead(int notificationId) async {
//     final userId = _requireUserId();
//     // Assuming a standard endpoint structure for marking individual notifications as read
//     final path = '/api/notifications/targeted/read/$userId/$notificationId';
//
//     // Use postJson with an empty body
//     await ApiClient.instance.postJson(path, body: {});
//   }
// }