// import 'http_client.dart';
// import 'auth_service.dart';
// import 'routes.dart';
//
// class EmployeeService {
//   EmployeeService._();
//   static final EmployeeService instance = EmployeeService._();
//
//   String _requireEmployeeId() {
//     final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
//     if (id == null || id.isEmpty) {
//       throw StateError('Not signed in: employeeId not available.');
//     }
//     return id;
//   }
//
//   Future<Map<String, dynamic>> getMe() async {
//     final id = _requireEmployeeId();
//     return await ApiClient.instance.getJson(Routes.employeeById(id));
//   }
//
//   Future<Map<String, dynamic>> getEmployeeByEmail(String email) async {
//     // This call uses the token set temporarily during the login flow.
//     return await ApiClient.instance.getJson(Routes.employeeByEmail(email));
//   }
// }

// --- 👇 ADD THESE IMPORTS AT THE TOP ---
import 'package:maplibre_gl/maplibre_gl.dart'; // For LatLng
import 'package:flutter/foundation.dart';
import '../models/reportee_model.dart';
import 'http_client.dart';
import 'auth_service.dart';
import 'routes.dart';
import '../models/employee_profile_model.dart';
import 'package:intl/intl.dart'; // 🎯 ADD THIS IMPORT

// --- 👇 ADD THIS DTO CLASS ---
// This class will hold the full response from the new API
class SessionPathResponse {
  final int sessionId;
  final String employeeId;
  final List<LatLng> path;
  final String startedAt; // 👈 ADD THIS
  final String endedAt;   // 👈 ADD THIS

  SessionPathResponse({
    required this.sessionId,
    required this.employeeId,
    required this.path,
    required this.startedAt, // 👈 ADD THIS
    required this.endedAt,   // 👈 ADD THIS
  });

  factory SessionPathResponse.fromJson(Map<String, dynamic> json) {
    var pathData = (json['path'] as List<dynamic>?) ?? [];
    List<LatLng> fullPath = pathData.map((coord) => LatLng(
      (coord['latitude'] as num).toDouble(),
      (coord['longitude'] as num).toDouble(),
    )).toList();

    return SessionPathResponse(
      sessionId: json['sessionId'] as int,
      employeeId: json['employeeId'] as String,
      path: fullPath,
      startedAt: json['startedAt'] as String? ?? '', // 👈 ADD THIS
      endedAt: json['endedAt'] as String? ?? '',     // 👈 ADD THIS
    );
  }
}
class EmployeeService {
  EmployeeService._();
  static final EmployeeService instance = EmployeeService._();

  // String _requireEmail() {
  //   final e = AuthService.instance.email ?? SessionController.instance.email;
  //   if (e == null || e.isEmpty) {
  //     throw StateError('Not signed in: email not available.');
  //   }
  //   return e;
  // }

  String _requireEmployeeId() {
    final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('employeeId not available.');
    }
    return id;
  }
  Future<EmployeeProfile> getProfileById() async {
    final id = _requireEmployeeId();
    final json = await ApiClient.instance.getJson(Routes.employeeById(id));
    return EmployeeProfile.fromJson(json);
  }

  /// Use EMAIL as the source of truth (because backend doesn't return employeeId at login).
  Future<Map<String, dynamic>> getMe() async {
    final id = _requireEmployeeId();
    return await ApiClient.instance.getJson(Routes.employeeById(id));
  }

  /// If you already have an ID somewhere, this still works.
  Future<Map<String, dynamic>> getById(String employeeId) async {
    return await ApiClient.instance.getJson(Routes.employeeById(employeeId));
  }

  /// Explicit lookup by email.
  Future<Map<String, dynamic>> getEmployeeByEmail(String email) async {
    return await ApiClient.instance.getJson(Routes.employeeByEmail(email));
  }

  /// Optional helper: fill AuthService.employeeId lazily if missing.
  Future<void> ensureEmployeeIdCached() async {
    if ((AuthService.instance.employeeId ?? '').isNotEmpty) return;
    final ej = await getMe();
    final eid = (ej['employeeId'] as String?) ?? (ej['id'] as String?);
    final name = (ej['employeeName'] as String?) ?? (ej['fullName'] as String?) ?? (ej['name'] as String?);
    if (eid != null && eid.isNotEmpty) {
      AuthService.instance.updateProfile(employeeId: eid, employeeName: name);
    }
  }
  /// Fetches the list of reportees for the currently logged-in user.
  Future<List<ReporteeModel>> getReportees() async {
    try {
      // We use getList because the API returns a JSON array (a List)
      final dynamic dataList = await ApiClient.instance.getList(Routes.getReportees);

      if (dataList is List) {
        return dataList
            .map((json) => ReporteeModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return []; // Return empty list if response is not a list
    } catch (e) {
      debugPrint('Failed to get reportees: $e');
      return []; // Return empty list on any error
    }
  }
// --- 👇 ADD THIS NEW METHOD ---

  /// Fetches the latest path for a specific reportee.
  Future<SessionPathResponse> getLatestReporteePath(String employeeId) async {
    try {
      final responseJson = await ApiClient.instance.getJson(
        Routes.getLatestReporteePath(employeeId),
      );
      return SessionPathResponse.fromJson(responseJson);
    } catch (e) {
      debugPrint('Failed to get reportee path: $e');
      // Re-throw to be handled by the FutureBuilder
      throw Exception('Failed to load path: $e');
    }
  }

  // 🎯 ADD THIS NEW METHOD
  /// Fetches the path for a specific reportee on a specific date.
  Future<SessionPathResponse> getReporteePathForDate(String employeeId, DateTime date) async {
    // 🎯 FIX: Define ymd outside the try-block to make it accessible in the catch-block
    final String ymd = DateFormat('yyyy-MM-dd').format(date);

    try {
      final responseJson = await ApiClient.instance.getJson(
        Routes.getReporteePathForDate(employeeId, ymd),
      );
      return SessionPathResponse.fromJson(responseJson);
    } catch (e) {
      debugPrint('Failed to get reportee path for date $ymd: $e');
      // Now 'ymd' is accessible here
      throw Exception('Failed to load path for $ymd: $e');
    }
  }

}
