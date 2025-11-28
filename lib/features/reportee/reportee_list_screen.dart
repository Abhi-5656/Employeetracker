// // lib/features/reportee/reportee_list_screen.dart
// import 'package:flutter/material.dart';
// import '../../data/models/reportee_model.dart';
// import '../../data/services/employee_service.dart';
// import '../../shared/widgets/lists.dart';
// import '../../shared/widgets/layouts.dart';
// import '../../shared/widgets/buttons.dart'; // 👈 --- ADD THIS IMPORT
// import 'reportee_map_view_screen.dart';   // 👈 --- ADD THIS IMPORT
//
// class ReporteeListScreen extends StatefulWidget {
//   @override
//   _ReporteeListScreenState createState() => _ReporteeListScreenState();
// }
//
// class _ReporteeListScreenState extends State<ReporteeListScreen> {
//   late Future<List<ReporteeModel>> _reporteesFuture;
//
//   // 🎯 NEW: Controller for the search bar
//   final TextEditingController _searchCtrl = TextEditingController();
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _reporteesFuture = _fetchReportees();
//     // 🎯 NEW: Listen to search input changes
//     _searchCtrl.addListener(() {
//       setState(() {
//         _searchQuery = _searchCtrl.text.trim().toLowerCase();
//       });
//     });
//   }
//   Future<List<ReporteeModel>> _fetchReportees() {
//     return EmployeeService.instance.getReportees();
//   }
//   Future<void> _onRefresh() async {
//     setState(() {
//       _reporteesFuture = _fetchReportees();
//     });
//   }
//
//   /// --- 👇 THIS IS THE FULLY REPLACED METHOD ---
//   /// --- 👇 REPLACED METHOD: Direct Navigation ---
//   void _onViewMapPressed(ReporteeModel reportee) {
//     // Directly navigate to the map view, defaulting to "Latest Path" (date: null)
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ReporteeMapViewScreen(
//           reportee: reportee,
//           date: null, // Null implies 'Latest Path'
//         ),
//       ),
//     );
//   }
//   // void _onViewMapPressed(ReporteeModel reportee) {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (modalContext) {
//   //       return SafeArea(
//   //         child: Column(
//   //           mainAxisSize: MainAxisSize.min,
//   //           children: [
//   //             // Option 1: Show Latest Path
//   //             ListTile(
//   //               leading: const Icon(Icons.timeline_rounded),
//   //               title: const Text('Show Latest Path'),
//   //               subtitle: const Text('Display the most recent completed session'),
//   //               onTap: () {
//   //                 Navigator.pop(modalContext); // Close bottom sheet
//   //                 Navigator.push(
//   //                   context,
//   //                   MaterialPageRoute(
//   //                     builder: (context) => ReporteeMapViewScreen(
//   //                       reportee: reportee,
//   //                       date: null, // <-- Pass null for latest
//   //                     ),
//   //                   ),
//   //                 );
//   //               },
//   //             ),
//   //             // Option 2: Select a Date
//   //             ListTile(
//   //               leading: const Icon(Icons.calendar_today_rounded),
//   //               title: const Text('Select a Date'),
//   //               subtitle: const Text('Pick a specific day to view session'),
//   //               onTap: () async {
//   //                 Navigator.pop(modalContext); // Close bottom sheet
//   //
//   //                 final DateTime? pickedDate = await showDatePicker(
//   //                   context: context,
//   //                   initialDate: DateTime.now(),
//   //                   firstDate: DateTime(2020),
//   //                   lastDate: DateTime.now(),
//   //                 );
//   //
//   //                 if (pickedDate != null) {
//   //                   Navigator.push(
//   //                     context,
//   //                     MaterialPageRoute(
//   //                       builder: (context) => ReporteeMapViewScreen(
//   //                         reportee: reportee,
//   //                         date: pickedDate, // <-- Pass the selected date
//   //                       ),
//   //                     ),
//   //                   );
//   //                 }
//   //               },
//   //             ),
//   //           ],
//   //         ),
//   //       );
//   //     },
//   //   );
//   // }
//   @override
//   Widget build(BuildContext context) {
//     return GradientScaffold(
//       title: 'My Reportees',
//       // 🎯 NEW: We wrap the content in a Column to place the SearchBar at the top
//       child: Column(
//         children: [
//           // 1. Search Bar
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
//             child: TextField(
//               controller: _searchCtrl,
//               decoration: InputDecoration(
//                 hintText: 'Search by name...',
//                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                 suffixIcon: _searchQuery.isNotEmpty
//                     ? IconButton(
//                   icon: const Icon(Icons.clear, color: Colors.grey),
//                   onPressed: () {
//                     _searchCtrl.clear();
//                     FocusScope.of(context).unfocus();
//                   },
//                 )
//                     : null,
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 14),
//               ),
//             ),
//           ),
//
//           // 2. Reportee List (Expanded to fill remaining space)
//           Expanded(
//             child: RefreshIndicator(
//               onRefresh: _onRefresh,
//               child: FutureBuilder<List<ReporteeModel>>(
//                 future: _reporteesFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (snapshot.hasError) {
//                     return Center(
//                       child: Text(
//                         "Error: ${snapshot.error}",
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                     );
//                   }
//
//                   final allReportees = snapshot.data ?? [];
//
//                   // 🎯 NEW: Filter the list based on the search query
//                   final filteredReportees = allReportees.where((r) {
//                     return r.fullName.toLowerCase().contains(_searchQuery);
//                   }).toList();
//
//                   if (filteredReportees.isEmpty) {
//                     return Center(
//                       child: Text(
//                         _searchQuery.isEmpty
//                             ? "You have no reportees."
//                             : "No reportee found matching '$_searchQuery'.",
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                     );
//                   }
//
//                   return ListView.builder(
//                     padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
//                     itemCount: filteredReportees.length,
//                     itemBuilder: (context, index) {
//                       final reportee = filteredReportees[index];
//
//                       return Card(
//                         margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//                         child: Column(
//                           children: [
//                             NotifRow(
//                               title: reportee.fullName,
//                               text: "${reportee.jobTitle} - ${reportee.department}",
//                               icon: Icons.person_outline_rounded,
//                               colorBg: const Color(0xFFE8EAF6),
//                               colorFg: const Color(0xFF3F51B5),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                               child: ActionBtn.primary(
//                                 'View Path on Map',
//                                     () => _onViewMapPressed(reportee),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// new
import 'package:flutter/material.dart';
import '../../data/models/reportee_model.dart';
import '../../data/services/employee_service.dart';
import 'reportee_map_view_screen.dart';

// 🎨 Theme Constants (Matching other tabs)
const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class ReporteeListScreen extends StatefulWidget {
  @override
  _ReporteeListScreenState createState() => _ReporteeListScreenState();
}

class _ReporteeListScreenState extends State<ReporteeListScreen> {
  late Future<List<ReporteeModel>> _reporteesFuture;

  // Controller for the search bar
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _reporteesFuture = _fetchReportees();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  Future<List<ReporteeModel>> _fetchReportees() {
    return EmployeeService.instance.getReportees();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _reporteesFuture = _fetchReportees();
    });
  }

  // Direct navigation to map
  void _onViewMapPressed(ReporteeModel reportee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReporteeMapViewScreen(
          reportee: reportee,
          date: null, // Null implies 'Latest Path'
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft grey background for contrast
      body: Stack(
        children: [
          // 1. HEADER BACKGROUND (Gradient)
          Container(
            height: 260, // Taller to fit Search Bar
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryColor, _kSecondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative Background Icon
                Positioned(
                  right: -30,
                  top: -30,
                  child: Icon(Icons.people_alt_rounded, size: 180, color: Colors.white.withOpacity(0.1)),
                ),
              ],
            ),
          ),

          // 2. CONTENT
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // HEADER CONTENT (Fixed Top)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Reportees',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage Team & Locations',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      // Search Bar (Integrated in Header)
                      TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchCtrl.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // BODY SECTION (Full Screen White Sheet)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA), // Matches Scaffold bg, but structure ready for rounded look if needed
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: FutureBuilder<List<ReporteeModel>>(
                          future: _reporteesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Error loading team",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final allReportees = snapshot.data ?? [];
                            final filteredReportees = allReportees.where((r) {
                              return r.fullName.toLowerCase().contains(_searchQuery);
                            }).toList();

                            if (filteredReportees.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? "You have no reportees."
                                          : "No matching reportee found.",
                                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredReportees.length,
                              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final reportee = filteredReportees[index];

                                // Enhanced Reportee Card
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Avatar / Initials
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [_kPrimaryColor.withOpacity(0.1), _kSecondaryColor.withOpacity(0.1)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                reportee.fullName.isNotEmpty ? reportee.fullName[0].toUpperCase() : '?',
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kPrimaryColor),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Name & Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  reportee.fullName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.work_outline_rounded, size: 14, color: Colors.grey[500]),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        "${reportee.jobTitle} • ${reportee.department}",
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Action Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _onViewMapPressed(reportee),
                                          icon: const Icon(Icons.map_rounded, size: 18),
                                          label: const Text('View Path on Map'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _kPrimaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0, // Flat style matches modern look
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
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