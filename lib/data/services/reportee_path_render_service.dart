import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

class ReporteePathRenderResult {
  const ReporteePathRenderResult({
    required this.rawPath,
    required this.displayPath,
    required this.usedSnappedPath,
  });

  final List<LatLng> rawPath;
  final List<LatLng> displayPath;
  final bool usedSnappedPath;
}

class ReporteePathRenderService {
  ReporteePathRenderService._();

  static final ReporteePathRenderService instance = ReporteePathRenderService._();

  static const String _osrmBaseUrl = String.fromEnvironment(
    'OSRM_BASE_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  final http.Client _client = http.Client();

  Future<ReporteePathRenderResult> preparePath(List<LatLng> input) async {
    final sanitized = _sanitize(input);
    debugPrint('ReporteePathRenderService -> input=${input.length}, sanitized=${sanitized.length}');

    if (sanitized.length < 2) {
      return ReporteePathRenderResult(
        rawPath: sanitized,
        displayPath: sanitized,
        usedSnappedPath: false,
      );
    }

    final snapped = await _snapWholePath(sanitized);
    debugPrint('ReporteePathRenderService -> snapped=${snapped.length}');

    if (snapped.length >= 2) {
      return ReporteePathRenderResult(
        rawPath: sanitized,
        displayPath: snapped,
        usedSnappedPath: true,
      );
    }

    return ReporteePathRenderResult(
      rawPath: sanitized,
      displayPath: sanitized,
      usedSnappedPath: false,
    );
  }

  List<LatLng> _sanitize(List<LatLng> input) {
    if (input.isEmpty) return const [];

    final out = <LatLng>[];
    LatLng? last;

    for (final point in input) {
      if (!_isValid(point)) continue;

      if (last != null) {
        final distance = _haversineMeters(last, point);

        if (distance < 3) {
          continue;
        }

        if (distance > 700) {
          continue;
        }
      }

      out.add(point);
      last = point;
    }

    return out;
  }

  bool _isValid(LatLng point) {
    return point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  Future<List<LatLng>> _snapWholePath(List<LatLng> points) async {
    if (points.length < 2) return const [];

    final merged = <LatLng>[];
    const int maxChunkSize = 100;

    for (int start = 0; start < points.length; start += (maxChunkSize - 1)) {
      final endExclusive = math.min(start + maxChunkSize, points.length);
      final chunk = points.sublist(start, endExclusive);

      if (chunk.length < 2) break;

      final snappedChunk = await _snapChunk(chunk);
      final chosen = snappedChunk.length >= 2 ? snappedChunk : chunk;

      if (merged.isEmpty) {
        merged.addAll(chosen);
      } else {
        if (_samePoint(merged.last, chosen.first)) {
          merged.addAll(chosen.skip(1));
        } else {
          merged.addAll(chosen);
        }
      }

      if (endExclusive == points.length) break;
    }

    return merged;
  }

  Future<List<LatLng>> _snapChunk(List<LatLng> chunk) async {
    try {
      final coords = chunk.map((p) => '${p.longitude},${p.latitude}').join(';');

      final timestamps = List<int>.generate(
        chunk.length,
            (i) => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + i,
      ).join(';');

      final uri = Uri.parse(
        '$_osrmBaseUrl/match/v1/driving/$coords'
            '?geometries=geojson&overview=full&steps=false&annotations=false'
            '&tidy=true&timestamps=$timestamps',
      );

      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];

      final matchings = decoded['matchings'];
      if (matchings is! List || matchings.isEmpty) return const [];

      final first = matchings.first;
      if (first is! Map<String, dynamic>) return const [];

      final geometry = first['geometry'];
      return _parseGeoJsonLineString(geometry);
    } catch (_) {
      return const [];
    }
  }

  List<LatLng> _parseGeoJsonLineString(Object? geometry) {
    if (geometry is! Map<String, dynamic>) return const [];

    final type = geometry['type']?.toString();
    if (type != 'LineString') return const [];

    final coordinates = geometry['coordinates'];
    if (coordinates is! List) return const [];

    final points = <LatLng>[];
    for (final item in coordinates) {
      if (item is List && item.length >= 2) {
        final lng = _toDouble(item[0]);
        final lat = _toDouble(item[1]);

        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }

    return points;
  }

  bool _samePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  double _haversineMeters(LatLng a, LatLng b) {
    const double earthRadius = 6371000;

    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.latitude)) *
            math.cos(_degToRad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}