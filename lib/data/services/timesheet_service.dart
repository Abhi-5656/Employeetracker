// import 'package:intl/intl.dart';
// import '../models/attendance_timesheet_model.dart';
// import 'http_client.dart';
// import '../models/timesheet_model.dart'; // for TimesheetEntry type in other methods
//
// class TimesheetService {
//   final _fmt = DateFormat('yyyy-MM-dd');
//
//   Future<List<AttendanceEntry>> getTimesheetsForRange({
//     required String employeeId,
//     required DateTime startDate,
//     required DateTime endDate,
//   }) async {
//     final list = await ApiClient.instance.getList(
//       '/api/wfm/timesheets/employee/$employeeId/range',
//       query: {
//         'startDate': _fmt.format(startDate),
//         'endDate': _fmt.format(endDate),
//       },
//     );
//     // Your API returns attendance-like rows: use the actual DTO you have
//     return list
//         .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
//
//   /// If your UI already builds the correct JSON shape, pass it directly.
//   Future<void> saveTimesheetsBulkRaw(List<Map<String, dynamic>> entriesJson) async {
//     await ApiClient.instance.postJson('/api/wfm/timesheets/bulk', {
//       'entries': entriesJson,
//     });
//   }
// }





// import 'package:intl/intl.dart';
//
// import 'http_client.dart';
// import 'auth_service.dart';
//
// class TimesheetService {
//   TimesheetService._();
//   static final TimesheetService instance = TimesheetService._();
//
//   String _requireEmployeeId() {
//     final id = SessionController.instance.employeeId ??
//         AuthService.instance.employeeId;
//     if (id == null || id.isEmpty) {
//       throw StateError('Not signed in: employeeId not available.');
//     }
//     return id;
//   }
//
//   String _d(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
//
//   /// Fetch my timesheet between [start] and [end].
//   ///
//   /// NOTE: This returns the raw decoded JSON OBJECT.
//   /// If your API returns an ARRAY instead, change the signature to:
//   ///   Future<List<dynamic>> getMyTimesheet({...})
//   /// and use `await ApiClient.instance.getList(path);`
//   Future<Map<String, dynamic>> getMyTimesheet({
//     required DateTime start,
//     required DateTime end,
//   }) async {
//     final employeeId = _requireEmployeeId();
//     final path =
//         '/api/timesheet/entries/$employeeId?start=${_d(start)}&end=${_d(end)}';
//
//     final json = await ApiClient.instance.getJson(path);
//     return json; // raw decoded object
//   }
//
//   /// Example punch/clock operation for the signed-in employee.
//   /// Adjust path/body to your backend if needed.
//   Future<void> clockAction({
//     required String action, // 'IN' | 'OUT'
//     required DateTime when,
//   }) async {
//     final employeeId = _requireEmployeeId();
//     await ApiClient.instance.postJson(
//       '/api/timesheet/clock/$employeeId',
//       body: {
//         'action': action,
//         'timestamp': when.toIso8601String(),
//       },
//     );
//   }
//
//   // ---------------- Back-compat shims (optional) ----------------
//
//   /// DEPRECATED: prefer getMyTimesheet(start:, end:) without passing employeeId.
//   @Deprecated('Use getMyTimesheet(start:, end:) without passing employeeId.')
//   Future<Map<String, dynamic>> getTimesheet(
//       String _ignoredEmployeeId, {
//         required DateTime start,
//         required DateTime end,
//       }) =>
//       getMyTimesheet(start: start, end: end);
//
//   /// DEPRECATED: prefer clockAction(action:, when:) for the signed-in employee.
//   @Deprecated('Use clockAction(action:, when:) for the signed-in employee.')
//   Future<void> clockActionFor(
//       String _ignoredEmployeeId, {
//         required String action,
//         required DateTime when,
//       }) =>
//       clockAction(action: action, when: when);
// }





import 'package:intl/intl.dart';

import 'auth_service.dart';
import 'http_client.dart';
import 'tenant_service.dart';

class TimesheetService {
  TimesheetService._();
  static final TimesheetService instance = TimesheetService._();

  // ✅ CloudFront distribution for timesheets
  static const String _cfBase = 'https://d3hs9u8alp2av.cloudfront.net';

  String _requireEmployeeId({String? employeeIdOpt}) {
    if (employeeIdOpt != null && employeeIdOpt.isNotEmpty) return employeeIdOpt;

    final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: employeeId not available.');
    }
    return id;
  }

  /// Build absolute CloudFront URL:
  /// https://d3.../{tenantId}/api/wfm/timesheets/employee/{employeeId}/range?start=YYYY-MM-DD&end=YYYY-MM-DD
  String _cfTimesheetRangeUrl({
    required String tenantId,
    required String employeeId,
    required String startYmd,
    required String endYmd,
  }) {
    return '$_cfBase/$tenantId/api/wfm/timesheets/employee/$employeeId/range'
        '?start=$startYmd&end=$endYmd';   // 👈 keys are start/end
  }

  /// Returns raw rows as a list of maps via CloudFront absolute URL
  Future<List<Map<String, dynamic>>> getRangeRaw({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    final id = _requireEmployeeId(employeeIdOpt: employeeId);

    final tenant = TenantService.instance.tenantId;
    if (tenant == null || tenant.isEmpty) {
      throw StateError('Tenant is not configured.');
    }

    final ymd = DateFormat('yyyy-MM-dd');
    final startYmd = ymd.format(start);
    final endYmd   = ymd.format(end);

    // ✅ Absolute URL (ApiClient will NOT prepend ALB base)
    final absoluteUrl = _cfTimesheetRangeUrl(
      tenantId: tenant,
      employeeId: id,
      startYmd: startYmd,
      endYmd: endYmd,
    );

    final list = await ApiClient.instance.getList(absoluteUrl);

    return list.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getMyTimesheet({
    required DateTime start,
    required DateTime end,
  }) {
    return getRangeRaw(start: start, end: end);
  }

  Future<List<Map<String, dynamic>>> getRangeThisWeekRaw({String? employeeId}) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end   = start.add(const Duration(days: 6));
    return getRangeRaw(start: start, end: end, employeeId: employeeId);
  }
}
