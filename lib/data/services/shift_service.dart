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

  Future<EmployeeShiftRoster?> getTodayShift() async {
    final empId = _requireEmployeeId();
    final ymd = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final list = await ApiClient.instance.getList(
      Routes.employeeShiftRoster(empId, ymd, ymd),
    );
    if (list.isEmpty) return null;
    return EmployeeShiftRoster.fromJson(list.first as Map<String, dynamic>);
  }
}
