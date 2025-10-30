import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/ui.dart';
// 🎯 NEW IMPORTS
import '../../data/services/notification_service.dart';
import '../../data/models/notification_model.dart';

class InboxScreen extends StatefulWidget {
  final VoidCallback onClockIn;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSettings;
  final VoidCallback onCantMake;

  const InboxScreen({
    super.key,
    required this.onClockIn,
    required this.onMarkAllRead,
    required this.onSettings,
    required this.onCantMake,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  Future<NotificationPage>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() {
    setState(() {
      _notificationsFuture = NotificationService.instance.fetchInbox();
    });
  }

  // 🎯 NEW: Handler for the Mark All Read button
  Future<void> _handleMarkAllRead() async {
    try {
      // 1. Call the new service method
      await NotificationService.instance.markAllAsRead();

      // 2. Trigger the callback passed from RootShell to clear the bell badge
      widget.onMarkAllRead();

      // 3. Refresh the local inbox list to show the new read status
      _fetchNotifications();

      // Display success toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  // Helper to determine icon and color based on notification content
  _PillData _getNotificationStyle(AppNotification n) {
    final title = n.title.toLowerCase();
    final priority = n.priority?.toUpperCase();

    if (priority == 'HIGH' || title.contains('urgent')) {
      return const _PillData('URGENT', Color(0xFFDC3545), Colors.white, Icons.warning_rounded);
    }
    if (title.contains('approved') || title.contains('complete')) {
      return const _PillData('STATUS', Color(0xFF28A745), Colors.white, Icons.check_circle_rounded);
    }
    if (title.contains('swap request') || title.contains('new training')) {
      return const _PillData('ACTION', Color(0xFF007BFF), Colors.white, Icons.send_rounded);
    }
    return const _PillData('INFO', Colors.grey, Colors.white, Icons.info_outline);
  }

  // The custom row widget (adapted to take AppNotification object)
  Widget _notificationRow(BuildContext context, AppNotification n) {
    final style = _getNotificationStyle(n);
    final isUnread = !n.isRead;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: style.bg, child: Icon(style.icon, color: style.fg, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(n.messageBody, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(
                  'Received: ${DateFormat('MMM d, HH:mm').format(n.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                // ❗️ ACTIONS: Hardcoded actions are removed, only sample buttons shown
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Example action: Should be dynamically generated based on n.actionUrl/additionalData
                      if (style.label == 'URGENT')
                        SmallBtn.primary('Clock In', widget.onClockIn),
                      if (style.label == 'STATUS')
                        SmallBtn.outline('View Details', () {}),
                    ]
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'Inbox',
      trailing: const Icon(Icons.inbox_rounded, color: Colors.white),
      child: RefreshIndicator(
        onRefresh: () async {
          _fetchNotifications();
          await _notificationsFuture;
        },
        child: FutureBuilder<NotificationPage>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load notifications: ${snapshot.error}', textAlign: TextAlign.center),
              );
            }

            final notifications = snapshot.data!.content;

            // 3. Data State (Dynamic List View)
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    children: [
                      if (notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Your inbox is empty.', style: TextStyle(color: Colors.black54)),
                        ),
                      // 🎯 DYNAMICALLY RENDERED ROWS
                      ...notifications.map((n) => Column(
                        children: [
                          _notificationRow(context, n),
                          const Divider(height: 1),
                        ],
                      )).toList(),
                    ],
                  ),
                ),

                // Static action buttons (kept for existing functionality)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(child: ActionBtn.outline('Mark All Read', widget.onMarkAllRead, context)),
                      Expanded(child: ActionBtn.outline('Filter', () {}, context)),
                      Expanded(child: ActionBtn.primary('Settings', widget.onSettings)),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

// Helper DTO used internally for pill styles
class _PillData {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _PillData(this.label, this.bg, this.fg, this.icon);
}


// import 'package:flutter/material.dart';
// import '../../shared/ui.dart';
//
// class InboxScreen extends StatelessWidget {
//   final VoidCallback onClockIn;
//   final VoidCallback onMarkAllRead;
//   final VoidCallback onSettings;
//   final VoidCallback onCantMake;
//
//   const InboxScreen({
//     super.key,
//     required this.onClockIn,
//     required this.onMarkAllRead,
//     required this.onSettings,
//     required this.onCantMake,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GradientScaffold(
//       title: 'Inbox',
//       trailing: const Icon(Icons.inbox_rounded, color: Colors.white),
//       child: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           Card(
//             margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//             child: Column(
//               children: [
//                 _inboxRow(
//                   const Color(0xFFFFE6E6),
//                   const Color(0xFFDC3545),
//                   Icons.circle,
//                   'URGENT - Shift starts in 15 min',
//                   'Thu 19 Sep, 08:00-16:00 Line A',
//                   [
//                     SmallBtn.primary('Clock In', onClockIn),
//                     SmallBtn.outline('Running Late', () {}),
//                     SmallBtn.danger('Can\'t Make', onCantMake),
//                   ],
//                 ),
//                 const Divider(height: 1),
//                 _inboxRow(
//                   const Color(0xFFE6F7E6),
//                   const Color(0xFF28A745),
//                   Icons.circle,
//                   'Leave Approved - 25-26 Sep',
//                   'Casual Leave approved by Manager',
//                   [
//                     SmallBtn.outline('View Details', () {}),
//                     SmallBtn.primary('Add to Calendar', () {}),
//                   ],
//                 ),
//                 const Divider(height: 1),
//                 _inboxRow(
//                   const Color(0xFFE6F3FF),
//                   const Color(0xFF007BFF),
//                   Icons.circle,
//                   'Shift Swap Request from Priya',
//                   'Wants to swap Fri 20 Sep for Mon 23',
//                   [
//                     SmallBtn.primary('Accept', () {}),
//                     SmallBtn.outline('Decline', () {}),
//                     SmallBtn.outline('Counter-offer', () {}),
//                   ],
//                 ),
//                 const Divider(height: 1),
//                 _inboxRow(
//                   const Color(0xFFE6F3FF),
//                   const Color(0xFF007BFF),
//                   Icons.circle,
//                   'New Training Available',
//                   'Line C Cross-training - Earn 2.0x rate',
//                   [
//                     SmallBtn.primary('Enroll', () {}),
//                     SmallBtn.outline('Learn More', () {}),
//                     SmallBtn.outline('Remind Later', () {}),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//             child: Row(
//               children: [
//                 Expanded(child: ActionBtn.outline('Mark All Read', onMarkAllRead, context)),
//                 Expanded(child: ActionBtn.outline('Filter', () {}, context)),
//                 Expanded(child: ActionBtn.primary('Settings', onSettings)),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _inboxRow(
//       Color bg, Color fg, IconData icon, String title, String text, List<Widget> actions,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(backgroundColor: bg, child: Icon(icon, color: fg, size: 18)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
//                 const SizedBox(height: 2),
//                 Text(text, style: const TextStyle(color: Colors.black54)),
//                 const SizedBox(height: 8),
//                 Wrap(spacing: 8, runSpacing: 8, children: actions),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
