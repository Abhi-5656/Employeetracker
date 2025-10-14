// lib/data/repositories/leave_repository.dart
import '../models/leave_and_holidays_model.dart';
import '../services/leave_service.dart';


class LeaveTabData {
  final String casual;  // numbers for StatCard
  final String sick;
  final String earned;

  final List<LeaveBalanceItem> policies;     // for dropdown
  final List<HolidayItem> holidays;          // future use (notifications)

  final List<String> dropdownLabels;         // "Casual Leave (12.0 days remaining)" etc.

  LeaveTabData({
    required this.casual,
    required this.sick,
    required this.earned,
    required this.policies,
    required this.holidays,
    required this.dropdownLabels,
  });
}

class LeaveRepository {
  LeaveRepository._();
  static final LeaveRepository instance = LeaveRepository._();

  static String _fmt(num? v) => (v ?? 0).toStringAsFixed(1);

  Future<LeaveTabData> load() async {
    final dto = await LeaveService.instance.getLeaveAndHolidays();

    // Map known policy names into the 3 stat cards you already show.
    double casual = 0, sick = 0, earned = 0;
    for (final p in dto.leaveBalances) {
      final name = (p.leaveName ?? '').toLowerCase();
      if (name.contains('casual')) casual = p.balance ?? 0;
      else if (name.contains('sick')) sick = p.balance ?? 0;
      else if (name.contains('earned')) earned = p.balance ?? 0;
    }

    // Build dropdown labels exactly like your current UI text
    final labels = dto.leaveBalances.map((p) {
      final remain = _fmt(p.balance);
      final title = p.leaveName ?? 'Leave';
      return '$title ($remain days remaining)';
    }).toList();

    return LeaveTabData(
      casual: _fmt(casual),
      sick: _fmt(sick),
      earned: _fmt(earned),
      policies: dto.leaveBalances,
      holidays: dto.upcomingHolidays,
      dropdownLabels: labels,
    );
  }
}
