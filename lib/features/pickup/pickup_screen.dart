import 'package:flutter/material.dart';
import '../../shared/ui.dart';

class PickupScreen extends StatelessWidget {
  final VoidCallback onPick;
  const PickupScreen({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Shifts')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFC107),
            child: const Text(
              '📱 OFFLINE MODE - Last sync: 2 min ago | ⚡ 3 actions queued',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: StatCard(value: '5', label: 'Available')),
                Expanded(child: StatCard(value: '3', label: 'Qualified')),
                Expanded(child: StatCard(value: '2.0x', label: 'Max Rate')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              _AvailShift(
                title: 'Today 14:00-22:00 (Line B)',
                rate: '1.5x Rate',
                badges: const ['✓ Qualified', 'Urgent', '4km away'],
                primary: 'Pick Up Now',
                onPrimary: onPick,
                secondary: 'Details',
              ),
              _AvailShift(
                title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
                rate: '1.5x Rate',
                badges: const ['✓ Qualified', 'Weekend', '2km away'],
                primary: 'Pick Up',
                onPrimary: onPick,
                secondary: 'Details',
              ),
              _AvailShift(
                title: 'Sun 22 Sep: 14:00-22:00 (Line C)',
                rate: '2.0x Rate',
                badges: const ['⚠ Training Needed', 'Night Premium', '8km away'],
                primary: 'Request Training',
                onPrimary: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Training requested'))),
                secondary: 'Details',
              ),
              _AvailShift(
                title: 'Mon 23 Sep: 22:00-06:00 (Line A)',
                rate: '1.8x Rate',
                badges: const ['✓ Qualified', 'Night Shift', 'Home line'],
                primary: 'Pick Up',
                onPrimary: onPick,
                secondary: 'Details',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: ActionBtn.outline('Filter Shifts', () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filter coming soon')));
                  }, context)),
                  Expanded(child: ActionBtn.primary('Set Preferences', () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved')));
                  })),
                ],
              ),
            ]),
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
