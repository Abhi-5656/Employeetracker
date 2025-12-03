// lib/features/home/my_day_screen.dart
//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
//
// import '../../data/repositories/myday_repository.dart';
// import '../../data/services/auth_service.dart';
// import '../../data/services/location_service.dart';
// import '../../shared/ui.dart';
// import '../../data/services/notification_service.dart';
// import '../visit_proof/add_visit_proof_screen.dart';
// import '../visit_proof/team_visits_screen.dart';
//
// class MyDayScreen extends StatefulWidget {
//   final VoidCallback onCantMake;
//   final VoidCallback onViewTeam;
//   final VoidCallback onLogout;
//   final bool deferFetch;
//   final VoidCallback? onBellClick;
//
//   static final GlobalKey<MyDayScreenState> globalKey = GlobalKey<MyDayScreenState>();
//
//   const MyDayScreen({
//     super.key,
//     required this.onCantMake,
//     required this.onViewTeam,
//     required this.onLogout,
//     this.onBellClick,
//     this.deferFetch = false,
//   });
//
//   @override
//   State<MyDayScreen> createState() => MyDayScreenState();
// }
//
// class MyDayScreenState extends State<MyDayScreen>
//     with AutomaticKeepAliveClientMixin<MyDayScreen> {
//
//   Future<MyDayData>? _future;
//
//   // --- STATE for Tracking ---
//   bool _isClockedIn = false;
//   String? _activeSessionId;
//   bool _isPunching = false; // Prevents double-taps on the button
//   // --------------------------
//
//   String get _punchButtonText => _isClockedIn ? 'Clock Out' : 'Clock In';
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize the Background Service system (if not already done in main)
//     LocationService.instance.initialize();
//
//     loadDataAndBadge();
//     _future = MyDayRepository.instance.load();
//
//     // Check for an existing active session on the server (Warm Start)
//     _warmStart();
//   }
//
//   /// Checks if the user has a live session on the server.
//   /// If yes, updates the UI to "Clocked In" state.
//   Future<void> _warmStart() async {
//     try {
//       // This calls GET /api/tracking/live
//       // The LocationService is responsible for ensuring the background service
//       // is running if a live session exists.
//       final live = await LocationService.instance.getLive();
//
//       if (live != null && live['sessionId'] != null && mounted) {
//         final sessionId = live['sessionId'].toString();
//         debugPrint('Warm-start: Found active session $sessionId');
//
//         setState(() {
//           _isClockedIn = true;
//           _activeSessionId = sessionId;
//         });
//       }
//     } catch (e) {
//       debugPrint('Warm-start failed: $e');
//       // If 404 or error, assume clocked out
//     }
//   }
//
//   void loadDataAndBadge() {
//     setState(() {
//       _future = MyDayRepository.instance.load();
//       NotificationService.instance.fetchUnreadCount();
//     });
//   }
//
//   void _triggerFetch() {
//     loadDataAndBadge();
//   }
//
//   Row _buildTrailingActions(BuildContext context, VoidCallback refreshCallback) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (widget.onBellClick != null)
//           ValueListenableBuilder<int>(
//             valueListenable: NotificationService.instance.badgeNotifier,
//             builder: (context, count, child) {
//               return GestureDetector(
//                 onTap: widget.onBellClick,
//                 child: BadgeIcon(
//                   icon: Icons.notifications_rounded,
//                   badge: count,
//                 ),
//               );
//             },
//           ),
//         const SizedBox(width: 8),
//         IconButton(
//           tooltip: 'Reload',
//           onPressed: refreshCallback,
//           icon: const Icon(Icons.refresh),
//         ),
//         IconButton(
//           tooltip: 'Logout',
//           onPressed: widget.onLogout,
//           icon: const Icon(Icons.logout_rounded),
//         ),
//       ],
//     );
//   }
//
//   void _showLocationAlert(String title, String message, {bool canOpenSettings = false}) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
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
//                   Geolocator.openLocationSettings();
//                 },
//               ),
//           ],
//         );
//       },
//     );
//   }
//   void _navigateToAddProof() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const AddVisitProofScreen()),
//     );
//   }
//
//   void _navigateToTeamProofs() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const TeamVisitsScreen()),
//     );
//   }
//   /// Handles the Clock In / Clock Out action.
//   /// It initiates the background service via LocationService.
//   void _handleClockIn() async {
//     if (_isPunching) return; // Prevent double-taps
//
//     setState(() { _isPunching = true; });
//
//     final isClockingIn = !_isClockedIn;
//     final statusLabel = isClockingIn ? 'Clock In' : 'Clock Out';
//     final String? currentSessionId = _activeSessionId;
//
//     try {
//       // 1. Check Permissions & Service Status BEFORE capturing location
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         throw const LocationServiceDisabledException();
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           throw Exception('Location permissions are denied');
//         }
//       }
//       if (permission == LocationPermission.deniedForever) {
//         throw Exception('Location permissions are permanently denied');
//       }
//
//       // 2. Get current location for the initial punch
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );
//
//       final capturedAt = DateTime.now().toUtc().toIso8601String();
//
//       String? newSessionId;
//
//       if (isClockingIn) {
//         // --- CLOCK IN ---
//         // This API call should also trigger the background service in LocationService
//         newSessionId = await LocationService.instance.startSession(
//           position.latitude,
//           position.longitude,
//           capturedAt,
//         );
//         debugPrint('Clock-In successful. Session ID: $newSessionId');
//       } else {
//         // --- CLOCK OUT ---
//         if (currentSessionId == null) {
//           throw Exception('Internal Error: No active session to close.');
//         }
//
//         // We pass 0 as sequence number for the closing punch, assuming backend/service handles
//         // the final sequence or simply closes the session by ID.
//         await LocationService.instance.endSession(
//             currentSessionId,
//             0
//         );
//         debugPrint('Clock-Out successful for session $currentSessionId');
//       }
//
//       // 3. Update UI State (only if API succeeded)
//       if (mounted) {
//         setState(() {
//           _isClockedIn = isClockingIn;
//           if (isClockingIn) {
//             _activeSessionId = newSessionId;
//           } else {
//             _activeSessionId = null;
//           }
//         });
//
//         _showLocationAlert(
//           'Punch Success',
//           'You are now ${isClockingIn ? "Clocked In" : "Clocked Out"}.',
//         );
//       }
//
//     } on LocationServiceDisabledException {
//       _showLocationAlert(
//         'Location Required',
//         'Please enable Location Services to $statusLabel.',
//         canOpenSettings: true,
//       );
//     } on Exception catch (e) {
//       _showLocationAlert('Error', 'Failed to $statusLabel.\n${e.toString().replaceAll("Exception:", "")}');
//
//       if (e.toString().contains('permission')) {
//         Geolocator.openAppSettings();
//       }
//     } finally {
//       if (mounted) {
//         setState(() { _isPunching = false; });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     // Common widgets for both states (Loading vs Loaded)
//     final greetingCard = _GreetingCard(
//       name: AuthService.instance.displayName,
//       sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
//     );
//
//     // Default empty state if data isn't loaded
//     if (_future == null) {
//       return GradientScaffold(
//         title: 'WorkForce',
//         trailing: _buildTrailingActions(context, _triggerFetch),
//         child: _buildContent(
//           greetingCard: greetingCard,
//           shiftCard: _buildShiftCard(null), // Empty shift card
//         ),
//       );
//     }
//
//     return FutureBuilder<MyDayData>(
//       future: _future,
//       builder: (context, snap) {
//         // 1. Loading State
//         if (snap.connectionState != ConnectionState.done) {
//           return GradientScaffold(
//             title: 'WorkForce',
//             trailing: _buildTrailingActions(context, _triggerFetch),
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         // 2. Error State
//         if (snap.hasError) {
//           return GradientScaffold(
//             title: 'WorkForce',
//             trailing: _buildTrailingActions(context, _triggerFetch),
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                     'Failed to load data.\n${snap.error}',
//                     textAlign: TextAlign.center
//                 ),
//               ),
//             ),
//           );
//         }
//
//         // 3. Success State
//         final d = snap.data!;
//         return GradientScaffold(
//           title: 'WorkForce',
//           trailing: _buildTrailingActions(context, _triggerFetch),
//           child: _buildContent(
//             greetingCard: _GreetingCard(name: d.employeeName, sub: d.dateLabel),
//             shiftCard: _buildShiftCard(d),
//             stats: d,
//           ),
//         );
//       },
//     );
//   }
//
//   // Helper to build the main list content
//   Widget _buildContent({
//     required Widget greetingCard,
//     required Widget shiftCard,
//     MyDayData? stats,
//   }) {
//     // Check role
//     final bool isManager = AuthService.instance.hasReportees;
//     return ListView(
//       padding: const EdgeInsets.only(bottom: 24),
//       children: [
//         const SizedBox(height: 8),
//         greetingCard,
//         shiftCard,
//         // --- NEW: Visit Proof Section ---
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           child: Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const Text("On-Field Activities",
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                   const SizedBox(height: 12),
//
//                   // 1. Field Employee Action
//                   ElevatedButton.icon(
//                     icon: const Icon(Icons.camera_alt),
//                     label: const Text('Add Client Visit Proof'),
//                     onPressed: _navigateToAddProof,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[50],
//                       foregroundColor: Colors.blue[800],
//                     ),
//                   ),
//
//                   // 2. Manager Action (Conditional Render)
//                   if (isManager) ...[
//                     const SizedBox(height: 8),
//                     OutlinedButton.icon(
//                       icon: const Icon(Icons.supervisor_account),
//                       label: const Text('View Team Visits'),
//                       onPressed: _navigateToTeamProofs,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//         // ----------------------------------
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Row(
//             children: [
//               Expanded(child: StatCard(value: stats?.pendingTasks ?? '—', label: 'Pending Tasks')),
//               Expanded(child: StatCard(value: stats?.leaveBalance ?? '—', label: 'Leave Balance')),
//               const Expanded(child: StatCard(value: '—', label: '—')),
//             ],
//           ),
//         ),
//         Card(
//           margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//           child: Column(
//             children: const [
//               NotifRow(
//                 colorBg: Color(0xFFFFE6E6),
//                 colorFg: Color(0xFFDC3545),
//                 icon: Icons.alarm_rounded,
//                 title: 'Shift Reminder',
//                 text: 'Ensure you clock in before your shift begins.',
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Helper to build the Shift Card with dynamic data
//   Widget _buildShiftCard(MyDayData? d) {
//     return ShiftCard(
//       timeRange: d?.timeRange ?? '—',
//       status: d?.status ?? '—',
//       statusColor: d != null ? Color(d.statusColorArgb) : Colors.grey,
//       details: [
//         ShiftDetail(label: 'Location', value: d?.location ?? '—'),
//         ShiftDetail(label: 'Duration', value: d?.duration ?? '—'),
//         ShiftDetail(label: 'Type',     value: d?.type ?? '—'),
//         ShiftDetail(label: 'Next',     value: d?.next ?? '—'),
//       ],
//       actions: [
//         ActionBtn.primary(_punchButtonText, _handleClockIn),
//         ActionBtn.outline('View Team', widget.onViewTeam, context),
//         ActionBtn.danger('Can\'t Make?', widget.onCantMake),
//       ],
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
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
//
// import '../../data/repositories/myday_repository.dart';
// import '../../data/services/auth_service.dart';
// import '../../data/services/location_service.dart';
// import '../../shared/ui.dart';
// import '../../data/services/notification_service.dart';
// import '../visit_proof/add_visit_proof_screen.dart';
// import '../visit_proof/team_visits_screen.dart';
//
// // 🎨 Theme Constants
// const Color _kPrimaryColor = Color(0xFF667EEA);
// const Color _kSecondaryColor = Color(0xFF764BA2);
//
// class MyDayScreen extends StatefulWidget {
//   final VoidCallback onCantMake;
//   final VoidCallback onViewTeam;
//   final VoidCallback onLogout;
//   final bool deferFetch;
//   final VoidCallback? onBellClick;
//
//   static final GlobalKey<MyDayScreenState> globalKey = GlobalKey<MyDayScreenState>();
//
//   const MyDayScreen({
//     super.key,
//     required this.onCantMake,
//     required this.onViewTeam,
//     required this.onLogout,
//     this.onBellClick,
//     this.deferFetch = false,
//   });
//
//   @override
//   State<MyDayScreen> createState() => MyDayScreenState();
// }
//
// class MyDayScreenState extends State<MyDayScreen>
//     with AutomaticKeepAliveClientMixin<MyDayScreen> {
//
//   Future<MyDayData>? _future;
//
//   // --- STATE for Tracking ---
//   bool _isClockedIn = false;
//   String? _activeSessionId;
//   bool _isPunching = false; // Prevents double-taps on the button
//   // --------------------------
//
//   String get _punchButtonText => _isClockedIn ? 'Clock Out' : 'Clock In';
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize the Background Service system (if not already done in main)
//     LocationService.instance.initialize();
//
//     loadDataAndBadge();
//     _future = MyDayRepository.instance.load();
//
//     // Check for an existing active session on the server (Warm Start)
//     _warmStart();
//   }
//
//   /// Checks if the user has a live session on the server.
//   /// If yes, updates the UI to "Clocked In" state.
//   Future<void> _warmStart() async {
//     try {
//       // This calls GET /api/tracking/live
//       final live = await LocationService.instance.getLive();
//
//       if (live != null && live['sessionId'] != null && mounted) {
//         final sessionId = live['sessionId'].toString();
//         debugPrint('Warm-start: Found active session $sessionId');
//
//         setState(() {
//           _isClockedIn = true;
//           _activeSessionId = sessionId;
//         });
//       }
//     } catch (e) {
//       debugPrint('Warm-start failed: $e');
//     }
//   }
//
//   void loadDataAndBadge() {
//     setState(() {
//       _future = MyDayRepository.instance.load();
//       NotificationService.instance.fetchUnreadCount();
//     });
//   }
//
//   void _triggerFetch() {
//     loadDataAndBadge();
//   }
//
//   Row _buildTrailingActions(BuildContext context, VoidCallback refreshCallback) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (widget.onBellClick != null)
//           ValueListenableBuilder<int>(
//             valueListenable: NotificationService.instance.badgeNotifier,
//             builder: (context, count, child) {
//               return GestureDetector(
//                 onTap: widget.onBellClick,
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     shape: BoxShape.circle,
//                   ),
//                   child: BadgeIcon(
//                     icon: Icons.notifications_rounded,
//                     badge: count,
//                     color: Colors.white,
//                   ),
//                 ),
//               );
//             },
//           ),
//         const SizedBox(width: 8),
//         IconButton(
//           tooltip: 'Reload',
//           onPressed: refreshCallback,
//           icon: const Icon(Icons.refresh, color: Colors.white),
//           style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
//         ),
//         const SizedBox(width: 8),
//         IconButton(
//           tooltip: 'Logout',
//           onPressed: widget.onLogout,
//           icon: const Icon(Icons.logout_rounded, color: Colors.white),
//           style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
//         ),
//       ],
//     );
//   }
//
//   void _showLocationAlert(String title, String message, {bool canOpenSettings = false}) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
//                   Geolocator.openLocationSettings();
//                 },
//               ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _navigateToAddProof() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const AddVisitProofScreen()),
//     );
//   }
//
//   void _navigateToTeamProofs() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const TeamVisitsScreen()),
//     );
//   }
//
//   void _handleClockIn() async {
//     if (_isPunching) return; // Prevent double-taps
//
//     setState(() { _isPunching = true; });
//
//     final isClockingIn = !_isClockedIn;
//     final statusLabel = isClockingIn ? 'Clock In' : 'Clock Out';
//     final String? currentSessionId = _activeSessionId;
//
//     try {
//       // 1. Check Permissions & Service Status BEFORE capturing location
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         throw const LocationServiceDisabledException();
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           throw Exception('Location permissions are denied');
//         }
//       }
//       if (permission == LocationPermission.deniedForever) {
//         throw Exception('Location permissions are permanently denied');
//       }
//
//       // 2. Get current location for the initial punch
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );
//
//       final capturedAt = DateTime.now().toUtc().toIso8601String();
//
//       String? newSessionId;
//
//       if (isClockingIn) {
//         newSessionId = await LocationService.instance.startSession(
//           position.latitude,
//           position.longitude,
//           capturedAt,
//         );
//         debugPrint('Clock-In successful. Session ID: $newSessionId');
//       } else {
//         if (currentSessionId == null) {
//           throw Exception('Internal Error: No active session to close.');
//         }
//         await LocationService.instance.endSession(
//             currentSessionId,
//             0
//         );
//         debugPrint('Clock-Out successful for session $currentSessionId');
//       }
//
//       // 3. Update UI State (only if API succeeded)
//       if (mounted) {
//         setState(() {
//           _isClockedIn = isClockingIn;
//           if (isClockingIn) {
//             _activeSessionId = newSessionId;
//           } else {
//             _activeSessionId = null;
//           }
//         });
//
//         _showLocationAlert(
//           'Punch Success',
//           'You are now ${isClockingIn ? "Clocked In" : "Clocked Out"}.',
//         );
//       }
//
//     } on LocationServiceDisabledException {
//       _showLocationAlert(
//         'Location Required',
//         'Please enable Location Services to $statusLabel.',
//         canOpenSettings: true,
//       );
//     } on Exception catch (e) {
//       _showLocationAlert('Error', 'Failed to $statusLabel.\n${e.toString().replaceAll("Exception:", "")}');
//
//       if (e.toString().contains('permission')) {
//         Geolocator.openAppSettings();
//       }
//     } finally {
//       if (mounted) {
//         setState(() { _isPunching = false; });
//       }
//     }
//   }
//
//   // 🎨 Enhanced Gradient Stat Card Helper
//   Widget _buildGradientStatCard(String label, String value, List<Color> colors) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
//           ],
//         ),
//         child: Column(
//           children: [
//             Text(
//               value,
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     // Header Content
//     final greetingCard = _GreetingCard(
//       name: AuthService.instance.displayName,
//       sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
//     );
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Stack(
//         children: [
//           // 1. HEADER BACKGROUND (Gradient)
//           Container(
//             height: 280, // Extended height
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [_kPrimaryColor, _kSecondaryColor],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Stack(
//               children: [
//                 Positioned(
//                   right: -30,
//                   top: -30,
//                   child: Icon(Icons.work_outline_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
//                 ),
//               ],
//             ),
//           ),
//
//           // 2. CONTENT
//           SafeArea(
//             bottom: false,
//             child: Column(
//               children: [
//                 // Header Actions (Top Bar)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'WorkForce',
//                         style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
//                       ),
//                       _buildTrailingActions(context, _triggerFetch),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 16),
//                 // Greeting (In Header)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: greetingCard,
//                 ),
//                 const SizedBox(height: 24),
//
//                 // BODY SECTION (Full Screen White Sheet)
//                 Expanded(
//                   child: Container(
//                     width: double.infinity,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//                       child: _future == null
//                           ? _buildContent(shiftCard: _buildShiftCard(null))
//                           : FutureBuilder<MyDayData>(
//                         future: _future,
//                         builder: (context, snap) {
//                           if (snap.connectionState != ConnectionState.done) {
//                             return const Center(child: CircularProgressIndicator());
//                           }
//                           if (snap.hasError) {
//                             return Center(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(24.0),
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
//                                     const SizedBox(height: 16),
//                                     Text('Failed to load data.\n${snap.error}', textAlign: TextAlign.center),
//                                     const SizedBox(height: 16),
//                                     ElevatedButton(onPressed: _triggerFetch, child: const Text('Retry')),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }
//                           final d = snap.data!;
//                           return _buildContent(
//                             shiftCard: _buildShiftCard(d),
//                             stats: d,
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
//
//   // Helper to build the main list content
//   Widget _buildContent({
//     required Widget shiftCard,
//     MyDayData? stats,
//   }) {
//     final bool isManager = AuthService.instance.hasReportees;
//     return ListView(
//       padding: const EdgeInsets.all(20),
//       children: [
//         // Shift Card (Floating)
//         shiftCard,
//
//         const SizedBox(height: 24),
//
//         // On-Field Activities Section
//         const Text('On-Field Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.camera_alt_rounded, size: 20),
//                 label: const Text('Add Client Visit Proof'),
//                 onPressed: _navigateToAddProof,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _kPrimaryColor.withOpacity(0.1),
//                   foregroundColor: _kPrimaryColor,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//               if (isManager) ...[
//                 const SizedBox(height: 12),
//                 OutlinedButton.icon(
//                   icon: const Icon(Icons.supervisor_account_rounded, size: 20),
//                   label: const Text('View Team Visits'),
//                   onPressed: _navigateToTeamProofs,
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: _kSecondaryColor,
//                     side: const BorderSide(color: _kSecondaryColor),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 24),
//
//         // Stats Row (Colorful Cards)
//         Row(
//           children: [
//             _buildGradientStatCard('Pending Tasks', stats?.pendingTasks ?? '—', [const Color(0xFFFF7043), const Color(0xFFFFAB91)]),
//             const SizedBox(width: 12),
//             _buildGradientStatCard('Leave Balance', stats?.leaveBalance ?? '—', [const Color(0xFF42A5F5), const Color(0xFF64B5F6)]),
//             const SizedBox(width: 12),
//             _buildGradientStatCard('Performance', 'Good', [const Color(0xFF66BB6A), const Color(0xFFA5D6A7)]),
//           ],
//         ),
//
//         const SizedBox(height: 24),
//
//         // Notification Card
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFFF3E0),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: const Color(0xFFFFE0B2)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
//                 child: const Icon(Icons.alarm_rounded, color: Colors.orangeAccent),
//               ),
//               const SizedBox(width: 16),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Shift Reminder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
//                     SizedBox(height: 4),
//                     Text('Ensure you clock in before your shift begins.', style: TextStyle(fontSize: 12, color: Colors.black54)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 40),
//       ],
//     );
//   }
//
//   // Helper to build the Shift Card with dynamic data
//   Widget _buildShiftCard(MyDayData? d) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
//       ),
//       child: ShiftCard(
//         timeRange: d?.timeRange ?? '—',
//         status: d?.status ?? '—',
//         statusColor: d != null ? Color(d.statusColorArgb) : Colors.grey,
//         details: [
//           ShiftDetail(label: 'Location', value: d?.location ?? '—'),
//           ShiftDetail(label: 'Duration', value: d?.duration ?? '—'),
//           ShiftDetail(label: 'Type',     value: d?.type ?? '—'),
//           ShiftDetail(label: 'Next',     value: d?.next ?? '—'),
//         ],
//         actions: [
//           ActionBtn.primary(_punchButtonText, _handleClockIn),
//           ActionBtn.outline('View Team', widget.onViewTeam, context),
//           ActionBtn.danger('Can\'t Make?', widget.onCantMake),
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
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('$greeting,', style: const TextStyle(color: Colors.white70, fontSize: 18)),
//         Text('$name! 👋', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 6),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             sub,
//             style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/myday_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/location_service.dart';
import '../../shared/ui.dart';
import '../../data/services/notification_service.dart';
import '../visit_proof/add_visit_proof_screen.dart';
import '../visit_proof/team_visits_screen.dart';

const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class MyDayScreen extends StatefulWidget {
  final VoidCallback onCantMake;
  final VoidCallback onViewTeam;
  final VoidCallback onLogout;
  final bool deferFetch;
  final VoidCallback? onBellClick;

  static final GlobalKey<MyDayScreenState> globalKey = GlobalKey<MyDayScreenState>();

  const MyDayScreen({
    super.key,
    required this.onCantMake,
    required this.onViewTeam,
    required this.onLogout,
    this.onBellClick,
    this.deferFetch = false,
  });

  @override
  State<MyDayScreen> createState() => MyDayScreenState();
}

class MyDayScreenState extends State<MyDayScreen> with AutomaticKeepAliveClientMixin<MyDayScreen> {
  Future<MyDayData>? _future;
  bool _isClockedIn = false;
  String? _activeSessionId;
  bool _isPunching = false;

  String get _punchButtonText => _isClockedIn ? 'Clock Out' : 'Clock In';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    LocationService.instance.initialize();
    loadDataAndBadge();
    _future = MyDayRepository.instance.load();
    _warmStart();
  }

  Future<void> _warmStart() async {
    try {
      final live = await LocationService.instance.getLive();
      if (live != null && live['sessionId'] != null && mounted) {
        setState(() {
          _isClockedIn = true;
          _activeSessionId = live['sessionId'].toString();
        });
      }
    } catch (e) {
      debugPrint('Warm-start failed: $e');
    }
  }

  void loadDataAndBadge() {
    setState(() {
      _future = MyDayRepository.instance.load();
      NotificationService.instance.fetchUnreadCount();
    });
  }

  void _triggerFetch() => loadDataAndBadge();

  // 🎨 Responsive Gradient Stat Card
  Widget _buildStatCard(String label, String value, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kPrimaryColor, _kSecondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight)
            ),
            child: Stack(children: [Positioned(right: -30, top: -30, child: Icon(Icons.work_outline_rounded, size: 200, color: Colors.white.withOpacity(0.1)))]),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('WorkForce', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Row(children: [
                        if (widget.onBellClick != null)
                          ValueListenableBuilder<int>(
                            valueListenable: NotificationService.instance.badgeNotifier,
                            builder: (context, count, child) => GestureDetector(onTap: widget.onBellClick, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: BadgeIcon(icon: Icons.notifications_rounded, badge: count, color: Colors.white))),
                          ),
                        const SizedBox(width: 8),
                        IconButton(onPressed: _triggerFetch, icon: const Icon(Icons.refresh, color: Colors.white)),
                        IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout_rounded, color: Colors.white)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _GreetingCard(name: AuthService.instance.displayName, sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now())),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: FutureBuilder<MyDayData>(
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                          final d = snap.data!;
                          return ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              ShiftCard(
                                timeRange: d.timeRange ?? '—',
                                status: d.status ?? '—',
                                statusColor: Color(d.statusColorArgb),
                                details: [
                                  ShiftDetail(label: 'Location', value: d.location ?? '—'),
                                  ShiftDetail(label: 'Duration', value: d.duration ?? '—'),
                                  ShiftDetail(label: 'Type', value: d.type ?? '—'),
                                  ShiftDetail(label: 'Next', value: d.next ?? '—'),
                                ],
                                actions: [
                                  ActionBtn.primary(_punchButtonText, _handleClockIn),
                                  // ActionBtn.outline('View Team', widget.onViewTeam, context),
                                  ActionBtn.danger('Can\'t Make?', widget.onCantMake),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text('On-Field Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text('Add Visit Proof'), onPressed: _navigateToAddProof, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
                                    if (AuthService.instance.hasReportees) ...[
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(icon: const Icon(Icons.supervisor_account), label: const Text('View Team Visits'), onPressed: _navigateToTeamProofs, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
                                    ]
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(children: [
                                _buildStatCard('Pending Tasks', d.pendingTasks ?? '—', [const Color(0xFFFF7043), const Color(0xFFFFAB91)]),
                                const SizedBox(width: 12),
                                _buildStatCard('Leave Balance', d.leaveBalance ?? '—', [const Color(0xFF42A5F5), const Color(0xFF64B5F6)]),
                                const SizedBox(width: 12),
                                _buildStatCard('Performance', 'Good', [const Color(0xFF66BB6A), const Color(0xFFA5D6A7)]),
                              ]),
                              const SizedBox(height: 40),
                            ],
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

  // Existing methods (Clock in, etc.) maintained...
  void _showLocationAlert(String title, String message, {bool canOpenSettings = false}) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
  }
  void _navigateToAddProof() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVisitProofScreen()));
  void _navigateToTeamProofs() => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamVisitsScreen()));
  void _handleClockIn() async {
    if (_isPunching) return;
    setState(() => _isPunching = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw const LocationServiceDisabledException();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) throw Exception('Location permissions denied');

      final position = await Geolocator.getCurrentPosition();
      final capturedAt = DateTime.now().toUtc().toIso8601String();

      if (!_isClockedIn) {
        final sid = await LocationService.instance.startSession(position.latitude, position.longitude, capturedAt);
        setState(() { _isClockedIn = true; _activeSessionId = sid; });
        _showLocationAlert('Success', 'Clocked In');
        // ✅ ADD THIS: Refresh global data so pending tasks/timesheet status updates
        _triggerFetch();
      } else {
        await LocationService.instance.endSession(_activeSessionId!, 0);
        setState(() { _isClockedIn = false; _activeSessionId = null; });
        _showLocationAlert('Success', 'Clocked Out');
        // ✅ ADD THIS: Refresh global data
        _triggerFetch();
      }
    } catch (e) {
      _showLocationAlert('Error', '$e');
    } finally {
      setState(() => _isPunching = false);
    }
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final String sub;
  const _GreetingCard({required this.name, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Good Day,', style: const TextStyle(color: Colors.white70, fontSize: 18)),
      Text('$name! 👋', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}