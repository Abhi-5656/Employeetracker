// // lib/features/reportee/reportee_map_view_screen.dart
//new
// lib/features/reportee/reportee_map_view_screen.dart

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../data/models/reportee_model.dart';
import '../../data/services/employee_service.dart';
import '../../shared/widgets/layouts.dart'; // For GradientScaffold if needed, though we use Scaffold here

// 🎨 Theme Constants
const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class ReporteeMapViewScreen extends StatefulWidget {
  final ReporteeModel reportee;
  final DateTime? date; // Initial date (null = latest)

  const ReporteeMapViewScreen({
    Key? key,
    required this.reportee,
    this.date,
  }) : super(key: key);

  @override
  _ReporteeMapViewScreenState createState() => _ReporteeMapViewScreenState();
}

class _ReporteeMapViewScreenState extends State<ReporteeMapViewScreen> {
  // ⚠️ PASTE YOUR MapTiler API KEY HERE
  static const String MAPTILER_STYLE_URL =
      "https://api.maptiler.com/maps/streets-v2/style.json?key=VMVIqNS4SYJhP8t1oDng";

  MapLibreMapController? _mapController;

  // State to track the currently viewed date (null means Latest)
  DateTime? _currentDate;

  late Future<SessionPathResponse> _pathFuture;
  bool _pathDrawn = false;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.date; // Initialize with passed date
    _loadPathData();
  }

  // 🎯 Centralized method to load data based on _currentDate
  void _loadPathData() {
    setState(() {
      _pathDrawn = false;

      // Clear old lines/symbols immediately if controller exists
      if (_mapController != null) {
        _mapController!.clearLines();
        _mapController!.clearSymbols();
      }

      if (_currentDate != null) {
        _pathFuture = EmployeeService.instance.getReporteePathForDate(
          widget.reportee.employeeId,
          _currentDate!,
        );
      } else {
        _pathFuture = EmployeeService.instance.getLatestReporteePath(
          widget.reportee.employeeId,
        );
      }
    });
  }

  // 🎯 Date Picker Handler
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate ?? now,
      firstDate: DateTime(2023),
      lastDate: now,
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

    if (picked != null) {
      setState(() {
        _currentDate = picked;
      });
      _loadPathData(); // Reload data for the new date
    }
  }

  Future<void> _loadImages() async {
    if (_mapController == null) return;

    try {
      final ByteData start = await rootBundle.load('assets/icons/start_marker.png');
      final ByteData end = await rootBundle.load('assets/icons/end_marker.png');

      await _mapController!.addImage('start-icon', start.buffer.asUint8List());
      await _mapController!.addImage('end-icon', end.buffer.asUint8List());
    } catch (e) {
      debugPrint("Warning: Could not load custom map icons. Using default. Error: $e");
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _drawPathOnMap(List<LatLng> path) async {
    if (_mapController == null || path.isEmpty || _pathDrawn) return;

    await _mapController!.clearLines();
    await _mapController!.clearSymbols();

    await _mapController!.addLine(
      LineOptions(
        geometry: path,
        lineColor: "#667EEA", // Primary Color Hex
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );

    // Start Marker
    await _mapController!.addSymbol(SymbolOptions(
      geometry: path.first,
      iconImage: 'start-icon',
      iconSize: 3,
      textField: 'START',
      textSize: 14.0,
      textColor: '#000000',
      textOffset: const Offset(0, -2.5),
      textHaloColor: '#FFFFFF',
      textHaloWidth: 1.0,
    ));

    // End Marker
    await _mapController!.addSymbol(SymbolOptions(
      geometry: path.last,
      iconImage: 'end-icon',
      iconSize: 3,
      textField: 'END',
      textSize: 14.0,
      textColor: '#000000',
      textOffset: const Offset(0, -2.5),
      textHaloColor: '#FFFFFF',
      textHaloWidth: 1.0,
    ));

    final LatLngBounds bounds = _calculateBounds(path);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: 50.0, top: 50.0, right: 50.0, bottom: 50.0,
      ),
    );

    _pathDrawn = true;
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude, minLng = points.first.longitude;
    double maxLat = points.first.latitude, maxLng = points.first.longitude;
    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // 🎯 Enhanced Info Card (Shown when data exists)
  Widget _buildInfoCard(SessionPathResponse sessionData) {
    String formatTimestamp(String ts) {
      if (ts.isEmpty) return "N/A";
      try {
        // ✅ FIX: Convert UTC string to Device Local Time
        return DateFormat('h:mm a').format(DateTime.parse(ts).toLocal());
      } catch (e) {
        return ts;
      }
    }

    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reportee.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      _currentDate == null ? "Latest Session" : DateFormat('MMM d, y').format(_currentDate!),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "COMPLETED",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryColor,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeStat("Start Time", formatTimestamp(sessionData.startedAt), Icons.play_circle_outline),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: _buildTimeStat("End Time", formatTimestamp(sessionData.endedAt), Icons.stop_circle_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  // 🎯 Enhanced Empty State Card
  Widget _buildEmptyStateCard() {
    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "No Path Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "There is no location history available for ${_currentDate == null ? 'the latest session' : DateFormat('MMM d').format(_currentDate!)}.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pickDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Select Another Date", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentDate == null
        ? "Latest Path"
        : DateFormat('MMM d, y').format(_currentDate!);

    return Scaffold(
      extendBodyBehindAppBar: true, // Map fills screen
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimaryColor.withOpacity(0.9), _kSecondaryColor.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: FutureBuilder<SessionPathResponse>(
        future: _pathFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. Error State - Styled View
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[200]),
                    const SizedBox(height: 16),
                    Text(
                      "Unable to Load Map",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We couldn't fetch the location data.\nPlease check your connection.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadPathData,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: const Text("Retry", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final sessionData = snapshot.data;
          final path = sessionData?.path ?? [];

          // 2. Empty State - Show Map + Floating "No Data" Card
          if (path.isEmpty) {
            return Stack(
              children: [
                MapLibreMap(
                  styleString: MAPTILER_STYLE_URL,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(26.4499, 80.3319),
                    zoom: 12.0,
                  ),
                ),
                _buildEmptyStateCard(),
              ],
            );
          }

          // 3. Success State - Map + Data Card
          return Stack(
            children: [
              MapLibreMap(
                styleString: MAPTILER_STYLE_URL,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: () async {
                  await _loadImages();
                  _drawPathOnMap(path);
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(26.4499, 80.3319),
                  zoom: 14.0,
                ),
              ),
              _buildInfoCard(sessionData!),
            ],
          );
        },
      ),
    );
  }
}
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:maplibre_gl/maplibre_gl.dart';
// import '../../data/models/reportee_model.dart';
// import '../../data/services/employee_service.dart';
// import '../../shared/widgets/layouts.dart';
//
// class ReporteeMapViewScreen extends StatefulWidget {
//   final ReporteeModel reportee;
//   final DateTime? date; // Initial date (null = latest)
//
//   const ReporteeMapViewScreen({
//     Key? key,
//     required this.reportee,
//     this.date,
//   }) : super(key: key);
//
//   @override
//   _ReporteeMapViewScreenState createState() => _ReporteeMapViewScreenState();
// }
//
// class _ReporteeMapViewScreenState extends State<ReporteeMapViewScreen> {
//   // ⚠️ PASTE YOUR MapTiler API KEY HERE
//   static const String MAPTILER_STYLE_URL =
//       "https://api.maptiler.com/maps/streets-v2/style.json?key=VMVIqNS4SYJhP8t1oDng";
//
//   MapLibreMapController? _mapController;
//
//   // State to track the currently viewed date (null means Latest)
//   DateTime? _currentDate;
//
//   late Future<SessionPathResponse> _pathFuture;
//   bool _pathDrawn = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentDate = widget.date; // Initialize with passed date
//     _loadPathData();
//   }
//
//   // 🎯 NEW: Centralized method to load data based on _currentDate
//   void _loadPathData() {
//     setState(() {
//       // Reset drawing flag so map redraws when data arrives
//       _pathDrawn = false;
//
//       // If controller exists, clear old lines/symbols immediately
//       if (_mapController != null) {
//         _mapController!.clearLines();
//         _mapController!.clearSymbols();
//       }
//
//       if (_currentDate != null) {
//         // Fetch for specific date
//         _pathFuture = EmployeeService.instance.getReporteePathForDate(
//           widget.reportee.employeeId,
//           _currentDate!,
//         );
//       } else {
//         // Fetch latest
//         _pathFuture = EmployeeService.instance.getLatestReporteePath(
//           widget.reportee.employeeId,
//         );
//       }
//     });
//   }
//
//   // 🎯 NEW: Date Picker Handler
//   Future<void> _pickDate() async {
//     final DateTime now = DateTime.now();
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _currentDate ?? now,
//       firstDate: DateTime(2023),
//       lastDate: now,
//       helpText: 'SELECT DATE FOR PATH',
//     );
//
//     if (picked != null) {
//       setState(() {
//         _currentDate = picked;
//       });
//       _loadPathData(); // Reload data for the new date
//     }
//   }
//
//   Future<void> _loadImages() async {
//     if (_mapController == null) return;
//
//     try {
//       final ByteData start = await rootBundle.load('assets/icons/start_marker.png');
//       final ByteData end = await rootBundle.load('assets/icons/end_marker.png');
//
//       await _mapController!.addImage('start-icon', start.buffer.asUint8List());
//       await _mapController!.addImage('end-icon', end.buffer.asUint8List());
//     } catch (e) {
//       debugPrint("Warning: Could not load custom map icons. Using default. Error: $e");
//     }
//   }
//
//   void _onMapCreated(MapLibreMapController controller) {
//     _mapController = controller;
//   }
//
//   void _drawPathOnMap(List<LatLng> path) async {
//     // If already drawn or empty, skip
//     if (_mapController == null || path.isEmpty || _pathDrawn) return;
//
//     // Double check to clear artifacts before drawing (safety)
//     await _mapController!.clearLines();
//     await _mapController!.clearSymbols();
//
//     await _mapController!.addLine(
//       LineOptions(
//         geometry: path,
//         lineColor: "#3F51B5",
//         lineWidth: 5.0,
//         lineOpacity: 0.8,
//       ),
//     );
//
//     // 1. Add START Icon
//     await _mapController!.addSymbol(SymbolOptions(
//       geometry: path.first,
//       iconImage: 'start-icon',
//       iconSize: 3,
//     ));
//     // 2. Add START Text
//     await _mapController!.addSymbol(SymbolOptions(
//       geometry: path.first,
//       textField: 'START',
//       textSize: 14.0,
//       textColor: '#000000',
//       textOffset: const Offset(0, -2.5),
//       textHaloColor: '#FFFFFF',
//       textHaloWidth: 1.0,
//     ));
//     // 3. Add END Icon
//     await _mapController!.addSymbol(SymbolOptions(
//       geometry: path.last,
//       iconImage: 'end-icon',
//       iconSize: 3,
//     ));
//     // 4. Add END Text
//     await _mapController!.addSymbol(SymbolOptions(
//       geometry: path.last,
//       textField: 'END',
//       textSize: 14.0,
//       textColor: '#000000',
//       textOffset: const Offset(0, -2.5),
//       textHaloColor: '#FFFFFF',
//       textHaloWidth: 1.0,
//     ));
//
//     final LatLngBounds bounds = _calculateBounds(path);
//     _mapController!.animateCamera(
//       CameraUpdate.newLatLngBounds(
//         bounds,
//         left: 50.0, top: 50.0, right: 50.0, bottom: 50.0,
//       ),
//     );
//
//     _pathDrawn = true;
//   }
//
//   LatLngBounds _calculateBounds(List<LatLng> points) {
//     double minLat = points.first.latitude, minLng = points.first.longitude;
//     double maxLat = points.first.latitude, maxLng = points.first.longitude;
//     for (var point in points) {
//       if (point.latitude < minLat) minLat = point.latitude;
//       if (point.longitude < minLng) minLng = point.longitude;
//       if (point.latitude > maxLat) maxLat = point.latitude;
//       if (point.longitude > maxLng) maxLng = point.longitude;
//     }
//     return LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );
//   }
//
//   Widget _buildInfoCard(SessionPathResponse sessionData) {
//     String formatTimestamp(String ts) {
//       if (ts.isEmpty) return "N/A";
//       try {
//         return DateFormat.yMd().add_jms().format(DateTime.parse(ts));
//       } catch (e) {
//         return ts;
//       }
//     }
//
//     return Positioned(
//       bottom: 20,
//       left: 20,
//       right: 20,
//       child: Card(
//         elevation: 4,
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     widget.reportee.fullName,
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   // Small badge showing what we are looking at
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: _currentDate == null ? Colors.green[100] : Colors.blue[100],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       _currentDate == null ? "LATEST" : "HISTORY",
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                         color: _currentDate == null ? Colors.green[800] : Colors.blue[800],
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Started: ${formatTimestamp(sessionData.startedAt)}",
//                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "Ended: ${formatTimestamp(sessionData.endedAt)}",
//                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // 🎯 Dynamic Title based on state
//     final title = _currentDate == null
//         ? "${widget.reportee.fullName}'s Latest Path"
//         : "${widget.reportee.fullName} - ${DateFormat('MMM d, y').format(_currentDate!)}";
//
//     return GradientScaffold(
//       title: title,
//       // 🎯 ADD CALENDAR ICON HERE
//       trailing: IconButton(
//         icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
//         tooltip: 'Select Date',
//         onPressed: _pickDate,
//       ),
//       child: FutureBuilder<SessionPathResponse>(
//         future: _pathFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
//                     const SizedBox(height: 16),
//                     Text(
//                       "Could not load path.",
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "${snapshot.error}".replaceAll("Exception: ", ""),
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       onPressed: _loadPathData,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text("Retry"),
//                     )
//                   ],
//                 ),
//               ),
//             );
//           }
//
//           // Handle empty data or success
//           final sessionData = snapshot.data;
//           final path = sessionData?.path ?? [];
//
//           if (path.isEmpty) {
//             return Stack(
//               children: [
//                 // Still show the map background even if no path
//                 MapLibreMap(
//                   styleString: MAPTILER_STYLE_URL,
//                   onMapCreated: _onMapCreated,
//                   initialCameraPosition: const CameraPosition(
//                     target: LatLng(26.4499, 80.3319),
//                     zoom: 12.0,
//                   ),
//                 ),
//                 Center(
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.9),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Text(
//                       "No path data available for this selection.",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }
//
//           // Success case with data
//           return Stack(
//             children: [
//               MapLibreMap(
//                 styleString: MAPTILER_STYLE_URL,
//                 onMapCreated: _onMapCreated,
//                 onStyleLoadedCallback: () async {
//                   await _loadImages();
//                   _drawPathOnMap(path);
//                 },
//                 initialCameraPosition: const CameraPosition(
//                   target: LatLng(26.4499, 80.3319),
//                   zoom: 14.0,
//                 ),
//               ),
//               _buildInfoCard(sessionData!),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:maplibre_gl/maplibre_gl.dart';
// import '../../data/models/reportee_model.dart';
// import '../../data/services/employee_service.dart';
// import '../../shared/widgets/layouts.dart';
//
// class ReporteeMapViewScreen extends StatefulWidget {
//   final ReporteeModel reportee;
//
//   const ReporteeMapViewScreen({
//     Key? key,
//     required this.reportee,
//   }) : super(key: key);
//
//   @override
//   _ReporteeMapViewScreenState createState() => _ReporteeMapViewScreenState();
// }
//
// class _ReporteeMapViewScreenState extends State<ReporteeMapViewScreen> {
//   // ⚠️ PASTE YOUR MapTiler API KEY HERE
//   static const String MAPTILER_STYLE_URL =
//       "https://api.maptiler.com/maps/satellite/style.json?key=VMVIqNS4SYJhP8t1oDng";
//
//   MapLibreMapController? _mapController;
//   late Future<SessionPathResponse> _pathFuture;
//   bool _pathDrawn = false; // Add a flag to prevent drawing multiple times
//
//   @override
//   void initState() {
//     super.initState();
//     _pathFuture = EmployeeService.instance.getLatestReporteePath(widget.reportee.employeeId);
//   }
//
//   void _onMapCreated(MapLibreMapController controller) {
//     _mapController = controller;
//     // We don't draw here immediately; we wait for the style to be loaded.
//   }
//
//   void _drawPathOnMap(List<LatLng> path) {
//     // Check if map is ready and path hasn't been drawn yet
//     if (_mapController == null || path.isEmpty || _pathDrawn) return;
//
//     _mapController!.addLine(
//       LineOptions(
//         geometry: path,
//         lineColor: "#FF0000", // Red
//         lineWidth: 4.0,
//         lineOpacity: 0.8,
//       ),
//     );
//     _mapController!.addSymbol(SymbolOptions(geometry: path.first, iconImage: 'marker-15'));
//     _mapController!.addSymbol(SymbolOptions(geometry: path.last, iconImage: 'marker-15'));
//
//     final LatLngBounds bounds = _calculateBounds(path);
//     _mapController!.animateCamera(
//       CameraUpdate.newLatLngBounds(
//         bounds,
//         left: 50.0, top: 50.0, right: 50.0, bottom: 50.0,
//       ),
//     );
//
//     // Set the flag to true
//     _pathDrawn = true;
//   }
//
//   LatLngBounds _calculateBounds(List<LatLng> points) {
//     double minLat = points.first.latitude, minLng = points.first.longitude;
//     double maxLat = points.first.latitude, maxLng = points.first.longitude;
//     for (var point in points) {
//       if (point.latitude < minLat) minLat = point.latitude;
//       if (point.longitude < minLng) minLng = point.longitude;
//       if (point.latitude > maxLat) maxLat = point.latitude;
//       if (point.longitude > maxLng) maxLng = point.longitude;
//     }
//     return LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GradientScaffold(
//       title: "${widget.reportee.fullName}'s Path",
//       child: FutureBuilder<SessionPathResponse>(
//         future: _pathFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 "Failed to load path: ${snapshot.error}",
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             );
//           }
//           if (!snapshot.hasData || snapshot.data!.path.isEmpty) {
//             return const Center(
//               child: Text(
//                 "No path data found for this employee's latest session.",
//                 style: TextStyle(color: Colors.white70),
//               ),
//             );
//           }
//
//           final path = snapshot.data!.path;
//
//           return MapLibreMap(
//             styleString: MAPTILER_STYLE_URL,
//             onMapCreated: _onMapCreated,
//
//             // --- ⛔ THIS IS THE FIX ---
//             // Replace `onMapRenderedCallback` with `onStyleLoadedCallback`
//             onStyleLoadedCallback: () {
//               _drawPathOnMap(path); // Draw the path once the style is loaded
//             },
//             // --- END OF FIX ---
//
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(26.4499, 80.3319), // Default
//               zoom: 14.0,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }