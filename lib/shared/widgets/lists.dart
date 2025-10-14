import 'package:flutter/material.dart';
import 'indicators.dart';

class NotifRow extends StatelessWidget {
  final Color colorBg;
  final Color colorFg;
  final IconData icon;
  final String title;
  final String text;
  const NotifRow({
    super.key,
    required this.colorBg,
    required this.colorFg,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: colorBg, child: Icon(icon, color: colorFg)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(text),
    );
  }
}

class SchedDayData {
  final String day; final String date; final String slot; final String line; final bool working;
  const SchedDayData(this.day, this.date, this.slot, this.line, this.working);
}

class WeekStrip extends StatelessWidget {
  final List<SchedDayData> days;
  const WeekStrip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = days[i];
          final border = d.working ? Colors.green : Colors.black26;
          final bg = d.working ? const Color(0x1A28A745) : const Color(0xFFF8F9FA);
          return Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 2),
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.day, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(d.date, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(d.slot, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                if (d.line.isNotEmpty)
                  Text(d.line, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
