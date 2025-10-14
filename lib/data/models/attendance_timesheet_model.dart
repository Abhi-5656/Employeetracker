class AttendanceEntry {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String totalHours;
  final String status;

  AttendanceEntry({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.totalHours,
    required this.status,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      date: json['date'] as String,
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      totalHours: json['totalHours'] as String,
      status: json['status'] as String,
    );
  }
}