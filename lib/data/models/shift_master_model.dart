// class ShiftMaster {
//   final String shiftId;
//   final String shiftName;
//   final String startTime;
//   final String endTime;
//   final String duration;
//   final bool isActive;
//
//   ShiftMaster({
//     required this.shiftId,
//     required this.shiftName,
//     required this.startTime,
//     required this.endTime,
//     required this.duration,
//     required this.isActive,
//   });
//
//   factory ShiftMaster.fromJson(Map<String, dynamic> json) {
//     return ShiftMaster(
//       shiftId: json['shiftId'] as String,
//       shiftName: json['shiftName'] as String,
//       startTime: json['startTime'] as String,
//       endTime: json['endTime'] as String,
//       duration: json['duration'] as String,
//       isActive: json['isActive'] as bool,
//     );
//   }
// }



// lib/data/models/shift_master_model.dart
class ShiftMaster {
  final int? id;
  final String? shiftName;
  final String? shiftLabel;
  final String? startTime;  // "08:00"
  final String? endTime;    // "16:00"
  final String? color;      // "#4A90E2" (optional)
  final bool? isActive;

  ShiftMaster({
    this.id,
    this.shiftName,
    this.shiftLabel,
    this.startTime,
    this.endTime,
    this.color,
    this.isActive,
  });

  factory ShiftMaster.fromJson(Map<String, dynamic> json) {
    return ShiftMaster(
      id: (json['id'] as num?)?.toInt(),
      shiftName: json['shiftName'] as String?,
      shiftLabel: json['shiftLabel'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool?,
    );
  }
}
