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





import 'package:intl/intl.dart';

import 'http_client.dart';
import 'auth_service.dart';

class TimesheetService {
  TimesheetService._();
  static final TimesheetService instance = TimesheetService._();

  String _requireEmployeeId() {
    final id = SessionController.instance.employeeId ??
        AuthService.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: employeeId not available.');
    }
    return id;
  }

  String _d(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  /// Fetch my timesheet between [start] and [end].
  ///
  /// NOTE: This returns the raw decoded JSON OBJECT.
  /// If your API returns an ARRAY instead, change the signature to:
  ///   Future<List<dynamic>> getMyTimesheet({...})
  /// and use `await ApiClient.instance.getList(path);`
  Future<Map<String, dynamic>> getMyTimesheet({
    required DateTime start,
    required DateTime end,
  }) async {
    final employeeId = _requireEmployeeId();
    final path =
        '/api/timesheet/entries/$employeeId?start=${_d(start)}&end=${_d(end)}';

    final json = await ApiClient.instance.getJson(path);
    return json; // raw decoded object
  }

  /// Example punch/clock operation for the signed-in employee.
  /// Adjust path/body to your backend if needed.
  Future<void> clockAction({
    required String action, // 'IN' | 'OUT'
    required DateTime when,
  }) async {
    final employeeId = _requireEmployeeId();
    await ApiClient.instance.postJson(
      '/api/timesheet/clock/$employeeId',
      body: {
        'action': action,
        'timestamp': when.toIso8601String(),
      },
    );
  }

  // ---------------- Back-compat shims (optional) ----------------

  /// DEPRECATED: prefer getMyTimesheet(start:, end:) without passing employeeId.
  @Deprecated('Use getMyTimesheet(start:, end:) without passing employeeId.')
  Future<Map<String, dynamic>> getTimesheet(
      String _ignoredEmployeeId, {
        required DateTime start,
        required DateTime end,
      }) =>
      getMyTimesheet(start: start, end: end);

  /// DEPRECATED: prefer clockAction(action:, when:) for the signed-in employee.
  @Deprecated('Use clockAction(action:, when:) for the signed-in employee.')
  Future<void> clockActionFor(
      String _ignoredEmployeeId, {
        required String action,
        required DateTime when,
      }) =>
      clockAction(action: action, when: when);
}

