//new 2
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/notification_model.dart';
import '../../data/services/leave_service.dart';
import '../../data/services/notification_service.dart';

const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class InboxScreen extends StatefulWidget {
  final VoidCallback? onClockIn;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onSettings;
  final VoidCallback? onCantMake;
  final bool isModal;

  const InboxScreen({
    super.key,
    this.onClockIn,
    this.onMarkAllRead,
    this.onSettings,
    this.onCantMake,
    this.isModal = false,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final Map<String, bool> _processingItems = {};

  @override
  void initState() {
    super.initState();
    // Fetch data on init
    NotificationService.instance.fetchNotifications();
  }

  Future<void> _handleMarkAllRead() async {
    await NotificationService.instance.markAllAsRead();
    widget.onMarkAllRead?.call();
  }

  Future<void> _handleAction(String approvalId, bool isApprove) async {
    setState(() {
      _processingItems[approvalId] = true;
    });

    try {
      if (isApprove) {
        await LeaveService.instance.approveLeaveRequest(approvalId);
        _showSnack('Request approved successfully ✅');
      } else {
        await LeaveService.instance.rejectLeaveRequest(approvalId);
        _showSnack('Request rejected ❌');
      }

      // Refresh list to fetch updated status (e.g. leaveStatus: APPROVED)
      await NotificationService.instance.fetchNotifications();
    } catch (e) {
      _showSnack('Action failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _processingItems.remove(approvalId);
        });
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  _PillData _getNotificationStyle(AppNotification n) {
    final title = n.title.toUpperCase();
    final type = n.type?.toUpperCase() ?? '';

    // Check status for style updates
    final status = n.data['leaveStatus']?.toString().toUpperCase() ??
        n.data['status']?.toString().toUpperCase() ?? '';

    if (status == 'APPROVED') return const _PillData('APPROVED', Color(0xFF28A745), Colors.white, Icons.check_circle_rounded);
    if (status == 'REJECTED') return const _PillData('REJECTED', Color(0xFFDC3545), Colors.white, Icons.cancel_rounded);

    if (type.contains('LEAVE') || type.contains('APPROVAL') || title.contains('LEAVE')) {
      return const _PillData('ACTION', Colors.orange, Colors.white, Icons.gavel_rounded);
    }
    if (title.contains('URGENT')) return const _PillData('URGENT', Color(0xFFDC3545), Colors.white, Icons.warning_rounded);

    return const _PillData('INFO', Colors.blueGrey, Colors.white, Icons.info_outline);
  }

  Widget _notificationRow(AppNotification n) {
    final style = _getNotificationStyle(n);

    // 1. Identify Notification Type
    final type = n.type?.toUpperCase() ?? '';
    final subType = n.data['notificationType']?.toString().toUpperCase() ?? '';
    final title = n.title.toUpperCase();

    final bool isLeaveType = type.contains('LEAVE') ||
        type.contains('APPROVAL') ||
        subType.contains('LEAVE') ||
        subType.contains('APPROVAL') ||
        title.contains('LEAVE REQUEST') ||
        title.contains('APPROVAL');

    // 2. Identify Current Status (from payload)
    final status = n.data['leaveStatus']?.toString().toUpperCase() ??
        n.data['status']?.toString().toUpperCase() ?? '';

    // 🟢 CRITICAL LOGIC: Hide buttons if already Approved or Rejected
    final bool isPending = status != 'APPROVED' && status != 'REJECTED';

    String? approvalId = n.leaveApprovalId;

    // Show buttons ONLY if: It's a leave type + Status is Pending + We have an ID
    final bool showButtons = isLeaveType && isPending && approvalId != null;

    final bool isProcessing = approvalId != null && _processingItems[approvalId] == true;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: style.bg.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.bg, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: !n.isRead ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.messageBody,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM d, HH:mm').format(n.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (status.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.bg.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: style.bg),
                            ),
                          )
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🟢 Only show buttons if pending
          if (showButtons) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),
            if (isProcessing)
              const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleAction(approvalId!, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _handleAction(approvalId!, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
                  ),
                ],
              )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryColor, _kSecondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inbox',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _handleMarkAllRead,
                        icon: const Icon(Icons.done_all, color: Colors.white),
                        tooltip: 'Mark all read',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: ValueListenableBuilder<List<AppNotification>>(
                        valueListenable: NotificationService.instance.notificationsNotifier,
                        builder: (context, list, child) {
                          if (list.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('No notifications', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              await NotificationService.instance.fetchNotifications();
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) => Container(
                                decoration: BoxDecoration(
                                  color: list[i].isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                  border: !list[i].isRead
                                      ? Border.all(color: _kPrimaryColor.withOpacity(0.3))
                                      : null,
                                ),
                                child: _notificationRow(list[i]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillData {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _PillData(this.label, this.bg, this.fg, this.icon);
}




// // new
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/services/notification_service.dart';
// import '../../data/models/notification_model.dart';
// import '../../shared/ui.dart';
//
// const Color _kPrimaryColor = Color(0xFF667EEA);
// const Color _kSecondaryColor = Color(0xFF764BA2);
//
// class InboxScreen extends StatefulWidget {
//   final VoidCallback onClockIn;
//   final VoidCallback onMarkAllRead;
//   final VoidCallback onSettings;
//   final VoidCallback onCantMake;
//   final bool isModal;
//
//   const InboxScreen({
//     super.key,
//     required this.onClockIn,
//     required this.onMarkAllRead,
//     required this.onSettings,
//     required this.onCantMake,
//     this.isModal = false,
//   });
//
//   @override
//   State<InboxScreen> createState() => _InboxScreenState();
// }
//
// class _InboxScreenState extends State<InboxScreen> {
//   Future<NotificationPage>? _notificationsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchNotifications();
//   }
//
//   void _fetchNotifications() {
//     setState(() {
//       _notificationsFuture = NotificationService.instance.fetchInbox();
//     });
//   }
//
//   Future<void> _handleMarkAllRead() async {
//     await NotificationService.instance.markAllAsRead();
//     widget.onMarkAllRead();
//     _fetchNotifications();
//   }
//
//   _PillData _getNotificationStyle(AppNotification n) {
//     final title = n.title.toLowerCase();
//     if (title.contains('urgent')) return const _PillData('URGENT', Color(0xFFDC3545), Colors.white, Icons.warning_rounded);
//     if (title.contains('approved')) return const _PillData('STATUS', Color(0xFF28A745), Colors.white, Icons.check_circle_rounded);
//     return const _PillData('INFO', Colors.grey, Colors.white, Icons.info_outline);
//   }
//
//   Widget _notificationRow(AppNotification n) {
//     final style = _getNotificationStyle(n);
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(color: style.bg.withOpacity(0.1), shape: BoxShape.circle),
//             child: Icon(style.icon, color: style.bg, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(n.title, style: TextStyle(fontWeight: !n.isRead ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
//                 const SizedBox(height: 4),
//                 Text(n.messageBody, style: const TextStyle(color: Colors.grey)),
//                 const SizedBox(height: 8),
//                 Text(DateFormat('MMM d, HH:mm').format(n.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           Container(
//             height: 200,
//             decoration: const BoxDecoration(
//                 gradient: LinearGradient(colors: [_kPrimaryColor, _kSecondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight)
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Inbox', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
//                       IconButton(onPressed: _handleMarkAllRead, icon: const Icon(Icons.done_all, color: Colors.white), tooltip: 'Mark all read'),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//                       child: FutureBuilder<NotificationPage>(
//                         future: _notificationsFuture,
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
//                           final list = snapshot.data?.content ?? [];
//                           if (list.isEmpty) return const Center(child: Text('No notifications'));
//
//                           return ListView.separated(
//                             padding: const EdgeInsets.all(20),
//                             itemCount: list.length,
//                             separatorBuilder: (_, __) => const SizedBox(height: 12),
//                             itemBuilder: (ctx, i) => Container(
//                               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
//                               child: _notificationRow(list[i]),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _PillData {
//   final String label;
//   final Color bg;
//   final Color fg;
//   final IconData icon;
//   const _PillData(this.label, this.bg, this.fg, this.icon);
// }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../shared/ui.dart';
// // 🎯 NEW IMPORTS
// import '../../data/services/notification_service.dart';
// import '../../data/models/notification_model.dart';
// import '../../shared/widgets/layouts.dart'; //
// import '../../shared/widgets/lists.dart'; //
//
// class InboxScreen extends StatefulWidget {
//   final VoidCallback onClockIn;
//   final VoidCallback onMarkAllRead;
//   final VoidCallback onSettings;
//   final VoidCallback onCantMake;
//   final bool isModal; // 👈 --- ADD THIS PROPERTY
//
//   const InboxScreen({
//     super.key,
//     required this.onClockIn,
//     required this.onMarkAllRead,
//     required this.onSettings,
//     required this.onCantMake,
//     this.isModal = false, // 👈 --- ADD THIS (default to false)
//   });
//
//   @override
//   State<InboxScreen> createState() => _InboxScreenState();
// }
//
// class _InboxScreenState extends State<InboxScreen> {
//   Future<NotificationPage>? _notificationsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchNotifications();
//   }
//
//   void _fetchNotifications() {
//     setState(() {
//       _notificationsFuture = NotificationService.instance.fetchInbox();
//     });
//   }
//
//   // 🎯 NEW: Handler for the Mark All Read button
//   Future<void> _handleMarkAllRead() async {
//     try {
//       // 1. Call the new service method
//       await NotificationService.instance.markAllAsRead();
//
//       // 2. Trigger the callback passed from RootShell to clear the bell badge
//       widget.onMarkAllRead();
//
//       // 3. Refresh the local inbox list to show the new read status
//       _fetchNotifications();
//
//       // Display success toast
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('All notifications marked as read.')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to mark all as read: $e')),
//         );
//       }
//     }
//   }
//
//   // Helper to determine icon and color based on notification content
//   _PillData _getNotificationStyle(AppNotification n) {
//     final title = n.title.toLowerCase();
//     final priority = n.priority?.toUpperCase();
//
//     if (priority == 'HIGH' || title.contains('urgent')) {
//       return const _PillData('URGENT', Color(0xFFDC3545), Colors.white, Icons.warning_rounded);
//     }
//     if (title.contains('approved') || title.contains('complete')) {
//       return const _PillData('STATUS', Color(0xFF28A745), Colors.white, Icons.check_circle_rounded);
//     }
//     if (title.contains('swap request') || title.contains('new training')) {
//       return const _PillData('ACTION', Color(0xFF007BFF), Colors.white, Icons.send_rounded);
//     }
//     return const _PillData('INFO', Colors.grey, Colors.white, Icons.info_outline);
//   }
//
//   // The custom row widget (adapted to take AppNotification object)
//   Widget _notificationRow(BuildContext context, AppNotification n) {
//     final style = _getNotificationStyle(n);
//     final isUnread = !n.isRead;
//
//     return Padding(
//       padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(backgroundColor: style.bg, child: Icon(style.icon, color: style.fg, size: 18)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   n.title,
//                   style: TextStyle(
//                     fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(n.messageBody, style: const TextStyle(color: Colors.black54)),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Received: ${DateFormat('MMM d, HH:mm').format(n.createdAt)}',
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//                 // ❗️ ACTIONS: Hardcoded actions are removed, only sample buttons shown
//                 Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       // Example action: Should be dynamically generated based on n.actionUrl/additionalData
//                       if (style.label == 'URGENT')
//                         SmallBtn.primary('Clock In', widget.onClockIn),
//                       if (style.label == 'STATUS')
//                         SmallBtn.outline('View Details', () {}),
//                     ]
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   return GradientScaffold(
//   //     title: 'Inbox',
//   //     trailing: const Icon(Icons.inbox_rounded, color: Colors.white),
//   //     child: RefreshIndicator(
//   //       onRefresh: () async {
//   //         _fetchNotifications();
//   //         await _notificationsFuture;
//   //       },
//   //       child: FutureBuilder<NotificationPage>(
//   //         future: _notificationsFuture,
//   //         builder: (context, snapshot) {
//   //           // 1. Loading State
//   //           if (snapshot.connectionState != ConnectionState.done) {
//   //             return const Center(child: CircularProgressIndicator());
//   //           }
//   //
//   //           // 2. Error State
//   //           if (snapshot.hasError) {
//   //             return Center(
//   //               child: Text('Failed to load notifications: ${snapshot.error}', textAlign: TextAlign.center),
//   //             );
//   //           }
//   //
//   //           final notifications = snapshot.data!.content;
//   //
//   //           // 3. Data State (Dynamic List View)
//   //           return ListView(
//   //             padding: const EdgeInsets.only(bottom: 24),
//   //             children: [
//   //               Card(
//   //                 margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//   //                 child: Column(
//   //                   children: [
//   //                     if (notifications.isEmpty)
//   //                       const Padding(
//   //                         padding: EdgeInsets.all(16.0),
//   //                         child: Text('Your inbox is empty.', style: TextStyle(color: Colors.black54)),
//   //                       ),
//   //                     // 🎯 DYNAMICALLY RENDERED ROWS
//   //                     ...notifications.map((n) => Column(
//   //                       children: [
//   //                         _notificationRow(context, n),
//   //                         const Divider(height: 1),
//   //                       ],
//   //                     )).toList(),
//   //                   ],
//   //                 ),
//   //               ),
//   //
//   //               // Static action buttons (kept for existing functionality)
//   //               Padding(
//   //                 padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//   //                 child: Row(
//   //                   children: [
//   //                     Expanded(child: ActionBtn.outline('Mark All Read', widget.onMarkAllRead, context)),
//   //                     Expanded(child: ActionBtn.outline('Filter', () {}, context)),
//   //                     Expanded(child: ActionBtn.primary('Settings', widget.onSettings)),
//   //                   ],
//   //                 ),
//   //               )
//   //             ],
//   //           );
//   //         },
//   //       ),
//   //     ),
//   //   );
//   // }
// // --- 3. 👇 THIS IS THE UPDATED BUILD METHOD ---
//   @override
//   Widget build(BuildContext context) {
//
//     // First, define the main content widget
//     final Widget screenBody = RefreshIndicator(
//       onRefresh: () async {
//         _fetchNotifications();
//         await _notificationsFuture;
//       },
//       child: FutureBuilder<NotificationPage>(
//         future: _notificationsFuture,
//         builder: (context, snapshot) {
//           // 1. Loading State
//           if (snapshot.connectionState != ConnectionState.done) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           // 2. Error State
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Failed to load notifications: ${snapshot.error}',
//                 textAlign: TextAlign.center,
//                 // Adjust text color if we are on the gradient
//                 style: widget.isModal ? null : const TextStyle(color: Colors.white70),
//               ),
//             );
//           }
//
//           final notifications = snapshot.data!.content;
//
//           // 3. Empty State
//           if (notifications.isEmpty) {
//             return Center(
//               child: Text(
//                 'Your inbox is empty.',
//                 style: widget.isModal
//                     ? const TextStyle(color: Colors.black54)
//                     : const TextStyle(color: Colors.white70),
//               ),
//             );
//           }
//
//           // 4. Data State (Dynamic List View)
//           return ListView(
//             padding: const EdgeInsets.only(bottom: 24),
//             children: [
//               Card(
//                 margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//                 child: Column(
//                   children: notifications.map((n) {
//                     return Column(
//                       children: [
//                         _notificationRow(context, n),
//                         if (n != notifications.last) const Divider(height: 1),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//
//               // 5. Show action buttons only if this is NOT a modal
//               if (!widget.isModal)
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//                   child: Row(
//                     children: [
//                       // "Mark All Read" is in the AppBar now, so we can remove it here.
//                       // Expanded(child: ActionBtn.outline('Mark All Read', _handleMarkAllRead, context)),
//                       Expanded(child: ActionBtn.outline('Filter', () {}, context)),
//                       Expanded(child: ActionBtn.primary('Settings', widget.onSettings)),
//                     ],
//                   ),
//                 )
//             ],
//           );
//         },
//       ),
//     );
//
//     // --- 4. Conditionally return the correct scaffold ---
//     if (widget.isModal) {
//       // If opened from the bell icon, build a plain white scaffold
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Inbox'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           scrolledUnderElevation: 1,
//           actions: [
//             IconButton(
//               tooltip: 'Mark All Read',
//               icon: const Icon(Icons.check_circle_outline),
//               onPressed: _handleMarkAllRead, // Use the existing handler
//             ),
//           ],
//         ),
//         // ✅ --- ADD THE GRADIENT CONTAINER TO THE BODY ---
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF667EEA), Color(0xFF764BA2)], // The app's gradient
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: screenBody, // Place the content inside the gradient
//         ),// Use the extracted body
//       );
//     }
//
//     // Otherwise, build the default gradient scaffold for the tab
//     return GradientScaffold(
//       title: 'Inbox',
//       trailing: IconButton(
//         tooltip: 'Mark All Read',
//         icon: const Icon(Icons.check_circle_outline, color: Colors.white),
//         onPressed: _handleMarkAllRead, // Use the existing handler
//       ),
//       child: screenBody, // Use the extracted body
//     );
//   }
// }
//
//
// // Helper DTO used internally for pill styles
// class _PillData {
//   final String label;
//   final Color bg;
//   final Color fg;
//   final IconData icon;
//   const _PillData(this.label, this.bg, this.fg, this.icon);
// }


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
