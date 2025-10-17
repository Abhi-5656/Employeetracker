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

// ✅ Service + models you added earlier for roster API
import '../../data/services/shift_service.dart';
import '../../data/models/shift_roster_model.dart';

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
  late DateTime _anchor; // any day in the visible week
  Future<List<EmployeeShiftRoster>>? _future;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
    _loadWeek();
  }

  // ---- Week paging helpers ----
  DateTime _startOfWeek(DateTime d) {
    // Monday start; adjust if your org starts Sunday
    final wd = d.weekday; // 1..7
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  void _loadWeek() {
    final start = _startOfWeek(_anchor);
    final end = start.add(const Duration(days: 6));
    setState(() {
      _future = ShiftService.instance.getRosterForRange(start: start, end: end);
    });
  }

  void _prevWeek() {
    setState(() => _anchor = _anchor.subtract(const Duration(days: 7)));
    _loadWeek();
  }

  void _nextWeek() {
    setState(() => _anchor = _anchor.add(const Duration(days: 7)));
    _loadWeek();
  }

  // ---- Mapping API -> UI week strip ----
  List<SchedDayData> _buildWeekStrip(List<EmployeeShiftRoster> roster) {
    final start = _startOfWeek(_anchor);
    final fmtDayNum = DateFormat('d');     // 1..31 (no leading zero)
    final fmtIso = DateFormat('yyyy-MM-dd');
    const weekdayShort = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    // index roster by date for O(1) lookups
    final byDate = <String, EmployeeShiftRoster>{};
    for (final r in roster) {
      final k = r.calendarDate;
      if (k != null) byDate[k] = r;
    }

    final days = <SchedDayData>[];
    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final key = fmtIso.format(day);
      final r = byDate[key];

      final hasShift = (r?.shift?.startTime != null || r?.shift?.endTime != null);
      final isOff = r?.isWeekOff == true;
      final isHoliday = r?.isHoliday == true;

      // time like '08-16' (match your current UI)
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

      // Location not in roster? Keep as empty (matches your UI for OFF/—)
      final location = (hasShift ? (r!.shift?.shiftLabel ?? r.shift?.shiftName ?? '') : '');

      days.add(
        SchedDayData(
          weekdayShort[i],
          fmtDayNum.format(day),
          time,
          location,
          hasShift && !isHoliday && !isOff,
        ),
      );
    }
    return days;
  }

  String _compactTime(String? start, String? end) {
    String cut(String? hhmm) {
      if (hhmm == null || hhmm.isEmpty) return '—';
      // "08:00" -> "08", "16:30" -> "16:30" (keep minutes if non-zero)
      final parts = hhmm.split(':');
      if (parts.length < 2) return hhmm;
      final h = parts[0].padLeft(2, '0');
      final m = parts[1];
      if (m == '00') return h; // 08
      return '$h:$m';          // 16:30
    }
    return '${cut(start)}-${cut(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(_anchor);
    final end = start.add(const Duration(days: 6));
    final hdr = '${DateFormat('dd MMM').format(start)} — ${DateFormat('dd MMM yyyy').format(end)}';

    return GradientScaffold(
      title: 'My Schedule',
      trailing: const Icon(Icons.calendar_today_rounded),
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
                      // Wire your existing chips
                      OutlineChip('← Prev', onTap: _prevWeek),
                      const Spacer(),
                      Flexible(
                        child: Center(
                          // Replace static label with the computed week header
                          child: Text(
                            'Week $hdr',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlineChip('Next →', onTap: _nextWeek),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🔁 Replace the hardcoded WeekStrip with a FutureBuilder-fed one
                  FutureBuilder<List<EmployeeShiftRoster>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        // lightweight placeholder keeping your exact UI
                        return const WeekStrip(days: [
                          SchedDayData('Mon', '—', '—', '', false),
                          SchedDayData('Tue', '—', '—', '', false),
                          SchedDayData('Wed', '—', '—', '', false),
                          SchedDayData('Thu', '—', '—', '', false),
                          SchedDayData('Fri', '—', '—', '', false),
                          SchedDayData('Sat', '—', '—', '', false),
                          SchedDayData('Sun', '—', '—', '', false),
                        ]);
                      }
                      if (snap.hasError) {
                        // Render a minimal error but do not change layout
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final msg = snap.error.toString();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
                          );
                        });
                        return const WeekStrip(days: [
                          SchedDayData('Mon', '—', '—', '', false),
                          SchedDayData('Tue', '—', '—', '', false),
                          SchedDayData('Wed', '—', '—', '', false),
                          SchedDayData('Thu', '—', '—', '', false),
                          SchedDayData('Fri', '—', '—', '', false),
                          SchedDayData('Sat', '—', '—', '', false),
                          SchedDayData('Sun', '—', '—', '', false),
                        ]);
                      }
                      final roster = snap.data ?? const <EmployeeShiftRoster>[];
                      final strip = _buildWeekStrip(roster);
                      return WeekStrip(days: strip); // ✅ your original widget
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔽 Everything below remains EXACTLY as-is
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
          ].map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: w)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(child: ActionBtn.outline('Swap Shifts', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap flow')));
                }, context)),
                const SizedBox(width: 8),
                Expanded(child: ActionBtn.danger('Can\'t Make It', widget.onCantMake)),
                const SizedBox(width: 8),
                Expanded(child: ActionBtn.primary('Request Time Off', widget.onRequestTimeOff)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----- your original _AvailShift stays unchanged -----
class _AvailShift extends StatelessWidget {
  final String title;
  final String rate;
  final List<String> badges;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;

  const _AvailShift({
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
        padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
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
                side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (secondary != null)
                  Expanded(
                      child: ActionBtn.outline(secondary!, () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Details opened')));
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
