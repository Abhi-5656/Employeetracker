// lib/features/reportee/reportee_list_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/reportee_model.dart';
import '../../data/services/employee_service.dart';
import '../../shared/widgets/lists.dart';
import '../../shared/widgets/layouts.dart';
import '../../shared/widgets/buttons.dart'; // 👈 --- ADD THIS IMPORT
import 'reportee_map_view_screen.dart';   // 👈 --- ADD THIS IMPORT

class ReporteeListScreen extends StatefulWidget {
  @override
  _ReporteeListScreenState createState() => _ReporteeListScreenState();
}

class _ReporteeListScreenState extends State<ReporteeListScreen> {
  late Future<List<ReporteeModel>> _reporteesFuture;

  // 🎯 NEW: Controller for the search bar
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _reporteesFuture = _fetchReportees();
    // 🎯 NEW: Listen to search input changes
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

  /// --- 👇 THIS IS THE FULLY REPLACED METHOD ---
  /// --- 👇 REPLACED METHOD: Direct Navigation ---
  void _onViewMapPressed(ReporteeModel reportee) {
    // Directly navigate to the map view, defaulting to "Latest Path" (date: null)
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
  // void _onViewMapPressed(ReporteeModel reportee) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (modalContext) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // Option 1: Show Latest Path
  //             ListTile(
  //               leading: const Icon(Icons.timeline_rounded),
  //               title: const Text('Show Latest Path'),
  //               subtitle: const Text('Display the most recent completed session'),
  //               onTap: () {
  //                 Navigator.pop(modalContext); // Close bottom sheet
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => ReporteeMapViewScreen(
  //                       reportee: reportee,
  //                       date: null, // <-- Pass null for latest
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //             // Option 2: Select a Date
  //             ListTile(
  //               leading: const Icon(Icons.calendar_today_rounded),
  //               title: const Text('Select a Date'),
  //               subtitle: const Text('Pick a specific day to view session'),
  //               onTap: () async {
  //                 Navigator.pop(modalContext); // Close bottom sheet
  //
  //                 final DateTime? pickedDate = await showDatePicker(
  //                   context: context,
  //                   initialDate: DateTime.now(),
  //                   firstDate: DateTime(2020),
  //                   lastDate: DateTime.now(),
  //                 );
  //
  //                 if (pickedDate != null) {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => ReporteeMapViewScreen(
  //                         reportee: reportee,
  //                         date: pickedDate, // <-- Pass the selected date
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'My Reportees',
      // 🎯 NEW: We wrap the content in a Column to place the SearchBar at the top
      child: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // 2. Reportee List (Expanded to fill remaining space)
          Expanded(
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
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final allReportees = snapshot.data ?? [];

                  // 🎯 NEW: Filter the list based on the search query
                  final filteredReportees = allReportees.where((r) {
                    return r.fullName.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredReportees.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? "You have no reportees."
                            : "No reportee found matching '$_searchQuery'.",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                    itemCount: filteredReportees.length,
                    itemBuilder: (context, index) {
                      final reportee = filteredReportees[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Column(
                          children: [
                            NotifRow(
                              title: reportee.fullName,
                              text: "${reportee.jobTitle} - ${reportee.department}",
                              icon: Icons.person_outline_rounded,
                              colorBg: const Color(0xFFE8EAF6),
                              colorFg: const Color(0xFF3F51B5),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: ActionBtn.primary(
                                'View Path on Map',
                                    () => _onViewMapPressed(reportee),
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
        ],
      ),
    );
  }
}