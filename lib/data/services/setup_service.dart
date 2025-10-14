import 'http_client.dart';
import '../models/shift_master_model.dart';

class SetupService {
  Future<List<ShiftMaster>> getAllShifts() async {
    final list = await ApiClient.instance.getList('/api/setup/wfm/shifts');
    return list
        .map((e) => ShiftMaster.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
