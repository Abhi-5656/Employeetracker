// import 'package:intl/intl.dart';
// import '../services/auth_service.dart';
// import '../services/dashboard_service.dart';
// import '../models/dashboard_summary_model.dart';
// import '../services/shift_service.dart';
// import '../models/shift_roster_model.dart';
//
// class MyDayData {
//   final String employeeName;
//   final String dateLabel;
//   final String timeRange;
//   final String status;
//   final int statusColorArgb;
//   final String pendingTasks;
//   final String leaveBalance;
//
//   MyDayData({
//     required this.employeeName,
//     required this.dateLabel,
//     required this.timeRange,
//     required this.status,
//     required this.statusColorArgb,
//     required this.pendingTasks,
//     required this.leaveBalance,
//   });
// }
//
// class MyDayRepository {
//   MyDayRepository._();
//   static final MyDayRepository instance = MyDayRepository._();
//
//   /// Fetch only the summary for the signed-in employee and build the schedule view model.
//   Future<MyDayData> load() async {
//     // Ensure we have a token (user is signed in)
//     if (AuthService.instance.accessToken == null || AuthService.instance.accessToken!.isEmpty) {
//       throw StateError('Not signed in.');
//     }
//
//     // 1) Fetch /api/dashboard/my-summary/{employeeId}
//     final DashboardSummary sum = await DashboardService.instance.getMySummary();
//
//     // 2) Name comes from JWT / login (no network)
//     final name = AuthService.instance.displayName;
//
//     // 3) Build schedule fields from the summary
//     final String inTime  = (sum.checkInTime  ?? '').toString();
//     final String outTime = (sum.checkOutTime ?? '').toString();
//
//     final String timeRange = (inTime.isNotEmpty || outTime.isNotEmpty)
//         ? '${inTime.isNotEmpty ? inTime : '—'} - ${outTime.isNotEmpty ? outTime : '—'}'
//         : '—';
//
//     final bool isClockedIn = inTime.isNotEmpty && outTime.isEmpty;
//     final String status = isClockedIn
//         ? 'Clocked In'
//         : (timeRange != '—' ? 'Scheduled' : 'No Shift');
//
//     final int statusColor = isClockedIn
//         ? 0xFF2196F3   // blue
//         : (timeRange != '—' ? 0xFF28A745 : 0xFF9E9E9E); // green / grey
//
//     // 4) Cosmetic date under greeting
//     final dateLabel = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
//
//     // 5) Keep tiles if present; otherwise default to 0
//     return MyDayData(
//       employeeName: name,
//       dateLabel: dateLabel,
//       timeRange: timeRange,
//       status: status,
//       statusColorArgb: statusColor,
//       pendingTasks: (sum.pendingTasks ?? 0).toString(),
//       leaveBalance: (sum.leaveBalance ?? 0).toString(),
//     );
//   }
// }
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/shift_service.dart';
import '../services/employee_service.dart';
import '../services/dashboard_service.dart';
import '../models/shift_roster_model.dart';
import '../models/employee_profile_model.dart';
import '../models/my_summary_model.dart';

class MyDayData {
  final String employeeName;
  final String dateLabel;
  final String timeRange;
  final String status;
  final int statusColorArgb;
  final String pendingTasks;   // keep as strings for existing UI
  final String leaveBalance;
  final String location;
  final String type;
  final String next; // upcoming shift time, e.g. "09:00"
  final String duration; // ⬅️ NEW

  MyDayData({
    required this.employeeName,
    required this.dateLabel,
    required this.timeRange,
    required this.status,
    required this.statusColorArgb,
    required this.pendingTasks,
    required this.leaveBalance,
    required this.location,
    required this.type,
    required this.next,
    required this.duration, // ⬅️ NEW
  });
}

class MyDayRepository {
  MyDayRepository._();
  static final MyDayRepository instance = MyDayRepository._();

  static int _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return 0xFF28A745; // default green
    final h = hex.replaceAll('#', '');
    final v = int.tryParse(h, radix: 16);
    if (v == null) return 0xFF28A745;
    return 0xFF000000 | v; // force opaque
  }

  static String _calcDuration(String? start, String? end) {
    if (start == null || start.length != 5) return '—';
    if (end == null || end.length != 5) return '—';
    final sh = int.tryParse(start.substring(0,2));
    final sm = int.tryParse(start.substring(3,5));
    final eh = int.tryParse(end.substring(0,2));
    final em = int.tryParse(end.substring(3,5));
    if (sh == null || sm == null || eh == null || em == null) return '—';
    var s = sh * 60 + sm;
    var e = eh * 60 + em;
    if (e < s) e += 24 * 60; // overnight shift
    final mins = e - s;
    if (mins <= 0) return '—';
    return '${(mins / 60).toStringAsFixed(1)} hrs';
  }


  Future<MyDayData> load() async {
    if ((AuthService.instance.accessToken ?? '').isEmpty) {
      throw StateError('Not signed in.');
    }

    // Call all three in parallel
    final results = await Future.wait([
      ShiftService.instance.getTodayShift(),   // index 0
      EmployeeService.instance.getProfileById(), // index 1
      DashboardService.instance.getMySummary(),  // index 2
    ]);
    final EmployeeShiftRoster? roster = results[0] as EmployeeShiftRoster?;
    final EmployeeProfile profile       = results[1] as EmployeeProfile;
    final MySummary summary             = results[2] as MySummary;

    // Derive shift info
    String timeRange = '—';
    String status    = 'No Shift';
    String duration = '—';
    if (roster != null && roster.shift != null) {
      final s = roster.shift!;
      final start = s.startTime?.trim();
      final end   = s.endTime?.trim();
      duration = _calcDuration(start, end);
    }

    int statusColor  = 0xFF9E9E9E; // grey
    String type      = '—';
    String location  = profile.workLocation?.name ?? '—';

    if (roster != null) {
      final s = roster.shift;
      final isOff = (roster.isWeekOff == true) || (roster.isHoliday == true);
      if (isOff) {
        status = roster.isHoliday == true ? 'Holiday' : 'Day Off';
        statusColor = 0xFF9E9E9E;
      } else if (s != null && (s.startTime?.isNotEmpty == true)) {
        final start = s.startTime!.trim();
        final end   = (s.endTime ?? '').trim();
        timeRange = end.isNotEmpty ? '$start - $end' : start;
        status = 'Scheduled';
        statusColor = _parseHexColor(s.color); // prefer server color
        type = (s.shiftLabel ?? s.shiftName ?? '—');
      }
    }

    // Tiles & “Next”
    final pendingTasks = (summary.pendingRequests ?? 0).toString();
    final leaveBalance = (summary.leaveBalance ?? '—');
    final next         = (summary.upcomingShift ?? '—').trim();

    return MyDayData(
      employeeName: AuthService.instance.displayName,
      dateLabel: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
      timeRange: timeRange,
      status: status,
      statusColorArgb: statusColor,
      pendingTasks: pendingTasks,
      leaveBalance: leaveBalance,
      location: location,
      type: type,
      next: next,
      duration: duration, // ⬅️ NEW
    );
  }
}
