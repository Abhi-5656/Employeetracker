import 'package:flutter/material.dart';
import '../../shared/ui.dart';

class LeaveScreen extends StatefulWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  const LeaveScreen({super.key, required this.onSaveDraft, required this.onSubmit});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  String _leaveType = 'Casual Leave (12 days remaining)';
  DateTime _from = DateTime(2024, 9, 25);
  DateTime _to = DateTime(2024, 9, 26);
  bool _halfDay = false;
  bool _includeWeekends = true;
  final TextEditingController _reason = TextEditingController();

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final res = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (res != null) {
      setState(() {
        if (isFrom) {
          _from = res;
          if (_to.isBefore(_from)) _to = _from;
        } else {
          _to = res.isBefore(_from) ? _from : res;
        }
      });
    }
  }

  InputDecoration _inputDeco(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'Apply for Leave',
      trailing: const Icon(Icons.beach_access_rounded),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader('Leave Balance', icon: Icons.account_balance_wallet),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: StatCard(value: '12', label: 'Casual')),
                Expanded(child: StatCard(value: '8', label: 'Sick')),
                Expanded(child: StatCard(value: '15', label: 'Earned')),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: _leaveType,
                  items: const [
                    DropdownMenuItem(
                        value: 'Casual Leave (12 days remaining)',
                        child: Text('Casual Leave (12 days remaining)')),
                    DropdownMenuItem(
                        value: 'Sick Leave (8 days remaining)',
                        child: Text('Sick Leave (8 days remaining)')),
                    DropdownMenuItem(
                        value: 'Earned Leave (15 days remaining)',
                        child: Text('Earned Leave (15 days remaining)')),
                  ],
                  onChanged: (v) => setState(() => _leaveType = v!),
                  decoration: _inputDeco('Leave Type'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: DateField(label: 'From Date', date: _from, onTap: () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(child: DateField(label: 'To Date', date: _to, onTap: () => _pickDate(false))),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _halfDay, onChanged: (v) => setState(() => _halfDay = v),
                  title: const Text('Half day (AM/PM)'),
                ),
                SwitchListTile(
                  value: _includeWeekends, onChanged: (v) => setState(() => _includeWeekends = v),
                  title: const Text('Include weekends/holidays'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reason, maxLines: 3,
                  decoration: _inputDeco('Reason', hint: 'Please provide reason for leave...'),
                ),
                const SizedBox(height: 12),
                const InfoBanner(
                  icon: Icons.warning_amber_rounded,
                  title: 'Team Impact',
                  text: '2 other team members are on leave the same day',
                  color: Color(0xFFFFF3CD),
                  fg: Color(0xFF856404),
                ),
                const SizedBox(height: 8),
                const InfoBanner(
                  icon: Icons.route_rounded,
                  title: 'Approval Route',
                  text: 'You → Supervisor → HR → Auto-approve',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: ActionBtn.outline('Save Draft', widget.onSaveDraft, context)),
                    Expanded(child: ActionBtn.primary('Submit', widget.onSubmit)),
                  ],
                )
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
