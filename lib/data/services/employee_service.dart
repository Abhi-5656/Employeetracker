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
import 'http_client.dart';
import 'auth_service.dart';
import 'routes.dart';
import '../models/employee_profile_model.dart';
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
}
