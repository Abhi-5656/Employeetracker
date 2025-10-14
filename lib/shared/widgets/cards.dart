import 'package:flutter/material.dart';
import 'indicators.dart';

class DetailTile extends StatelessWidget {
  final String label;
  final String value;
  const DetailTile({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class ShiftDetail {
  final String label;
  final String value;
  const ShiftDetail({required this.label, required this.value});
}

class ShiftCard extends StatelessWidget {
  final String timeRange;
  final String status;
  final Color statusColor;
  final List<ShiftDetail> details;
  final List<Widget> actions;

  const ShiftCard({
    super.key,
    required this.timeRange,
    required this.status,
    required this.statusColor,
    required this.details,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(width: 5, color: statusColor)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(timeRange, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Pill(status, bg: statusColor, fg: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final isWide = c.maxWidth > 360;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 2 : 1,
                childAspectRatio: isWide ? 4 : 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                children: [
                  for (final d in details) DetailTile(label: d.label, value: d.value),
                ],
              );
            }),
            const SizedBox(height: 8),
            if (actions.isNotEmpty)
              Row(children: [for (final a in actions) Expanded(child: a)]),
          ],
        ),
      ),
    );
  }
}
