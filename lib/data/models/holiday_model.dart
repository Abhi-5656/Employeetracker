// data/models/holiday_model.dart
// Minimal, defensive model that tolerates multiple backend JSON shapes.

class Holiday {
  final int? id;
  final String name;            // Holiday display name
  final String type;            // "NATIONAL", "RELIGIOUS", "REGIONAL" or raw text
  final DateTime startDate;     // inclusive
  final DateTime? endDate;      // inclusive (null => one-day holiday)

  const Holiday({
    this.id,
    required this.name,
    required this.type,
    required this.startDate,
    this.endDate,
  });

  /// Accept both camelCase and snake_case keys and multiple naming variants.
  factory Holiday.fromJson(Map<String, dynamic> json) {
    // id
    final id = (json['id'] ?? json['holidayId']) as int?;

    // name
    final name = (json['holidayName'] ?? json['name'] ?? json['title'] ?? '').toString();

    // type
    final type = (json['holidayType'] ?? json['type'] ?? json['category'] ?? '').toString();

    // Dates – try common keys
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) {
        // accept epoch secs or ms
        final ms = v > 20000000000 ? v : v * 1000;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
      return DateTime.tryParse(v.toString());
    }

    final sd = _parseDate(json['startDate'] ?? json['date'] ?? json['fromDate']);
    final ed = _parseDate(json['endDate'] ?? json['toDate']);

    if (sd == null) {
      throw FormatException('Holiday.startDate missing/invalid: $json');
    }

    return Holiday(
      id: id,
      name: name.isEmpty ? 'Holiday' : name,
      type: type.isEmpty ? 'UNKNOWN' : type,
      startDate: DateTime(sd.year, sd.month, sd.day),
      endDate: ed != null ? DateTime(ed.year, ed.month, ed.day) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'holidayName': name,
    'holidayType': type,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
  };

  /// True if this holiday covers the given (local) date.
  bool coversDate(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = endDate == null
        ? s
        : DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }
}
