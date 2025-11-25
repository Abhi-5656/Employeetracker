// lib/features/home/my_day_screen.dart

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

class MyDayScreenState extends State<MyDayScreen>
    with AutomaticKeepAliveClientMixin<MyDayScreen> {

  Future<MyDayData>? _future;

  // --- STATE for Tracking ---
  bool _isClockedIn = false;
  String? _activeSessionId;
  bool _isPunching = false; // Prevents double-taps on the button
  // --------------------------

  String get _punchButtonText => _isClockedIn ? 'Clock Out' : 'Clock In';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize the Background Service system (if not already done in main)
    LocationService.instance.initialize();

    loadDataAndBadge();
    _future = MyDayRepository.instance.load();

    // Check for an existing active session on the server (Warm Start)
    _warmStart();
  }

  /// Checks if the user has a live session on the server.
  /// If yes, updates the UI to "Clocked In" state.
  Future<void> _warmStart() async {
    try {
      // This calls GET /api/tracking/live
      // The LocationService is responsible for ensuring the background service
      // is running if a live session exists.
      final live = await LocationService.instance.getLive();

      if (live != null && live['sessionId'] != null && mounted) {
        final sessionId = live['sessionId'].toString();
        debugPrint('Warm-start: Found active session $sessionId');

        setState(() {
          _isClockedIn = true;
          _activeSessionId = sessionId;
        });
      }
    } catch (e) {
      debugPrint('Warm-start failed: $e');
      // If 404 or error, assume clocked out
    }
  }

  void loadDataAndBadge() {
    setState(() {
      _future = MyDayRepository.instance.load();
      NotificationService.instance.fetchUnreadCount();
    });
  }

  void _triggerFetch() {
    loadDataAndBadge();
  }

  Row _buildTrailingActions(BuildContext context, VoidCallback refreshCallback) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onBellClick != null)
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.instance.badgeNotifier,
            builder: (context, count, child) {
              return GestureDetector(
                onTap: widget.onBellClick,
                child: BadgeIcon(
                  icon: Icons.notifications_rounded,
                  badge: count,
                ),
              );
            },
          ),
        const SizedBox(width: 8),
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

  void _showLocationAlert(String title, String message, {bool canOpenSettings = false}) {
    if (!mounted) return;
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
                  Geolocator.openLocationSettings();
                },
              ),
          ],
        );
      },
    );
  }
  void _navigateToAddProof() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVisitProofScreen()),
    );
  }

  void _navigateToTeamProofs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TeamVisitsScreen()),
    );
  }
  /// Handles the Clock In / Clock Out action.
  /// It initiates the background service via LocationService.
  void _handleClockIn() async {
    if (_isPunching) return; // Prevent double-taps

    setState(() { _isPunching = true; });

    final isClockingIn = !_isClockedIn;
    final statusLabel = isClockingIn ? 'Clock In' : 'Clock Out';
    final String? currentSessionId = _activeSessionId;

    try {
      // 1. Check Permissions & Service Status BEFORE capturing location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceDisabledException();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // 2. Get current location for the initial punch
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final capturedAt = DateTime.now().toUtc().toIso8601String();

      String? newSessionId;

      if (isClockingIn) {
        // --- CLOCK IN ---
        // This API call should also trigger the background service in LocationService
        newSessionId = await LocationService.instance.startSession(
          position.latitude,
          position.longitude,
          capturedAt,
        );
        debugPrint('Clock-In successful. Session ID: $newSessionId');
      } else {
        // --- CLOCK OUT ---
        if (currentSessionId == null) {
          throw Exception('Internal Error: No active session to close.');
        }

        // We pass 0 as sequence number for the closing punch, assuming backend/service handles
        // the final sequence or simply closes the session by ID.
        await LocationService.instance.endSession(
            currentSessionId,
            0
        );
        debugPrint('Clock-Out successful for session $currentSessionId');
      }

      // 3. Update UI State (only if API succeeded)
      if (mounted) {
        setState(() {
          _isClockedIn = isClockingIn;
          if (isClockingIn) {
            _activeSessionId = newSessionId;
          } else {
            _activeSessionId = null;
          }
        });

        _showLocationAlert(
          'Punch Success',
          'You are now ${isClockingIn ? "Clocked In" : "Clocked Out"}.',
        );
      }

    } on LocationServiceDisabledException {
      _showLocationAlert(
        'Location Required',
        'Please enable Location Services to $statusLabel.',
        canOpenSettings: true,
      );
    } on Exception catch (e) {
      _showLocationAlert('Error', 'Failed to $statusLabel.\n${e.toString().replaceAll("Exception:", "")}');

      if (e.toString().contains('permission')) {
        Geolocator.openAppSettings();
      }
    } finally {
      if (mounted) {
        setState(() { _isPunching = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Common widgets for both states (Loading vs Loaded)
    final greetingCard = _GreetingCard(
      name: AuthService.instance.displayName,
      sub: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
    );

    // Default empty state if data isn't loaded
    if (_future == null) {
      return GradientScaffold(
        title: 'WorkForce',
        trailing: _buildTrailingActions(context, _triggerFetch),
        child: _buildContent(
          greetingCard: greetingCard,
          shiftCard: _buildShiftCard(null), // Empty shift card
        ),
      );
    }

    return FutureBuilder<MyDayData>(
      future: _future,
      builder: (context, snap) {
        // 1. Loading State
        if (snap.connectionState != ConnectionState.done) {
          return GradientScaffold(
            title: 'WorkForce',
            trailing: _buildTrailingActions(context, _triggerFetch),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Error State
        if (snap.hasError) {
          return GradientScaffold(
            title: 'WorkForce',
            trailing: _buildTrailingActions(context, _triggerFetch),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    'Failed to load data.\n${snap.error}',
                    textAlign: TextAlign.center
                ),
              ),
            ),
          );
        }

        // 3. Success State
        final d = snap.data!;
        return GradientScaffold(
          title: 'WorkForce',
          trailing: _buildTrailingActions(context, _triggerFetch),
          child: _buildContent(
            greetingCard: _GreetingCard(name: d.employeeName, sub: d.dateLabel),
            shiftCard: _buildShiftCard(d),
            stats: d,
          ),
        );
      },
    );
  }

  // Helper to build the main list content
  Widget _buildContent({
    required Widget greetingCard,
    required Widget shiftCard,
    MyDayData? stats,
  }) {
    // Check role
    final bool isManager = AuthService.instance.hasReportees;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        greetingCard,
        shiftCard,
        // --- NEW: Visit Proof Section ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("On-Field Activities",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  // 1. Field Employee Action
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Add Client Visit Proof'),
                    onPressed: _navigateToAddProof,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
                    ),
                  ),

                  // 2. Manager Action (Conditional Render)
                  if (isManager) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.supervisor_account),
                      label: const Text('View Team Visits'),
                      onPressed: _navigateToTeamProofs,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // ----------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: StatCard(value: stats?.pendingTasks ?? '—', label: 'Pending Tasks')),
              Expanded(child: StatCard(value: stats?.leaveBalance ?? '—', label: 'Leave Balance')),
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
                title: 'Shift Reminder',
                text: 'Ensure you clock in before your shift begins.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build the Shift Card with dynamic data
  Widget _buildShiftCard(MyDayData? d) {
    return ShiftCard(
      timeRange: d?.timeRange ?? '—',
      status: d?.status ?? '—',
      statusColor: d != null ? Color(d.statusColorArgb) : Colors.grey,
      details: [
        ShiftDetail(label: 'Location', value: d?.location ?? '—'),
        ShiftDetail(label: 'Duration', value: d?.duration ?? '—'),
        ShiftDetail(label: 'Type',     value: d?.type ?? '—'),
        ShiftDetail(label: 'Next',     value: d?.next ?? '—'),
      ],
      actions: [
        ActionBtn.primary(_punchButtonText, _handleClockIn),
        ActionBtn.outline('View Team', widget.onViewTeam, context),
        ActionBtn.danger('Can\'t Make?', widget.onCantMake),
      ],
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