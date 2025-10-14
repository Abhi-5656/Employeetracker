// lib/data/models/leave_and_holidays_model.dart
class LeaveBalanceItem {
  final int? leavePolicyId;
  final String? leaveName;
  final double? balance;
  final double? total;

  LeaveBalanceItem({
    this.leavePolicyId,
    this.leaveName,
    this.balance,
    this.total,
  });

  factory LeaveBalanceItem.fromJson(Map<String, dynamic> j) => LeaveBalanceItem(
    leavePolicyId: j['leavePolicyId'] is num ? (j['leavePolicyId'] as num).toInt() : null,
    leaveName: j['leaveName'] as String?,
    balance: (j['balance'] is num) ? (j['balance'] as num).toDouble() : null,
    total:   (j['total']   is num) ? (j['total']   as num).toDouble()   : null,
  );
}

class HolidayItem {
  final int? id;
  final String? holidayName;
  final String? holidayType;
  final String? startDate; // "yyyy-MM-dd"
  final String? endDate;   // "yyyy-MM-dd"
  final String? startTime; // optional
  final String? endTime;   // optional

  HolidayItem({
    this.id,
    this.holidayName,
    this.holidayType,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
  });

  factory HolidayItem.fromJson(Map<String, dynamic> j) => HolidayItem(
    id: j['id'] is num ? (j['id'] as num).toInt() : null,
    holidayName: j['holidayName'] as String?,
    holidayType: j['holidayType'] as String?,
    startDate: j['startDate'] as String?,
    endDate:   j['endDate']   as String?,
    startTime: j['startTime'] as String?,
    endTime:   j['endTime']   as String?,
  );
}

class LeaveAndHolidays {
  final List<LeaveBalanceItem> leaveBalances;
  final List<HolidayItem> upcomingHolidays;

  LeaveAndHolidays({
    required this.leaveBalances,
    required this.upcomingHolidays,
  });

  factory LeaveAndHolidays.fromJson(Map<String, dynamic> j) => LeaveAndHolidays(
    leaveBalances: (j['leaveBalances'] as List<dynamic>? ?? const [])
        .map((e) => LeaveBalanceItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    upcomingHolidays: (j['upcomingHolidays'] as List<dynamic>? ?? const [])
        .map((e) => HolidayItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
