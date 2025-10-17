// import 'package:flutter/material.dart';
// import '../../shared/ui.dart';
//
// class LeaveScreen extends StatefulWidget {
//   final VoidCallback onSaveDraft;
//   final VoidCallback onSubmit;
//   const LeaveScreen({super.key, required this.onSaveDraft, required this.onSubmit});
//
//   @override
//   State<LeaveScreen> createState() => _LeaveScreenState();
// }
//
// class _LeaveScreenState extends State<LeaveScreen> {
//   String _leaveType = 'Casual Leave (12 days remaining)';
//   DateTime _from = DateTime(2024, 9, 25);
//   DateTime _to = DateTime(2024, 9, 26);
//   bool _halfDay = false;
//   bool _includeWeekends = true;
//   final TextEditingController _reason = TextEditingController();
//
//   Future<void> _pickDate(bool isFrom) async {
//     final initial = isFrom ? _from : _to;
//     final res = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(2023),
//       lastDate: DateTime(2030),
//     );
//     if (res != null) {
//       setState(() {
//         if (isFrom) {
//           _from = res;
//           if (_to.isBefore(_from)) _to = _from;
//         } else {
//           _to = res.isBefore(_from) ? _from : res;
//         }
//       });
//     }
//   }
//
//   InputDecoration _inputDeco(String label, {String? hint}) => InputDecoration(
//     labelText: label,
//     hintText: hint,
//     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return GradientScaffold(
//       title: 'Apply for Leave',
//       trailing: const Icon(Icons.beach_access_rounded),
//       child: ListView(
//         padding: const EdgeInsets.only(bottom: 24),
//         children: [
//           const SectionHeader('Leave Balance', icon: Icons.account_balance_wallet),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 Expanded(child: StatCard(value: '12', label: 'Casual')),
//                 Expanded(child: StatCard(value: '8', label: 'Sick')),
//                 Expanded(child: StatCard(value: '15', label: 'Earned')),
//               ],
//             ),
//           ),
//           Card(
//             margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(children: [
//                 DropdownButtonFormField<String>(
//                   value: _leaveType,
//                   items: const [
//                     DropdownMenuItem(
//                         value: 'Casual Leave (12 days remaining)',
//                         child: Text('Casual Leave (12 days remaining)')),
//                     DropdownMenuItem(
//                         value: 'Sick Leave (8 days remaining)',
//                         child: Text('Sick Leave (8 days remaining)')),
//                     DropdownMenuItem(
//                         value: 'Earned Leave (15 days remaining)',
//                         child: Text('Earned Leave (15 days remaining)')),
//                   ],
//                   onChanged: (v) => setState(() => _leaveType = v!),
//                   decoration: _inputDeco('Leave Type'),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(child: DateField(label: 'From Date', date: _from, onTap: () => _pickDate(true))),
//                     const SizedBox(width: 12),
//                     Expanded(child: DateField(label: 'To Date', date: _to, onTap: () => _pickDate(false))),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 SwitchListTile(
//                   value: _halfDay, onChanged: (v) => setState(() => _halfDay = v),
//                   title: const Text('Half day (AM/PM)'),
//                 ),
//                 SwitchListTile(
//                   value: _includeWeekends, onChanged: (v) => setState(() => _includeWeekends = v),
//                   title: const Text('Include weekends/holidays'),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _reason, maxLines: 3,
//                   decoration: _inputDeco('Reason', hint: 'Please provide reason for leave...'),
//                 ),
//                 const SizedBox(height: 12),
//                 const InfoBanner(
//                   icon: Icons.warning_amber_rounded,
//                   title: 'Team Impact',
//                   text: '2 other team members are on leave the same day',
//                   color: Color(0xFFFFF3CD),
//                   fg: Color(0xFF856404),
//                 ),
//                 const SizedBox(height: 8),
//                 const InfoBanner(
//                   icon: Icons.route_rounded,
//                   title: 'Approval Route',
//                   text: 'You → Supervisor → HR → Auto-approve',
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(child: ActionBtn.outline('Save Draft', widget.onSaveDraft, context)),
//                     Expanded(child: ActionBtn.primary('Submit', widget.onSubmit)),
//                   ],
//                 )
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import '../../shared/ui.dart';
// import '../../data/repositories/leave_repository.dart';
//
// // NEW: import the dedicated form page
// import 'apply_leave_screen.dart';
//
// class LeaveScreen extends StatefulWidget {
//   final VoidCallback onSaveDraft;
//   final VoidCallback onSubmit;
//   const LeaveScreen({super.key, required this.onSaveDraft, required this.onSubmit});
//
//   @override
//   State<LeaveScreen> createState() => _LeaveScreenState();
// }
//
// class _LeaveScreenState extends State<LeaveScreen>
//     with AutomaticKeepAliveClientMixin<LeaveScreen> {
//   Future<LeaveTabData>? _future;
//   String? _leaveType; // keep a memory of last selected type (optional)
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     _future = LeaveRepository.instance.load();
//   }
//
//   Future<void> _reload() async {
//     setState(() => _future = LeaveRepository.instance.load());
//     await _future;
//   }
//
//   void _goToApplyForm(String preselectLabel, List<String> allLabels) {
//     _leaveType = preselectLabel; // remember (optional)
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => ApplyLeaveScreen(
//           dropdownLabels: allLabels,
//           initialLabel: preselectLabel,
//           onSaveDraft: widget.onSaveDraft,
//           onSubmit: widget.onSubmit,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     return FutureBuilder<LeaveTabData>(
//       future: _future,
//       builder: (context, snap) {
//         if (snap.connectionState != ConnectionState.done) {
//           return GradientScaffold(
//             title: 'Apply for Leave',
//             trailing: IconButton(
//               onPressed: _reload,
//               icon: const Icon(Icons.refresh),
//               tooltip: 'Reload',
//             ),
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (snap.hasError) {
//           return GradientScaffold(
//             title: 'Apply for Leave',
//             trailing: IconButton(
//               onPressed: _reload,
//               icon: const Icon(Icons.refresh),
//               tooltip: 'Retry',
//             ),
//             child: Center(child: Text('${snap.error}', textAlign: TextAlign.center)),
//           );
//         }
//
//         final d = snap.data!;
//         // default selected (optional memory)
//         _leaveType ??= (d.dropdownLabels.isNotEmpty ? d.dropdownLabels.first : null);
//
//         return GradientScaffold(
//           title: 'Apply for Leave',
//           trailing: const Icon(Icons.beach_access_rounded),
//           child: RefreshIndicator(
//             onRefresh: _reload,
//             child: ListView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               padding: const EdgeInsets.only(bottom: 24),
//               children: [
//                 const SectionHeader('Leave Balance', icon: Icons.account_balance_wallet),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: Row(
//                     children: [
//                       Expanded(child: StatCard(value: d.casual, label: 'Casual')),
//                       Expanded(child: StatCard(value: d.sick,   label: 'Sick')),
//                       Expanded(child: StatCard(value: d.earned, label: 'Earned')),
//                     ],
//                   ),
//                 ),
//
//                 // Policies list → tap navigates to ApplyLeaveScreen
//                 Card(
//                   margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const ListTile(
//                         title: Text('Leave Policies', style: TextStyle(fontWeight: FontWeight.w700)),
//                         dense: true,
//                       ),
//                       const Divider(height: 1),
//                       if (d.policies.isEmpty)
//                         const Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Text('No leave policies found'),
//                         )
//                       else
//                         ...d.policies.asMap().entries.map((e) {
//                           final p = e.value;
//                           final label = d.dropdownLabels[e.key];
//                           final balanceStr = (p.total != null)
//                               ? '${(p.balance ?? 0).toStringAsFixed(1)} / ${p.total!.toStringAsFixed(1)}'
//                               : (p.balance ?? 0).toStringAsFixed(1);
//                           return ListTile(
//                             leading: const Icon(Icons.inventory_2_outlined),
//                             title: Text(p.leaveName ?? 'Leave'),
//                             subtitle: Text(balanceStr),
//                             trailing: FilledButton(
//                               onPressed: () => _goToApplyForm(label, d.dropdownLabels),
//                               child: const Text('Apply'),
//                             ),
//                             onTap: () => _goToApplyForm(label, d.dropdownLabels),
//                           );
//                         }),
//                     ],
//                   ),
//                 ),
//
//                 // Upcoming holidays (unchanged)
//                 Card(
//                   margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const ListTile(
//                         title: Text('Upcoming Holidays', style: TextStyle(fontWeight: FontWeight.w700)),
//                         dense: true,
//                       ),
//                       const Divider(height: 1),
//                       if (d.holidays.isEmpty)
//                         const Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Text('No upcoming holidays'),
//                         )
//                       else
//                         ...d.holidays.map((h) {
//                           final dateStr = (h.startDate == h.endDate || h.endDate == null)
//                               ? (h.startDate ?? '')
//                               : '${h.startDate} → ${h.endDate}';
//                           return Column(
//                             children: [
//                               NotifRow(
//                                 colorBg: const Color(0xFFE6F7E6),
//                                 colorFg: const Color(0xFF28A745),
//                                 icon: Icons.event_rounded,
//                                 title: h.holidayName ?? 'Holiday',
//                                 text: '${h.holidayType ?? ''} • $dateStr',
//                               ),
//                               const Divider(height: 1),
//                             ],
//                           );
//                         }).toList(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../data/services/leave_service.dart';
import '../../shared/ui.dart';
import '../../data/repositories/leave_repository.dart';

class LeaveScreen extends StatefulWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  const LeaveScreen({super.key, required this.onSaveDraft, required this.onSubmit});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with AutomaticKeepAliveClientMixin<LeaveScreen> {
  Future<LeaveTabData>? _future;
  String? _leaveType; // last picked label
  bool _isApplying = false;

  // NEW: in-page submit overlay flag (replaces blocking dialog)
  bool _submitting = false;

  // form state (used only when _isApplying == true)
  DateTime _from = DateTime(2024, 9, 25);
  DateTime _to = DateTime(2024, 9, 26);
  bool _halfDay = false;
  bool _includeWeekends = true;
  final TextEditingController _reason = TextEditingController();

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = LeaveRepository.instance.load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _future = LeaveRepository.instance.load());
    await _future;
  }

  void _startApply(String preselectLabel) {
    setState(() {
      _isApplying = true;
      _leaveType = preselectLabel;
    });
  }

  void _exitApply() {
    setState(() {
      _isApplying = false;
    });
  }

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
    super.build(context);

    return FutureBuilder<LeaveTabData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return GradientScaffold(
            title: 'Apply for Leave',
            trailing: IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return GradientScaffold(
            title: 'Apply for Leave',
            trailing: IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
            ),
            child: Center(child: Text('${snap.error}', textAlign: TextAlign.center)),
          );
        }

        final d = snap.data!;
        _leaveType ??= (d.dropdownLabels.isNotEmpty ? d.dropdownLabels.first : null);

        // APPLY MODE: inline form with same structure, plus in-page overlay when submitting
        if (_isApplying) {
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
          return GradientScaffold(
            title: 'Apply for Leave',
            trailing: IconButton(
              tooltip: 'Back',
              onPressed: _exitApply,
              icon: const Icon(Icons.arrow_back),
            ),
            // Stack lets us overlay a spinner without changing routes (no black screen)
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _leaveType,
                                  items: d.dropdownLabels
                                      .map((label) => DropdownMenuItem<String>(
                                    value: label,
                                    child: Text(label),
                                  ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _leaveType = v),
                                  decoration: _inputDeco('Leave Type'),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DateField(
                                        label: 'From Date',
                                        date: _from,
                                        onTap: () => _pickDate(true),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DateField(
                                        label: 'To Date',
                                        date: _to,
                                        onTap: () => _pickDate(false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  value: _halfDay,
                                  onChanged: (v) => setState(() => _halfDay = v),
                                  title: const Text('Half day (AM/PM)'),
                                ),
                                SwitchListTile(
                                  value: _includeWeekends,
                                  onChanged: (v) => setState(() => _includeWeekends = v),
                                  title: const Text('Include weekends/holidays'),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _reason,
                                  maxLines: 3,
                                  decoration: _inputDeco(
                                    'Reason',
                                    hint: 'Please provide reason for leave...',
                                  ),
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
                                    Expanded(
                                      child: ActionBtn.outline('Save Draft', widget.onSaveDraft, context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ActionBtn.primary('Submit', () async {
                                        if (_leaveType == null) return;

                                        // Resolve selected policy -> id
                                        final labels = d.dropdownLabels;
                                        final idx = labels.indexOf(_leaveType!);
                                        if (idx < 0 || idx >= d.policies.length) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Invalid leave type selected')),
                                          );
                                          return;
                                        }

                                        final policy = d.policies[idx];
                                        final policyId = policy.leavePolicyId; // DTO field
                                        if (policyId == null) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('This leave policy has no ID.')),
                                          );
                                          return;
                                        }

                                        // IN-PAGE OVERLAY (no dialog; avoids black screen)
                                        setState(() => _submitting = true);
                                        try {
                                          await LeaveService.instance.applyLeave(
                                            leavePolicyId: policyId,
                                            from: _from,
                                            to: _to,
                                            halfDay: _halfDay,
                                            includeWeekends: _includeWeekends,
                                            reason: _reason.text,
                                          );

                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Leave request submitted'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          // Exit form and refresh balances/policies
                                          _exitApply();
                                          await _reload();
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to submit: $e'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        } finally {
                                          if (mounted) setState(() => _submitting = false);
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: SizedBox(height: 12 + bottomInset),
                    ),
                  ],
                ),

                // ⬇️ In-page loading mask shown only while submitting
                if (_submitting)
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: Colors.black38,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Default: show balances, policies, holidays (original list page)
        return GradientScaffold(
          title: 'Apply for Leave',
          trailing: const Icon(Icons.beach_access_rounded),
          child: RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SectionHeader('Leave Balance',
                    icon: Icons.account_balance_wallet),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(child: StatCard(value: d.casual, label: 'Casual')),
                      Expanded(child: StatCard(value: d.sick, label: 'Sick')),
                      Expanded(child: StatCard(value: d.earned, label: 'Earned')),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text('Leave Policies',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        dense: true,
                      ),
                      const Divider(height: 1),
                      if (d.policies.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No leave policies found'),
                        )
                      else
                        ...d.policies.asMap().entries.map((e) {
                          final p = e.value;
                          final label = d.dropdownLabels[e.key];
                          final balanceStr = (p.total != null)
                              ? '${(p.balance ?? 0).toStringAsFixed(1)} / ${p.total!.toStringAsFixed(1)}'
                              : (p.balance ?? 0).toStringAsFixed(1);
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(p.leaveName ?? 'Leave'),
                            subtitle: Text(balanceStr),
                            trailing: FilledButton(
                              onPressed: () => _startApply(label),
                              child: const Text('Apply'),
                            ),
                            onTap: () => _startApply(label),
                          );
                        }),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text('Upcoming Holidays',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        dense: true,
                      ),
                      const Divider(height: 1),
                      if (d.holidays.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No upcoming holidays'),
                        )
                      else
                        ...d.holidays.map((h) {
                          final dateStr =
                          (h.startDate == h.endDate || h.endDate == null)
                              ? (h.startDate ?? '')
                              : '${h.startDate} → ${h.endDate}';
                          return Column(
                            children: [
                              NotifRow(
                                colorBg: const Color(0xFFE6F7E6),
                                colorFg: const Color(0xFF28A745),
                                icon: Icons.event_rounded,
                                title: h.holidayName ?? 'Holiday',
                                text: '${h.holidayType ?? ''} • $dateStr',
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
