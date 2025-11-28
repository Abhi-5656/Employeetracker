// import 'package:flutter/material.dart';
// import '../../shared/ui.dart';
//
// class PickupScreen extends StatelessWidget {
//   final VoidCallback onPick;
//   const PickupScreen({super.key, required this.onPick});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Available Shifts')),
//       body: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             color: const Color(0xFFFFC107),
//             child: const Text(
//               '📱 OFFLINE MODE - Last sync: 2 min ago | ⚡ 3 actions queued',
//               style: TextStyle(fontWeight: FontWeight.w700),
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 Expanded(child: StatCard(value: '5', label: 'Available')),
//                 Expanded(child: StatCard(value: '3', label: 'Qualified')),
//                 Expanded(child: StatCard(value: '2.0x', label: 'Max Rate')),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Column(children: [
//               _AvailShift(
//                 title: 'Today 14:00-22:00 (Line B)',
//                 rate: '1.5x Rate',
//                 badges: const ['✓ Qualified', 'Urgent', '4km away'],
//                 primary: 'Pick Up Now',
//                 onPrimary: onPick,
//                 secondary: 'Details',
//               ),
//               _AvailShift(
//                 title: 'Sat 21 Sep: 06:00-14:00 (Line B)',
//                 rate: '1.5x Rate',
//                 badges: const ['✓ Qualified', 'Weekend', '2km away'],
//                 primary: 'Pick Up',
//                 onPrimary: onPick,
//                 secondary: 'Details',
//               ),
//               _AvailShift(
//                 title: 'Sun 22 Sep: 14:00-22:00 (Line C)',
//                 rate: '2.0x Rate',
//                 badges: const ['⚠ Training Needed', 'Night Premium', '8km away'],
//                 primary: 'Request Training',
//                 onPrimary: () => ScaffoldMessenger.of(context)
//                     .showSnackBar(const SnackBar(content: Text('Training requested'))),
//                 secondary: 'Details',
//               ),
//               _AvailShift(
//                 title: 'Mon 23 Sep: 22:00-06:00 (Line A)',
//                 rate: '1.8x Rate',
//                 badges: const ['✓ Qualified', 'Night Shift', 'Home line'],
//                 primary: 'Pick Up',
//                 onPrimary: onPick,
//                 secondary: 'Details',
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(child: ActionBtn.outline('Filter Shifts', () {
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filter coming soon')));
//                   }, context)),
//                   Expanded(child: ActionBtn.primary('Set Preferences', () {
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved')));
//                   })),
//                 ],
//               ),
//             ]),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AvailShift extends StatelessWidget {
//   final String title;
//   final String rate;
//   final List<String> badges;
//   final String primary;
//   final VoidCallback onPrimary;
//   final String? secondary;
//
//   const _AvailShift({
//     required this.title,
//     required this.rate,
//     required this.badges,
//     required this.primary,
//     required this.onPrimary,
//     this.secondary,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
//               Pill(rate, bg: Colors.green, fg: Colors.white),
//             ]),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 6,
//               runSpacing: -6,
//               children: badges.map((b) => Chip(
//                 label: Text(b),
//                 visualDensity: VisualDensity.compact,
//                 side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
//               )).toList(),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 if (secondary != null)
//                   Expanded(child: ActionBtn.outline(secondary!, () {
//                     ScaffoldMessenger.of(context)
//                         .showSnackBar(const SnackBar(content: Text('Details opened')));
//                   }, context)),
//                 Expanded(child: ActionBtn.primary(primary, onPrimary)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
// new
import 'package:flutter/material.dart';
import '../../shared/ui.dart';

const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class PickupScreen extends StatelessWidget {
  final VoidCallback onPick;
  const PickupScreen({super.key, required this.onPick});

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_kPrimaryColor, _kSecondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Shifts', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(children: [_buildStat('Available', '5'), const SizedBox(width: 8), _buildStat('Qualified', '3'), const SizedBox(width: 8), _buildStat('Max Rate', '2.0x')]),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _AvailShift(title: 'Today 14:00-22:00 (Line B)', rate: '1.5x Rate', badges: const ['✓ Qualified', 'Urgent'], primary: 'Pick Up Now', onPrimary: onPick),
                        const SizedBox(height: 12),
                        _AvailShift(title: 'Sat 21 Sep: 06:00-14:00', rate: '1.5x Rate', badges: const ['Weekend'], primary: 'Pick Up', onPrimary: onPick),
                      ],
                    ),
                  ),
                ),
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

  const _AvailShift({required this.title, required this.rate, required this.badges, required this.primary, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text(rate, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)))]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: badges.map((b) => Chip(label: Text(b), visualDensity: VisualDensity.compact, backgroundColor: Colors.grey[100])).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPrimary, style: ElevatedButton.styleFrom(backgroundColor: _kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(primary, style: const TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }
}