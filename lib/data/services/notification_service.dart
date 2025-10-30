// lib/data/services/notification_service.dart

import '../models/notification_model.dart';
import 'package:flutter/foundation.dart'; // 🎯 NEW IMPORT
import 'auth_service.dart';
import 'http_client.dart';
import 'routes.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // 🎯 NEW: Notifier to signal when badges need to be reloaded
  final ValueNotifier<int> badgeNotifier = ValueNotifier<int>(0);

  String _requireUserId() {
    final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: userId (employeeId) not available.');
    }
    return id;
  }

  /// Fetches a paginated list of all notifications for the logged-in user.
  Future<NotificationPage> fetchInbox({int page = 0, int size = 20}) async {
    final userId = _requireUserId();
    final path = Routes.notificationsAll(userId, page: page, size: size);

    // ApiClient.getJson returns Map<String, dynamic> which matches the Page structure
    final json = await ApiClient.instance.getJson(path);

    return NotificationPage.fromJson(json);
  }

  /// Fetches the current count of unread notifications for the badge.
  Future<int> fetchUnreadCount() async {
    final userId = _requireUserId();
    final path = Routes.notificationsUnreadCount(userId);

    final json = await ApiClient.instance.getJson(path);

    final count = json['unreadCount'] as int;

    // 🎯 UPDATE NOTIFIER VALUE
    badgeNotifier.value = count;

    return count;
  }

  // 🎯 NEW: Method to mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _requireUserId();
    // Assuming a POST endpoint for marking all notifications as read
    final path = '/api/notifications/targeted/user/$userId/mark-all-read';

    // Use postJson with an empty body to trigger the server action
    await ApiClient.instance.postJson(path, body: {});

    // 🎯 CRITICAL: Signal the UI immediately after API success
    badgeNotifier.value = 0; // Optimistically set to 0, or trigger a re-fetch if necessary
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(int notificationId) async {
    final userId = _requireUserId();
    // Assuming a standard endpoint structure for marking individual notifications as read
    final path = '/api/notifications/targeted/read/$userId/$notificationId';

    // Use postJson with an empty body
    await ApiClient.instance.postJson(path, body: {});
  }
}