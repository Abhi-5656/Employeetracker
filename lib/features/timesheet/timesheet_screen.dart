import 'package:flutter/material.dart';
import '../../shared/ui.dart';

class TimesheetScreen extends StatefulWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmitWeek;
  const TimesheetScreen({super.key, required this.onSaveDraft, required this.onSubmitWeek});
  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'Timesheet',
      trailing: const Icon(Icons.save_alt_rounded),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader('Week 13-19 Sep', icon: Icons.date_range_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Total: 40h | OT: 0h | Status: Draft', style: TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 8),
          const _TimesheetWeekGrid(),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _HeaderWithPill(),
                  SizedBox(height: 12),
                  KeyVal('IN', '07:55 (Rounded: 08:00)'),
                  KeyVal('OUT', '12:05 (Lunch)'),
                  KeyVal('IN', '12:35 (Return)'),
                  KeyVal('OUT', '--:-- (Pending)'),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: DetailTile(label: 'Total Hours', value: '4h 30m')),
                      Expanded(child: DetailTile(label: 'Exceptions', value: 'None')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderWithPill extends StatelessWidget {
  const _HeaderWithPill();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Text('Thu 19 Sep Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Spacer(),
        Pill('In Progress', bg: Colors.orange, fg: Colors.white),
      ],
    );
  }
}

class _TimesheetWeekGrid extends StatelessWidget {
  const _TimesheetWeekGrid();

  @override
  Widget build(BuildContext context) {
    final cells = [
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
          children: [for (final c in cells) _DayTile(cell: c)],
        ),
      ),
    );
  }
}

enum DayState { today, completed, pending, off }

class _DayCell {
  final String day; final String date; final String hours; final DayState state;
  _DayCell(this.day, this.date, this.hours, this.state);
}

class _DayTile extends StatelessWidget {
  final _DayCell cell;
  const _DayTile({required this.cell});

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
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${cell.day} ${cell.date} tapped'))),
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
