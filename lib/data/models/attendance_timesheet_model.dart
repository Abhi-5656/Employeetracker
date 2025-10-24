class AttendanceEntry {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String totalHours;// may be "8:15" or "8.25" etc.
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
      totalHours: (json['totalHours'] ?? '0').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }

  /// Converts `totalHours` to minutes.
  /// Supports: "HH:mm", decimal hours "8.5" or "8.50", and integers.
  int get totalMinutes {
    final raw = totalHours.trim();

    // "HH:mm"
    final hhmm = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
    if (hhmm != null) {
      final hh = int.tryParse(hhmm.group(1)!) ?? 0;
      final mm = int.tryParse(hhmm.group(2)!) ?? 0;
      return hh * 60 + mm;
    }

    // Decimal hours "8.25" => minutes
    final asDouble = double.tryParse(raw);
    if (asDouble != null) {
      return (asDouble * 60).round();
    }

    // Fallback integer minutes
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;

    return 0;
  }

  /// Heuristic to mark exceptions (until backend sends a dedicated flag).
  bool get isException {
    final s = status.toLowerCase();
    return s.contains('miss') ||
        s.contains('exception') ||
        s.contains('anomaly') ||
        s.contains('error');
  }
}

// 🎯 NEW: DTOs for Timesheet Total Hours and Exceptions
class Anomaly {
  final String message;
  final String date;

  Anomaly({required this.message, required this.date});

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      message: json['message'] as String,
      date: json['date'] as String,
    );
  }
}

class DailyHour {
  final String day; // Abbreviated day name (Mon, Tue, etc.)
  final double hours;

  DailyHour({required this.day, required this.hours});

  factory DailyHour.fromJson(Map<String, dynamic> json) {
    return DailyHour(
      day: json['day'] as String,
      hours: (json['hours'] as num).toDouble(),
    );
  }

  // Convert decimal hours to minutes
  int get totalMinutes => (hours * 60).round();
}

class AttendanceTimesheetData {
  final double weeklyProgress;
  final Anomaly? anomaly;
  final List<DailyHour> dailyHours;

  AttendanceTimesheetData({
    required this.weeklyProgress,
    this.anomaly,
    required this.dailyHours,
  });

  factory AttendanceTimesheetData.fromJson(Map<String, dynamic> json) {
    final anomalyJson = json['anomaly'] as Map<String, dynamic>?;
    final dailyHoursList = json['dailyHours'] as List<dynamic>? ?? [];

    return AttendanceTimesheetData(
      weeklyProgress: (json['weeklyProgress'] as num).toDouble(),
      anomaly: anomalyJson != null ? Anomaly.fromJson(anomalyJson) : null,
      dailyHours: dailyHoursList
          .map((e) => DailyHour.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}