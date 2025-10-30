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
// lib/features/home/my_day_screen.dart


import 'dart:async'; // ⭐ IMPORT Timer
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Required for location settings
import 'package:intl/intl.dart';

import '../../data/repositories/myday_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/location_service.dart'; // Import the new service
import '../../shared/ui.dart';
// 🎯 NEW IMPORT for notification service
import '../../data/services/notification_service.dart';

class MyDayScreen extends StatefulWidget {
  // final int bellBadge;
  // We're removing the VoidCallback onClockIn here, as the location logic
  // and direct API call now happen within this screen. If you have another
  // logic after location, you would implement it in _handleClockIn.
  // final VoidCallback onClockIn;
  final VoidCallback onCantMake;
  final VoidCallback onViewTeam;
  final VoidCallback onLogout;
  final bool deferFetch;
  // 🎯 NEW PROP: Callback to switch to the Inbox tab when the bell is clicked
  final VoidCallback onBellClick;
// 🎯 FIX: ADD THIS PUBLIC TYPEDEF TO EXPOSE THE STATE TYPE
  static final GlobalKey<MyDayScreenState> globalKey = GlobalKey<MyDayScreenState>();
  const MyDayScreen({
    super.key,
    // required this.bellBadge,
    // required this.onClockIn, // REMOVED
    required this.onCantMake,
    required this.onViewTeam,
    required this.onLogout,
    // 🎯 ADDED BELL CLICK HANDLER
    required this.onBellClick,
    this.deferFetch = false,
  });

  @override
  State<MyDayScreen> createState() => MyDayScreenState();
}

class MyDayScreenState extends State<MyDayScreen>
    with AutomaticKeepAliveClientMixin<MyDayScreen> {
  Future<MyDayData>? _future;
// ⭐ NEW STATE VARIABLE: Tracks current punch status
  bool _isClockedIn = false;

  // ⭐ NEW COMPUTED PROPERTY: Determines the button text
  String get _punchButtonText => _isClockedIn ? 'Clock Out' : 'Clock In';

// ⭐ NEW: Timer instance for periodic tracking
  Timer? _locationTimer;

  // // 🎯 NEW: State to hold the live unread count
  // int _unreadBadgeCount = 0;
  // Future<void>? _badgeFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadDataAndBadge();
    _future = MyDayRepository.instance.load();
    // TODO: Initialize _isClockedIn based on actual data from d.status (in FutureBuilder success path)
  }

  void loadDataAndBadge() {
    setState(() {
      // Load main data
      _future = MyDayRepository.instance.load();
      // Only trigger the fetch; the UI listens to the Notifier
      NotificationService.instance.fetchUnreadCount();
    });
  }

  void _triggerFetch() {
    // 🎯 Use the combined loader to refresh everything
    loadDataAndBadge();
  }

  Row _buildTrailingActions(BuildContext context, VoidCallback refreshCallback) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🎯 CRITICAL FIX: The Bell icon uses ValueListenableBuilder directly
        ValueListenableBuilder<int>(
          valueListenable: NotificationService.instance.badgeNotifier,
          builder: (context, count, child) {
            return GestureDetector(
              onTap: widget.onBellClick,
              child: BadgeIcon(
                icon: Icons.notifications_rounded,
                badge: count, // 👈 Reads dynamic count from Notifier
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // Original Refresh Button
        IconButton(
          tooltip: 'Reload',
          onPressed: refreshCallback,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }

  // --- NEW DIALOG HELPER ---
  void _showLocationAlert(String title, String message, {bool canOpenSettings = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (canOpenSettings)
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Opens the system location settings screen
                  Geolocator.openLocationSettings();
                },
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // ⭐ IMPORTANT: Cancel the timer when the widget is disposed
    _locationTimer?.cancel();
    super.dispose();
  }

  // ⭐ NEW: Method to start the periodic tracking
  void _startLocationTracking() {
    // Ensure any existing timer is cancelled before starting a new one
    _locationTimer?.cancel();

    debugPrint('Starting periodic location tracking (Interval: ${LOCATION_TRACKING_INTERVAL.inSeconds}s)');

    // Use Timer.periodic to repeatedly call the tracking logic
    _locationTimer = Timer.periodic(LOCATION_TRACKING_INTERVAL, (timer) async {
      // NOTE: We pass 'IN' because the location tracking only happens while clocked IN.
      // The server will use this data for background tracking updates.
      final status = await LocationService.instance.checkAndTrackLocation('IN');

      if (status == LocationCheckStatus.apiFailure) {
        debugPrint('Periodic tracking failed to send data. Retrying on next interval.');
      }
      // Permissions should already be granted; if not, the original punch-in
      // logic handles the alert, and the stream will silently fail in the background.
    });
  }

  // ⭐ NEW: Method to stop the periodic tracking
  void _stopLocationTracking() {
    debugPrint('Stopping periodic location tracking.');
    _locationTimer?.cancel();
    _locationTimer = null;
  }
  // --- NEW CLOCK-IN HANDLER WITH LOCATION LOGIC ---
  void _handleClockIn() async {
    // 1. Determine the punch type to SEND based on the current state
    // If we are currently IN, the next action is OUT. Otherwise, it is IN.
    final String punchType = _isClockedIn ? 'OUT' : 'IN';
    final String statusLabel = _isClockedIn ? 'Clock Out' : 'Clock In';
    debugPrint('Attempting $statusLabel ($punchType)...');

    // 2. Call the location service, passing the determined punchType
    // ⭐ FIX: Pass the punchType argument. Service requires this now.
    final status = await LocationService.instance.checkAndTrackLocation(punchType);

    // 3. Handle results and show appropriate alerts
    switch (status) {
      case LocationCheckStatus.success:
      // Location successfully captured and sent.
      // Now, TOGGLE the local state for UI update
        setState(() {
          _isClockedIn = !_isClockedIn;
        });
        // ⭐ NEW LOGIC: START/STOP TIMER
        if (_isClockedIn) {
          _startLocationTracking(); // Just clocked IN, so start tracking
        } else {
          _stopLocationTracking();  // Just clocked OUT, so stop tracking
        }
// ⭐ FIX: Determine success message based on the NEW state (post-toggle)
        final String newStateLabel = _isClockedIn ? 'Clocked In' : 'Clocked Out';

        // ⭐ FIX: Use dynamic label in the success message
        _showLocationAlert(
          'Punch Success',
          'Your location has been successfully tracked and you are now **$newStateLabel**.',
        );
        // TODO: ADD YOUR MAIN ATTENDANCE/PUNCH API CALL HERE
        break;

      case LocationCheckStatus.serviceDisabled:
        _showLocationAlert(
          'Location Required',
          'Please **enable your device\'s location service** to proceed with $statusLabel.', // Use dynamic label
          canOpenSettings: true,
        );
        break;

      case LocationCheckStatus.permissionDenied:
      case LocationCheckStatus.permissionDeniedForever:
      // Automatically open app settings if permission is denied
        _showLocationAlert(
          'Permission Required',
          'Location permission is mandatory. Please grant it in app settings.',
          canOpenSettings: true,
        );
        // Note: Geolocator.requestPermission() already prompts the user.
        // openAppSettings() is primarily for "deniedForever" states.
        Geolocator.openAppSettings();
        break;

      case LocationCheckStatus.apiFailure:
        _showLocationAlert(
          'Error',
          'Failed to complete $statusLabel. Unable to send location data to the server (400, 403, or network error).',
        );
        break;
    }
    // 3. Dismiss loading/processing state if necessary
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ... (rest of the build method for FutureBuilder remains the same)

    if (_future == null) {
      return GradientScaffold(
        title: 'WorkForce',
        trailing: _buildTrailingActions(context, _triggerFetch),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            _GreetingCard(
              name: AuthService.instance.displayName,
              sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
            ),
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
                // ⭐ UPDATED BUTTON CALL
                ActionBtn.primary(_punchButtonText, _handleClockIn), // ⭐ USE computed property
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
            trailing: _buildTrailingActions(context, _triggerFetch),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        // --- 2. Error State ---
        if (snap.hasError) {
          return GradientScaffold(
            title: 'WorkForce',
            trailing: _buildTrailingActions(context, _triggerFetch),
            child: Center(child: Text('${snap.error}', textAlign: TextAlign.center)),
          );
        }

        final d = snap.data!;
        return GradientScaffold(
          title: 'WorkForce',
          trailing: _buildTrailingActions(context, _triggerFetch),
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
                  // ⭐ USE COMPUTED PROPERTY HERE
                  ActionBtn.primary(_punchButtonText, _handleClockIn),
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









//
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
//
// import '../../data/repositories/myday_repository.dart';
// import '../../data/services/auth_service.dart';
// import '../../data/services/location_service.dart';
// import '../../shared/ui.dart';
//
// class MyDayScreen extends StatefulWidget {
//   final int bellBadge;
//   final VoidCallback onClockIn;
//   final VoidCallback onCantMake;
//   final VoidCallback onViewTeam;
//   // 🎯 NEW PROP: Action for logout
//   final VoidCallback onLogout;
//
//   /// When true (default), do NOT hit the network on first render.
//   final bool deferFetch;
//
//   const MyDayScreen({
//     super.key,
//     required this.bellBadge,
//     required this.onClockIn,
//     required this.onCantMake,
//     required this.onViewTeam,
//     // 👈 ADDED LOGOUT PROP HERE
//     required this.onLogout,
//     this.deferFetch = false,
//   });
//
//   @override
//   State<MyDayScreen> createState() => _MyDayScreenState();
// }
//
// class _MyDayScreenState extends State<MyDayScreen>
//     with AutomaticKeepAliveClientMixin<MyDayScreen> {   // <-- ADD THIS MIXIN
//   Future<MyDayData>? _future;
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     // Always trigger the initial load
//     _future = MyDayRepository.instance.load();
//   }
//
//   void _showLocationAlert(BuildContext context, String message, {bool canOpenSettings = false}) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Location Required'),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             if (canOpenSettings)
//               TextButton(
//                 child: const Text('Open Settings'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   // Opens the system location settings screen
//                   Geolocator.openLocationSettings();
//                 },
//               ),
//           ],
//         );
//       },
//     );
//   }
//
//   void handleClockIn(BuildContext context) async {
//     // You might show a loading indicator here (e.g., a modal barrier)
//
//     final status = await LocationService.instance.checkAndTrackLocation();
//
//     // Dismiss loading indicator here
//
//     switch (status) {
//       case LocationCheckStatus.success:
//       // Location successfully captured and sent. Proceed to the next step.
//       // E.g., Navigate to a camera screen, or complete the punch via a different API call.
//       // This would replace the original logic for 'onClockIn'.
//         _showLocationAlert(context, 'Location tracked. Proceeding to clock in!');
//         break;
//
//       case LocationCheckStatus.serviceDisabled:
//       // Show alert with option to open settings
//         _showLocationAlert(
//           context,
//           'Please enable your device\'s location service to clock in.',
//           canOpenSettings: true,
//         );
//         break;
//
//       case LocationCheckStatus.permissionDenied:
//       case LocationCheckStatus.permissionDeniedForever:
//       // Show alert with an explanation and prompt to open app settings
//         Geolocator.openAppSettings(); // Automatically open app settings for the user
//         _showLocationAlert(
//           context,
//           'Location permission is required for clock-in. Please grant permission in the app settings.',
//           canOpenSettings: true,
//         );
//         break;
//
//       case LocationCheckStatus.apiFailure:
//       // Handle server communication errors
//         _showLocationAlert(
//           context,
//           'Clock-in failed: Unable to send location data to the server. Please try again.',
//         );
//         break;
//     }
//   }
//
//   void _triggerFetch() {
//     setState(() {
//       _future = MyDayRepository.instance.load();
//     });
//   }
//
// // 🎯 NEW: Helper to build the trailing actions row with Logout
//   Row _buildTrailingActions(BuildContext context, VoidCallback refreshCallback) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         BadgeIcon(icon: Icons.notifications_rounded, badge: widget.bellBadge),
//         IconButton(
//           tooltip: 'Reload',
//           onPressed: refreshCallback,
//           icon: const Icon(Icons.refresh),
//         ),
//         // 👈 NEW LOGOUT BUTTON
//         IconButton(
//           tooltip: 'Logout',
//           onPressed: widget.onLogout, // Calls the method passed from RootShell
//           icon: const Icon(Icons.logout_rounded),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // <-- ADD THIS (required when using the mixin)
//     // No future yet (deferred): render shell, no network, NO use of `d`
//     if (_future == null) {
//       return GradientScaffold(
//         title: 'WorkForce',
//         trailing: _buildTrailingActions(context, _triggerFetch),
//         child: ListView(
//           padding: const EdgeInsets.only(bottom: 24),
//           children: [
//             const SizedBox(height: 8),
//             _GreetingCard(
//               name: AuthService.instance.displayName,
//               sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
//             ),
//             // All placeholders here; do NOT reference `d`
//             ShiftCard(
//               timeRange: '—',
//               status: '—',
//               statusColor: Colors.grey,
//               details: const [
//                 ShiftDetail(label: 'Location', value: '—'),
//                 ShiftDetail(label: 'Duration', value: '—'),
//                 ShiftDetail(label: 'Type',     value: '—'),
//                 ShiftDetail(label: 'Next',     value: '—'),
//               ],
//               actions: [
//                 ActionBtn.primary('Clock In', widget.onClockIn),
//                 ActionBtn.outline('View Team', widget.onViewTeam, context),
//                 ActionBtn.danger('Can\'t Make?', widget.onCantMake),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: const [
//                   Expanded(child: StatCard(value: '—', label: 'Pending Tasks')),
//                   Expanded(child: StatCard(value: '—', label: 'Leave Balance')),
//                   Expanded(child: StatCard(value: '—', label: '—')),
//                 ],
//               ),
//             ),
//             Card(
//               margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//               child: Column(
//                 children: const [
//                   NotifRow(
//                     colorBg: Color(0xFFFFE6E6),
//                     colorFg: Color(0xFFDC3545),
//                     icon: Icons.alarm_rounded,
//                     title: 'Welcome',
//                     text: 'Tap the refresh icon to load your data.',
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     // When a fetch is requested, use FutureBuilder
//     return FutureBuilder<MyDayData>(
//       future: _future,
//       builder: (context, snap) {
//         if (snap.connectionState != ConnectionState.done) {
//           return GradientScaffold(
//             title: 'WorkForce',
//             trailing: _buildTrailingActions(context, _triggerFetch),
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         }
//         // --- 2. Error State ---
//         if (snap.hasError) {
//           return GradientScaffold(
//             title: 'WorkForce',
//             // 🎯 USE NEW HELPER
//             trailing: _buildTrailingActions(context, _triggerFetch),
//             child: Center(child: Text('${snap.error}', textAlign: TextAlign.center)),
//           );
//         }
//
//         final d = snap.data!;
//         return GradientScaffold(
//           title: 'WorkForce',
//           // 🎯 USE NEW HELPER
//           trailing: _buildTrailingActions(context, _triggerFetch),
//           child: ListView(
//             padding: const EdgeInsets.only(bottom: 24),
//             children: [
//               const SizedBox(height: 8),
//               _GreetingCard(name: d.employeeName, sub: d.dateLabel),
//
//               // Bind dynamic fields from repository result
//               ShiftCard(
//                 timeRange: d.timeRange,
//                 status: d.status,
//                 statusColor: Color(d.statusColorArgb),
//                 details: [
//                   ShiftDetail(label: 'Location', value: d.location),
//                   ShiftDetail(label: 'Duration', value: d.duration),
//                   ShiftDetail(label: 'Type',     value: d.type),
//                   ShiftDetail(label: 'Next',     value: d.next),
//                 ],
//                 actions: [
//                   ActionBtn.primary('Clock In', widget.onClockIn),
//                   ActionBtn.outline('View Team', widget.onViewTeam, context),
//                   ActionBtn.danger('Can\'t Make?', widget.onCantMake),
//                 ],
//               ),
//
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Row(
//                   children: [
//                     Expanded(child: StatCard(value: d.pendingTasks, label: 'Pending Tasks')),
//                     Expanded(child: StatCard(value: d.leaveBalance, label: 'Leave Balance')),
//                     const Expanded(child: StatCard(value: '—', label: '—')),
//                   ],
//                 ),
//               ),
//               Card(
//                 margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//                 child: Column(
//                   children: const [
//                     NotifRow(
//                       colorBg: Color(0xFFFFE6E6),
//                       colorFg: Color(0xFFDC3545),
//                       icon: Icons.alarm_rounded,
//                       title: 'Shift starts in 30 minutes',
//                       text: 'Don\'t forget your safety gear',
//                     ),
//                     Divider(height: 1),
//                     NotifRow(
//                       colorBg: Color(0xFFE6F7E6),
//                       colorFg: Color(0xFF28A745),
//                       icon: Icons.check_circle_rounded,
//                       title: 'Leave approved',
//                       text: '25–26 Sep casual leave approved',
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _GreetingCard extends StatelessWidget {
//   final String name;
//   final String sub;
//   const _GreetingCard({required this.name, required this.sub});
//
//   String _greetingNow() {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good morning';
//     if (h < 17) return 'Good afternoon';
//     if (h < 21) return 'Good evening';
//     return 'Good night';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final greeting = _greetingNow();
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('$greeting, $name! 👋', style: Theme.of(context).textTheme.headlineSmall),
//           const SizedBox(height: 6),
//           Text(sub, style: const TextStyle(color: Colors.black54)),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }
//
