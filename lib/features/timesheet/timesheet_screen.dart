// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../shared/ui.dart';
//
// // services
// import '../../data/services/auth_service.dart';
// import '../../data/services/timesheet_service.dart';
// import '../../data/services/dashboard_service.dart';
// import '../../data/services/auth_service.dart';
// import '../../data/models/attendance_timesheet_model.dart';
//
// class TimesheetScreen extends StatefulWidget {
//   final VoidCallback onSaveDraft;
//   final VoidCallback onSubmitWeek;
//   const TimesheetScreen({super.key, required this.onSaveDraft, required this.onSubmitWeek});
//
//   @override
//   State<TimesheetScreen> createState() => _TimesheetScreenState();
// }
//
// class _TimesheetScreenState extends State<TimesheetScreen>
//     with AutomaticKeepAliveClientMixin<TimesheetScreen>
// {
//
//   String _yesterdayStr = '—';
//   String _thisWeekStr  = '—';
//   int _exceptionsCount = 0;
//
//   Future<void>? _loadFuture;
//
//   @override
//   bool get wantKeepAlive => true;
//
//   // ---------- helpers ----------
//
//   int _toMinutes(String hhmm) {
//     final p = hhmm.split(':');
//     final h = int.tryParse(p[0]) ?? 0;
//     final m = int.tryParse(p[1]) ?? 0;
//     return h * 60 + m;
//   }
//
//   /// returns minutes between "HH:mm" pair; handles overnight (out < in)
//   int _minsBetween(String? inStr, String? outStr) {
//     final a = (inStr ?? '').trim();
//     final b = (outStr ?? '').trim();
//     if (a.isEmpty || b.isEmpty) return 0;
//     var s = _toMinutes(a), e = _toMinutes(b);
//     if (e < s) e += 24 * 60; // overnight
//     return e - s;
//   }
//
//   String _fmtHrsMins(int totalMins) {
//     final h = totalMins ~/ 60;
//     final m = totalMins % 60;
//     return '${h}h ${m.toString().padLeft(2, '0')}m';
//   }
//
//   String _safeTime(dynamic v) {
//     if (v == null) return '—';
//     final raw = v.toString().trim();
//     if (raw.isEmpty || raw == '—') return '—';
//
//     final iso = DateTime.tryParse(raw);
//     if (iso != null) {
//       final hh = iso.hour.toString().padLeft(2, '0');
//       final mm = iso.minute.toString().padLeft(2, '0');
//       return '$hh:$mm';
//     }
//     final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
//     if (m != null) {
//       final hh = m.group(1)!.padLeft(2, '0');
//       final mm = m.group(2)!;
//       return '$hh:$mm';
//     }
//     final digits = raw.replaceAll(RegExp(r'\D+'), '');
//     if (digits.length == 3 || digits.length == 4) {
//       final h = int.tryParse(digits.substring(0, digits.length - 2)) ?? 0;
//       final mi = int.tryParse(digits.substring(digits.length - 2)) ?? 0;
//       return '${h.toString().padLeft(2, '0')}:${mi.toString().padLeft(2, '0')}';
//     }
//     return '—';
//   }
//
//   DateTime? _asDateTime(dynamic v) {
//     if (v == null) return null;
//     if (v is int || v is num) {
//       final n = v.toInt();
//       final ms = (n > 20000000000) ? n : n * 1000; // secs or millis
//       return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
//     }
//     final s = v.toString().trim();
//     if (s.isEmpty) return null;
//     return DateTime.tryParse(s);
//   }
//
//   String _fmt(DateTime dt) =>
//       '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//
//   bool _isMidnight(DateTime dt) => dt.hour == 0 && dt.minute == 0;
//
//   bool _isSameDay(DateTime a, DateTime b) =>
//       a.year == b.year && a.month == b.month && a.day == b.day;
//
//   /// Unified minute extraction for a timesheet "row" with various shapes.
//   int _minsOfRow(Map<String, dynamic> row) {
//     if (row['totalMinutes'] is num) return (row['totalMinutes'] as num).toInt();
//     if (row['totalDurationMinutes'] is num) return (row['totalDurationMinutes'] as num).toInt();
//     if (row['totalHours'] is num) return ((row['totalHours'] as num) * 60).toInt();
//
//     final inV  = row['checkInTime'] ?? row['inTime'] ?? row['startTime'];
//     final outV = row['checkOutTime'] ?? row['outTime'] ?? row['endTime'];
//     final a = _safeTime(inV), b = _safeTime(outV);
//     if (a == '—' || b == '—') return 0;
//
//     int _toMin(String hhmm) {
//       final parts = hhmm.split(':');
//       if (parts.length < 2) return 0;
//       final h = int.tryParse(parts[0]) ?? 0;
//       final m = int.tryParse(parts[1]) ?? 0;
//       return h * 60 + m;
//     }
//
//     var s = _toMin(a), e = _toMin(b);
//     if (e < s) e += 24 * 60;
//     return e - s;
//   }
//
//   // ---------- state ----------
//
//   List<_DayCell>? _cells; // null while loading
//   late DateTime _weekStartSun;
//   late DateTime _weekEndSat;
//
//   // rows grouped by 'yyyy-MM-dd'
//   final Map<String, List<Map<String, dynamic>>> _rowsByDate = {};
//   late DateTime _selectedDate; // which day’s details to show
//
//   // NEW: total minutes for the week (computed on each load)
//   int _totalWeekMinutes = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     final daysFromSunday = now.weekday % 7;
//     _weekStartSun = DateTime(now.year, now.month, now.day)
//         .subtract(Duration(days: daysFromSunday));
//     _weekEndSat = _weekStartSun.add(const Duration(days: 6));
//
//     // default selection = today clamped to [Sun..Sat]
//     _selectedDate = now.isBefore(_weekStartSun)
//         ? _weekStartSun
//         : (now.isAfter(_weekEndSat) ? _weekEndSat : now);
//     _loadFuture = _loadAttendanceFromBackend();
//
//     _loadWeek();
//   }
//
//   Future<void> _loadAttendanceFromBackend() async {
//     final empId = AuthService.instance.employeeId;
//     if (empId == null || empId.isEmpty) return;
//
//     final list = await DashboardService.instance.fetchAttendanceEntries(empId);
//     if (!mounted) return;
//
//     // Build a map by yyyy-MM-dd for quick lookup
//     final byDate = {for (final e in list) e.date: e};
//
//     final today = DateTime.now();
//     final y = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));
//     final ymdYesterday = _ymd(y);
//
//     // Yesterday
//     final yEntry = byDate[ymdYesterday];
//     final yMin   = yEntry?.totalMinutes ?? 0;
//
//     // Week sum up to today (Mon..Sun model, inclusive to today)
//     final weekStart = _startOfWeek(today); // Monday start
//     int weekMinutes = 0;
//     for (int i = 0; i <= today.difference(weekStart).inDays; i++) {
//       final d = weekStart.add(Duration(days: i));
//       final key = _ymd(d);
//       final e = byDate[key];
//       if (e != null) weekMinutes += e.totalMinutes;
//     }
//
//     // Exceptions (count)
//     final exCount = list.where((e) => e.isException).length;
//
//     setState(() {
//       _yesterdayStr = _fmtHhMm(yMin);
//       _thisWeekStr  = _fmtHhMm(weekMinutes);
//       _exceptionsCount = exCount;
//     });
//   }
//
//   String _ymd(DateTime d) =>
//       '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
//
//   DateTime _startOfWeek(DateTime d) {
//     // Monday as start (1..7) -> subtract weekday-1 days
//     final wd = d.weekday; // Mon=1..Sun=7
//     return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
//   }
//
//   String _fmtHhMm(int totalMin) {
//     final hh = totalMin ~/ 60;
//     final mm = totalMin % 60;
//     return '${hh}h ${mm}m';
//   }
//
//
//   Future<void> _loadWeek() async {
//     setState(() {
//       _cells = null; // show spinner in place of grid
//       _rowsByDate.clear();
//       _totalWeekMinutes = 0;
//     });
//
//     try {
//       final empId = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
//       if (empId == null || empId.isEmpty) {
//         setState(() => _cells = _buildPlaceholderCells());
//         return;
//       }
//
//       final rows = await TimesheetService.instance.getRangeRaw(
//         start: _weekStartSun,
//         end: _weekEndSat,
//       );
//
//       // group rows by date key
//       String? _keyOf(Map<String, dynamic> row) {
//         for (final k in const ['date', 'workDate', 'calendarDate', 'day', 'forDate']) {
//           final v = row[k];
//           if (v is String && v.isNotEmpty) {
//             final d = DateTime.tryParse(v);
//             if (d != null) return DateFormat('yyyy-MM-dd').format(d);
//           }
//         }
//         final inV = row['checkInTime'] ?? row['inTime'] ?? row['startTime'];
//         if (inV is String && inV.isNotEmpty) {
//           final d = DateTime.tryParse(inV);
//           if (d != null) return DateFormat('yyyy-MM-dd').format(d);
//         }
//         // if none, also try first punchEvents item date
//         final pe = row['punchEvents'];
//         if (pe is List && pe.isNotEmpty) {
//           final dt = _asDateTime((pe.first as Map)['eventTime']);
//           if (dt != null) return DateFormat('yyyy-MM-dd').format(dt);
//         }
//         return null;
//       }
//
//       for (final r in rows) {
//         if (r is! Map<String, dynamic>) continue;
//         final key = _keyOf(r);
//         if (key == null) continue;
//         (_rowsByDate[key] ??= <Map<String, dynamic>>[]).add(r);
//       }
//
//       final Map<String, int> minutesByDate = {
//         for (int i = 0; i < 7; i++)
//           DateFormat('yyyy-MM-dd').format(_weekStartSun.add(Duration(days: i))): 0
//       };
//       _rowsByDate.forEach((key, list) {
//         for (final r in list) {
//           minutesByDate[key] = (minutesByDate[key] ?? 0) + _minsOfRow(r);
//         }
//       });
//
//       // NEW: sum the week total minutes
//       int sum = 0;
//       minutesByDate.forEach((_, m) => sum += m);
//       _totalWeekMinutes = sum;
//
//       // Build grid cells
//       final newCells = <_DayCell>[];
//       for (int i = 0; i < 7; i++) {
//         final d = _weekStartSun.add(Duration(days: i));
//         final dayAbbrev = DateFormat('E').format(d);
//         final dateStr   = DateFormat('d').format(d);
//         final mins = minutesByDate[DateFormat('yyyy-MM-dd').format(d)] ?? 0;
//
//         String hoursLabel;
//         DayState state;
//         if (mins <= 0) {
//           final isWeekend = d.weekday == DateTime.sunday || d.weekday == DateTime.saturday;
//           hoursLabel = isWeekend ? 'OFF' : '0h';
//           state = isWeekend
//               ? DayState.off
//               : (_isSameDay(d, DateTime.now()) ? DayState.today : DayState.pending);
//         } else {
//           hoursLabel = '${mins ~/ 60}h';
//           state = _isSameDay(d, DateTime.now()) ? DayState.today : DayState.completed;
//         }
//         newCells.add(_DayCell(dayAbbrev, dateStr, hoursLabel, state));
//       }
//
//       if (!mounted) return;
//       setState(() => _cells = newCells);
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _cells = _buildPlaceholderCells());
//     }
//   }
//
//   List<_DayCell> _buildPlaceholderCells() => const [
//     _DayCell('Sun', '15', 'OFF', DayState.off),
//     _DayCell('Mon', '16', '8h', DayState.completed),
//     _DayCell('Tue', '17', '8h', DayState.completed),
//     _DayCell('Wed', '18', '8h', DayState.completed),
//     _DayCell('Thu', '19', '8h', DayState.today),
//     _DayCell('Fri', '20', '8h', DayState.pending),
//     _DayCell('Sat', '21', 'OFF', DayState.off),
//   ];
//
//   String _weekLabel() {
//     final left = DateFormat('d MMM').format(_weekStartSun);
//     final right = DateFormat('d MMM').format(_weekEndSat);
//     return 'Week $left - $right';
//   }
//
//   // ---- detail card (IN/OUT) for selected date ----
//   List<String> _detailPunchesForSelected() {
//     final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
//     final rows = _rowsByDate[key] ?? const <Map<String, dynamic>>[];
//
//     // A) Prefer punchEvents (or events) with explicit type + timestamp
//     final evts = <Map<String, dynamic>>[];
//     for (final r in rows) {
//       final pe = r['punchEvents'];
//       if (pe is List) {
//         for (final e in pe) {
//           if (e is Map<String, dynamic>) evts.add(e);
//         }
//       }
//       final e2 = r['events'];
//       if (e2 is List) {
//         for (final e in e2) {
//           if (e is Map<String, dynamic>) evts.add(e);
//         }
//       }
//     }
//
//     if (evts.isNotEmpty) {
//       evts.sort((a, b) {
//         final ta = _asDateTime(a['eventTime'] ?? a['time'] ?? a['timestamp'] ?? a['at']) ??
//             DateTime.fromMillisecondsSinceEpoch(0);
//         final tb = _asDateTime(b['eventTime'] ?? b['time'] ?? b['timestamp'] ?? b['at']) ??
//             DateTime.fromMillisecondsSinceEpoch(0);
//         return ta.compareTo(tb);
//       });
//
//       String? in1, out1, in2, out2;
//       for (final e in evts) {
//         final dt = _asDateTime(e['eventTime'] ?? e['time'] ?? e['timestamp'] ?? e['at']);
//         if (dt == null || !_isSameDay(dt, _selectedDate)) continue;
//
//         final tRaw = (e['punchType'] ?? e['type'] ?? e['eventType'] ?? e['action'] ?? '')
//             .toString()
//             .toUpperCase();
//
//         if (tRaw.contains('IN')) {
//           if (in1 == null) in1 = _fmt(dt);
//           else if (in2 == null) in2 = _fmt(dt);
//         } else if (tRaw.contains('OUT')) {
//           if (in1 != null && out1 == null) out1 = _fmt(dt);
//           else if (in2 != null && out2 == null) out2 = _fmt(dt);
//         }
//       }
//       return [in1 ?? '—', out1 ?? '--:-- (Pending)', in2 ?? '—', out2 ?? '—'];
//     }
//
//     // B) Otherwise, fallback to flat fields if present
//     String in1 = '—', out1 = '--:-- (Pending)', in2 = '—', out2 = '—';
//     for (final r in rows) {
//       final a = _asDateTime(r['checkInTime'] ?? r['inTime'] ?? r['startTime'] ?? r['firstInTime'] ?? r['in1']);
//       final b = _asDateTime(r['checkOutTime'] ?? r['outTime'] ?? r['endTime'] ?? r['firstOutTime'] ?? r['out1']);
//       if (a != null && _isSameDay(a, _selectedDate)) in1 = _fmt(a);
//       if (b != null && _isSameDay(b, _selectedDate)) out1 = _fmt(b);
//       if (in1 != '—' || out1 != '--:-- (Pending)') break;
//     }
//     for (final r in rows) {
//       final a2 = _asDateTime(r['secondInTime'] ?? r['in2'] ?? r['checkInTime2'] ?? r['inTime2'] ?? r['startTime2']);
//       final b2 = _asDateTime(r['secondOutTime'] ?? r['out2'] ?? r['checkOutTime2'] ?? r['outTime2'] ?? r['endTime2']);
//       if (a2 != null && _isSameDay(a2, _selectedDate)) in2 = _fmt(a2);
//       if (b2 != null && _isSameDay(b2, _selectedDate)) out2 = _fmt(b2);
//       if (in2 != '—' || out2 != '—') break;
//     }
//
//     return [in1, out1, in2, out2];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     // Selected-day dynamic totals
//     final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
//     final selectedRows = _rowsByDate[selectedKey] ?? const <Map<String, dynamic>>[];
//     final selectedMins = selectedRows.fold<int>(0, (acc, r) => acc + _minsOfRow(r));
//     final selectedDurLabel = _fmtHrsMins(selectedMins);
//
//     final punches = _detailPunchesForSelected(); // [IN, OUT, IN, OUT]
//
//     return GradientScaffold(
//       title: 'Timesheet',
//       trailing: const Icon(Icons.save_alt_rounded),
//       child: RefreshIndicator(
//         onRefresh: _loadWeek,
//         child: ListView(
//           padding: const EdgeInsets.only(bottom: 24),
//           children: [
//             SectionHeader(_weekLabel(), icon: Icons.date_range_rounded),
//
//             // Week totals (dynamic)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Text(
//                 'Total: ${_fmtHrsMins(_totalWeekMinutes)} | OT: 0h | Status: Draft',
//                 style: const TextStyle(color: Colors.black54),
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             if (_cells == null)
//               const Padding(
//                 padding: EdgeInsets.only(top: 24),
//                 child: Center(child: CircularProgressIndicator()),
//               )
//             else
//               _TimesheetWeekGrid(
//                 cells: _cells,
//                 weekStart: _weekStartSun,
//                 onTapDay: (date) => setState(() => _selectedDate = date),
//               ),
//
//             // Detail card
//             Card(
//               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           '${DateFormat('EEE d MMM').format(_selectedDate)} Details',
//                           style: const TextStyle(
//                               fontWeight: FontWeight.w800, fontSize: 16),
//                         ),
//                         const Spacer(),
//                         const Pill('In Progress', bg: Colors.orange, fg: Colors.white),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     KeyVal('IN',  '${punches[0]} (Rounded: ${punches[0] == '—' ? '—' : punches[0]})'),
//                     KeyVal('OUT', punches[1]),
//                     KeyVal('IN',  punches[2] == '—' ? '—' : '${punches[2]} (Return)'),
//                     KeyVal('OUT', punches[3] == '—' ? '--:-- (Pending)' : punches[3]),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(child: DetailTile(label: 'Total Hours', value: selectedDurLabel)),
//                         const Expanded(child: DetailTile(label: 'Exceptions', value: 'None')),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// enum DayState { today, completed, pending, off }
//
// class _DayCell {
//   final String day;
//   final String date;
//   final String hours;
//   final DayState state;
//   const _DayCell(this.day, this.date, this.hours, this.state);
// }
//
// class _TimesheetWeekGrid extends StatelessWidget {
//   final List<_DayCell>? cells;
//   final DateTime weekStart;
//   final void Function(DateTime date)? onTapDay;
//   const _TimesheetWeekGrid({
//     this.cells,
//     required this.weekStart,
//     this.onTapDay,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final cells = this.cells ??
//         const [
//           _DayCell('Sun', '15', 'OFF', DayState.off),
//           _DayCell('Mon', '16', '8h', DayState.completed),
//           _DayCell('Tue', '17', '8h', DayState.completed),
//           _DayCell('Wed', '18', '8h', DayState.completed),
//           _DayCell('Thu', '19', '8h', DayState.today),
//           _DayCell('Fri', '20', '8h', DayState.pending),
//           _DayCell('Sat', '21', 'OFF', DayState.off),
//         ];
//
//     return Card(
//       margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: GridView.count(
//           crossAxisCount: 7,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           mainAxisSpacing: 6,
//           crossAxisSpacing: 6,
//           childAspectRatio: 0.75,
//           children: [
//             for (int i = 0; i < cells.length; i++)
//               _DayTile(
//                 cell: cells[i],
//                 onTap: () {
//                   final date = DateTime(
//                     weekStart.year,
//                     weekStart.month,
//                     weekStart.day,
//                   ).add(Duration(days: i));
//                   onTapDay?.call(date);
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _DayTile extends StatelessWidget {
//   final _DayCell cell;
//   final VoidCallback? onTap;
//   const _DayTile({required this.cell, this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     Color bg; Color fg;
//     switch (cell.state) {
//       case DayState.today:     bg = const Color(0xFF667EEA); fg = Colors.white; break;
//       case DayState.completed: bg = const Color(0xFF28A745); fg = Colors.white; break;
//       case DayState.pending:   bg = const Color(0xFFFFC107); fg = Colors.black87; break;
//       case DayState.off: default: bg = const Color(0xFFF8F9FA); fg = Colors.black54;
//     }
//     return InkWell(
//       borderRadius: BorderRadius.circular(10),
//       onTap: onTap,
//       child: Ink(
//         decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
//         child: Center(
//           child: Column(mainAxisSize: MainAxisSize.min, children: [
//             Text(cell.date, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
//             const SizedBox(height: 4),
//             Text(cell.hours, style: TextStyle(color: fg, fontSize: 12)),
//           ]),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// services
import '../../data/services/auth_service.dart';
import '../../data/services/timesheet_service.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/shift_service.dart'; // 👈 Ensure this exists
import '../../data/models/attendance_timesheet_model.dart';
import '../../data/models/shift_roster_model.dart'; // 👈 Ensure this exists
import '../../shared/ui.dart';

// 🎯 DTO for Dynamic Punch Display
class PunchEventDetail {
  final String type;
  final String time;
  final String dateKey;

  PunchEventDetail({required this.type, required this.time, required this.dateKey});
}

// 🎯 Helper DTO for Pill Data
class _PillData {
  final String label;
  final Color bg;
  final Color fg;
  const _PillData(this.label, this.bg, this.fg);
}

class TimesheetScreen extends StatefulWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmitWeek;
  const TimesheetScreen({super.key, required this.onSaveDraft, required this.onSubmitWeek});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen>
    with AutomaticKeepAliveClientMixin<TimesheetScreen>
{
  // State variables for displaying summary data
  String _yesterdayStr = '—';
  String _thisWeekStr  = '—';
  int _exceptionsCount = 0;
  AttendanceTimesheetData? _summaryData;

  Future<void>? _loadFuture;

  // State variables for timesheet grid/detail
  List<_DayCell>? _cells;

  late DateTime _currentWeekStart;
  late DateTime _weekEndSat;

  final Map<String, List<Map<String, dynamic>>> _rowsByDate = {};

  // 🎯 Store Roster Data to display Schedule
  final Map<String, EmployeeShiftRoster> _rosterByDate = {};

  late DateTime _selectedDate;

  // Total minutes calculated for each day
  final Map<String, int> _minutesByDate = {};

  @override
  bool get wantKeepAlive => true;

  // ---------- initialization and loading ----------

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    final daysFromSunday = now.weekday % 7;
    _currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysFromSunday));
    _weekEndSat = _currentWeekStart.add(const Duration(days: 6));

    _selectedDate = now.isBefore(_currentWeekStart)
        ? _currentWeekStart
        : (now.isAfter(_weekEndSat) ? _weekEndSat : now);

    _loadFuture = _loadAllTimesheetData();
  }

  Future<void> _loadAllTimesheetData() async {
    // Reset display data
    setState(() {
      _cells = null;
      _rowsByDate.clear();
      _rosterByDate.clear();
      _yesterdayStr = '—';
      _thisWeekStr = '—';
      _exceptionsCount = 0;
      _summaryData = null;
      _minutesByDate.clear();
    });

    try {
      final empId = AuthService.instance.employeeId;
      if (empId == null || empId.isEmpty) {
        // 🎯 If no user, show empty cells for the ACTUAL week, not static 15-21
        setState(() => _cells = _buildEmptyCellsForWeek(_currentWeekStart));
        return;
      }

      final currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
      final systemWeekStart = _getSystemWeekStart();

      // 1. Fetch Summary Data
      try {
        if (_isSameDay(_currentWeekStart, systemWeekStart)) {
          final summary = await DashboardService.instance.getAttendanceTimesheetData();
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final yDayAbbrev = DateFormat('E').format(yesterday);

          final yDailyHour = summary.dailyHours.firstWhere(
                (dh) => dh.day == yDayAbbrev,
            orElse: () => DailyHour(day: yDayAbbrev, hours: 0.0),
          );

          final totalWeekMinutes = summary.dailyHours.fold<int>(0, (sum, dh) => sum + dh.totalMinutes);

          _yesterdayStr = _fmtHrsMins(yDailyHour.totalMinutes);
          _thisWeekStr  = _fmtHrsMins(totalWeekMinutes);
          _exceptionsCount = summary.anomaly != null ? 1 : 0;
          _summaryData = summary;
        }
      } catch (e) {
        debugPrint('⚠️ Dashboard summary failed (non-critical): $e');
      }

      // 2. Fetch Timesheet Grid Data (Critical)
      final rows = await TimesheetService.instance.getRangeRaw(
        start: _currentWeekStart,
        end: currentWeekEnd,
      );

      // 3. 🎯 Fetch Shift Roster Data (For Schedule Times)
      try {
        final rosterList = await ShiftService.instance.getRosterForRange(
          start: _currentWeekStart,
          end: currentWeekEnd,
        );
        for (final r in rosterList) {
          if (r.calendarDate != null) {
            _rosterByDate[r.calendarDate!] = r;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load shift roster: $e');
      }

      // --- Process Grid Data ---
      String? _keyOf(Map<String, dynamic> row) {
        for (final k in const ['date', 'workDate', 'calendarDate', 'day', 'forDate']) {
          final v = row[k];
          if (v is String && v.isNotEmpty) {
            final d = DateTime.tryParse(v);
            if (d != null) return DateFormat('yyyy-MM-dd').format(d);
          }
        }
        final inV = row['checkInTime'] ?? row['inTime'] ?? row['startTime'];
        if (inV is String && inV.isNotEmpty) {
          final d = DateTime.tryParse(inV);
          if (d != null) return DateFormat('yyyy-MM-dd').format(d);
        }
        return null;
      }

      for (final r in rows) {
        if (r is! Map<String, dynamic>) continue;
        final key = _keyOf(r);
        if (key == null) continue;
        (_rowsByDate[key] ??= <Map<String, dynamic>>[]).add(r);
      }

      final Map<String, int> minutesByDateLocal = {
        for (int i = 0; i < 7; i++)
          DateFormat('yyyy-MM-dd').format(_currentWeekStart.add(Duration(days: i))): 0
      };
      _rowsByDate.forEach((key, list) {
        for (final r in list) {
          minutesByDateLocal[key] = (minutesByDateLocal[key] ?? 0) + _minsOfRow(r);
        }
      });

      final newCells = <_DayCell>[];
      final today = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final d = _currentWeekStart.add(Duration(days: i));
        final dayAbbrev = DateFormat('E').format(d);
        final dateStr   = DateFormat('d').format(d);
        final mins = minutesByDateLocal[DateFormat('yyyy-MM-dd').format(d)] ?? 0;
        final isSameDay = _isSameDay(d, today);

        String hoursLabel;
        DayState state;
        if (mins <= 0) {
          final isWeekend = d.weekday == DateTime.sunday || d.weekday == DateTime.saturday;
          hoursLabel = isWeekend ? 'OFF' : '0h';
          state = isWeekend
              ? DayState.off
              : (isSameDay ? DayState.today : DayState.pending);
        } else {
          hoursLabel = '${mins ~/ 60}h';
          state = isSameDay ? DayState.today : DayState.completed;
        }
        newCells.add(_DayCell(dayAbbrev, dateStr, hoursLabel, state));
      }

      if (!mounted) return;
      setState(() {
        _cells = newCells;
        _minutesByDate.clear();
        _minutesByDate.addAll(minutesByDateLocal);
      });

    } catch (e) {
      // 🛑 THIS IS WHY YOU SAW STATIC DATA
      // An error occurred, so we printed it and generated empty cells for the CURRENT week
      print('🔴 Error loading timesheet data: $e');

      if (!mounted) return;
      setState(() {
        // 🎯 FIX: Use dynamic empty cells for the selected week, not hardcoded 15-21
        _cells = _buildEmptyCellsForWeek(_currentWeekStart);
        _yesterdayStr = 'Error';
        _thisWeekStr  = 'Error';
      });
    }
  }

  DateTime _getSystemWeekStart() {
    final now = DateTime.now();
    final daysFromSunday = now.weekday % 7;
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromSunday));
  }

  void _navigateToWeek(int offset) {
    final newWeekStart = _currentWeekStart.add(Duration(days: offset * 7));
    final daysFromWeekStart = _selectedDate.difference(_currentWeekStart).inDays;
    final newSelectedDate = newWeekStart.add(Duration(days: daysFromWeekStart));
    final newWeekEnd = newWeekStart.add(const Duration(days: 6));
    final finalSelectedDate = newSelectedDate.isAfter(newWeekEnd) ? newWeekEnd : newSelectedDate;

    setState(() {
      _currentWeekStart = newWeekStart;
      _selectedDate = finalSelectedDate;
      _loadFuture = _loadAllTimesheetData();
    });
  }

  // ---------- helper methods ----------

  String _fmtHrsMins(int totalMins) {
    if (totalMins <= 0) return '0h 00m';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _minsOfRow(Map<String, dynamic> row) {
    final totalWorkMinutes = row['totalWorkDurationMinutes'];
    if (totalWorkMinutes is num) return totalWorkMinutes.toInt();

    final totalMinsNum = row['totalMinutes'] ?? row['totalDurationMinutes'];
    if (totalMinsNum is num) return totalMinsNum.toInt();

    final rawHours = row['totalHours'] ?? row['totalDuration'] ?? row['duration'];

    if (rawHours != null) {
      if (rawHours is num) {
        return (rawHours * 60).round();
      }
      if (rawHours is String) {
        final cleanStr = rawHours.trim();
        final asDouble = double.tryParse(cleanStr);
        if (asDouble != null) return (asDouble * 60).round();

        final hhmm = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(cleanStr);
        if (hhmm != null) {
          final hh = int.tryParse(hhmm.group(1)!) ?? 0;
          final mm = int.tryParse(hhmm.group(2)!) ?? 0;
          return (hh * 60) + mm;
        }
      }
    }

    String _safeTime(dynamic v) {
      if (v == null) return '—';
      final raw = v.toString().trim();
      if (raw.isEmpty || raw == '—') return '—';
      final iso = DateTime.tryParse(raw);
      if (iso != null) {
        final hh = iso.hour.toString().padLeft(2, '0');
        final mm = iso.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      }
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
      if (m != null) {
        final hh = m.group(1)!.padLeft(2, '0');
        final mm = m.group(2)!;
        return '$hh:$mm';
      }
      final digits = raw.replaceAll(RegExp(r'\D+'), '');
      if (digits.length == 3 || digits.length == 4) {
        final h = int.tryParse(digits.substring(0, digits.length - 2)) ?? 0;
        final mi = int.tryParse(digits.substring(digits.length - 2)) ?? 0;
        return '${h.toString().padLeft(2, '0')}:${mi.toString().padLeft(2, '0')}';
      }
      return '—';
    }
    int _toMin(String hhmm) {
      final parts = hhmm.split(':');
      if (parts.length < 2) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }

    final inV  = row['checkInTime'] ?? row['inTime'] ?? row['startTime'];
    final outV = row['checkOutTime'] ?? row['outTime'] ?? row['endTime'];
    final a = _safeTime(inV), b = _safeTime(outV);
    if (a == '—' || b == '—') return 0;

    var s = _toMin(a), e = _toMin(b);
    if (e < s) e += 24 * 60;
    return e - s;
  }

  // 🎯 NEW: Dynamic placeholder builder (Replaces static 15-21 data)
  List<_DayCell> _buildEmptyCellsForWeek(DateTime start) {
    final list = <_DayCell>[];
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      final isToday = _isSameDay(d, now);
      final isWeekend = d.weekday == DateTime.sunday || d.weekday == DateTime.saturday;

      list.add(_DayCell(
        DateFormat('E').format(d),
        DateFormat('d').format(d),
        isWeekend ? 'OFF' : '0h',
        isWeekend ? DayState.off : (isToday ? DayState.today : DayState.pending),
      ));
    }
    return list;
  }

  // ❗️ This is the OLD method causing static data. You can remove it or keep it unused.
  List<_DayCell> _buildPlaceholderCells() => const [
    _DayCell('Sun', '15', 'OFF', DayState.off),
    _DayCell('Mon', '16', '—h', DayState.pending),
    // ... this was causing your static data ...
  ];

  String _weekLabel() {
    final left = DateFormat('d MMM').format(_currentWeekStart);
    final right = DateFormat('d MMM').format(_currentWeekStart.add(const Duration(days: 6)));
    return 'Week $left - $right';
  }

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is int || v is num) {
      final n = v.toInt();
      final ms = (n > 20000000000) ? n : n * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  List<PunchEventDetail> _getDynamicPunchesForSelected() {
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final rows = _rowsByDate[key] ?? const <Map<String, dynamic>>[];

    final evts = <Map<String, dynamic>>[];
    for (final r in rows) {
      final pe = r['punchEvents'];
      if (pe is List) {
        for (final e in pe) {
          if (e is Map<String, dynamic>) evts.add(e);
        }
      }
      final e2 = r['events'];
      if (e2 is List) {
        for (final e in e2) {
          if (e is Map<String, dynamic>) evts.add(e);
        }
      }
    }

    evts.sort((a, b) {
      final ta = _asDateTime(a['eventTime'] ?? a['time'] ?? a['timestamp'] ?? a['at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = _asDateTime(b['eventTime'] ?? b['time'] ?? b['timestamp'] ?? b['at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });

    final dynamicPunches = <PunchEventDetail>[];
    int punchSet = 0;

    for (final e in evts) {
      final dt = _asDateTime(e['eventTime'] ?? e['time'] ?? e['timestamp'] ?? e['at']);
      if (dt == null || !_isSameDay(dt, _selectedDate)) continue;

      final tRaw = (e['punchType'] ?? e['type'] ?? e['eventType'] ?? e['action'] ?? '')
          .toString()
          .toUpperCase();

      String typeLabel = 'EVENT';

      if (tRaw.contains('IN')) {
        punchSet++;
        typeLabel = 'Punch ${punchSet} IN';
        dynamicPunches.add(PunchEventDetail(
          type: typeLabel,
          time: _fmt(dt),
          dateKey: key,
        ));
      } else if (tRaw.contains('OUT')) {
        final currentSet = punchSet > 0 ? punchSet : 1;
        typeLabel = 'Punch ${currentSet} OUT';
        dynamicPunches.add(PunchEventDetail(
          type: typeLabel,
          time: _fmt(dt),
          dateKey: key,
        ));
      } else if (tRaw.contains('BREAK')) {
        dynamicPunches.add(PunchEventDetail(
          type: 'BREAK',
          time: _fmt(dt),
          dateKey: key,
        ));
      } else {
        dynamicPunches.add(PunchEventDetail(
          type: 'EVENT',
          time: _fmt(dt),
          dateKey: key,
        ));
      }
    }

    return dynamicPunches;
  }

  _PillData _getPillData(String rawStatus) {
    final status = rawStatus.toUpperCase();
    switch (status) {
      case 'PRESENT':
      case 'COMPLETED':
      case 'APPROVED':
      case 'VERIFIED':
        return const _PillData('Completed', Color(0xFF28A745), Colors.white);
      case 'ABSENT':
      case 'LEAVE':
      case 'HOLIDAY':
      case 'OFF':
        return const _PillData('Non-Work Day', Color(0xFF6C757D), Colors.white);
      case 'DRAFT':
      case 'PENDING':
      case 'SUBMITTED':
      case 'IN PROGRESS':
        return const _PillData('In Progress', Color(0xFFFFC107), Colors.black87);
      case 'VIOLATION':
      case 'EXCEPTION':
      case 'REJECTED':
        return const _PillData('Violation', Color(0xFFDC3545), Colors.white);
      default:
        final label = status.isNotEmpty && status.length < 20 ? status : 'Pending/Unknown';
        return _PillData(label, const Color(0xFFF8F9FA), Colors.black54);
    }
  }

  // ✅ Helper to calculate schedule duration
  String _calculateScheduleDuration(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty) return '';

    try {
      DateTime parseTime(String timeStr) {
        final parts = timeStr.split(':');
        final now = DateTime.now();
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      final s = parseTime(start);
      final e = parseTime(end);

      final endAdjusted = e.isBefore(s) ? e.add(const Duration(days: 1)) : e;
      final diff = endAdjusted.difference(s);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);

      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      if (m > 0) return '${m}m';
      return '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedRows = _rowsByDate[selectedKey] ?? const <Map<String, dynamic>>[];
    final selectedMins = selectedRows.fold<int>(0, (acc, r) => acc + _minsOfRow(r));
    final selectedDurLabel = _fmtHrsMins(selectedMins);

    final dynamicPunches = _getDynamicPunchesForSelected();

    String exceptionStatus = 'None';
    final anomaly = _summaryData?.anomaly;
    if (anomaly != null) {
      try {
        final anomalyDate = DateTime.tryParse(anomaly.date);
        if (anomalyDate != null && _isSameDay(anomalyDate, _selectedDate)) {
          String rawMessage = anomaly.message.toLowerCase();
          if (rawMessage.contains('punch-out')) {
            exceptionStatus = 'Missing Clock-Out';
          } else if (rawMessage.contains('late')) {
            exceptionStatus = 'Late Clock-In Detected';
          } else if (rawMessage.contains('early')) {
            exceptionStatus = 'Early Clock-Out Detected';
          } else if (rawMessage.contains('anomaly') || rawMessage.contains('violation')) {
            exceptionStatus = 'Policy Violation Found';
          } else {
            exceptionStatus = anomaly.message;
          }
        }
      } catch (_) {}
    }

    final dayBeforeSelected = _selectedDate.subtract(const Duration(days: 1));
    final keyDayBefore = DateFormat('yyyy-MM-dd').format(dayBeforeSelected);

    final relativeYesterdayMins = _minutesByDate[keyDayBefore] ?? 0;
    final relativeYesterdayHours = _fmtHrsMins(relativeYesterdayMins);

    final yesterdayCardLabel = _isSameDay(_selectedDate, DateTime.now())
        ? 'Yesterday'
        : DateFormat('EEE d MMM').format(dayBeforeSelected);

    final selectedRow = selectedRows.isNotEmpty ? selectedRows.first : null;
    final rawStatus = selectedRow?['status']?.toString().toUpperCase() ?? 'PENDING';
    final pillData = _getPillData(rawStatus);

    // 🎯 EXTRACT SCHEDULE DATA (Prefer Roster API, Fallback to Timesheet)
    final roster = _rosterByDate[selectedKey];

    final String? shiftStart = roster?.shift?.startTime
        ?? selectedRow?['shiftStart']?.toString()
        ?? selectedRow?['rosterStart']?.toString()
        ?? selectedRow?['startTime']?.toString();

    final String? shiftEnd = roster?.shift?.endTime
        ?? selectedRow?['shiftEnd']?.toString()
        ?? selectedRow?['rosterEnd']?.toString()
        ?? selectedRow?['endTime']?.toString();

    final String scheduleDuration = _calculateScheduleDuration(shiftStart, shiftEnd);

    // ✅ Format Schedule String
    final String scheduleDisplay = (shiftStart != null && shiftEnd != null)
        ? '$shiftStart - $shiftEnd${scheduleDuration.isNotEmpty ? ' ($scheduleDuration)' : ''}'
        : '—';

    return GradientScaffold(
      title: 'Timesheet',
      trailing: const Icon(Icons.save_alt_rounded),
      child: RefreshIndicator(
        onRefresh: _loadAllTimesheetData,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => _navigateToWeek(-1),
                  ),
                  Expanded(
                    child: SectionHeader(
                      _weekLabel(),
                      icon: Icons.date_range_rounded,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => _navigateToWeek(1),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: $_thisWeekStr | OT: 0h | Status: Draft',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: StatCard(value: relativeYesterdayHours, label: yesterdayCardLabel)),
                      Expanded(child: StatCard(value: '$_exceptionsCount', label: 'Exceptions')),
                      const Expanded(child: StatCard(value: '—', label: '—')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (_cells == null)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _TimesheetWeekGrid(
                cells: _cells,
                weekStart: _currentWeekStart,
                onTapDay: (date) => setState(() => _selectedDate = date),
              ),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${DateFormat('EEE d MMM').format(_selectedDate)} Details',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const Spacer(),
                        Pill(pillData.label, bg: pillData.bg, fg: pillData.fg),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ ADDED: Schedule Row Display
                    KeyVal('Schedule', scheduleDisplay),
                    const SizedBox(height: 12),

                    if (dynamicPunches.isEmpty)
                      const KeyVal('Punches', 'No recorded punches for this day.')
                    else
                      ...dynamicPunches.map((punch) {
                        return KeyVal(
                          punch.type,
                          punch.time,
                        );
                      }).toList(),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: DetailTile(label: 'Total Hours', value: selectedDurLabel)),
                        Expanded(child: DetailTile(label: 'Exceptions', value: exceptionStatus)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DayState { today, completed, pending, off }

class _DayCell {
  final String day;
  final String date;
  final String hours;
  final DayState state;
  const _DayCell(this.day, this.date, this.hours, this.state);
}

class _TimesheetWeekGrid extends StatelessWidget {
  final List<_DayCell>? cells;
  final DateTime weekStart;
  final void Function(DateTime date)? onTapDay;
  const _TimesheetWeekGrid({
    this.cells,
    required this.weekStart,
    this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final cells = this.cells ??
        const [
          _DayCell('Sun', '15', 'OFF', DayState.off),
          _DayCell('Mon', '16', '8h', DayState.completed),
          _DayCell('Tue', '17', '8h', DayState.completed),
          _DayCell('Wed', '18', '8h', DayState.completed),
          _DayCell('Thu', '19', '8h', DayState.today),
          _DayCell('Fri', '20', '8h', DayState.pending),
          _DayCell('Sat', '21', 'OFF', DayState.off),
        ];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.75,
          children: [
            for (int i = 0; i < cells.length; i++)
              _DayTile(
                cell: cells[i],
                onTap: () {
                  final date = DateTime(
                    weekStart.year,
                    weekStart.month,
                    weekStart.day,
                  ).add(Duration(days: i));
                  onTapDay?.call(date);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final _DayCell cell;
  final VoidCallback? onTap;
  const _DayTile({required this.cell, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg;
    switch (cell.state) {
      case DayState.today:     bg = const Color(0xFF667EEA); fg = Colors.white; break;
      case DayState.completed: bg = const Color(0xFF28A745); fg = Colors.white; break;
      case DayState.pending:   bg = const Color(0xFFFFC107); fg = Colors.black87; break;
      case DayState.off: bg = const Color(0xFFF8F9FA); fg = Colors.black54;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(cell.date, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(cell.hours, style: TextStyle(color: fg, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
