// import 'package:flutter/material.dart';
// import '../../shared/ui.dart';
//
// class MyDayScreen extends StatelessWidget {
//   final int bellBadge;
//   final VoidCallback onClockIn;
//   final VoidCallback onCantMake;
//   final VoidCallback onViewTeam;
//
//   const MyDayScreen({
//     super.key,
//     required this.bellBadge,
//     required this.onClockIn,
//     required this.onCantMake,
//     required this.onViewTeam,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GradientScaffold(
//       title: 'WorkForce',
//       trailing: BadgeIcon(icon: Icons.notifications_rounded, badge: bellBadge),
//       child: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           const SizedBox(height: 8),
//           const _GreetingCard(name: 'Harsh', sub: 'Thursday, September 19, 2024'),
//           ShiftCard(
//             timeRange: '08:00 - 16:00',
//             status: 'Scheduled',
//             statusColor: Colors.green,
//             details: const [
//               ShiftDetail(label: 'Location', value: 'Line A'),
//               ShiftDetail(label: 'Duration', value: '8.0 hrs'),
//               ShiftDetail(label: 'Type', value: 'Regular'),
//               ShiftDetail(label: 'Next', value: 'Huddle 09:00'),
//             ],
//             actions: [
//               ActionBtn.primary('Clock In', onClockIn),
//               ActionBtn.outline('View Team', onViewTeam, context),
//               ActionBtn.danger('Can\'t Make?', onCantMake),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: const [
//                 Expanded(child: StatCard(value: '7h 52m', label: 'Yesterday')),
//                 Expanded(child: StatCard(value: '32h', label: 'This Week')),
//                 Expanded(child: StatCard(value: '0', label: 'Exceptions')),
//               ],
//             ),
//           ),
//           Card(
//             margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//             child: Column(
//               children: const [
//                 NotifRow(
//                   colorBg: Color(0xFFFFE6E6),
//                   colorFg: Color(0xFFDC3545),
//                   icon: Icons.alarm_rounded,
//                   title: 'Shift starts in 30 minutes',
//                   text: 'Don\'t forget your safety gear',
//                 ),
//                 Divider(height: 1),
//                 NotifRow(
//                   colorBg: Color(0xFFE6F7E6),
//                   colorFg: Color(0xFF28A745),
//                   icon: Icons.check_circle_rounded,
//                   title: 'Leave approved',
//                   text: '25-26 Sep casual leave approved',
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
// class _GreetingCard extends StatelessWidget {
//   final String name;
//   final String sub;
//   const _GreetingCard({required this.name, required this.sub});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Good morning, $name! 👋', style: Theme.of(context).textTheme.headlineSmall),
//           const SizedBox(height: 6),
//           Text(sub, style: const TextStyle(color: Colors.black54)),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }








// lib/features/home/my_day_screen.dart
// import 'package:flutter/material.dart';
// import '../../data/repositories/myday_repository.dart';
// import '../../shared/ui.dart';
//
// class MyDayScreen extends StatelessWidget {
//   final int bellBadge;
//   final VoidCallback onClockIn;
//   final VoidCallback onCantMake;
//   final VoidCallback onViewTeam;
//
//   const MyDayScreen({
//     super.key,
//     required this.bellBadge,
//     required this.onClockIn,
//     required this.onCantMake,
//     required this.onViewTeam,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<MyDayData>(
//         future: MyDayRepository.instance.load(),
//         builder: (context, snap) {
//           if (snap.connectionState != ConnectionState.done) {
//             return GradientScaffold(
//               title: 'WorkForce',
//               trailing: BadgeIcon(
//                   icon: Icons.notifications_rounded, badge: bellBadge),
//               child: const Center(child: CircularProgressIndicator()),
//             );
//           }
//           if (snap.hasError) {
//             return GradientScaffold(
//               title: 'WorkForce',
//               trailing: BadgeIcon(
//                   icon: Icons.notifications_rounded, badge: bellBadge),
//               child: Center(
//                   child: Text('${snap.error}', textAlign: TextAlign.center)),
//             );
//           }
//
//           final d = snap.data!;
//           return GradientScaffold(
//             title: 'WorkForce',
//             trailing: BadgeIcon(
//                 icon: Icons.notifications_rounded, badge: bellBadge),
//             child: ListView(
//               padding: const EdgeInsets.only(bottom: 24),
//               children: [
//                 const SizedBox(height: 8),
//                 _GreetingCard(name: d.employeeName, sub: d.dateLabel),
//
//                 ShiftCard(
//                   timeRange: d.timeRange,
//                   status: d.status,
//                   statusColor: Color(d.statusColorArgb),
//                   details: const [
//                     ShiftDetail(label: 'Location', value: '—'),
//                     ShiftDetail(label: 'Duration', value: '—'),
//                     ShiftDetail(label: 'Type', value: '—'),
//                     ShiftDetail(label: 'Next', value: '—'),
//                   ],
//                   actions: [
//                     ActionBtn.primary('Clock In', onClockIn),
//                     ActionBtn.outline('View Team', onViewTeam, context),
//                     ActionBtn.danger('Can\'t Make?', onCantMake),
//                   ],
//                 ),
//
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: Row(
//                     children: [
//                       Expanded(child: StatCard(
//                           value: d.pendingTasks, label: 'Pending Tasks')),
//                       Expanded(child: StatCard(
//                           value: d.leaveBalance, label: 'Leave Balance')),
//                       const Expanded(child: StatCard(value: '—', label: '—')),
//                     ],
//                   ),
//                 ),
//                 // // ===== Static data (temporary until API is ready) =====
//                 // const String employeeName = 'Utkarsh Shukla';
//                 // const String todayDate = 'Friday, 10 Oct 2025';
//                 //
//                 // // Shift window (static)
//                 // const String checkInTime = '09:30';
//                 // const String checkOutTime = '18:30';
//                 // const String timeRange = '$checkInTime - $checkOutTime';
//                 //
//                 // // Status (static)
//                 // const bool isClockedIn = false; // change to true if you want the blue "Clocked In"
//                 // final String status = isClockedIn ? 'Clocked In' : 'Scheduled';
//                 // final Color statusColor = isClockedIn ? Colors.blue : Colors.green;
//                 //
//                 // // Stats (static)
//                 // const String pendingTasks = '3';
//                 // const String leaveBalance = '8.5';
//                 // const String extraStatValue = '96%';
//                 // const String extraStatLabel = 'Attendance';
//                 //
//                 // return GradientScaffold(
//                 //   title: 'WorkForce',
//                 //   trailing: BadgeIcon(icon: Icons.notifications_rounded, badge: bellBadge),
//                 //   child: ListView(
//                 //     padding: const EdgeInsets.only(bottom: 24),
//                 //     children: [
//                 //       const SizedBox(height: 8),
//                 //
//                 //       // Greeting
//                 //       _GreetingCard(
//                 //         name: employeeName,
//                 //         sub: todayDate,
//                 //       ),
//                 //
//                 //       // Shift card (static)
//                 //       ShiftCard(
//                 //         timeRange: timeRange,
//                 //         status: status,
//                 //         statusColor: statusColor,
//                 //         details: const [
//                 //           ShiftDetail(label: 'Location', value: 'Bengaluru HO'),
//                 //           ShiftDetail(label: 'Duration', value: '9h'),
//                 //           ShiftDetail(label: 'Type', value: 'Regular'),
//                 //           ShiftDetail(label: 'Next', value: 'Mon, 13 Oct 2025 • 09:30'),
//                 //         ],
//                 //         actions: [
//                 //           ActionBtn.primary('Clock In', onClockIn),
//                 //           ActionBtn.outline('View Team', onViewTeam, context),
//                 //           ActionBtn.danger('Can\'t Make?', onCantMake),
//                 //         ],
//                 //       ),
//                 //
//                 //       // Stats row (static)
//                 //       Padding(
//                 //         padding: const EdgeInsets.symmetric(horizontal: 12),
//                 //         child: Row(
//                 //           children: const [
//                 //             Expanded(child: StatCard(value: pendingTasks, label: 'Pending Tasks')),
//                 //             Expanded(child: StatCard(value: leaveBalance, label: 'Leave Balance')),
//                 //             Expanded(child: StatCard(value: extraStatValue, label: extraStatLabel)),
//                 //           ],
//                 //         ),
//                 //       ),
//
//                 // Notifications (static)
//                 Card(
//                   margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//                   child: Column(
//                     children: const [
//                       NotifRow(
//                         colorBg: Color(0xFFFFE6E6),
//                         colorFg: Color(0xFFDC3545),
//                         icon: Icons.alarm_rounded,
//                         title: 'Shift starts in 30 minutes',
//                         text: 'Don\'t forget your safety gear',
//                       ),
//                       Divider(height: 1),
//                       NotifRow(
//                         colorBg: Color(0xFFE6F7E6),
//                         colorFg: Color(0xFF28A745),
//                         icon: Icons.check_circle_rounded,
//                         title: 'Leave approved',
//                         text: '25–26 Sep casual leave approved',
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         });
//   }
// }
//
// class _GreetingCard extends StatelessWidget {
//   final String name;
//   final String sub;
//   const _GreetingCard({required this.name, required this.sub});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Good morning, $name! 👋', style: Theme.of(context).textTheme.headlineSmall),
//           const SizedBox(height: 6),
//           Text(sub, style: const TextStyle(color: Colors.black54)),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/myday_repository.dart';
import '../../data/services/auth_service.dart';
import '../../shared/ui.dart';

class MyDayScreen extends StatefulWidget {
  final int bellBadge;
  final VoidCallback onClockIn;
  final VoidCallback onCantMake;
  final VoidCallback onViewTeam;

  /// When true (default), do NOT hit the network on first render.
  final bool deferFetch;

  const MyDayScreen({
    super.key,
    required this.bellBadge,
    required this.onClockIn,
    required this.onCantMake,
    required this.onViewTeam,
    this.deferFetch = false,
  });

  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen>
    with AutomaticKeepAliveClientMixin<MyDayScreen> {   // <-- ADD THIS MIXIN
  Future<MyDayData>? _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Always trigger the initial load
    _future = MyDayRepository.instance.load();
  }

  void _triggerFetch() {
    setState(() {
      _future = MyDayRepository.instance.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // <-- ADD THIS (required when using the mixin)
    // No future yet (deferred): render shell, no network, NO use of `d`
    if (_future == null) {
      return GradientScaffold(
        title: 'WorkForce',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeIcon(icon: Icons.notifications_rounded, badge: widget.bellBadge),
            IconButton(
              tooltip: 'Load data',
              onPressed: _triggerFetch,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            _GreetingCard(
              name: AuthService.instance.displayName,
              sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
            ),
            // All placeholders here; do NOT reference `d`
            ShiftCard(
              timeRange: '—',
              status: '—',
              statusColor: Colors.grey,
              details: const [
                ShiftDetail(label: 'Location', value: '—'),
                ShiftDetail(label: 'Duration', value: '—'),
                ShiftDetail(label: 'Type',     value: '—'),
                ShiftDetail(label: 'Next',     value: '—'),
              ],
              actions: [
                ActionBtn.primary('Clock In', widget.onClockIn),
                ActionBtn.outline('View Team', widget.onViewTeam, context),
                ActionBtn.danger('Can\'t Make?', widget.onCantMake),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  Expanded(child: StatCard(value: '—', label: 'Pending Tasks')),
                  Expanded(child: StatCard(value: '—', label: 'Leave Balance')),
                  Expanded(child: StatCard(value: '—', label: '—')),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: const [
                  NotifRow(
                    colorBg: Color(0xFFFFE6E6),
                    colorFg: Color(0xFFDC3545),
                    icon: Icons.alarm_rounded,
                    title: 'Welcome',
                    text: 'Tap the refresh icon to load your data.',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // When a fetch is requested, use FutureBuilder
    return FutureBuilder<MyDayData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return GradientScaffold(
            title: 'WorkForce',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeIcon(icon: Icons.notifications_rounded, badge: widget.bellBadge),
                // AFTER:
                IconButton(
                  tooltip: 'Reload',
                  onPressed: _triggerFetch,          // <-- just reload; do NOT set _future to null
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return GradientScaffold(
            title: 'WorkForce',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeIcon(icon: Icons.notifications_rounded, badge: widget.bellBadge),
                IconButton(
                  tooltip: 'Retry',
                  onPressed: _triggerFetch,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            child: Center(child: Text('${snap.error}', textAlign: TextAlign.center)),
          );
        }

        final d = snap.data!;
        return GradientScaffold(
          title: 'WorkForce',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeIcon(icon: Icons.notifications_rounded, badge: widget.bellBadge),
              IconButton(
                tooltip: 'Reload',
                onPressed: _triggerFetch,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 8),
              _GreetingCard(name: d.employeeName, sub: d.dateLabel),

              // Bind dynamic fields from repository result
              ShiftCard(
                timeRange: d.timeRange,
                status: d.status,
                statusColor: Color(d.statusColorArgb),
                details: [
                  ShiftDetail(label: 'Location', value: d.location),
                  ShiftDetail(label: 'Duration', value: d.duration),
                  ShiftDetail(label: 'Type',     value: d.type),
                  ShiftDetail(label: 'Next',     value: d.next),
                ],
                actions: [
                  ActionBtn.primary('Clock In', widget.onClockIn),
                  ActionBtn.outline('View Team', widget.onViewTeam, context),
                  ActionBtn.danger('Can\'t Make?', widget.onCantMake),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: StatCard(value: d.pendingTasks, label: 'Pending Tasks')),
                    Expanded(child: StatCard(value: d.leaveBalance, label: 'Leave Balance')),
                    const Expanded(child: StatCard(value: '—', label: '—')),
                  ],
                ),
              ),
              Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: const [
                    NotifRow(
                      colorBg: Color(0xFFFFE6E6),
                      colorFg: Color(0xFFDC3545),
                      icon: Icons.alarm_rounded,
                      title: 'Shift starts in 30 minutes',
                      text: 'Don\'t forget your safety gear',
                    ),
                    Divider(height: 1),
                    NotifRow(
                      colorBg: Color(0xFFE6F7E6),
                      colorFg: Color(0xFF28A745),
                      icon: Icons.check_circle_rounded,
                      title: 'Leave approved',
                      text: '25–26 Sep casual leave approved',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final String sub;
  const _GreetingCard({required this.name, required this.sub});

  String _greetingNow() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingNow();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting, $name! 👋', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

