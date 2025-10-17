// class ShiftDTO {
//   final int? id;
//   final String? shiftName;
//   final String? shiftLabel;
//   final String? color;       // e.g. "#4A90E2"
//   final String? startTime;   // "08:00"
//   final String? endTime;     // "16:00"
//   final bool? isActive;
//
//   ShiftDTO({
//     this.id, this.shiftName, this.shiftLabel, this.color,
//     this.startTime, this.endTime, this.isActive,
//   });
//
//   factory ShiftDTO.fromJson(Map<String, dynamic> j) => ShiftDTO(
//     id: (j['id'] is num) ? (j['id'] as num).toInt() : null,
//     shiftName: j['shiftName'] as String?,
//     shiftLabel: j['shiftLabel'] as String?,
//     color: j['color'] as String?,
//     startTime: j['startTime'] as String?,
//     endTime: j['endTime'] as String?,
//     isActive: j['isActive'] as bool?,
//   );
// }
//
// class EmployeeShiftRoster {
//   final String? employeeId;
//   final String? fullName;
//   final String? calendarDate; // "YYYY-MM-DD"
//   final ShiftDTO? shift;
//   final bool? isWeekOff;
//   final bool? isHoliday;
//   final String? weekday;
//
//   EmployeeShiftRoster({
//     this.employeeId, this.fullName, this.calendarDate,
//     this.shift, this.isWeekOff, this.isHoliday, this.weekday,
//   });
//
//   factory EmployeeShiftRoster.fromJson(Map<String, dynamic> j) => EmployeeShiftRoster(
//     employeeId: j['employeeId'] as String?,
//     fullName: j['fullName'] as String?,
//     calendarDate: j['calendarDate'] as String?,
//     shift: j['shift'] == null ? null : ShiftDTO.fromJson(j['shift'] as Map<String,dynamic>),
//     isWeekOff: j['isWeekOff'] as bool?,
//     isHoliday: j['isHoliday'] as bool?,
//     weekday: j['weekday'] as String?,
//   );
// }



// lib/data/models/shift_roster_model.dart
import 'shift_master_model.dart';

class EmployeeShiftRoster {
  final String? employeeId;
  final String? fullName;
  final String? calendarDate; // "2025-10-13"
  final String? weekday;      // "MONDAY"
  final bool? isWeekOff;
  final bool? isHoliday;
  final bool? deleted;
  final String? assignedBy;
  final ShiftMaster? shift;   // may be null on off/holiday

  EmployeeShiftRoster({
    this.employeeId,
    this.fullName,
    this.calendarDate,
    this.weekday,
    this.isWeekOff,
    this.isHoliday,
    this.deleted,
    this.assignedBy,
    this.shift,
  });

  factory EmployeeShiftRoster.fromJson(Map<String, dynamic> json) {
    return EmployeeShiftRoster(
      employeeId: json['employeeId'] as String?,
      fullName: json['fullName'] as String?,
      calendarDate: json['calendarDate'] as String?,
      weekday: json['weekday'] as String?,
      isWeekOff: json['isWeekOff'] as bool?,
      isHoliday: json['isHoliday'] as bool?,
      deleted: json['deleted'] as bool?,
      assignedBy: json['assignedBy'] as String?,
      shift: (json['shift'] is Map) ? ShiftMaster.fromJson(json['shift'] as Map<String, dynamic>) : null,
    );
  }
}

