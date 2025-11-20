// import 'package:flutter/material.dart';
//
// import '../features/home/my_day_screen.dart';
// import '../features/timesheet/timesheet_screen.dart';
// import '../features/schedule/schedule_screen.dart';
// import '../features/leave/leave_screen.dart';
// import '../features/inbox/inbox_screen.dart';
// import '../features/replacement/replacement_screen.dart';
// import '../features/pickup/pickup_screen.dart';
//
// import '../shared/ui.dart';
// import 'app_theme.dart';
//
// // Modern services (no legacy controllers here)
// import '../data/services/tenant_service.dart';
// import '../data/services/auth_service.dart';
// import '../features/auth/tenant_setup_screen.dart';
// import '../features/auth/login_screen.dart';
//
// final GlobalKey<NavigatorState> appNavigator = GlobalKey<NavigatorState>();
//
// class WfmApp extends StatefulWidget {
//   const WfmApp({super.key});
//   @override
//   State<WfmApp> createState() => _WfmAppState();
// }
//
// class _WfmAppState extends State<WfmApp> {
//   // Bootstrap both services using their real singletons
//   late final Future<void> _bootstrap = Future.wait(<Future<void>>[
//     TenantService.instance.init(),
//     AuthService.instance.init(),
//   ]);
//
//   Future<void> _persistTokensAndGoHome(
//       String accessToken,
//       String refreshToken,
//       String? displayName,
//       ) async {
//     // AuthService expects a map (align with your login/refresh handlers)
//     await AuthService.instance.signInPersist({
//       'accessToken': accessToken,
//       'refreshToken': refreshToken,
//       if (displayName != null) 'displayName': displayName,
//     });
//
//     // Navigate after the frame to avoid deactivated context warnings
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       appNavigator.currentState?.pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const RootShell()),
//             (route) => false,
//       );
//     });
//   }
//
//   void _goToLogin() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       appNavigator.currentState?.pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => LoginScreen(
//             onSignedIn: (access, refresh, displayName) =>
//                 _persistTokensAndGoHome(access, refresh, displayName),
//           ),
//         ),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: _bootstrap,
//       builder: (_, snap) {
//         if (snap.connectionState != ConnectionState.done) {
//           return MaterialApp(
//             debugShowCheckedModeBanner: false,
//             title: 'WFM Employee',
//             theme: buildAppTheme(),
//             home: const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             ),
//           );
//         }
//
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'WFM Employee',
//           theme: buildAppTheme(),
//           navigatorKey: appNavigator,
//           home: Builder(
//             builder: (_) {
//               // Use modern services directly
//               final tenant = TenantService.instance.tenantIdOrNull;
//               final signedIn = AuthService.instance.isAuthenticated.value;
//
//               if (tenant == null) {
//                 // No tenant yet → tenant setup first
//                 return TenantSetupScreen(onConfigured: _goToLogin);
//               }
//
//               if (!signedIn) {
//                 // Tenant exists but not signed in → login screen
//                 return LoginScreen(
//                   onSignedIn: (access, refresh, displayName) =>
//                       _persistTokensAndGoHome(access, refresh, displayName),
//                 );
//               }
//
//               // Ready → app shell
//               return const RootShell();
//             },
//           ),
//         );
//       },
//     );
//   }
// }
//
// class RootShell extends StatefulWidget {
//   const RootShell({super.key});
//   @override
//   State<RootShell> createState() => _RootShellState();
// }
//
// class _RootShellState extends State<RootShell> {
//   int _index = 0;
//   int inboxBadge = 4;
//   int bellBadge = 3;
//
//   final PageController _pageController = PageController();
//
//   void _toast(String msg) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(
//         behavior: SnackBarBehavior.floating,
//         content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
//         duration: const Duration(seconds: 2),
//       ));
//   }
//
//   void _gotoReplacement() {
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (_) => ReplacementScreen(onSubmit: () {
//         _toast('📤 Replacement request sent to manager');
//       }),
//     ));
//   }
//
//   void _gotoPickup() {
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (_) => PickupScreen(
//         onPick: () => _toast('🎯 Shift pickup request submitted'),
//       ),
//     ));
//   }
//
//   void _pageTo(int index) {
//     setState(() => _index = index);
//     _pageController.jumpToPage(index);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final navItems = <_NavItem>[
//       _NavItem('My Day', Icons.home_rounded),
//       _NavItem('Timesheet', Icons.bar_chart_rounded),
//       _NavItem('Schedule', Icons.calendar_month_rounded),
//       _NavItem('Leave', Icons.beach_access_rounded),
//       _NavItem('Inbox', Icons.inbox_rounded, badge: inboxBadge),
//     ];
//
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: Colors.transparent,
//           floatingActionButton: FloatingActionButton(
//             tooltip: 'Show All',
//             onPressed: () => _toast('👁️ All sections accessible via tabs & routes'),
//             child: const Text('👁️', style: TextStyle(fontSize: 20)),
//           ),
//           bottomNavigationBar: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
//             ),
//             child: NavigationBar(
//               selectedIndex: _index,
//               height: 72,
//               onDestinationSelected: (i) {
//                 setState(() => _index = i);
//                 _pageController.jumpToPage(i);
//               },
//               destinations: [
//                 for (final item in navItems)
//                   NavigationDestination(
//                     icon: BadgeIcon(icon: item.icon, badge: item.badge),
//                     label: item.label,
//                   ),
//               ],
//             ),
//           ),
//           body: PageView(
//             controller: _pageController,
//             physics: const NeverScrollableScrollPhysics(),
//             children: [
//               MyDayScreen(
//                 bellBadge: bellBadge,
//                 onClockIn: () => _toast('✅ Clocked in successfully at 08:00'),
//                 onCantMake: _gotoReplacement,
//                 onViewTeam: () => _toast('👥 Team screen coming soon'),
//               ),
//               TimesheetScreen(
//                 onSaveDraft: () => _toast('💾 Draft saved'),
//                 onSubmitWeek: () => _toast('⏰ Timesheet submitted for manager approval'),
//               ),
//               ScheduleScreen(
//                 onRequestTimeOff: () => _pageTo(3),
//                 onPickShift: _gotoPickup,
//                 onCantMake: _gotoReplacement,
//               ),
//               LeaveScreen(
//                 onSaveDraft: () => _toast('💾 Leave draft saved'),
//                 onSubmit: () => _toast('📋 Leave application submitted for approval'),
//               ),
//               InboxScreen(
//                 onClockIn: () => _toast('✅ Clocked in'),
//                 onMarkAllRead: () {
//                   setState(() => inboxBadge = 0);
//                   _toast('📬 All messages marked as read');
//                 },
//                 onSettings: () => _toast('⚙️ Settings opened'),
//                 onCantMake: _gotoReplacement,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _NavItem {
//   final String label;
//   final IconData icon;
//   final int badge;
//   _NavItem(this.label, this.icon, {this.badge = 0});
// }











import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 NEEDED FOR SYSTEM EXIT
import '../data/services/notification_service.dart';
import '../features/home/my_day_screen.dart';
import '../features/timesheet/timesheet_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/leave/leave_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/replacement/replacement_screen.dart';
import '../features/pickup/pickup_screen.dart';

import '../shared/ui.dart';
import 'app_theme.dart';

// Modern services
import '../data/services/tenant_service.dart';
import '../data/services/auth_service.dart'; // 👈 NO CHANGE (already imported)
import '../features/auth/tenant_setup_screen.dart';
import '../features/auth/login_screen.dart';
// --- 👇 ADD THIS IMPORT ---
import '../features/reportee/reportee_list_screen.dart';
// --- END OF IMPORT ---

final GlobalKey<NavigatorState> appNavigator = GlobalKey<NavigatorState>();


class WfmApp extends StatefulWidget {
  const WfmApp({super.key});
  @override
  State<WfmApp> createState() => _WfmAppState();
}

class _WfmAppState extends State<WfmApp> {
  // Bootstrap both services using their real singletons
  late final Future<void> _bootstrap = Future.wait(<Future<void>>[
    TenantService.instance.init(),
    AuthService.instance.init(),
  ]);

  // Navigate to Login (LoginScreen handles its own success -> pushReplacementNamed('/'))
  void _goToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigator.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'WFM Employee',
            theme: buildAppTheme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WFM Employee',
          theme: buildAppTheme(),
          navigatorKey: appNavigator,
          home: Builder(
            builder: (_) {
              final tenant = TenantService.instance.hasTenant;
              final signedIn = AuthService.instance.isAuthenticated.value;

              if (!tenant) {
                // No tenant yet → tenant setup first; once configured, go to login
                return TenantSetupScreen(onConfigured: _goToLogin);
              }

              if (!signedIn) {
                // Tenant exists but not signed in → login screen (no callback)
                return const LoginScreen();
              }

              // Ready → app shell
              return const RootShell();
            },
          ),
        );
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}
// ❗️ REMOVED: final GlobalKey<MyDayScreenState> _myDayScreenKey = MyDayScreen.globalKey;


class _RootShellState extends State<RootShell> {
  int _index = 0;
  // int inboxBadge = 4;
  int bellBadge = 3;

  // final PageController _pageController = PageController();

  // 🎯 MODIFIED: This function now pushes the Inbox as a new page
  // It's called by the bell icon (from MyDayScreen)
  void _goToInbox() {
    // We use the root navigator (Navigator.of(context)) to push
    // the InboxScreen on top of the current tab.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => InboxScreen(
        isModal: true, // 👈 --- PASS `true` HERE
        // We must pass the same props here that the tab used to have
        onClockIn: () => _toast('✅ Clocked in'),
        onMarkAllRead: () {
          NotificationService.instance.markAllAsRead();
        },
        onSettings: () => _toast('⚙️ Settings opened'),
        onCantMake: _gotoReplacement,
      ),
    ));
  }

  void _pageTo(int index) {
    setState(() => _index = index);
    // _pageController.jumpToPage(index);
  }

  // Navigator per tab (order must match tabs)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // 0: My Day
    GlobalKey<NavigatorState>(), // 1: Timesheet
    GlobalKey<NavigatorState>(), // 2: Schedule
    GlobalKey<NavigatorState>(), // 3: Leave
    GlobalKey<NavigatorState>(), // 4: Inbox
  ];

  DateTime? _lastExitTime;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 2),
      ));
  }

  void _gotoReplacement() {
    // Pushed on the root app navigator (as before)
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReplacementScreen(onSubmit: () {
        _toast('📤 Replacement request sent to manager');
      }),
    ));
  }

  void _gotoPickup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PickupScreen(
        onPick: () => _toast('🎯 Shift pickup request submitted'),
      ),
    ));
  }

  // build a tab with its own Navigator so inner routes pop first
  Widget _buildTabNavigator(int tabIndex, Widget root) {
    return Navigator(
      key: _navigatorKeys[tabIndex],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => root, settings: settings);
      },
    );
  }

  Future<void> _handleBack() async {
    final nav = _navigatorKeys[_index].currentState;
    // 1) If current tab can pop an inner route (e.g., Leave -> Apply form), do that.
    if (nav != null && await nav.maybePop()) {
      return;
    }

    // 2) If not on My Day, go to My Day.
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }

    // 3) Already on My Day root: double-back to exit.
    final now = DateTime.now();
    if (_lastExitTime == null ||
        now.difference(_lastExitTime!) > const Duration(seconds: 2)) {
      _lastExitTime = now;
      _toast('Press back again to exit the app.');
      return;
    }

    // 🎯 CRITICAL FIX: Explicitly exit the app process
    SystemNavigator.pop();
  }
// 👇 NEW: Logout Confirmation and Action
  Future<void> _confirmAndLogout() async {
    // 1. Show Confirmation Dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to sign out of the application?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              // Use primary button for confirmation action
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // 2. Perform Logout if confirmed
    if (shouldLogout == true) {
      await AuthService.instance.signOut(); // Clears local tokens and state

      // Navigate back to the initial LoginScreen
      if (!mounted) return;
      // We use the global appNavigator to pop all authenticated routes
      // and push the login page.
      appNavigator.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false, // Remove all previous routes from the stack
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    // --- 👇 GET THE FLAG FROM AUTHSERVICE ---
    final bool hasReportees = AuthService.instance.hasReportees;

    // --- 👇 REPLACE THE STATIC navItems LIST ---
    // ⛔ REMOVE THIS:
    // final navItems = <_NavItem>[
    //   _NavItem('My Day', Icons.home_rounded),
    //   _NavItem('Timesheet', Icons.bar_chart_rounded),
    //   _NavItem('Schedule', Icons.calendar_month_rounded),
    //   _NavItem('Leave', Icons.beach_access_rounded),
    //   _NavItem('Inbox', Icons.inbox_rounded),
    // ];

    // ✅ ADD THIS DYNAMIC LIST INSTEAD:
    final navItems = <_NavItem>[
      _NavItem('My Day', Icons.home_rounded),
      _NavItem('Timesheet', Icons.bar_chart_rounded),
      _NavItem('Schedule', Icons.calendar_month_rounded),
      _NavItem('Leave', Icons.beach_access_rounded),
      // This is now the conditional 5th item
      if (hasReportees)
        _NavItem('Reportee', Icons.people_outline_rounded)
      else
        _NavItem('Inbox', Icons.inbox_rounded),
    ];
    // --- END OF CHANGE ---

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: PopScope(
          canPop: false, // we’ll decide what happens on back
          onPopInvoked: (didPop) {
            if (didPop) return;
            _handleBack();
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton(
              tooltip: 'Show All',
              onPressed: () => _toast('👁️ All sections accessible via tabs & routes'),
              child: const Text('👁️', style: TextStyle(fontSize: 20)),
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                height: 72,
                onDestinationSelected: (i) {
                  // 🎯 NEW: If navigating to Schedule tab (index 2), force a reset of its Navigator.
                  // This ensures ScheduleScreen starts fresh (default 'Week' view) every time the user visits it.
                  if (i == 2) {
                    _navigatorKeys[2] = GlobalKey<NavigatorState>();
                  }
                  setState(() => _index = i);
                },
                destinations: [
                  for (final item in navItems)
                    NavigationDestination(
                      icon: BadgeIcon(icon: item.icon, badge: item.badge),
                      label: item.label,
                    ),
                ],
              ),
            ),

            // NOTE: use IndexedStack (no swipe, preserves state, no UI change)
            body: IndexedStack(
              index: _index,
              children: [
                _buildTabNavigator(
                  0,
                  MyDayScreen(
                    // bellBadge: bellBadge,
                    // onClockIn: () => _toast('✅ Clocked in successfully at 08:00'),
                    onCantMake: _gotoReplacement,
                    onViewTeam: () => _toast('👥 Team screen coming soon'),
                    // 🎯 NEW: Pass the logout function to the MyDayScreen
                    onLogout: _confirmAndLogout,
                    // 👇 THIS IS THE KEY CHANGE FOR THE BELL ICON
                    // It will pass `_goToInbox` if user has reportees (showing the bell)
                    // It will pass `null` if not (hiding the bell)
                    onBellClick: hasReportees ? _goToInbox : null,
                  ),
                ),
                _buildTabNavigator(
                  1,
                  TimesheetScreen(
                    onSaveDraft: () => _toast('💾 Draft saved'),
                    onSubmitWeek: () =>
                        _toast('⏰ Timesheet submitted for manager approval'),
                  ),
                ),
                _buildTabNavigator(
                  2,
                  ScheduleScreen(
                    onRequestTimeOff: () => setState(() => _index = 3),
                    onPickShift: _gotoPickup,
                    onCantMake: _gotoReplacement,
                  ),
                ),
                _buildTabNavigator(
                  3,
                  LeaveScreen(
                    onSaveDraft: () => _toast('💾 Leave draft saved'),
                    onSubmit: () =>
                        _toast('📋 Leave application submitted for approval'),
                  ),
                ),
                // --- 👇 REPLACE THE 5TH CHILD ---
                // ⛔ REMOVE THIS:
                // _buildTabNavigator(
                //   4,
                //   InboxScreen(
                //     onClockIn: () => _toast('✅ Clocked in'),
                //     onMarkAllRead: () { ... },
                //     onSettings: () => _toast('⚙️ Settings opened'),
                //     onCantMake: _gotoReplacement,
                //   ),
                // ),

                // ✅ ADD THIS CONDITIONAL BLOCK INSTEAD:
                hasReportees
                // 5.a: If user HAS reportees, show the new ReporteeListScreen
                    ? _buildTabNavigator(
                  4,
                  ReporteeListScreen(),
                )
                // 5.b: Otherwise, show the existing InboxScreen
                    : _buildTabNavigator(
                  4,
                  InboxScreen(
                    onClockIn: () => _toast('✅ Clocked in'),
                    onMarkAllRead: () {
                      NotificationService.instance.markAllAsRead();
                    },
                    onSettings: () => _toast('⚙️ Settings opened'),
                    onCantMake: _gotoReplacement,
                  ),
                ),
                // --- END OF CHANGE ---
              ],
            ),
          ),
        ),
      ),
    );
  }

}


// class RootShell extends StatefulWidget {
//   const RootShell({super.key});
//   @override
//   State<RootShell> createState() => _RootShellState();
// }
//
// class _RootShellState extends State<RootShell> {
//   int _index = 0;
//   int inboxBadge = 4;
//   int bellBadge = 3;
//
//   final PageController _pageController = PageController();
//
//
//   // 👇 NEW: Keys for each Nested Navigator (Must match tab order)
//   final List<GlobalKey<NavigatorState>> _navigatorKeys = [
//     GlobalKey<NavigatorState>(), // 0: My Day
//     GlobalKey<NavigatorState>(), // 1: Timesheet
//     GlobalKey<NavigatorState>(), // 2: Schedule
//     GlobalKey<NavigatorState>(), // 3: Leave
//     GlobalKey<NavigatorState>(), // 4: Inbox
//   ];
//
//   DateTime? _lastExitTime; // Keep this for the reliable double-back exit
//
//
//   void _toast(String msg) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(
//         behavior: SnackBarBehavior.floating,
//         content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
//         duration: const Duration(seconds: 2),
//       ));
//   }
//
//   void _gotoReplacement() {
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (_) => ReplacementScreen(onSubmit: () {
//         _toast('📤 Replacement request sent to manager');
//       }),
//     ));
//   }
//
//   void _gotoPickup() {
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (_) => PickupScreen(
//         onPick: () => _toast('🎯 Shift pickup request submitted'),
//       ),
//     ));
//   }
//
//   void _pageTo(int index) {
//     setState(() => _index = index);
//     _pageController.jumpToPage(index);
//   }
//
//   // NEW: central back handler
//   Future<bool> _onWillPop() async {
//     final currentNavigator = _navigatorKeys[_index].currentState;
//
//     // 1) If current tab has an inner page, pop it first
//     if (currentNavigator != null && currentNavigator.canPop()) {
//       currentNavigator.pop();
//       return false;
//     }
//
//     // 2) If not on My Day (index 0), go to My Day
//     if (_index != 0) {
//       setState(() => _index = 0);
//       _pageController.jumpToPage(0);
//       return false;
//     }
//
//     // 3) Already on My Day root → double back to exit
//     final now = DateTime.now();
//     if (_lastExitTime == null ||
//         now.difference(_lastExitTime!) > const Duration(seconds: 2)) {
//       _lastExitTime = now;
//       _toast('Press back again to exit the app.');
//       return false;
//     }
//
//     return true; // exit app
//   }
//
//   // NEW: wrap each tab content with its own Navigator
//   Widget _buildTabNavigator(int index, Widget child) {
//     return Navigator(
//       key: _navigatorKeys[index],
//       onGenerateRoute: (settings) {
//         return MaterialPageRoute(builder: (_) => child, settings: settings);
//       },
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final navItems = <_NavItem>[
//       _NavItem('My Day', Icons.home_rounded),
//       _NavItem('Timesheet', Icons.bar_chart_rounded),
//       _NavItem('Schedule', Icons.calendar_month_rounded),
//       _NavItem('Leave', Icons.beach_access_rounded),
//       _NavItem('Inbox', Icons.inbox_rounded, badge: inboxBadge),
//     ];
//
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: Scaffold(
//             backgroundColor: Colors.transparent,
//             floatingActionButton: FloatingActionButton(
//               tooltip: 'Show All',
//               onPressed: () => _toast('👁️ All sections accessible via tabs & routes'),
//               child: const Text('👁️', style: TextStyle(fontSize: 20)),
//             ),
//             bottomNavigationBar: Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
//               ),
//               child: NavigationBar(
//                 selectedIndex: _index,
//                 height: 72,
//                 onDestinationSelected: (i) {
//                   setState(() => _index = i);
//                   _pageController.jumpToPage(i);
//                 },
//                 destinations: [
//                   for (final item in navItems)
//                     NavigationDestination(
//                       icon: BadgeIcon(icon: item.icon, badge: item.badge),
//                       label: item.label,
//                     ),
//                 ],
//               ),
//             ),
//             body: PageView(
//               controller: _pageController,
//               physics: const NeverScrollableScrollPhysics(),
//               children: [
//                 _buildTabNavigator(
//                   0,
//                   MyDayScreen(
//                     bellBadge: bellBadge,
//                     onClockIn: () => _toast('✅ Clocked in successfully at 08:00'),
//                     onCantMake: _gotoReplacement,
//                     onViewTeam: () => _toast('👥 Team screen coming soon'),
//                   ),
//                 ),
//                 _buildTabNavigator(
//                   1,
//                   TimesheetScreen(
//                     onSaveDraft: () => _toast('💾 Draft saved'),
//                     onSubmitWeek: () =>
//                         _toast('⏰ Timesheet submitted for manager approval'),
//                   ),
//                 ),
//                 _buildTabNavigator(
//                   2,
//                   ScheduleScreen(
//                     onRequestTimeOff: () => _pageTo(3),
//                     onPickShift: _gotoPickup,
//                     onCantMake: _gotoReplacement,
//                   ),
//                 ),
//                 _buildTabNavigator(
//                   3,
//                   LeaveScreen(
//                     onSaveDraft: () => _toast('💾 Leave draft saved'),
//                     onSubmit: () =>
//                         _toast('📋 Leave application submitted for approval'),
//                   ),
//                 ),
//                 _buildTabNavigator(
//                   4,
//                   InboxScreen(
//                     onClockIn: () => _toast('✅ Clocked in'),
//                     onMarkAllRead: () {
//                       setState(() => inboxBadge = 0);
//                       _toast('📬 All messages marked as read');
//                     },
//                     onSettings: () => _toast('⚙️ Settings opened'),
//                     onCantMake: _gotoReplacement,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
class _NavItem {
  final String label;
  final IconData icon;
  final int badge;
  _NavItem(this.label, this.icon, {this.badge = 0});
}
