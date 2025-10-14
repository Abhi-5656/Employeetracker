import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  final String title;
  final Widget child; // typically a ListView/ScrollView
  final Widget? trailing;

  const GradientScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null)
                IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 24),
                  child: trailing!,
                ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  const SectionHeader(this.title, {this.icon, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          if (icon != null) const SizedBox(width: 8),
          Text(title, style: t),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class KeyVal extends StatelessWidget {
  final String k;
  final String v;
  const KeyVal(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const DateField({super.key, required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final txt = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(txt),
      ),
    );
  }
}
