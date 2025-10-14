import 'package:flutter/material.dart';
import '../../shared/ui.dart';

class InboxScreen extends StatelessWidget {
  final VoidCallback onClockIn;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSettings;
  final VoidCallback onCantMake;

  const InboxScreen({
    super.key,
    required this.onClockIn,
    required this.onMarkAllRead,
    required this.onSettings,
    required this.onCantMake,
  });

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'Inbox',
      trailing: const Icon(Icons.inbox_rounded, color: Colors.white),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                _inboxRow(
                  const Color(0xFFFFE6E6),
                  const Color(0xFFDC3545),
                  Icons.circle,
                  'URGENT - Shift starts in 15 min',
                  'Thu 19 Sep, 08:00-16:00 Line A',
                  [
                    SmallBtn.primary('Clock In', onClockIn),
                    SmallBtn.outline('Running Late', () {}),
                    SmallBtn.danger('Can\'t Make', onCantMake),
                  ],
                ),
                const Divider(height: 1),
                _inboxRow(
                  const Color(0xFFE6F7E6),
                  const Color(0xFF28A745),
                  Icons.circle,
                  'Leave Approved - 25-26 Sep',
                  'Casual Leave approved by Manager',
                  [
                    SmallBtn.outline('View Details', () {}),
                    SmallBtn.primary('Add to Calendar', () {}),
                  ],
                ),
                const Divider(height: 1),
                _inboxRow(
                  const Color(0xFFE6F3FF),
                  const Color(0xFF007BFF),
                  Icons.circle,
                  'Shift Swap Request from Priya',
                  'Wants to swap Fri 20 Sep for Mon 23',
                  [
                    SmallBtn.primary('Accept', () {}),
                    SmallBtn.outline('Decline', () {}),
                    SmallBtn.outline('Counter-offer', () {}),
                  ],
                ),
                const Divider(height: 1),
                _inboxRow(
                  const Color(0xFFE6F3FF),
                  const Color(0xFF007BFF),
                  Icons.circle,
                  'New Training Available',
                  'Line C Cross-training - Earn 2.0x rate',
                  [
                    SmallBtn.primary('Enroll', () {}),
                    SmallBtn.outline('Learn More', () {}),
                    SmallBtn.outline('Remind Later', () {}),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(child: ActionBtn.outline('Mark All Read', onMarkAllRead, context)),
                Expanded(child: ActionBtn.outline('Filter', () {}, context)),
                Expanded(child: ActionBtn.primary('Settings', onSettings)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _inboxRow(
      Color bg, Color fg, IconData icon, String title, String text, List<Widget> actions,
      ) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: bg, child: Icon(icon, color: fg, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
