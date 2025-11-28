// // lib/data/services/leave_service.dart
// import 'package:intl/intl.dart';
//
// import '../models/leave_and_holidays_model.dart';
// import 'http_client.dart';
// import 'auth_service.dart';
// import 'routes.dart';
//
//
// class LeaveService {
//   LeaveService._();
//   static final LeaveService instance = LeaveService._();
//
//   String _requireEmployeeId() {
//     final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
//     if (id == null || id.isEmpty) {
//       throw StateError('Not signed in: employeeId not available.');
//     }
//     return id;
//   }
//
//   Future<LeaveAndHolidays> getLeaveAndHolidays() async {
//     final id = _requireEmployeeId();
//     final json = await ApiClient.instance.getJson(Routes.leaveAndHolidays(id));
//     return LeaveAndHolidays.fromJson(json);
//   }
//
//   Future<void> applyLeave({
//     required int leavePolicyId,
//     required DateTime from,
//     required DateTime to,
//     bool halfDay = false,
//     bool includeWeekends = true,
//     String? reason,
//   }) async {
//     final employeeId = _requireEmployeeId();
//
//     final ymd = DateFormat('yyyy-MM-dd');
//     final body = <String, dynamic>{
//       'employeeId': employeeId,
//       'leavePolicyId': leavePolicyId,
//       // common naming
//       'fromDate': ymd.format(from),
//       'toDate': ymd.format(to),
//       // alt keys (some backends use start/end)
//       'startDate': ymd.format(from),
//       'endDate': ymd.format(to),
//
//       'halfDay': halfDay,
//       'includeWeekends': includeWeekends,
//     };
//     if (reason != null && reason.trim().isNotEmpty) {
//       body['reason'] = reason.trim();
//     }
//
//     await ApiClient.instance.postJson(Routes.applyLeave, body: body);
//   }
// }




// lib/data/services/leave_service.dart
import 'package:intl/intl.dart';

import '../models/leave_and_holidays_model.dart';
import 'http_client.dart';
import 'auth_service.dart';
import 'routes.dart';

class LeaveService {
  LeaveService._();
  static final LeaveService instance = LeaveService._();

  String _requireEmployeeId() {
    final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: employeeId not available.');
    }
    return id;
  }

  Future<LeaveAndHolidays> getLeaveAndHolidays() async {
    final id = _requireEmployeeId();
    final json = await ApiClient.instance.getJson(Routes.leaveAndHolidays(id));
    return LeaveAndHolidays.fromJson(json);
  }

  Future<void> applyLeave({
    required int leavePolicyId,
    required DateTime from,
    required DateTime to,
    bool halfDay = false,
    bool includeWeekends = true,
    String? reason,
  }) async {
    final employeeId = _requireEmployeeId();

    // 1️⃣ Calculate Leave Days
    // If halfDay is true, we assume it's 0.5 days.
    // Otherwise, it's the difference in days + 1 (inclusive).
    double leaveDays;
    if (halfDay) {
      leaveDays = 0.5;
    } else {
      final diff = to.difference(from).inDays;
      leaveDays = (diff + 1).toDouble();
      // Ensure non-negative
      if (leaveDays < 0) leaveDays = 0;
    }

    final ymd = DateFormat('yyyy-MM-dd');

    final body = <String, dynamic>{
      'employeeId': employeeId,
      'leavePolicyId': leavePolicyId,

      // Backend expects these specific keys based on your JSON:
      'startDate': ymd.format(from),
      'endDate': ymd.format(to),
      'leaveDays': leaveDays,           // ✅ ADDED: Missing required field
      'status': 'PENDING_APPROVAL',     // ✅ ADDED: Missing required field

      // Retain these just in case your backend logic uses them as flags or aliases
      'fromDate': ymd.format(from),
      'toDate': ymd.format(to),
      'halfDay': halfDay,
      'includeWeekends': includeWeekends,
    };

    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }

    await ApiClient.instance.postJson(Routes.applyLeave, body: body);
  }
}