import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/ui.dart';

// services
import '../../data/services/auth_service.dart';
import '../../data/services/timesheet_service.dart';

class TimesheetScreen extends StatefulWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmitWeek;
  const TimesheetScreen({super.key, required this.onSaveDraft, required this.onSubmitWeek});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen>
    with AutomaticKeepAliveClientMixin<TimesheetScreen> {
  @override
  bool get wantKeepAlive => true;

  // ---------- helpers ----------

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return h * 60 + m;
  }

  /// returns minutes between "HH:mm" pair; handles overnight (out < in)
  int _minsBetween(String? inStr, String? outStr) {
    final a = (inStr ?? '').trim();
    final b = (outStr ?? '').trim();
    if (a.isEmpty || b.isEmpty) return 0;
    var s = _toMinutes(a), e = _toMinutes(b);
    if (e < s) e += 24 * 60; // overnight
    return e - s;
  }

  String _fmtHrsMins(int totalMins) {
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
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

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is int || v is num) {
      final n = v.toInt();
      final ms = (n > 20000000000) ? n : n * 1000; // secs or millis
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool _isMidnight(DateTime dt) => dt.hour == 0 && dt.minute == 0;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Unified minute extraction for a timesheet "row" with various shapes.
  int _minsOfRow(Map<String, dynamic> row) {
    if (row['totalMinutes'] is num) return (row['totalMinutes'] as num).toInt();
    if (row['totalDurationMinutes'] is num) return (row['totalDurationMinutes'] as num).toInt();
    if (row['totalHours'] is num) return ((row['totalHours'] as num) * 60).toInt();

    final inV  = row['checkInTime'] ?? row['inTime'] ?? row['startTime'];
    final outV = row['checkOutTime'] ?? row['outTime'] ?? row['endTime'];
    final a = _safeTime(inV), b = _safeTime(outV);
    if (a == '—' || b == '—') return 0;

    int _toMin(String hhmm) {
      final parts = hhmm.split(':');
      if (parts.length < 2) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }

    var s = _toMin(a), e = _toMin(b);
    if (e < s) e += 24 * 60;
    return e - s;
  }

  // ---------- state ----------

  List<_DayCell>? _cells; // null while loading
  late DateTime _weekStartSun;
  late DateTime _weekEndSat;

  // rows grouped by 'yyyy-MM-dd'
  final Map<String, List<Map<String, dynamic>>> _rowsByDate = {};
  late DateTime _selectedDate; // which day’s details to show

  // NEW: total minutes for the week (computed on each load)
  int _totalWeekMinutes = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final daysFromSunday = now.weekday % 7;
    _weekStartSun = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysFromSunday));
    _weekEndSat = _weekStartSun.add(const Duration(days: 6));

    // default selection = today clamped to [Sun..Sat]
    _selectedDate = now.isBefore(_weekStartSun)
        ? _weekStartSun
        : (now.isAfter(_weekEndSat) ? _weekEndSat : now);

    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() {
      _cells = null; // show spinner in place of grid
      _rowsByDate.clear();
      _totalWeekMinutes = 0;
    });

    try {
      final empId = AuthService.instance.employeeId ?? SessionController.instance.employeeId;
      if (empId == null || empId.isEmpty) {
        setState(() => _cells = _buildPlaceholderCells());
        return;
      }

      final rows = await TimesheetService.instance.getRangeRaw(
        start: _weekStartSun,
        end: _weekEndSat,
      );

      // group rows by date key
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
        // if none, also try first punchEvents item date
        final pe = row['punchEvents'];
        if (pe is List && pe.isNotEmpty) {
          final dt = _asDateTime((pe.first as Map)['eventTime']);
          if (dt != null) return DateFormat('yyyy-MM-dd').format(dt);
        }
        return null;
      }

      for (final r in rows) {
        if (r is! Map<String, dynamic>) continue;
        final key = _keyOf(r);
        if (key == null) continue;
        (_rowsByDate[key] ??= <Map<String, dynamic>>[]).add(r);
      }

      final Map<String, int> minutesByDate = {
        for (int i = 0; i < 7; i++)
          DateFormat('yyyy-MM-dd').format(_weekStartSun.add(Duration(days: i))): 0
      };
      _rowsByDate.forEach((key, list) {
        for (final r in list) {
          minutesByDate[key] = (minutesByDate[key] ?? 0) + _minsOfRow(r);
        }
      });

      // NEW: sum the week total minutes
      int sum = 0;
      minutesByDate.forEach((_, m) => sum += m);
      _totalWeekMinutes = sum;

      // Build grid cells
      final newCells = <_DayCell>[];
      for (int i = 0; i < 7; i++) {
        final d = _weekStartSun.add(Duration(days: i));
        final dayAbbrev = DateFormat('E').format(d);
        final dateStr   = DateFormat('d').format(d);
        final mins = minutesByDate[DateFormat('yyyy-MM-dd').format(d)] ?? 0;

        String hoursLabel;
        DayState state;
        if (mins <= 0) {
          final isWeekend = d.weekday == DateTime.sunday || d.weekday == DateTime.saturday;
          hoursLabel = isWeekend ? 'OFF' : '0h';
          state = isWeekend
              ? DayState.off
              : (_isSameDay(d, DateTime.now()) ? DayState.today : DayState.pending);
        } else {
          hoursLabel = '${mins ~/ 60}h';
          state = _isSameDay(d, DateTime.now()) ? DayState.today : DayState.completed;
        }
        newCells.add(_DayCell(dayAbbrev, dateStr, hoursLabel, state));
      }

      if (!mounted) return;
      setState(() => _cells = newCells);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cells = _buildPlaceholderCells());
    }
  }

  List<_DayCell> _buildPlaceholderCells() => const [
    _DayCell('Sun', '15', 'OFF', DayState.off),
    _DayCell('Mon', '16', '8h', DayState.completed),
    _DayCell('Tue', '17', '8h', DayState.completed),
    _DayCell('Wed', '18', '8h', DayState.completed),
    _DayCell('Thu', '19', '8h', DayState.today),
    _DayCell('Fri', '20', '8h', DayState.pending),
    _DayCell('Sat', '21', 'OFF', DayState.off),
  ];

  String _weekLabel() {
    final left = DateFormat('d MMM').format(_weekStartSun);
    final right = DateFormat('d MMM').format(_weekEndSat);
    return 'Week $left - $right';
  }

  // ---- detail card (IN/OUT) for selected date ----
  List<String> _detailPunchesForSelected() {
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final rows = _rowsByDate[key] ?? const <Map<String, dynamic>>[];

    // A) Prefer punchEvents (or events) with explicit type + timestamp
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

    if (evts.isNotEmpty) {
      evts.sort((a, b) {
        final ta = _asDateTime(a['eventTime'] ?? a['time'] ?? a['timestamp'] ?? a['at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final tb = _asDateTime(b['eventTime'] ?? b['time'] ?? b['timestamp'] ?? b['at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });

      String? in1, out1, in2, out2;
      for (final e in evts) {
        final dt = _asDateTime(e['eventTime'] ?? e['time'] ?? e['timestamp'] ?? e['at']);
        if (dt == null || !_isSameDay(dt, _selectedDate)) continue;

        final tRaw = (e['punchType'] ?? e['type'] ?? e['eventType'] ?? e['action'] ?? '')
            .toString()
            .toUpperCase();

        if (tRaw.contains('IN')) {
          if (in1 == null) in1 = _fmt(dt);
          else if (in2 == null) in2 = _fmt(dt);
        } else if (tRaw.contains('OUT')) {
          if (in1 != null && out1 == null) out1 = _fmt(dt);
          else if (in2 != null && out2 == null) out2 = _fmt(dt);
        }
      }
      return [in1 ?? '—', out1 ?? '--:-- (Pending)', in2 ?? '—', out2 ?? '—'];
    }

    // B) Otherwise, fallback to flat fields if present
    String in1 = '—', out1 = '--:-- (Pending)', in2 = '—', out2 = '—';
    for (final r in rows) {
      final a = _asDateTime(r['checkInTime'] ?? r['inTime'] ?? r['startTime'] ?? r['firstInTime'] ?? r['in1']);
      final b = _asDateTime(r['checkOutTime'] ?? r['outTime'] ?? r['endTime'] ?? r['firstOutTime'] ?? r['out1']);
      if (a != null && _isSameDay(a, _selectedDate)) in1 = _fmt(a);
      if (b != null && _isSameDay(b, _selectedDate)) out1 = _fmt(b);
      if (in1 != '—' || out1 != '--:-- (Pending)') break;
    }
    for (final r in rows) {
      final a2 = _asDateTime(r['secondInTime'] ?? r['in2'] ?? r['checkInTime2'] ?? r['inTime2'] ?? r['startTime2']);
      final b2 = _asDateTime(r['secondOutTime'] ?? r['out2'] ?? r['checkOutTime2'] ?? r['outTime2'] ?? r['endTime2']);
      if (a2 != null && _isSameDay(a2, _selectedDate)) in2 = _fmt(a2);
      if (b2 != null && _isSameDay(b2, _selectedDate)) out2 = _fmt(b2);
      if (in2 != '—' || out2 != '—') break;
    }

    return [in1, out1, in2, out2];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Selected-day dynamic totals
    final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedRows = _rowsByDate[selectedKey] ?? const <Map<String, dynamic>>[];
    final selectedMins = selectedRows.fold<int>(0, (acc, r) => acc + _minsOfRow(r));
    final selectedDurLabel = _fmtHrsMins(selectedMins);

    final punches = _detailPunchesForSelected(); // [IN, OUT, IN, OUT]

    return GradientScaffold(
      title: 'Timesheet',
      trailing: const Icon(Icons.save_alt_rounded),
      child: RefreshIndicator(
        onRefresh: _loadWeek,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SectionHeader(_weekLabel(), icon: Icons.date_range_rounded),

            // Week totals (dynamic)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Total: ${_fmtHrsMins(_totalWeekMinutes)} | OT: 0h | Status: Draft',
                style: const TextStyle(color: Colors.black54),
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
                weekStart: _weekStartSun,
                onTapDay: (date) => setState(() => _selectedDate = date),
              ),

            // Detail card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${DateFormat('EEE d MMM').format(_selectedDate)} Details',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const Spacer(),
                        const Pill('In Progress', bg: Colors.orange, fg: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    KeyVal('IN',  '${punches[0]} (Rounded: ${punches[0] == '—' ? '—' : punches[0]})'),
                    KeyVal('OUT', punches[1]),
                    KeyVal('IN',  punches[2] == '—' ? '—' : '${punches[2]} (Return)'),
                    KeyVal('OUT', punches[3] == '—' ? '--:-- (Pending)' : punches[3]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: DetailTile(label: 'Total Hours', value: selectedDurLabel)),
                        const Expanded(child: DetailTile(label: 'Exceptions', value: 'None')),
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
      case DayState.off: default: bg = const Color(0xFFF8F9FA); fg = Colors.black54;
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
