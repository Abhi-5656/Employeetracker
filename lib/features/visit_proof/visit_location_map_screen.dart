import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

// 🎨 Theme Constants
const Color _kPrimaryColor = Color(0xFF667EEA);
const Color _kSecondaryColor = Color(0xFF764BA2);

class VisitLocationMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String clientName;
  final String visitedAt;

  const VisitLocationMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.clientName,
    required this.visitedAt,
  });

  @override
  State<VisitLocationMapScreen> createState() => _VisitLocationMapScreenState();
}

class _VisitLocationMapScreenState extends State<VisitLocationMapScreen> {
  // Standard MapTiler Style
  static const String MAPTILER_STYLE_URL =
      "https://api.maptiler.com/maps/streets-v2/style.json?key=VMVIqNS4SYJhP8t1oDng";

  MapLibreMapController? _mapController;

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  /// ✅ FIX: Load a visible marker (Image or Circle)
  Future<void> _onStyleLoaded() async {
    if (_mapController == null) return;

    try {
      // 1. Try to load the App's existing "End Marker" (Red Pin)
      final ByteData bytes = await rootBundle.load('assets/icons/end_marker.png');
      final Uint8List list = bytes.buffer.asUint8List();

      // Add image to map style
      await _mapController!.addImage('visit-marker', list);

      // Add Symbol using the image
      await _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(widget.latitude, widget.longitude),
        iconImage: "visit-marker",
        iconSize: 3.0, // Adjusted size for visibility
        iconAnchor: "bottom", // Pin tip points to location
        textField: widget.clientName,
        textOffset: const Offset(0, 1.0), // Text below the pin
        textSize: 14.0,
        textColor: '#000000',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.0,
      ));

    } catch (e) {
      // ⚠️ FALLBACK: If image asset is missing, draw a Red Circle instead.
      // This ensures the user ALWAYS sees a location mark.
      debugPrint("Marker asset not found, using Circle fallback: $e");

      await _mapController!.addCircle(CircleOptions(
        geometry: LatLng(widget.latitude, widget.longitude),
        circleColor: "#FF0000", // Red Dot
        circleRadius: 10.0,
        circleStrokeWidth: 2.0,
        circleStrokeColor: "#FFFFFF",
      ));

      // Add Text Label
      await _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(widget.latitude, widget.longitude),
        textField: widget.clientName,
        textOffset: const Offset(0, 1.5),
        textSize: 14.0,
        textColor: '#000000',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Visit Location", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.visitedAt, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimaryColor.withOpacity(0.9), _kSecondaryColor.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: MAPTILER_STYLE_URL,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 15.0,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded, // ✅ Calls our fixed marker logic
          ),

          // Floating Info Card
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: _kPrimaryColor),
                ),
                title: Text(widget.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Lat: ${widget.latitude.toStringAsFixed(5)}, Lng: ${widget.longitude.toStringAsFixed(5)}"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}