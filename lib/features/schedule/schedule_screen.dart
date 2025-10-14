import 'package:flutter/material.dart';
import '../../shared/ui.dart';

class ScheduleScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                      OutlineChip('← Prev', onTap: () {}),
                      const Spacer(),
                      const Flexible(
                        child: Center(
                          child: Text('Week 16-22 Sep',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      const Spacer(),
                      OutlineChip('Next →', onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const WeekStrip(days: [
                    SchedDayData('Mon', '16', '08-16', 'Line A', true),
                    SchedDayData('Tue', '17', '08-16', 'Line A', true),
                    SchedDayData('Wed', '18', '08-16', 'Line A', true),
                    SchedDayData('Thu', '19', '08-16', 'Line A', true),
                    SchedDayData('Fri', '20', '08-16', 'Line A', true),
                    SchedDayData('Sat', '21', 'OFF',   '',      false),
                    SchedDayData('Sun', '22', 'OFF',   '',      false),
                  ]),
                ],
              ),
            ),
          ),
          const SectionHeader('Available Shifts', icon: Icons.work_history),
          ...[
            _AvailShift(
              title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
              rate: '1.5x Rate',
              badges: const ['✓ Qualified', 'Weekend Shift'],
              primary: 'Pick Up',
              onPrimary: onPickShift,
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
                Expanded(child: ActionBtn.danger('Can\'t Make It', onCantMake)),
                const SizedBox(width: 8),
                Expanded(child: ActionBtn.primary('Request Time Off', onRequestTimeOff)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              children: badges.map((b) => Chip(
                label: Text(b),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
              )).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (secondary != null)
                  Expanded(child: ActionBtn.outline(secondary!, () {
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
