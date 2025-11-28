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

// lib/features/leave/leave_screen.dart
//
// import 'package:flutter/material.dart';
//
// import '../../data/services/leave_service.dart';
// import '../../shared/ui.dart';
// import '../../data/repositories/leave_repository.dart';
//
// // --- NEW CLASS: Extracted Apply Leave Form Screen ---
// class _ApplyLeaveFormScreen extends StatefulWidget {
//   final LeaveTabData data;
//   final String initialLeaveType;
//   final VoidCallback onSubmitted; // Callback to notify parent (LeaveScreen) to reload data
//
//   const _ApplyLeaveFormScreen({
//     super.key,
//     required this.data,
//     required this.initialLeaveType,
//     required this.onSubmitted,
//   });
//
//   @override
//   State<_ApplyLeaveFormScreen> createState() => _ApplyLeaveFormScreenState();
// }
//
// class _ApplyLeaveFormScreenState extends State<_ApplyLeaveFormScreen> {
//   // Transfer form state from the old _LeaveScreenState
//   late String _leaveType = widget.initialLeaveType;
//   DateTime _from = DateTime(2024, 9, 25);
//   DateTime _to = DateTime(2024, 9, 26);
//   bool _halfDay = false;
//   bool _includeWeekends = true;
//   final TextEditingController _reason = TextEditingController();
//   bool _submitting = false;
//
//   @override
//   void dispose() {
//     _reason.dispose();
//     super.dispose();
//   }
//
//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
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
//     final d = widget.data;
//     final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
//
//     return GradientScaffold(
//       title: 'Apply for Leave',
//       // Default back button from the AppBar handles the nested pop.
//
//       child: Stack(
//         children: [
//           CustomScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//             slivers: [
//               const SliverToBoxAdapter(child: SizedBox(height: 12)),
//               SliverPadding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 sliver: SliverToBoxAdapter(
//                   child: Card(
//                     margin: EdgeInsets.zero,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     clipBehavior: Clip.antiAlias,
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           DropdownButtonFormField<String>(
//                             value: _leaveType,
//                             items: d.dropdownLabels
//                                 .map((label) => DropdownMenuItem<String>(
//                               value: label,
//                               child: Text(label),
//                             ))
//                                 .toList(),
//                             onChanged: (v) => setState(() => _leaveType = v!),
//                             decoration: _inputDeco('Leave Type'),
//                           ),
//                           const SizedBox(height: 12),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: DateField(
//                                   label: 'From Date',
//                                   date: _from,
//                                   onTap: () => _pickDate(true),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: DateField(
//                                   label: 'To Date',
//                                   date: _to,
//                                   onTap: () => _pickDate(false),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           SwitchListTile(
//                             value: _halfDay,
//                             onChanged: (v) => setState(() => _halfDay = v),
//                             title: const Text('Half day (AM/PM)'),
//                           ),
//                           SwitchListTile(
//                             value: _includeWeekends,
//                             onChanged: (v) => setState(() => _includeWeekends = v),
//                             title: const Text('Include weekends/holidays'),
//                           ),
//                           const SizedBox(height: 8),
//                           TextField(
//                             controller: _reason,
//                             maxLines: 3,
//                             decoration: _inputDeco(
//                               'Reason',
//                               hint: 'Please provide reason for leave...',
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           const InfoBanner(
//                             icon: Icons.warning_amber_rounded,
//                             title: 'Team Impact',
//                             text: '2 other team members are on leave the same day',
//                             color: Color(0xFFFFF3CD),
//                             fg: Color(0xFF856404),
//                           ),
//                           const SizedBox(height: 8),
//                           const InfoBanner(
//                             icon: Icons.route_rounded,
//                             title: 'Approval Route',
//                             text: 'You → Supervisor → HR → Auto-approve',
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ActionBtn.outline('Save Draft', widget.onSubmitted, context), // Reuse onSubmitted for save draft logic
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: ActionBtn.primary('Submit', () async {
//                                   if (_leaveType == null || _leaveType.isEmpty) return;
//
//                                   final labels = d.dropdownLabels;
//                                   final idx = labels.indexOf(_leaveType);
//                                   if (idx < 0 || idx >= d.policies.length) {
//                                     if (!mounted) return;
//                                     _toast('Invalid leave type selected');
//                                     return;
//                                   }
//
//                                   final policy = d.policies[idx];
//                                   final policyId = policy.leavePolicyId; // DTO field
//                                   if (policyId == null) {
//                                     if (!mounted) return;
//                                     _toast('This leave policy has no ID.');
//                                     return;
//                                   }
//
//                                   // IN-PAGE OVERLAY
//                                   setState(() => _submitting = true);
//                                   try {
//                                     await LeaveService.instance.applyLeave(
//                                       leavePolicyId: policyId,
//                                       from: _from,
//                                       to: _to,
//                                       halfDay: _halfDay,
//                                       includeWeekends: _includeWeekends,
//                                       reason: _reason.text,
//                                     );
//
//                                     if (!mounted) return;
//                                     _toast('Leave request submitted');
//
//                                     // ❗️ Pop the form off the nested stack and notify parent
//                                     Navigator.of(context).pop();
//                                     widget.onSubmitted();
//
//                                   } catch (e) {
//                                     if (!mounted) return;
//                                     _toast('Failed to submit: $e');
//                                   } finally {
//                                     if (mounted) setState(() => _submitting = false);
//                                   }
//                                 }),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SliverFillRemaining(
//                 hasScrollBody: false,
//                 child: SizedBox(height: 12 + bottomInset),
//               ),
//             ],
//           ),
//
//           // In-page loading mask shown only while submitting
//           if (_submitting)
//             Positioned.fill(
//               child: AbsorbPointer(
//                 absorbing: true,
//                 child: Container(
//                   color: Colors.black38,
//                   child: const Center(child: CircularProgressIndicator()),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
// // --- END NEW CLASS ---
//
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
//
//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
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
//     // The await ensures the FutureBuilder has the new data before we continue.
//     await _future;
//   }
//
//   // ❗️ CORRECTED: Now takes LeaveTabData argument.
//   void _startApply(String preselectLabel, LeaveTabData data) {
//     // ❗️ CRITICAL CHANGE: Push the form as a NEW ROUTE onto the nested Navigator
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (ctx) => _ApplyLeaveFormScreen(
//         data: data,
//         initialLeaveType: preselectLabel,
//         // The form screen will call this after successful submit AND pop itself.
//         onSubmitted: () {
//           widget.onSubmit();
//           _reload(); // Reload data after submission
//         },
//       ),
//     ));
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
//             title: 'Leave',
//             trailing: IconButton(
//               onPressed: _reload,
//               icon: const Icon(Icons.refresh),
//               tooltip: 'Reload',
//             ),
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (snap.hasError) {
//           return GradientScaffold(
//             title: 'Leave',
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
//
//         // Default: show balances, policies, holidays (original list page)
//         return GradientScaffold(
//           title: 'Leave',
//           trailing: const Icon(Icons.beach_access_rounded),
//           child: RefreshIndicator(
//             onRefresh: _reload,
//             child: ListView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               padding: const EdgeInsets.only(bottom: 24),
//               children: [
//                 const SectionHeader('Leave Balance',
//                     icon: Icons.account_balance_wallet),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: Row(
//                     children: [
//                       Expanded(child: StatCard(value: d.casual, label: 'Casual')),
//                       Expanded(child: StatCard(value: d.sick, label: 'Sick')),
//                       Expanded(child: StatCard(value: d.earned, label: 'Earned')),
//                     ],
//                   ),
//                 ),
//                 Card(
//                   margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const ListTile(
//                         title: Text('Leave Policies',
//                             style: TextStyle(fontWeight: FontWeight.w700)),
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
//                               // ❗️ FIX 1: Provide BOTH arguments (label and data)
//                               onPressed: () => _startApply(label, d),
//                               child: const Text('Apply'),
//                             ),
//                             // ❗️ FIX 2: Provide BOTH arguments (label and data)
//                             onTap: () => _startApply(label, d),
//                           );
//                         }),
//                     ],
//                   ),
//                 ),
//                 Card(
//                   margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const ListTile(
//                         title: Text('Upcoming Holidays',
//                             style: TextStyle(fontWeight: FontWeight.w700)),
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
//                           final dateStr =
//                           (h.startDate == h.endDate || h.endDate == null)
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
// new
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/leave_service.dart';
import '../../shared/ui.dart';
import '../../data/repositories/leave_repository.dart';

// 🎨 Theme Constants
const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

// --- NEW CLASS: Enhanced Apply Leave Form ---
class _ApplyLeaveFormScreen extends StatefulWidget {
  final LeaveTabData data;
  final String initialLeaveType;
  final VoidCallback onSubmitted;

  const _ApplyLeaveFormScreen({
    super.key,
    required this.data,
    required this.initialLeaveType,
    required this.onSubmitted,
  });

  @override
  State<_ApplyLeaveFormScreen> createState() => _ApplyLeaveFormScreenState();
}

class _ApplyLeaveFormScreenState extends State<_ApplyLeaveFormScreen> {
  int? _selectedPolicyId; // ✅ Changed to int? for strict type safety
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 1));
  bool _halfDay = false;
  final TextEditingController _reason = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    // Attempt to find the policy ID from the label passed
    try {
      final initialLabel = widget.initialLeaveType;
      final policyIndex = widget.data.dropdownLabels.indexOf(initialLabel);

      if (policyIndex != -1 && policyIndex < widget.data.policies.length) {
        final p = widget.data.policies[policyIndex];
        // Only set if ID is valid
        if (p.leavePolicyId != null) {
          _selectedPolicyId = p.leavePolicyId;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final res = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
    labelStyle: TextStyle(color: Colors.grey[600]),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kPrimaryColor, width: 1.5),
    ),
  );

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: _kPrimaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    // 1️⃣ PREPARE ITEMS: Deduplicate by ID using a Set
    // This ensures we NEVER have two items with the same value
    final items = <DropdownMenuItem<int>>[];
    final seenIds = <int>{};

    for (var p in d.policies) {
      if (p.leavePolicyId != null && !seenIds.contains(p.leavePolicyId)) {
        seenIds.add(p.leavePolicyId!);
        items.add(DropdownMenuItem(
          value: p.leavePolicyId,
          child: Text(
            '${p.leaveName} (${(p.balance ?? 0).toStringAsFixed(1)} left)',
            overflow: TextOverflow.ellipsis,
          ),
        ));
      }
    }

    // 2️⃣ VALIDATE VALUE: Ensure _selectedPolicyId is actually in our valid list
    // If not found, reset to null to prevent "exactly one item" error.
    int? validValue = _selectedPolicyId;
    if (validValue != null && !seenIds.contains(validValue)) {
      validValue = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryColor, _kSecondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Apply for Leave',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // ✅ SAFE DROPDOWN: Uses strict int type and validated value
                                DropdownButtonFormField<int>(
                                  value: validValue,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  isExpanded: true,
                                  items: items,
                                  onChanged: (v) {
                                    setState(() => _selectedPolicyId = v);
                                  },
                                  decoration: _inputDeco('Leave Type'),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(child: _buildDateSelector('From Date', _from, () => _pickDate(true))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildDateSelector('To Date', _to, () => _pickDate(false))),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      SwitchListTile(
                                        value: _halfDay,
                                        activeColor: _kPrimaryColor,
                                        onChanged: (v) => setState(() => _halfDay = v),
                                        title: const Text('Half Day', style: TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: const Text('Apply for half day only', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _reason,
                                  maxLines: 4,
                                  decoration: _inputDeco('Reason', hint: 'Enter reason for leave...'),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: widget.onSubmitted,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: const BorderSide(color: _kPrimaryColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Save Draft', style: TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          // Auto-select if only one option exists
                                          if (_selectedPolicyId == null && items.length == 1) {
                                            _selectedPolicyId = items.first.value;
                                          }

                                          if (_selectedPolicyId == null) {
                                            _toast('Please select a leave type');
                                            return;
                                          }

                                          setState(() => _submitting = true);
                                          try {
                                            await LeaveService.instance.applyLeave(
                                              leavePolicyId: _selectedPolicyId!,
                                              from: _from,
                                              to: _to,
                                              halfDay: _halfDay,
                                              includeWeekends: false,
                                              reason: _reason.text,
                                            );
                                            if (!mounted) return;
                                            _toast('Leave request submitted');
                                            Navigator.of(context).pop();
                                            widget.onSubmitted();
                                          } catch (e) {
                                            if (!mounted) return;
                                            _toast('Failed to submit: $e');
                                          } finally {
                                            if (mounted) setState(() => _submitting = false);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kPrimaryColor,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 4,
                                          shadowColor: _kPrimaryColor.withOpacity(0.4),
                                        ),
                                        child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_submitting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// --- MAIN LEAVE SCREEN ---

class LeaveScreen extends StatefulWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  const LeaveScreen({super.key, required this.onSaveDraft, required this.onSubmit});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with AutomaticKeepAliveClientMixin<LeaveScreen> {
  Future<LeaveTabData>? _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = LeaveRepository.instance.load();
  }

  Future<void> _reload() async {
    setState(() => _future = LeaveRepository.instance.load());
    await _future;
  }

  void _startApply(String preselectLabel, LeaveTabData data) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => _ApplyLeaveFormScreen(
        data: data,
        initialLeaveType: preselectLabel,
        onSubmitted: () {
          widget.onSubmit();
          _reload();
        },
      ),
    ));
  }

  Widget _buildBalanceCard(String label, double value, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryColor, _kSecondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(Icons.beach_access_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
                ),
              ],
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Leaves', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Manage & Apply', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: FutureBuilder<LeaveTabData>(
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return Center(child: Text('Error: ${snap.error}'));
                          }
                          final d = snap.data!;
                          return ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Row(
                                children: [
                                  _buildBalanceCard('Casual', d.casual, [const Color(0xFFFFA726), const Color(0xFFFF7043)]),
                                  const SizedBox(width: 12),
                                  _buildBalanceCard('Sick', d.sick, [const Color(0xFFEC407A), const Color(0xFFAB47BC)]),
                                  const SizedBox(width: 12),
                                  _buildBalanceCard('Earned', d.earned, [const Color(0xFF26A69A), const Color(0xFF00897B)]),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Leave Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                              if (d.policies.isEmpty)
                                const Center(child: Text('No policies available'))
                              else
                                ...d.policies.asMap().entries.map((e) {
                                  final p = e.value;
                                  final label = d.dropdownLabels[e.key];
                                  final balanceStr = (p.total != null)
                                      ? '${(p.balance ?? 0).toStringAsFixed(1)} / ${p.total!.toStringAsFixed(1)}'
                                      : (p.balance ?? 0).toStringAsFixed(1);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _kPrimaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.assignment_outlined, color: _kPrimaryColor, size: 22),
                                      ),
                                      title: Text(p.leaveName ?? 'Leave', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Balance: $balanceStr', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      trailing: ElevatedButton(
                                        onPressed: () => _startApply(label, d),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kPrimaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          elevation: 0,
                                        ),
                                        child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  );
                                }),
                              const SizedBox(height: 24),
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Upcoming Holidays', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    if (d.holidays.isEmpty)
                                      const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No upcoming holidays')))
                                    else
                                      ...d.holidays.map((h) {
                                        final dateStr = (h.startDate == h.endDate || h.endDate == null)
                                            ? (h.startDate ?? '')
                                            : '${h.startDate} - ${h.endDate}';
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 45, width: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.orangeAccent,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(h.holidayName ?? 'Holiday', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                    const SizedBox(height: 4),
                                                    Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  h.holidayType ?? 'Public',
                                                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                                                ),
                                              )
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                      ),
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