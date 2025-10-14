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
import '../data/services/auth_service.dart';
import '../features/auth/tenant_setup_screen.dart';
import '../features/auth/login_screen.dart';

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

class _RootShellState extends State<RootShell> {
  int _index = 0;
  int inboxBadge = 4;
  int bellBadge = 3;

  final PageController _pageController = PageController();

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

  void _pageTo(int index) {
    setState(() => _index = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final navItems = <_NavItem>[
      _NavItem('My Day', Icons.home_rounded),
      _NavItem('Timesheet', Icons.bar_chart_rounded),
      _NavItem('Schedule', Icons.calendar_month_rounded),
      _NavItem('Leave', Icons.beach_access_rounded),
      _NavItem('Inbox', Icons.inbox_rounded, badge: inboxBadge),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
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
                border: Border(top: BorderSide(color: Color(0xFFE9ECEF)))),
            child: NavigationBar(
              selectedIndex: _index,
              height: 72,
              onDestinationSelected: (i) {
                setState(() => _index = i);
                _pageController.jumpToPage(i);
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
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MyDayScreen(
                bellBadge: bellBadge,
                onClockIn: () => _toast('✅ Clocked in successfully at 08:00'),
                onCantMake: _gotoReplacement,
                onViewTeam: () => _toast('👥 Team screen coming soon'),
                // deferFetch: true, // ⬅️ ensures no network on first render
              ),
              TimesheetScreen(
                onSaveDraft: () => _toast('💾 Draft saved'),
                onSubmitWeek: () => _toast('⏰ Timesheet submitted for manager approval'),
              ),
              ScheduleScreen(
                onRequestTimeOff: () => _pageTo(3),
                onPickShift: _gotoPickup,
                onCantMake: _gotoReplacement,
              ),
              LeaveScreen(
                onSaveDraft: () => _toast('💾 Leave draft saved'),
                onSubmit: () => _toast('📋 Leave application submitted for approval'),
              ),
              InboxScreen(
                onClockIn: () => _toast('✅ Clocked in'),
                onMarkAllRead: () {
                  setState(() => inboxBadge = 0);
                  _toast('📬 All messages marked as read');
                },
                onSettings: () => _toast('⚙️ Settings opened'),
                onCantMake: _gotoReplacement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final int badge;
  _NavItem(this.label, this.icon, {this.badge = 0});
}
