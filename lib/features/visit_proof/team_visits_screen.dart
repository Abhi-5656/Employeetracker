import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ Fixed Imports
import '../../data/models/reportee_model.dart';
import '../../data/models/visit_proof_model.dart';
import '../../data/services/employee_service.dart';
import '../../data/services/visit_proof_service.dart';
import '../../data/services/auth_service.dart'; // Required for auth token in image

// ✅ Import the new Map Screen
import 'visit_location_map_screen.dart';

// 🎨 Theme Constants
const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class TeamVisitsScreen extends StatefulWidget {
  const TeamVisitsScreen({super.key});

  @override
  State<TeamVisitsScreen> createState() => _TeamVisitsScreenState();
}

class _TeamVisitsScreenState extends State<TeamVisitsScreen> {
  Future<List<ReporteeModel>>? _reporteesFuture;

  @override
  void initState() {
    super.initState();
    _loadReportees();
  }

  void _loadReportees() {
    setState(() {
      _reporteesFuture = EmployeeService.instance.getReportees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Background
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
                // AppBar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Team Visits',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: FutureBuilder<List<ReporteeModel>>(
                      future: _reporteesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          String errorMsg = snapshot.error.toString();
                          if (errorMsg.contains("403")) errorMsg = "Access Denied. Check permissions.";
                          return Center(child: Text(errorMsg));
                        }

                        final list = snapshot.data ?? [];
                        if (list.isEmpty) {
                          return const Center(child: Text('No reportees found.'));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reportee = list[index];
                            return _ReporteeTile(
                              reportee: reportee,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReporteeVisitProofsScreen(reportee: reportee),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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

class _ReporteeTile extends StatelessWidget {
  final ReporteeModel reportee;
  final VoidCallback onTap;

  const _ReporteeTile({required this.reportee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = reportee.fullName.isNotEmpty
        ? reportee.fullName.trim().split(' ').take(2).map((e) => e[0]).join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _kPrimaryColor.withOpacity(0.1),
          child: Text(initials, style: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(reportee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(reportee.jobTitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Screen
// ---------------------------------------------------------------------------

class ReporteeVisitProofsScreen extends StatefulWidget {
  final ReporteeModel reportee;

  const ReporteeVisitProofsScreen({super.key, required this.reportee});

  @override
  State<ReporteeVisitProofsScreen> createState() => _ReporteeVisitProofsScreenState();
}

class _ReporteeVisitProofsScreenState extends State<ReporteeVisitProofsScreen> {
  late DateTime _selectedDate;
  Future<List<VisitProof>>? _proofsFuture;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchProofs();
  }

  void _fetchProofs() {
    setState(() {
      _proofsFuture = VisitProofService.instance.getVisitProofs(
        employeeId: widget.reportee.employeeId,
        date: _selectedDate,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchProofs();
    }
  }

  void _changeDay(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _fetchProofs();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.reportee.fullName, style: const TextStyle(fontSize: 16)),
            const Text('Visit Proofs', style: TextStyle(fontSize: 12)),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kPrimaryColor, _kSecondaryColor]),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDay(-1)),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: _kPrimaryColor),
                        const SizedBox(width: 8),
                        Text(dateStr, style: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDay(1)),
              ],
            ),
          ),

          // List
          Expanded(
            child: FutureBuilder<List<VisitProof>>(
              future: _proofsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  String err = snapshot.error.toString();
                  if (err.contains("403")) err = "Permission Denied.";
                  return Center(child: Text(err));
                }
                final proofs = snapshot.data ?? [];

                if (proofs.isEmpty) {
                  return const Center(child: Text('No proofs uploaded for this date.'));
                }

                // Sort newest first
                proofs.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: proofs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _VisitProofCard(proof: proofs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitProofCard extends StatelessWidget {
  final VisitProof proof;
  const _VisitProofCard({required this.proof});

  void _showOptions(BuildContext context) {
    final hasLocation = (proof.latitude != null && proof.longitude != null);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              if (hasLocation)
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: _kPrimaryColor),
                  title: const Text('Show location on map'),
                  onTap: () {
                    Navigator.pop(ctx); // Close sheet
                    // Redirect to Map Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VisitLocationMapScreen(
                          latitude: proof.latitude!,
                          longitude: proof.longitude!,
                          clientName: proof.clientName,
                          visitedAt: DateFormat('h:mm a').format(proof.capturedAt),
                        ),
                      ),
                    );
                  },
                )
              else
                const ListTile(
                  leading: Icon(Icons.location_off, color: Colors.grey),
                  title: Text('No location data available'),
                ),
              // Add other options here if needed (e.g., View Image Fullscreen)
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(proof.capturedAt);
    // ✅ Fix: Pass the unique ID of the visit proof
    final imageUrl = VisitProofService.instance.getProofImageApiUrl(proof.id);
    final token = AuthService.instance.token;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showOptions(context), // 👈 Triggers options on tap
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.grey),
              title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Show visual indicator that location is available
              trailing: (proof.latitude != null)
                  ? const Icon(Icons.location_on, color: Colors.redAccent)
                  : null,
            ),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (ctx, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.grey, size: 32),
                          SizedBox(height: 4),
                          Text("No Image", style: TextStyle(color: Colors.grey, fontSize: 10))
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (proof.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(proof.comment),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// // ✅ Fixed Imports
// import '../../data/models/reportee_model.dart';
// import '../../data/models/visit_proof_model.dart';
// import '../../data/services/employee_service.dart';
// import '../../data/services/visit_proof_service.dart';
// import '../../data/services/auth_service.dart'; // <--- ADD THIS LINE
// // 🎨 Theme Constants
// const Color _kPrimaryColor = Color(0xFF667EEA);
// const Color _kSecondaryColor = Color(0xFF764BA2);
//
// class TeamVisitsScreen extends StatefulWidget {
//   const TeamVisitsScreen({super.key});
//
//   @override
//   State<TeamVisitsScreen> createState() => _TeamVisitsScreenState();
// }
//
// class _TeamVisitsScreenState extends State<TeamVisitsScreen> {
//   // ✅ Use ReporteeModel
//   Future<List<ReporteeModel>>? _reporteesFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadReportees();
//   }
//
//   void _loadReportees() {
//     setState(() {
//       // ✅ Use existing method getReportees()
//       _reporteesFuture = EmployeeService.instance.getReportees();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Header Background
//           Container(
//             height: 200,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [_kPrimaryColor, _kSecondaryColor],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 // AppBar
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Team Visits',
//                         style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // List
//                 Expanded(
//                   child: Container(
//                     width: double.infinity,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                     ),
//                     child: FutureBuilder<List<ReporteeModel>>(
//                       future: _reporteesFuture,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return const Center(child: CircularProgressIndicator());
//                         }
//                         if (snapshot.hasError) {
//                           // ✅ Clean Error Message
//                           String errorMsg = snapshot.error.toString();
//                           if (errorMsg.contains("403")) errorMsg = "Access Denied. Check permissions.";
//                           return Center(child: Text(errorMsg));
//                         }
//
//                         final list = snapshot.data ?? [];
//                         if (list.isEmpty) {
//                           return const Center(child: Text('No reportees found.'));
//                         }
//
//                         return ListView.separated(
//                           padding: const EdgeInsets.all(16),
//                           itemCount: list.length,
//                           separatorBuilder: (_, __) => const SizedBox(height: 12),
//                           itemBuilder: (context, index) {
//                             final reportee = list[index];
//                             return _ReporteeTile(
//                               reportee: reportee,
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => ReporteeVisitProofsScreen(reportee: reportee),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _ReporteeTile extends StatelessWidget {
//   final ReporteeModel reportee; // ✅ Correct Model
//   final VoidCallback onTap;
//
//   const _ReporteeTile({required this.reportee, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     final initials = reportee.fullName.isNotEmpty
//         ? reportee.fullName.trim().split(' ').take(2).map((e) => e[0]).join()
//         : '?';
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         onTap: onTap,
//         leading: CircleAvatar(
//           radius: 24,
//           backgroundColor: _kPrimaryColor.withOpacity(0.1),
//           child: Text(initials, style: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
//         ),
//         title: Text(reportee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(reportee.jobTitle, style: TextStyle(color: Colors.grey[600])),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//       ),
//     );
//   }
// }
//
// // ---------------------------------------------------------------------------
// // Detail Screen
// // ---------------------------------------------------------------------------
//
// class ReporteeVisitProofsScreen extends StatefulWidget {
//   final ReporteeModel reportee; // ✅ Correct Model
//
//   const ReporteeVisitProofsScreen({super.key, required this.reportee});
//
//   @override
//   State<ReporteeVisitProofsScreen> createState() => _ReporteeVisitProofsScreenState();
// }
//
// class _ReporteeVisitProofsScreenState extends State<ReporteeVisitProofsScreen> {
//   late DateTime _selectedDate;
//   Future<List<VisitProof>>? _proofsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = DateTime.now();
//     _fetchProofs();
//   }
//
//   void _fetchProofs() {
//     setState(() {
//       // Uses the new filter logic
//       _proofsFuture = VisitProofService.instance.getVisitProofs(
//         employeeId: widget.reportee.employeeId,
//         date: _selectedDate,
//       );
//     });
//   }
//
//   Future<void> _pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(const Duration(days: 30)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() => _selectedDate = picked);
//       _fetchProofs();
//     }
//   }
//
//   void _changeDay(int days) {
//     setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
//     _fetchProofs();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.reportee.fullName, style: const TextStyle(fontSize: 16)),
//             const Text('Visit Proofs', style: TextStyle(fontSize: 12)),
//           ],
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(colors: [_kPrimaryColor, _kSecondaryColor]),
//           ),
//         ),
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // Date Selector
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDay(-1)),
//                 GestureDetector(
//                   onTap: _pickDate,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: _kPrimaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.calendar_today, size: 16, color: _kPrimaryColor),
//                         const SizedBox(width: 8),
//                         Text(dateStr, style: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                   ),
//                 ),
//                 IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDay(1)),
//               ],
//             ),
//           ),
//
//           // List
//           Expanded(
//             child: FutureBuilder<List<VisitProof>>(
//               future: _proofsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   String err = snapshot.error.toString();
//                   // ✅ User friendly error
//                   if (err.contains("403")) err = "Permission Denied.";
//                   return Center(child: Text(err));
//                 }
//                 final proofs = snapshot.data ?? [];
//
//                 // Filter Logic for "No Data"
//                 if (proofs.isEmpty) {
//                   return const Center(child: Text('No proofs uploaded for this date.'));
//                 }
//
//                 // Sort newest first
//                 proofs.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
//
//                 return ListView.separated(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: proofs.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 16),
//                   itemBuilder: (context, index) => _VisitProofCard(proof: proofs[index]),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// // lib/features/visit_proof/team_visits_screen.dart
//
// class _VisitProofCard extends StatelessWidget {
//   final VisitProof proof;
//   const _VisitProofCard({required this.proof});
//
//   @override
//   Widget build(BuildContext context) {
//     final timeStr = DateFormat('h:mm a').format(proof.capturedAt);
//
//     // ✅ 1. Get the API URL using the ID
//     final imageUrl = VisitProofService.instance.getProofImageApiUrl(proof.id);
//
//     // ✅ 2. Get Token for Auth Header
//     final token = AuthService.instance.token;
//
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         children: [
//           ListTile(
//             leading: const Icon(Icons.access_time, color: Colors.grey),
//             title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
//             trailing: (proof.latitude != null) ? const Icon(Icons.location_on, color: Colors.redAccent) : null,
//           ),
//           AspectRatio(
//             aspectRatio: 4 / 3,
//             child: Image.network(
//               imageUrl,
//               fit: BoxFit.cover,
//               // ✅ 3. ESSENTIAL: Send Bearer Token so Backend accepts request
//               headers: token != null ? {'Authorization': 'Bearer $token'} : null,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                         loadingProgress.expectedTotalBytes!
//                         : null,
//                   ),
//                 );
//               },
//               errorBuilder: (ctx, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey[200],
//                   child: const Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.broken_image, color: Colors.grey, size: 32),
//                       SizedBox(height: 4),
//                       Text("Image not found", style: TextStyle(color: Colors.grey, fontSize: 10))
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (proof.comment.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(proof.comment),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// // ✅ Use Existing Models & Services
// import '../../data/models/reportee_model.dart';
// import '../../data/models/visit_proof_model.dart';
// import '../../data/services/employee_service.dart';
// import '../../data/services/visit_proof_service.dart';
//
// // 🎨 Theme Constants
// const Color _kPrimaryColor = Color(0xFF667EEA);
// const Color _kSecondaryColor = Color(0xFF764BA2);
//
// class TeamVisitsScreen extends StatefulWidget {
//   const TeamVisitsScreen({super.key});
//
//   @override
//   State<TeamVisitsScreen> createState() => _TeamVisitsScreenState();
// }
//
// class _TeamVisitsScreenState extends State<TeamVisitsScreen> {
//   // ✅ Use ReporteeModel
//   Future<List<ReporteeModel>>? _reporteesFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadReportees();
//   }
//
//   void _loadReportees() {
//     setState(() {
//       // ✅ Use existing method: getReportees()
//       _reporteesFuture = EmployeeService.instance.getReportees();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Header Background
//           Container(
//             height: 200,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [_kPrimaryColor, _kSecondaryColor],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 // AppBar
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Team Visits',
//                         style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // List
//                 Expanded(
//                   child: Container(
//                     width: double.infinity,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFF5F7FA),
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                     ),
//                     child: FutureBuilder<List<ReporteeModel>>(
//                       future: _reporteesFuture,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return const Center(child: CircularProgressIndicator());
//                         }
//                         if (snapshot.hasError) {
//                           return Center(child: Text('Error: ${snapshot.error}'));
//                         }
//
//                         final list = snapshot.data ?? [];
//                         if (list.isEmpty) {
//                           return const Center(child: Text('No reportees found.'));
//                         }
//
//                         return ListView.separated(
//                           padding: const EdgeInsets.all(16),
//                           itemCount: list.length,
//                           separatorBuilder: (_, __) => const SizedBox(height: 12),
//                           itemBuilder: (context, index) {
//                             final reportee = list[index];
//                             return _ReporteeTile(
//                               reportee: reportee,
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => ReporteeVisitProofsScreen(reportee: reportee),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _ReporteeTile extends StatelessWidget {
//   final ReporteeModel reportee; // ✅ Updated Type
//   final VoidCallback onTap;
//
//   const _ReporteeTile({required this.reportee, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     final initials = reportee.fullName.isNotEmpty
//         ? reportee.fullName.trim().split(' ').take(2).map((e) => e[0]).join()
//         : '?';
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         onTap: onTap,
//         leading: CircleAvatar(
//           radius: 24,
//           backgroundColor: _kPrimaryColor.withOpacity(0.1),
//           child: Text(initials, style: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
//         ),
//         title: Text(reportee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(reportee.jobTitle, style: TextStyle(color: Colors.grey[600])),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//       ),
//     );
//   }
// }
//
// // ---------------------------------------------------------------------------
// // Detail Screen
// // ---------------------------------------------------------------------------
//
// class ReporteeVisitProofsScreen extends StatefulWidget {
//   final ReporteeModel reportee; // ✅ Updated Type
//
//   const ReporteeVisitProofsScreen({super.key, required this.reportee});
//
//   @override
//   State<ReporteeVisitProofsScreen> createState() => _ReporteeVisitProofsScreenState();
// }
//
// class _ReporteeVisitProofsScreenState extends State<ReporteeVisitProofsScreen> {
//   late DateTime _selectedDate;
//   Future<List<VisitProof>>? _proofsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = DateTime.now();
//     _fetchProofs();
//   }
//
//   void _fetchProofs() {
//     setState(() {
//       _proofsFuture = VisitProofService.instance.getVisitProofs(
//         employeeId: widget.reportee.employeeId,
//         date: _selectedDate,
//       );
//     });
//   }
//
//   Future<void> _pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(const Duration(days: 30)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() => _selectedDate = picked);
//       _fetchProofs();
//     }
//   }
//
//   void _changeDay(int days) {
//     setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
//     _fetchProofs();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.reportee.fullName, style: const TextStyle(fontSize: 16)),
//             const Text('Visit Proofs', style: TextStyle(fontSize: 12)),
//           ],
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(colors: [_kPrimaryColor, _kSecondaryColor]),
//           ),
//         ),
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // Date Selector
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDay(-1)),
//                 GestureDetector(
//                   onTap: _pickDate,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: _kPrimaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.calendar_today, size: 16, color: _kPrimaryColor),
//                         const SizedBox(width: 8),
//                         Text(dateStr, style: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                   ),
//                 ),
//                 IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDay(1)),
//               ],
//             ),
//           ),
//
//           // List
//           Expanded(
//             child: FutureBuilder<List<VisitProof>>(
//               future: _proofsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 final proofs = snapshot.data ?? [];
//                 if (proofs.isEmpty) {
//                   return const Center(child: Text('No proofs uploaded for this date.'));
//                 }
//
//                 // Sort newest first
//                 proofs.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
//
//                 return ListView.separated(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: proofs.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 16),
//                   itemBuilder: (context, index) => _VisitProofCard(proof: proofs[index]),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _VisitProofCard extends StatelessWidget {
//   final VisitProof proof;
//   const _VisitProofCard({required this.proof});
//
//   @override
//   Widget build(BuildContext context) {
//     final timeStr = DateFormat('h:mm a').format(proof.capturedAt);
//     final imageUrl = VisitProofService.instance.getFullImageUrl(proof.proofImageUrl);
//
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         children: [
//           ListTile(
//             leading: const Icon(Icons.access_time, color: Colors.grey),
//             title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
//             trailing: (proof.latitude != null) ? const Icon(Icons.location_on, color: Colors.redAccent) : null,
//           ),
//           AspectRatio(
//             aspectRatio: 4 / 3,
//             child: Image.network(
//               imageUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (ctx, _, __) => Container(
//                 color: Colors.grey[200],
//                 child: const Icon(Icons.broken_image, color: Colors.grey),
//               ),
//             ),
//           ),
//           if (proof.comment.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(proof.comment),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }