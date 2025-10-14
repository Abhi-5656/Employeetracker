class ShiftMaster {
  final String shiftId;
  final String shiftName;
  final String startTime;
  final String endTime;
  final String duration;
  final bool isActive;

  ShiftMaster({
    required this.shiftId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isActive,
  });

  factory ShiftMaster.fromJson(Map<String, dynamic> json) {
    return ShiftMaster(
      shiftId: json['shiftId'] as String,
      shiftName: json['shiftName'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      duration: json['duration'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}