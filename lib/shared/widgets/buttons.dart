import 'package:flutter/material.dart';

class ActionBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final Color? fg;
  const ActionBtn._(this.text, this.onTap, this.color, this.fg, {super.key});

  factory ActionBtn.primary(String text, VoidCallback onTap) =>
      ActionBtn._(text, onTap, null, null);

  factory ActionBtn.outline(String text, VoidCallback onTap, BuildContext context) =>
      ActionBtn._(text, onTap, Colors.transparent, Theme.of(context).colorScheme.primary);

  factory ActionBtn.danger(String text, VoidCallback onTap) =>
      ActionBtn._(text, onTap, Colors.redAccent, Colors.white);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = color ?? cs.primary;
    final foreground = fg ?? (color == null ? Colors.white : cs.primary);
    final isOutline = color == Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOutline ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

enum SmallBtnKind { primary, outline, danger }

class SmallBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final SmallBtnKind kind;

  const SmallBtn._(this.text, this.onTap, this.kind, {super.key});

  factory SmallBtn.primary(String text, VoidCallback onTap) =>
      SmallBtn._(text, onTap, SmallBtnKind.primary);

  factory SmallBtn.outline(String text, VoidCallback onTap) =>
      SmallBtn._(text, onTap, SmallBtnKind.outline);

  factory SmallBtn.danger(String text, VoidCallback onTap) =>
      SmallBtn._(text, onTap, SmallBtnKind.danger);

  @override
  Widget build(BuildContext context) {
    final child = Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12));
    switch (kind) {
      case SmallBtnKind.primary:
        return ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        );
      case SmallBtnKind.outline:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        );
      case SmallBtnKind.danger:
        return ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        );
    }
  }
}

class OutlineChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const OutlineChip(this.text, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
