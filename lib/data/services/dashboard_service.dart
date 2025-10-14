// import 'http_client.dart';
// import '../models/dashboard_summary_model.dart';
// import '../models/attendance_timesheet_model.dart';
//
// class DashboardService {
//   Future<DashboardSummary> getMySummary(String employeeId) async {
//     final json = await ApiClient.instance.getJson('/api/dashboard/summary/$employeeId');
//     return DashboardSummary.fromJson(json);
//   }
//
//   Future<List<AttendanceEntry>> getMyAttendance(String employeeId) async {
//     final list = await ApiClient.instance.getList('/api/dashboard/attendance/$employeeId');
//     return list
//         .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
// }


// lib/data/services/dashboard_service.dart
import '././routes.dart';

import 'http_client.dart';
import '../models/dashboard_summary_model.dart';
import '../models/attendance_timesheet_model.dart';
import 'auth_service.dart';

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  String _requireEmployeeId() {
    final id = SessionController.instance.employeeId ??
        AuthService.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: employeeId not available.');
    }
    return id;
  }

  /// Your required endpoint:
  /// GET /api/dashboard/my-summary/{employeeId}
  // Future<DashboardSummary> getMySummary() async {
  //   final employeeId = _requireEmployeeId();
  //   final json = await ApiClient.instance
  //       .getJson('/api/dashboard/my-summary/$employeeId');
  //   return DashboardSummary.fromJson(json);
  // }

  Future<DashboardSummary> getMySummary() async {
    final employeeId = _requireEmployeeId();
    // FIXED: Changed hardcoded string to use the Routes class method
    final json = await ApiClient.instance.getJson(Routes.mySummary(employeeId));
    return DashboardSummary.fromJson(json);
  }

  /// Optional: attendance pinned to same signed-in employee.
  // Future<List<AttendanceEntry>> getMyAttendance() async {
  //   final employeeId = _requireEmployeeId();
  //   final list = await ApiClient.instance
  //       .getList('/api/dashboard/attendance/$employeeId');
  //   return list
  //       .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
  //       .toList();
  // }

  Future<List<AttendanceEntry>> getMyAttendance() async {
    final employeeId = _requireEmployeeId();
    // FIXED: Changed hardcoded string to use the Routes class method
    // NOTE: This assumes you have added `dashboardAttendance` to your Routes class.
    final list = await ApiClient.instance.getList(Routes.dashboardAttendance(employeeId));
    return list
        .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
