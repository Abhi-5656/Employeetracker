// import 'package:flutter/material.dart';
// import '../../shared/ui.dart';
//
// class ScheduleScreen extends StatelessWidget {
//   final VoidCallback onPickShift;
//   final VoidCallback onRequestTimeOff;
//   final VoidCallback onCantMake;
//   const ScheduleScreen({
//     super.key,
//     required this.onPickShift,
//     required this.onRequestTimeOff,
//     required this.onCantMake,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GradientScaffold(
//       title: 'My Schedule',
//       trailing: const Icon(Icons.calendar_today_rounded),
//       child: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           Card(
//             margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       OutlineChip('← Prev', onTap: () {}),
//                       const Spacer(),
//                       const Flexible(
//                         child: Center(
//                           child: Text('Week 16-22 Sep',
//                               maxLines: 1, overflow: TextOverflow.ellipsis,
//                               style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
//                         ),
//                       ),
//                       const Spacer(),
//                       OutlineChip('Next →', onTap: () {}),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   const WeekStrip(days: [
//                     SchedDayData('Mon', '16', '08-16', 'Line A', true),
//                     SchedDayData('Tue', '17', '08-16', 'Line A', true),
//                     SchedDayData('Wed', '18', '08-16', 'Line A', true),
//                     SchedDayData('Thu', '19', '08-16', 'Line A', true),
//                     SchedDayData('Fri', '20', '08-16', 'Line A', true),
//                     SchedDayData('Sat', '21', 'OFF',   '',      false),
//                     SchedDayData('Sun', '22', 'OFF',   '',      false),
//                   ]),
//                 ],
//               ),
//             ),
//           ),
//           const SectionHeader('Available Shifts', icon: Icons.work_history),
//           ...[
//             _AvailShift(
//               title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
//               rate: '1.5x Rate',
//               badges: const ['✓ Qualified', 'Weekend Shift'],
//               primary: 'Pick Up',
//               onPrimary: onPickShift,
//               secondary: 'Details',
//             ),
//             _AvailShift(
//               title: 'Sun 22 Sep: 14:00-22:00 (Line C)',
//               rate: '2.0x Rate',
//               badges: const ['⚠ Training Needed', 'Night Shift'],
//               primary: 'Request Training',
//               onPrimary: () => ScaffoldMessenger.of(context)
//                   .showSnackBar(const SnackBar(content: Text('Training requested'))),
//               secondary: 'Details',
//             ),
//           ].map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: w)),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//             child: Row(
//               children: [
//                 Expanded(child: ActionBtn.outline('Swap Shifts', () {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap flow')));
//                 }, context)),
//                 const SizedBox(width: 8),
//                 Expanded(child: ActionBtn.danger('Can\'t Make It', onCantMake)),
//                 const SizedBox(width: 8),
//                 Expanded(child: ActionBtn.primary('Request Time Off', onRequestTimeOff)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AvailShift extends StatelessWidget {
//   final String title;
//   final String rate;
//   final List<String> badges;
//   final String primary;
//   final VoidCallback onPrimary;
//   final String? secondary;
//
//   const _AvailShift({
//     required this.title,
//     required this.rate,
//     required this.badges,
//     required this.primary,
//     required this.onPrimary,
//     this.secondary,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
//               Pill(rate, bg: Colors.green, fg: Colors.white),
//             ]),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 6,
//               runSpacing: -6,
//               children: badges.map((b) => Chip(
//                 label: Text(b),
//                 visualDensity: VisualDensity.compact,
//                 side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
//               )).toList(),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 if (secondary != null)
//                   Expanded(child: ActionBtn.outline(secondary!, () {
//                     ScaffoldMessenger.of(context)
//                         .showSnackBar(const SnackBar(content: Text('Details opened')));
//                   }, context)),
//                 Expanded(child: ActionBtn.primary(primary, onPrimary)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/ui.dart';

// ✅ Existing roster API
import '../../data/services/shift_service.dart';
import '../../data/models/shift_roster_model.dart';

// ✅ NEW: holidays API + auth
import '../../data/models/holiday_model.dart';
import '../../data/services/holiday_service.dart';
import '../../data/services/auth_service.dart';

// 🎯 View modes
enum ScheduleViewMode { week, month }

class ScheduleScreen extends StatefulWidget {
  final VoidCallback onPickShift;
  final VoidCallback onRequestTimeOff;
  final VoidCallback onCantMake;

  const ScheduleScreen({
    super.key,
    required this.onPickShift,
    required this.onRequestTimeOff,
    required this.onCantMake,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _anchor; // any day inside the visible period
  Future<List<EmployeeShiftRoster>>? _future;

  // 🔒 Keep existing default: week view
  ScheduleViewMode _viewMode = ScheduleViewMode.week;

  // --- Holidays state (cached by year; 'yyyy-MM-dd' -> list of Holiday) ---
  final Map<String, List<Holiday>> _holidaysByDateKey = {};
  int? _holidaysYearLoaded;
  bool _holidaysLoading = false;
  String? _holidaysError;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
    _loadRoster();
    // Kick off holiday load for the current visible year without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureHolidaysForVisibleYear(_startOfPeriod(_anchor));
    });
  }

  // ---------- Period helpers ----------
  DateTime _startOfPeriod(DateTime d) {
    if (_viewMode == ScheduleViewMode.month) {
      return DateTime(d.year, d.month, 1);
    }
    final wd = d.weekday; // 1..7 (Mon..Sun)
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1)); // Monday
  }

  DateTime _endOfPeriod(DateTime start) {
    if (_viewMode == ScheduleViewMode.month) {
      return DateTime(start.year, start.month + 1, 0); // last day of month
    }
    return start.add(const Duration(days: 6)); // Sunday
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- Data loads ----------
  void _loadRoster() {
    final start = _startOfPeriod(_anchor);
    final end = _endOfPeriod(start);
    setState(() {
      _future = ShiftService.instance.getRosterForRange(start: start, end: end);
    });
  }

  /// Robust loader that never throws if API returns partial/dirty holiday rows.
  Future<void> _ensureHolidaysForVisibleYear(DateTime anyDayInPeriod) async {
    final y = anyDayInPeriod.year;
    if (_holidaysYearLoaded == y || _holidaysLoading) return;

    final empId = AuthService.instance.employeeId;
    if (empId == null || empId.isEmpty) return;

    setState(() {
      _holidaysLoading = true;
      _holidaysError = null;
    });

    try {
      final list = await HolidayService.instance
          .fetchEmployeeHolidays(employeeId: empId, year: y);

      // Index holidays by date (handles multi-day holidays)
      final map = <String, List<Holiday>>{};
      for (final h in list) {
        DateTime d = h.startDate;
        final last = h.endDate ?? h.startDate;
        while (!d.isAfter(last)) {
          final k = _dayKey(d);
          (map[k] ??= <Holiday>[]).add(h);
          d = d.add(const Duration(days: 1));
        }
      }

      setState(() {
        _holidaysByDateKey.addAll(map);
        _holidaysYearLoaded = y;
        _holidaysError = null; // ✅ clear any previous error
      });
    } catch (e) {
      // Read a statusCode if the thrown error has one (from ApiClient.ApiException)
      int? code;
      try {
        final dyn = e as dynamic;
        if (dyn.statusCode is int) code = dyn.statusCode as int;
      } catch (_) {}

      // If backend says “no holidays” (404/204), treat as empty, not an error.
      if (code == 404 || code == 204) {
        setState(() {
          _holidaysYearLoaded = y;
          _holidaysError = null; // ✅ do NOT show the yellow warning
        });
      } else {
        // Real failure (network, 5xx, parse, etc.) — show the warning line
        setState(() => _holidaysError = 'Holidays fetch failed');
      }
    } finally {
      if (mounted) setState(() => _holidaysLoading = false);
    }

  }










  // Future<void> _ensureHolidaysForVisibleYear(DateTime anyDayInPeriod) async {
  //   final y = anyDayInPeriod.year;
  //   if (_holidaysYearLoaded == y || _holidaysLoading) return;
  //
  //   // Pull employee id from your auth/session
  //   final empId = AuthService.instance.employeeId ??
  //       AuthService.instance.profile?.employeeId?.toString();
  //
  //   if (empId == null || empId.isEmpty) return;
  //
  //   setState(() {
  //     _holidaysLoading = true;
  //     _holidaysError = null;
  //   });
  //
  //   try {
  //     final list = await HolidayService.instance
  //         .fetchEmployeeHolidays(employeeId: empId, year: y);
  //
  //     // Index holidays by each covered day (handles single/multi-day holidays).
  //     final map = <String, List<Holiday>>{};
  //     for (final h in list) {
  //       try {
  //         // Be tolerant: start/end can be null; skip if invalid.
  //         final DateTime? start = _extractDate(h.startDate);
  //         final DateTime? end = _extractDate(h.endDate) ?? start;
  //         if (start == null || end == null) continue;
  //
  //         // Ensure start <= end
  //         final DateTime first =
  //         start.isAfter(end) ? end : start;
  //         final DateTime last =
  //         end.isBefore(start) ? start : end;
  //
  //         DateTime d = DateTime(first.year, first.month, first.day);
  //         final endD = DateTime(last.year, last.month, last.day);
  //
  //         while (!d.isAfter(endD)) {
  //           final k = _dayKey(d);
  //           (map[k] ??= <Holiday>[]).add(h);
  //           d = d.add(const Duration(days: 1));
  //         }
  //       } catch (_) {
  //         // Skip bad holiday rows silently
  //         continue;
  //       }
  //     }
  //
  //     setState(() {
  //       _holidaysByDateKey.addAll(map); // additive caching
  //       _holidaysYearLoaded = y;
  //     });
  //   } catch (e) {
  //     // Soft-fail: Keep the rest of the screen functional
  //     setState(() => _holidaysError = 'Holidays fetch failed');
  //   } finally {
  //     if (mounted) setState(() => _holidaysLoading = false);
  //   }
  // }

  /// Accepts DateTime or null; returns DateTime? (no parsing of strings here).
  /// If your Holiday model uses String dates in some tenants, switch to:
  ///   DateTime? _extractDate(dynamic v) { if (v is DateTime) return v; if (v is String && v.isNotEmpty) return DateTime.tryParse(v); return null; }
  DateTime? _extractDate(DateTime? v) => v;

  // ---------- Navigation ----------
  void _prevPeriod() {
    setState(() {
      if (_viewMode == ScheduleViewMode.month) {
        _anchor = DateTime(_anchor.year, _anchor.month - 1, 1);
      } else {
        _anchor = _anchor.subtract(const Duration(days: 7));
      }
    });
    _loadRoster();
    _ensureHolidaysForVisibleYear(_startOfPeriod(_anchor));
  }

  void _nextPeriod() {
    setState(() {
      if (_viewMode == ScheduleViewMode.month) {
        _anchor = DateTime(_anchor.year, _anchor.month + 1, 1);
      } else {
        _anchor = _anchor.add(const Duration(days: 7));
      }
    });
    _loadRoster();
    _ensureHolidaysForVisibleYear(_startOfPeriod(_anchor));
  }

  // ---------- UI helpers ----------
  String _buildHeaderLabel(DateTime start, DateTime end) {
    if (_viewMode == ScheduleViewMode.month) {
      return DateFormat('MMMM yyyy').format(start);
    }
    final hdr =
        '${DateFormat('dd MMM').format(start)} — ${DateFormat('dd MMM yyyy').format(end)}';
    return 'Week $hdr';
  }

  List<SchedDayData> _buildWeekStrip(List<EmployeeShiftRoster> roster) {
    final start = _startOfPeriod(_anchor);

    final byDate = <String, EmployeeShiftRoster>{};
    for (final r in roster) {
      final k = r.calendarDate;
      if (k != null) byDate[k] = r;
    }

    const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fmtIso = DateFormat('yyyy-MM-dd');
    final days = <SchedDayData>[];

    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final key = fmtIso.format(day);
      final r = byDate[key];

      final hasShift = (r?.shift?.startTime != null || r?.shift?.endTime != null);
      final isOff = r?.isWeekOff == true;
      // Prefer roster.isHoliday if backend already merges it. If not, month view still uses the fetched map.
      final isHoliday = r?.isHoliday == true;

      String time;
      if (isHoliday) {
        time = 'HOL';
      } else if (isOff) {
        time = 'OFF';
      } else if (hasShift) {
        time = _compactTime(r!.shift!.startTime, r.shift!.endTime); // e.g. 08-16
      } else {
        time = '—';
      }

      final location =
      (hasShift ? (r!.shift?.shiftLabel ?? r.shift?.shiftName ?? '') : '');

      days.add(
        SchedDayData(
          weekdayShort[(day.weekday - 1) % 7],
          DateFormat('d').format(day),
          time,
          location,
          hasShift && !isHoliday && !isOff,
        ),
      );
    }
    return days;
  }

  /// Month list: holidays **replace** the shift line; supports multi-holiday days.
  List<Widget> _buildMonthList(List<EmployeeShiftRoster> roster) {
    if (roster.isEmpty && _monthHasNoHolidayKeys()) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No entries this month.')),
        )
      ];
    }

    // Merge roster days with all days in visible month so holidays show even if no roster row exists
    final mapByDate = <String, EmployeeShiftRoster?>{};
    for (final r in roster) {
      if (r.calendarDate != null) {
        mapByDate[r.calendarDate!] = r;
      }
    }

    final start = DateTime(_anchor.year, _anchor.month, 1);
    final end = DateTime(_anchor.year, _anchor.month + 1, 0);
    DateTime d = start;
    while (!d.isAfter(end)) {
      final key = _dayKey(d);
      mapByDate.putIfAbsent(key, () => mapByDate[key]);
      d = d.add(const Duration(days: 1));
    }

    final sortedKeys = mapByDate.keys.toList()..sort();

    return sortedKeys.map((key) {
      final r = mapByDate[key];
      final date = DateFormat('EEEE, dd MMM').format(DateTime.parse(key));

      final todaysHolidays = _holidaysByDateKey[key] ?? const <Holiday>[];
      final hasHoliday = todaysHolidays.isNotEmpty || r?.isHoliday == true;

      final isOff = r?.isWeekOff == true;
      final hasShift = (r?.shift?.startTime != null || r?.shift?.endTime != null);

      String subtitle;
      IconData icon;
      Color color;

      if (hasHoliday) {
        final names = todaysHolidays.isNotEmpty
            ? todaysHolidays.map((h) => h.name).toSet().join(', ')
            : 'Holiday';
        icon = Icons.beach_access_rounded;
        color = Colors.lightGreen;
        if (isOff) {
          subtitle = 'Holiday: $names · OFF Day';
        } else if (hasShift) {
          final time = _compactTime(r!.shift!.startTime, r.shift!.endTime);
          final loc = r.shift?.shiftLabel ?? r.shift?.shiftName ?? '';
          subtitle = 'Holiday: $names${time.trim().isNotEmpty ? " · Shift: $time" : ""}${loc.isNotEmpty ? " | Location: $loc" : ""}';
        } else {
          subtitle = 'Holiday: $names';
        }
      } else if (isOff) {
        icon = Icons.calendar_today;
        color = Colors.blueGrey;
        subtitle = 'OFF Day – ${r?.shift?.shiftLabel ?? 'No Shift'}';
      } else if (hasShift) {
        icon = Icons.work;
        color = Colors.blue;
        final time = _compactTime(r!.shift!.startTime, r.shift!.endTime);
        final loc = r.shift?.shiftLabel ?? r.shift?.shiftName ?? '';
        subtitle = 'Shift: $time${loc.isNotEmpty ? " | Location: $loc" : ""}';
      } else {
        icon = Icons.event_busy;
        color = Colors.orange;
        subtitle = 'No Shift Scheduled';
      }

      return Column(
        children: [
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            dense: true,
            onTap: () {},
          ),
          const Divider(height: 1),
        ],
      );
    }).toList();
  }

  bool _monthHasNoHolidayKeys() {
    final start = DateTime(_anchor.year, _anchor.month, 1);
    final end = DateTime(_anchor.year, _anchor.month + 1, 0);
    DateTime d = start;
    while (!d.isAfter(end)) {
      if (_holidaysByDateKey.containsKey(_dayKey(d))) return false;
      d = d.add(const Duration(days: 1));
    }
    return true;
  }

  String _compactTime(String? start, String? end) {
    String cut(String? hhmm) {
      if (hhmm == null || hhmm.isEmpty) return '—';
      final parts = hhmm.split(':');
      if (parts.length < 2) return hhmm;
      final h = parts[0].padLeft(2, '0');
      final m = parts[1];
      if (m == '00') return h;
      return '$h:$m';
    }
    return '${cut(start)}-${cut(end)}';
  }
  // 🎯 NEW: Helper to build the Calendar Grid for Month View
  Widget _buildMonthCalendar(List<EmployeeShiftRoster> roster) {
    final startOfMonth = DateTime(_anchor.year, _anchor.month, 1);
    final daysInMonth = DateTime(_anchor.year, _anchor.month + 1, 0).day;

    // Determine starting offset (Mon=0, Tue=1, etc.)
    // We assume Monday start to match your Week View.
    // weekday returns 1(Mon)..7(Sun). We convert to 0..6.
    final firstWeekday = startOfMonth.weekday;
    final startingOffset = firstWeekday - 1;

    // Map roster for O(1) lookup
    final Map<String, EmployeeShiftRoster> rosterMap = {};
    for (final r in roster) {
      if (r.calendarDate != null) rosterMap[r.calendarDate!] = r;
    }

    final List<String> weekHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // 1. Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekHeaders.map((e) => Expanded(
              child: Text(e,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
              ),
            )).toList(),
          ),
        ),

        // 2. The Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth + startingOffset,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.8, // Adjust height of cells
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            // Empty cells before the 1st of the month
            if (index < startingOffset) {
              return const SizedBox.shrink();
            }

            final dayNum = index - startingOffset + 1;
            final date = DateTime(_anchor.year, _anchor.month, dayNum);
            final dateKey = DateFormat('yyyy-MM-dd').format(date);

            final rosterItem = rosterMap[dateKey];
            final holidays = _holidaysByDateKey[dateKey] ?? [];

            return _buildCalendarCell(dayNum, rosterItem, holidays);
          },
        ),

        // 3. Holiday Warning (Keep existing logic)
        if (_monthHasNoHolidayKeys() && _holidaysError != null)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Holidays fetch failed', style: TextStyle(color: Colors.orange, fontSize: 12)),
          ),
      ],
    );
  }

  // 🎯 NEW: Helper to build individual Calendar Cell
  Widget _buildCalendarCell(int dayNum, EmployeeShiftRoster? r, List<Holiday> holidays) {
    final isHoliday = (r?.isHoliday == true) || holidays.isNotEmpty;
    final isOff = r?.isWeekOff == true;
    final hasShift = (r?.shift?.startTime != null || r?.shift?.endTime != null);

    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    String? infoText;
    Color statusColor = Colors.transparent;

    if (isHoliday) {
      bgColor = const Color(0xFFE8F5E9); // Light Green
      statusColor = Colors.green;
      infoText = "HOL";
    } else if (isOff) {
      bgColor = const Color(0xFFF5F5F5); // Light Grey
      infoText = "OFF";
    } else if (hasShift) {
      bgColor = const Color(0xFFE3F2FD); // Light Blue
      statusColor = Colors.blue;
      // Format: 08:00
      final start = r?.shift?.startTime?.split(':').take(2).join(':') ?? '';
      infoText = start;
    }

    return InkWell(
      onTap: () {
        // Optional: Show details in snackbar or bottom sheet
        if (r != null) {
          final details = isHoliday ? 'Holiday' : (hasShift ? '${r.shift?.startTime}-${r.shift?.endTime}' : 'No Shift');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Day $dayNum: $details'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNum',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOff ? Colors.grey : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            if (infoText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor == Colors.transparent ? Colors.grey[300] : statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  infoText,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor == Colors.transparent ? Colors.black54 : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = _startOfPeriod(_anchor);
    final end = _endOfPeriod(start);
    final headerLabel = _buildHeaderLabel(start, end);

    final showHolidayFetchNote =
        _viewMode == ScheduleViewMode.month && _holidaysError != null && _monthHasNoHolidayKeys();

    return GradientScaffold(
      title: 'My Schedule',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ScheduleViewMode.week
                    ? ScheduleViewMode.month
                    : ScheduleViewMode.week;
              });
              _loadRoster();
              _ensureHolidaysForVisibleYear(_startOfPeriod(_anchor));
            },
            child: Text(
              _viewMode == ScheduleViewMode.week ? 'MONTH VIEW' : 'WEEK VIEW',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.calendar_today_rounded),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      OutlineChip('← Prev', onTap: _prevPeriod),
                      const Spacer(),
                      Flexible(
                        child: Center(
                          child: Text(
                            headerLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlineChip('Next →', onTap: _nextPeriod),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<EmployeeShiftRoster>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(snap.error.toString()),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                        return const SizedBox.shrink();
                      }

                      final roster =
                          snap.data ?? const <EmployeeShiftRoster>[];

                      if (_viewMode == ScheduleViewMode.week) {
                        final strip = _buildWeekStrip(roster);
                        return WeekStrip(days: strip);
                      } else {
                        // NEW CODE:
                        return _buildMonthCalendar(roster);
                        // ---------------- CHANGE ENDS HERE ----------------
                        // final monthListWidgets = _buildMonthList(roster);
                        // return Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     const Padding(
                        //       padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        //       child: Text(
                        //         'Monthly Roster Details:',
                        //         style: TextStyle(fontWeight: FontWeight.bold),
                        //       ),
                        //     ),
                        //     ...monthListWidgets,
                        //     if (showHolidayFetchNote) ...[
                        //       const SizedBox(height: 8),
                        //       const Text(
                        //         'Holidays fetch failed',
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: Colors.orange,
                        //         ),
                        //       ),
                        //     ],
                        //   ],
                        // );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Available Shifts (unchanged) ---
          const SectionHeader('Available Shifts', icon: Icons.work_history),
          ...[
            _AvailShift(
              title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
              rate: '1.5x Rate',
              badges: const ['✓ Qualified', 'Weekend Shift'],
              primary: 'Pick Up',
              onPrimary: widget.onPickShift,
              secondary: 'Details',
            ),
            _AvailShift(
              title: 'Sun 22 Sep: 14:00-22:00 (Line C)',
              rate: '2.0x Rate',
              badges: const ['⚠ Training Needed', 'Night Shift'],
              primary: 'Request Training',
              onPrimary: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Training requested'))),
              secondary: 'Details',
            ),
          ].map((w) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: w,
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                    child: ActionBtn.outline(
                        'Swap Shifts',
                            () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Swap flow')));
                        },
                        context)),
                const SizedBox(width: 8),
                Expanded(
                    child: ActionBtn.danger(
                        'Can\'t Make It', widget.onCantMake)),
                const SizedBox(width: 8),
                Expanded(
                    child: ActionBtn.primary(
                        'Request Time Off', widget.onRequestTimeOff)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----- supporting classes (unchanged visually/behaviorally) -----
class _AvailShift extends StatelessWidget {
  final String title;
  final String rate;
  final List<String> badges;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;

  const _AvailShift({
    super.key,
    required this.title,
    required this.rate,
    required this.badges,
    required this.primary,
    required this.onPrimary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14))),
              Pill(rate, bg: Colors.green, fg: Colors.white),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: badges
                  .map((b) => Chip(
                label: Text(b),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(
                    color: Color(0xFFE9ECEF), width: 2),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (secondary != null)
                  Expanded(
                      child: ActionBtn.outline(secondary!, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Details opened')));
                      }, context)),
                Expanded(child: ActionBtn.primary(primary, onPrimary)),
              ],
            )
          ],
        ),
      ),
    );
  }
}














// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../shared/ui.dart';
//
// // ✅ Service + models you added earlier for roster API
// import '../../data/services/shift_service.dart';
// import '../../data/models/shift_roster_model.dart';
//
// // 🎯 NEW: Enum for view modes
// enum ScheduleViewMode { week, month }
//
// class ScheduleScreen extends StatefulWidget {
//   final VoidCallback onPickShift;
//   final VoidCallback onRequestTimeOff;
//   final VoidCallback onCantMake;
//
//   const ScheduleScreen({
//     super.key,
//     required this.onPickShift,
//     required this.onRequestTimeOff,
//     required this.onCantMake,
//   });
//
//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }
//
// class _ScheduleScreenState extends State<ScheduleScreen> {
//   late DateTime _anchor; // any day in the visible period
//   Future<List<EmployeeShiftRoster>>? _future;
//
//   // 🎯 NEW STATE: Track the current view mode (default is week)
//   ScheduleViewMode _viewMode = ScheduleViewMode.week;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize anchor to the current date
//     _anchor = DateTime.now();
//     _loadRoster();
//   }
//
//   // ---- Date Calculation Helpers ----
//
//   // 🎯 Determines the start date of the current period based on view mode
//   DateTime _startOfPeriod(DateTime d) {
//     if (_viewMode == ScheduleViewMode.month) {
//       // Return the first day of the month
//       return DateTime(d.year, d.month, 1);
//     }
//     // Default to Monday start for week view
//     final wd = d.weekday; // 1..7 (Mon..Sun)
//     return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
//   }
//
//   // 🎯 Calculates the end date of the current period
//   DateTime _endOfPeriod(DateTime start) {
//     if (_viewMode == ScheduleViewMode.month) {
//       // Calculate the last day of the month
//       return DateTime(start.year, start.month + 1, 0);
//     }
//     // Sunday end for week view (6 days after Monday start)
//     return start.add(const Duration(days: 6));
//   }
//
//   // ---- Loading Logic ----
//
//   void _loadRoster() {
//     final start = _startOfPeriod(_anchor);
//     final end = _endOfPeriod(start);
//     setState(() {
//       // The same API is used, but with monthly start/end dates
//       _future = ShiftService.instance.getRosterForRange(start: start, end: end);
//     });
//   }
//
//   // 🎯 NEW: Navigate to the previous period (week or month)
//   void _prevPeriod() {
//     setState(() {
//       if (_viewMode == ScheduleViewMode.month) {
//         _anchor = DateTime(_anchor.year, _anchor.month - 1, 1);
//       } else {
//         _anchor = _anchor.subtract(const Duration(days: 7));
//       }
//     });
//     _loadRoster();
//   }
//
//   // 🎯 NEW: Navigate to the next period (week or month)
//   void _nextPeriod() {
//     setState(() {
//       if (_viewMode == ScheduleViewMode.month) {
//         _anchor = DateTime(_anchor.year, _anchor.month + 1, 1);
//       } else {
//         _anchor = _anchor.add(const Duration(days: 7));
//       }
//     });
//     _loadRoster();
//   }
//
//   // ---- UI Mapping Helpers ----
//
//   // 🎯 Helper to build the header label based on view mode
//   String _buildHeaderLabel(DateTime start, DateTime end) {
//     if (_viewMode == ScheduleViewMode.month) {
//       return DateFormat('MMMM yyyy').format(start); // e.g., October 2025
//     }
//     // Weekly format
//     final hdr = '${DateFormat('dd MMM').format(start)} — ${DateFormat('dd MMM yyyy').format(end)}';
//     return 'Week $hdr';
//   }
//
//   // 🎯 _buildWeekStrip: Used ONLY when in Week View Mode
//   List<SchedDayData> _buildWeekStrip(List<EmployeeShiftRoster> roster) {
//     final start = _startOfPeriod(_anchor);
//
//     // index roster by date for O(1) lookups
//     final fmtIso = DateFormat('yyyy-MM-dd');
//     final byDate = <String, EmployeeShiftRoster>{};
//     for (final r in roster) {
//       final k = r.calendarDate;
//       if (k != null) byDate[k] = r;
//     }
//
//     const weekdayShort = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
//     final days = <SchedDayData>[];
//
//     // Iterate over 7 days for the WeekStrip visualization
//     for (int i = 0; i < 7; i++) {
//       final day = start.add(Duration(days: i));
//       final key = fmtIso.format(day);
//       final r = byDate[key];
//
//       final hasShift = (r?.shift?.startTime != null || r?.shift?.endTime != null);
//       final isOff = r?.isWeekOff == true;
//       final isHoliday = r?.isHoliday == true;
//
//       String time;
//       if (isHoliday) {
//         time = 'HOL';
//       } else if (isOff) {
//         time = 'OFF';
//       } else if (hasShift) {
//         time = _compactTime(r!.shift!.startTime, r.shift!.endTime); // e.g. 08-16
//       } else {
//         time = '—';
//       }
//
//       final location = (hasShift ? (r!.shift?.shiftLabel ?? r.shift?.shiftName ?? '') : '');
//
//       days.add(
//         SchedDayData(
//           // Adjust weekday index (Dart: Mon=1, Sun=7. Array: 0..6)
//           weekdayShort[(day.weekday - 1) % 7],
//           DateFormat('d').format(day),
//           time,
//           location,
//           hasShift && !isHoliday && !isOff,
//         ),
//       );
//     }
//     return days;
//   }
//
//   // 🎯 NEW: Builds the full monthly list of shifts
//   List<Widget> _buildMonthList(List<EmployeeShiftRoster> roster) {
//     // Roster items already contain shift details; filter for relevant days
//
//     if (roster.isEmpty) {
//       return [const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No shifts scheduled this month.')))];
//     }
//
//     // Ensure data is sorted by date
//     roster.sort((a, b) => (a.calendarDate ?? '').compareTo(b.calendarDate ?? ''));
//
//     return roster.map((r) {
//       final date = r.calendarDate != null ? DateFormat('EEEE, dd MMM').format(DateTime.parse(r.calendarDate!)) : 'Unknown Date';
//       final hasShift = (r.shift?.startTime != null || r.shift?.endTime != null);
//       final isOff = r.isWeekOff == true;
//       final isHoliday = r.isHoliday == true;
//
//       String shiftDetails;
//       IconData icon;
//       Color color;
//
//       if (isHoliday) {
//         // 🎯 FIX: Assuming a field named 'holidayName' exists in the backend data model
//         // that's merged into the EmployeeShiftRoster list.
//         shiftDetails = 'HOLIDAY: ${r.shift ?? r.shift?.shiftLabel ?? 'General Holiday'}';
//         icon = Icons.beach_access_rounded;
//         color = Colors.lightGreen;
//       } else if (isOff) {
//         shiftDetails = 'OFF Day - ${r.shift?.shiftLabel ?? 'No Shift'}';
//         icon = Icons.calendar_today;
//         color = Colors.blueGrey;
//       } else if (hasShift) {
//         final time = _compactTime(r.shift!.startTime, r.shift!.endTime);
//         shiftDetails = 'Shift: $time | Location: ${r.shift?.shiftLabel ?? r.shift?.shiftName}';
//         icon = Icons.work;
//         color = Colors.blue;
//       } else {
//         // Day with no shift defined or shift details are incomplete
//         shiftDetails = 'No Shift Scheduled';
//         icon = Icons.event_busy;
//         color = Colors.orange;
//       }
//
//       return Column(
//         children: [
//           ListTile(
//             leading: Icon(icon, color: color),
//             title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
//             subtitle: Text(shiftDetails),
//             dense: true,
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing shift details for $date')));
//             },
//           ),
//           const Divider(height: 1),
//         ],
//       );
//     }).toList();
//   }
//
//   String _compactTime(String? start, String? end) {
//     String cut(String? hhmm) {
//       if (hhmm == null || hhmm.isEmpty) return '—';
//       final parts = hhmm.split(':');
//       if (parts.length < 2) return hhmm;
//       final h = parts[0].padLeft(2, '0');
//       final m = parts[1];
//       if (m == '00') return h;
//       return '$h:$m';
//     }
//     return '${cut(start)}-${cut(end)}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final start = _startOfPeriod(_anchor);
//     final end = _endOfPeriod(start);
//     final headerLabel = _buildHeaderLabel(start, end);
//
//     return GradientScaffold(
//       title: 'My Schedule',
//       // 🎯 NEW: Trailing row with the toggle button
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 _viewMode = _viewMode == ScheduleViewMode.week
//                     ? ScheduleViewMode.month
//                     : ScheduleViewMode.week;
//                 _loadRoster(); // Reload roster when mode changes
//               });
//             },
//             child: Text(
//               _viewMode == ScheduleViewMode.week ? 'MONTH VIEW' : 'WEEK VIEW',
//               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const Icon(Icons.calendar_today_rounded),
//         ],
//       ),
//       child: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           Card(
//             margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       // 🎯 Period navigation buttons
//                       OutlineChip('← Prev', onTap: _prevPeriod),
//                       const Spacer(),
//                       Flexible(
//                         child: Center(
//                           child: Text(
//                             headerLabel,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
//                           ),
//                         ),
//                       ),
//                       const Spacer(),
//                       OutlineChip('Next →', onTap: _nextPeriod),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//
//                   // 🔁 FutureBuilder for the Roster Strip / Month List
//                   FutureBuilder<List<EmployeeShiftRoster>>(
//                     future: _future,
//                     builder: (context, snap) {
//                       if (snap.connectionState != ConnectionState.done) {
//                         return const Center(child: CircularProgressIndicator());
//                       }
//                       if (snap.hasError) {
//                         WidgetsBinding.instance.addPostFrameCallback((_) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text(snap.error.toString()), behavior: SnackBarBehavior.floating),
//                           );
//                         });
//                         return const SizedBox.shrink();
//                       }
//
//                       final roster = snap.data ?? const <EmployeeShiftRoster>[];
//
//                       if (_viewMode == ScheduleViewMode.week) {
//                         // 1. WEEK VIEW: Show the 7-day strip (existing visualization)
//                         final strip = _buildWeekStrip(roster);
//                         return WeekStrip(days: strip);
//                       } else {
//                         // 2. MONTH VIEW: Show the full list of all shifts in the month
//                         final monthListWidgets = _buildMonthList(roster);
//                         // We return a small container with the list, replacing the WeekStrip visually
//                         // NOTE: If the list is empty, show a dedicated message.
//                         if (monthListWidgets.isEmpty || (monthListWidgets.length == 1 && monthListWidgets[0] is Center)) {
//                           return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No shift details found for this month.')));
//                         }
//
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Padding(
//                               padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
//                               child: Text('Monthly Roster Details:', style: TextStyle(fontWeight: FontWeight.bold)),
//                             ),
//                             ...monthListWidgets
//                           ],
//                         );
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // 🔽 Available Shifts and Actions remain unchanged
//           const SectionHeader('Available Shifts', icon: Icons.work_history),
//           ...[
//             _AvailShift(
//               title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
//               rate: '1.5x Rate',
//               badges: const ['✓ Qualified', 'Weekend Shift'],
//               primary: 'Pick Up',
//               onPrimary: widget.onPickShift,
//               secondary: 'Details',
//             ),
//             _AvailShift(
//               title: 'Sun 22 Sep: 14:00-22:00 (Line C)',
//               rate: '2.0x Rate',
//               badges: const ['⚠ Training Needed', 'Night Shift'],
//               primary: 'Request Training',
//               onPrimary: () => ScaffoldMessenger.of(context)
//                   .showSnackBar(const SnackBar(content: Text('Training requested'))),
//               secondary: 'Details',
//             ),
//           ].map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: w)),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//             child: Row(
//               children: [
//                 Expanded(child: ActionBtn.outline('Swap Shifts', () {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap flow')));
//                 }, context)),
//                 const SizedBox(width: 8),
//                 Expanded(child: ActionBtn.danger('Can\'t Make It', widget.onCantMake)),
//                 const SizedBox(width: 8),
//                 Expanded(child: ActionBtn.primary('Request Time Off', widget.onRequestTimeOff)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ----- supporting classes remain unchanged -----
// class _AvailShift extends StatelessWidget {
//   final String title;
//   final String rate;
//   final List<String> badges;
//   final String primary;
//   final VoidCallback onPrimary;
//   final String? secondary;
//
//   const _AvailShift({
//     super.key,
//     required this.title,
//     required this.rate,
//     required this.badges,
//     required this.primary,
//     required this.onPrimary,
//     this.secondary,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               // FIX: Accessing fields directly
//               Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
//               Pill(rate, bg: Colors.green, fg: Colors.white),
//             ]),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 6,
//               runSpacing: -6,
//               children: badges
//                   .map((b) => Chip(
//                 label: Text(b),
//                 visualDensity: VisualDensity.compact,
//                 side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
//               ))
//                   .toList(),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 if (secondary != null)
//                 // FIX: Accessing fields directly
//                   Expanded(
//                       child: ActionBtn.outline(secondary!, () {
//                         ScaffoldMessenger.of(context)
//                             .showSnackBar(const SnackBar(content: Text('Details opened')));
//                       }, context)),
//                 // FIX: Accessing fields directly
//                 Expanded(child: ActionBtn.primary(primary, onPrimary)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }






//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../shared/ui.dart';
//
// // ✅ Service + models you added earlier for roster API
// import '../../data/services/shift_service.dart';
// import '../../data/models/shift_roster_model.dart';
//
// class ScheduleScreen extends StatefulWidget {
//   final VoidCallback onPickShift;
//   final VoidCallback onRequestTimeOff;
//   final VoidCallback onCantMake;
//
//   const ScheduleScreen({
//     super.key,
//     required this.onPickShift,
//     required this.onRequestTimeOff,
//     required this.onCantMake,
//   });
//
//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }
//
// class _ScheduleScreenState extends State<ScheduleScreen> {
//   late DateTime _anchor; // any day in the visible week
//   Future<List<EmployeeShiftRoster>>? _future;
//
//   @override
//   void initState() {
//     super.initState();
//     _anchor = DateTime.now();
//     _loadWeek();
//   }
//
//   // ---- Week paging helpers ----
//   DateTime _startOfWeek(DateTime d) {
//     // Monday start; adjust if your org starts Sunday
//     final wd = d.weekday; // 1..7
//     return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
//   }
//
//   void _loadWeek() {
//     final start = _startOfWeek(_anchor);
//     final end = start.add(const Duration(days: 6));
//     setState(() {
//       _future = ShiftService.instance.getRosterForRange(start: start, end: end);
//     });
//   }
//
//   void _prevWeek() {
//     setState(() => _anchor = _anchor.subtract(const Duration(days: 7)));
//     _loadWeek();
//   }
//
//   void _nextWeek() {
//     setState(() => _anchor = _anchor.add(const Duration(days: 7)));
//     _loadWeek();
//   }
//
//   // ---- Mapping API -> UI week strip ----
//   List<SchedDayData> _buildWeekStrip(List<EmployeeShiftRoster> roster) {
//     final start = _startOfWeek(_anchor);
//     final fmtDayNum = DateFormat('d');     // 1..31 (no leading zero)
//     final fmtIso = DateFormat('yyyy-MM-dd');
//     const weekdayShort = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
//
//     // index roster by date for O(1) lookups
//     final byDate = <String, EmployeeShiftRoster>{};
//     for (final r in roster) {
//       final k = r.calendarDate;
//       if (k != null) byDate[k] = r;
//     }
//
//     final days = <SchedDayData>[];
//     for (int i = 0; i < 7; i++) {
//       final day = start.add(Duration(days: i));
//       final key = fmtIso.format(day);
//       final r = byDate[key];
//
//       final hasShift = (r?.shift?.startTime != null || r?.shift?.endTime != null);
//       final isOff = r?.isWeekOff == true;
//       final isHoliday = r?.isHoliday == true;
//
//       // time like '08-16' (match your current UI)
//       String time;
//       if (isHoliday) {
//         time = 'HOL';
//       } else if (isOff) {
//         time = 'OFF';
//       } else if (hasShift) {
//         time = _compactTime(r!.shift!.startTime, r.shift!.endTime); // e.g. 08-16
//       } else {
//         time = '—';
//       }
//
//       // Location not in roster? Keep as empty (matches your UI for OFF/—)
//       final location = (hasShift ? (r!.shift?.shiftLabel ?? r.shift?.shiftName ?? '') : '');
//
//       days.add(
//         SchedDayData(
//           weekdayShort[i],
//           fmtDayNum.format(day),
//           time,
//           location,
//           hasShift && !isHoliday && !isOff,
//         ),
//       );
//     }
//     return days;
//   }
//
//   String _compactTime(String? start, String? end) {
//     String cut(String? hhmm) {
//       if (hhmm == null || hhmm.isEmpty) return '—';
//       // "08:00" -> "08", "16:30" -> "16:30" (keep minutes if non-zero)
//       final parts = hhmm.split(':');
//       if (parts.length < 2) return hhmm;
//       final h = parts[0].padLeft(2, '0');
//       final m = parts[1];
//       if (m == '00') return h; // 08
//       return '$h:$m';          // 16:30
//     }
//     return '${cut(start)}-${cut(end)}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final start = _startOfWeek(_anchor);
//     final end = start.add(const Duration(days: 6));
//     final hdr = '${DateFormat('dd MMM').format(start)} — ${DateFormat('dd MMM yyyy').format(end)}';
//
//     return GradientScaffold(
//       title: 'My Schedule',
//       trailing: const Icon(Icons.calendar_today_rounded),
//       child: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           Card(
//             margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       // Wire your existing chips
//                       OutlineChip('← Prev', onTap: _prevWeek),
//                       const Spacer(),
//                       Flexible(
//                         child: Center(
//                           // Replace static label with the computed week header
//                           child: Text(
//                             'Week $hdr',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
//                           ),
//                         ),
//                       ),
//                       const Spacer(),
//                       OutlineChip('Next →', onTap: _nextWeek),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//
//                   // 🔁 Replace the hardcoded WeekStrip with a FutureBuilder-fed one
//                   FutureBuilder<List<EmployeeShiftRoster>>(
//                     future: _future,
//                     builder: (context, snap) {
//                       if (snap.connectionState != ConnectionState.done) {
//                         // lightweight placeholder keeping your exact UI
//                         return const WeekStrip(days: [
//                           SchedDayData('Mon', '—', '—', '', false),
//                           SchedDayData('Tue', '—', '—', '', false),
//                           SchedDayData('Wed', '—', '—', '', false),
//                           SchedDayData('Thu', '—', '—', '', false),
//                           SchedDayData('Fri', '—', '—', '', false),
//                           SchedDayData('Sat', '—', '—', '', false),
//                           SchedDayData('Sun', '—', '—', '', false),
//                         ]);
//                       }
//                       if (snap.hasError) {
//                         // Render a minimal error but do not change layout
//                         WidgetsBinding.instance.addPostFrameCallback((_) {
//                           final msg = snap.error.toString();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//                           );
//                         });
//                         return const WeekStrip(days: [
//                           SchedDayData('Mon', '—', '—', '', false),
//                           SchedDayData('Tue', '—', '—', '', false),
//                           SchedDayData('Wed', '—', '—', '', false),
//                           SchedDayData('Thu', '—', '—', '', false),
//                           SchedDayData('Fri', '—', '—', '', false),
//                           SchedDayData('Sat', '—', '—', '', false),
//                           SchedDayData('Sun', '—', '—', '', false),
//                         ]);
//                       }
//                       final roster = snap.data ?? const <EmployeeShiftRoster>[];
//                       final strip = _buildWeekStrip(roster);
//                       return WeekStrip(days: strip); // ✅ your original widget
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // 🔽 Everything below remains EXACTLY as-is
//           const SectionHeader('Available Shifts', icon: Icons.work_history),
//           ...[
//             _AvailShift(
//               title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
//               rate: '1.5x Rate',
//               badges: const ['✓ Qualified', 'Weekend Shift'],
//               primary: 'Pick Up',
//               onPrimary: widget.onPickShift,
//               secondary: 'Details',
//             ),
//             _AvailShift(
//               title: 'Sun 22 Sep: 14:00-22:00 (Line C)',
//               rate: '2.0x Rate',
//               badges: const ['⚠ Training Needed', 'Night Shift'],
//               primary: 'Request Training',
//               onPrimary: () => ScaffoldMessenger.of(context)
//                   .showSnackBar(const SnackBar(content: Text('Training requested'))),
//               secondary: 'Details',
//             ),
//           ].map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: w)),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//             child: Row(
//               children: [
//                 Expanded(child: ActionBtn.outline('Swap Shifts', () {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap flow')));
//                 }, context)),
//                 const SizedBox(width: 8),
//                 Expanded(child: ActionBtn.danger('Can\'t Make It', widget.onCantMake)),
//                 const SizedBox(width: 8),
//                 Expanded(child: ActionBtn.primary('Request Time Off', widget.onRequestTimeOff)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ----- your original _AvailShift stays unchanged -----
// class _AvailShift extends StatelessWidget {
//   final String title;
//   final String rate;
//   final List<String> badges;
//   final String primary;
//   final VoidCallback onPrimary;
//   final String? secondary;
//
//   const _AvailShift({
//     required this.title,
//     required this.rate,
//     required this.badges,
//     required this.primary,
//     required this.onPrimary,
//     this.secondary,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
//               Pill(rate, bg: Colors.green, fg: Colors.white),
//             ]),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 6,
//               runSpacing: -6,
//               children: badges
//                   .map((b) => Chip(
//                 label: Text(b),
//                 visualDensity: VisualDensity.compact,
//                 side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
//               ))
//                   .toList(),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 if (secondary != null)
//                   Expanded(
//                       child: ActionBtn.outline(secondary!, () {
//                         ScaffoldMessenger.of(context)
//                             .showSnackBar(const SnackBar(content: Text('Details opened')));
//                       }, context)),
//                 Expanded(child: ActionBtn.primary(primary, onPrimary)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
