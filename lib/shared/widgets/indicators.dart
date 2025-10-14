import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, {super.key, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  const StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 14, left: 12, right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int badge;
  const BadgeIcon({super.key, required this.icon, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (badge <= 0) return iconWidget;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color fg;
  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.color = const Color(0xFFF8F9FA),
    this.fg = const Color(0xFF333333),
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: fg.withOpacity(0.9))),
              ],
            ),
          )
        ],
      ),
    );
  }
}
