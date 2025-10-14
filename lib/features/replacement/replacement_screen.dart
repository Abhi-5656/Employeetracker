import 'package:flutter/material.dart';
import '../../shared/ui.dart';

class ReplacementScreen extends StatefulWidget {
  final VoidCallback onSubmit;
  const ReplacementScreen({super.key, required this.onSubmit});
  @override
  State<ReplacementScreen> createState() => _ReplacementScreenState();
}

class _ReplacementScreenState extends State<ReplacementScreen> {
  String _reason = 'Sick';
  bool _notify = true;
  bool _autoReplace = true;
  bool _offerSwap = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Can't Make Your Shift?")),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ShiftCard(
            timeRange: 'Thu 19 Sep, 08:00-16:00',
            status: 'Line A',
            statusColor: Colors.deepPurple,
            details: const [],
            actions: const [],
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: _reason,
                  items: const [
                    DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                    DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                    DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _reason = v!),
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SwitchListTile(title: const Text('Notify manager immediately'), value: _notify, onChanged: (v) => setState(() => _notify = v)),
                SwitchListTile(title: const Text('Find replacement automatically'), value: _autoReplace, onChanged: (v) => setState(() => _autoReplace = v)),
                SwitchListTile(title: const Text('Offer to swap with future shift'), value: _offerSwap, onChanged: (v) => setState(() => _offerSwap = v)),
              ]),
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Replacement Ranking Preview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                _ReplaceTile('Priya S.', 'Available, same line experience', score: '95%', color: Colors.green),
                Divider(height: 1),
                _ReplaceTile('Raj K.', 'Available, overtime eligible', score: '87%', color: Colors.amber),
                Divider(height: 1),
                _ReplaceTile('Amit P.', 'Cross-trained, good performance', score: '82%', color: Colors.grey),
                SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const InfoBanner(
                  icon: Icons.smart_toy_rounded,
                  title: 'Replacement Engine',
                  text: 'Factors: Skill match, availability, overtime rules, fairness rotation, location proximity, past performance',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: ActionBtn.outline('Cancel', () => Navigator.of(context).pop(), context)),
                    Expanded(child: ActionBtn.primary('Submit Request', () {
                      widget.onSubmit();
                      Navigator.of(context).pop();
                    })),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplaceTile extends StatelessWidget {
  final String name;
  final String details;
  final String score;
  final Color color;
  const _ReplaceTile(this.name, this.details, {required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final onLight = color.computeLuminance() > 0.5;
    return ListTile(
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(details),
      trailing: Pill(score, bg: color, fg: onLight ? Colors.black : Colors.white),
    );
  }
}
