import 'package:intl/intl.dart';
import './http_client.dart';
import './auth_service.dart';
import './routes.dart';
import '../models/shift_roster_model.dart';

class ShiftService {
  ShiftService._();
  static final ShiftService instance = ShiftService._();

  String _requireEmployeeId() {
    final id = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
    if (id == null || id.isEmpty) {
      throw StateError('Not signed in: employeeId not available.');
    }
    return id;
  }

  Future<EmployeeShiftRoster?> getShiftForDate(DateTime day) async {
    final empId = _requireEmployeeId();
    final ymd = DateFormat('yyyy-MM-dd').format(day);
    final list = await ApiClient.instance.getList(
      Routes.employeeShiftRoster(empId, ymd, ymd),
    );
    if (list.isEmpty) return null;
    return EmployeeShiftRoster.fromJson(list.first as Map<String, dynamic>);
  }

  Future<EmployeeShiftRoster?> getTodayShift() => getShiftForDate(DateTime.now());
}
