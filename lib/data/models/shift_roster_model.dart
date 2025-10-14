class ShiftDTO {
  final int? id;
  final String? shiftName;
  final String? shiftLabel;
  final String? color;       // e.g. "#4A90E2"
  final String? startTime;   // "08:00"
  final String? endTime;     // "16:00"
  final bool? isActive;

  ShiftDTO({
    this.id, this.shiftName, this.shiftLabel, this.color,
    this.startTime, this.endTime, this.isActive,
  });

  factory ShiftDTO.fromJson(Map<String, dynamic> j) => ShiftDTO(
    id: (j['id'] is num) ? (j['id'] as num).toInt() : null,
    shiftName: j['shiftName'] as String?,
    shiftLabel: j['shiftLabel'] as String?,
    color: j['color'] as String?,
    startTime: j['startTime'] as String?,
    endTime: j['endTime'] as String?,
    isActive: j['isActive'] as bool?,
  );
}

class EmployeeShiftRoster {
  final String? employeeId;
  final String? fullName;
  final String? calendarDate; // "YYYY-MM-DD"
  final ShiftDTO? shift;
  final bool? isWeekOff;
  final bool? isHoliday;
  final String? weekday;

  EmployeeShiftRoster({
    this.employeeId, this.fullName, this.calendarDate,
    this.shift, this.isWeekOff, this.isHoliday, this.weekday,
  });

  factory EmployeeShiftRoster.fromJson(Map<String, dynamic> j) => EmployeeShiftRoster(
    employeeId: j['employeeId'] as String?,
    fullName: j['fullName'] as String?,
    calendarDate: j['calendarDate'] as String?,
    shift: j['shift'] == null ? null : ShiftDTO.fromJson(j['shift'] as Map<String,dynamic>),
    isWeekOff: j['isWeekOff'] as bool?,
    isHoliday: j['isHoliday'] as bool?,
    weekday: j['weekday'] as String?,
  );
}
