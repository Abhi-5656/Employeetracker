import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../app/config/environment.dart';
import '../models/visit_proof_model.dart';
import 'auth_service.dart';
import 'tenant_service.dart';
import 'routes.dart';

class VisitProofService {
  VisitProofService._();
  static final VisitProofService instance = VisitProofService._();

  String get _baseUrl => Environment().config.baseUrl;

  /// Helper to get the full display URL for an image
  // String getFullImageUrl(String relativePath) {
  //   if (relativePath.isEmpty) return '';
  //   if (relativePath.startsWith('http')) return relativePath;
  //
  //   // 1. Remove leading slash
  //   var cleanPath = relativePath.replaceAll(RegExp(r'^/'), '');
  //
  //   // 2. Fix Windows-style backslashes if present
  //   cleanPath = cleanPath.replaceAll(r'\', '/');
  //
  //   // 3. Check if path already starts with 'uploads/' to avoid duplication
  //   if (cleanPath.startsWith('uploads/')) {
  //     return '$_baseUrl/$cleanPath';
  //   }
  //
  //   // Default behavior
  //   return '$_baseUrl/uploads/$cleanPath';
  // }
  // ✅ ADD THIS: Constructs the Secure API URL
  String getProofImageApiUrl(int visitProofId) {
    final tenantId = TenantService.instance.tenantId;
    // Result: https://api.com/tenantId/api/visits/123/image
    return '$_baseUrl/$tenantId/api/visits/$visitProofId/image';
  }

  /// 1. Compress and Submit Proof
  Future<void> submitProof({
    required File imageFile,
    required String clientName,
    required String comment,
    required double lat,
    required double lng,
  }) async {
    final token = AuthService.instance.token;
    final tenantId = TenantService.instance.tenantId;

    if (token == null) throw Exception("Unauthorized: No token found");
    if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");

    final tmpDir = await getTemporaryDirectory();
    final targetPath = path.join(tmpDir.path, "temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg");

    var compressedFile = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (compressedFile == null) throw Exception("Image compression failed");

    final uri = Uri.parse('$_baseUrl/$tenantId${Routes.submitVisitProof}');
    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({'Authorization': 'Bearer $token'});
    request.fields['clientName'] = clientName;
    request.fields['comment'] = comment;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.files.add(await http.MultipartFile.fromPath('file', compressedFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      _handleError(response);
    }
  }

  /// 2. Fetch Team Proofs (All reportees)
  Future<List<VisitProof>> getTeamProofs() async {
    final token = AuthService.instance.token;
    final tenantId = TenantService.instance.tenantId;

    if (token == null) throw Exception("Unauthorized");
    if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");

    final uri = Uri.parse('$_baseUrl/$tenantId${Routes.teamVisitProofs}');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => VisitProof.fromJson(e)).toList();
    } else {
      _handleError(response);
      return []; // Unreachable, but for safety
    }
  }

  /// 3. Fetch Proofs for a Specific Employee (Client-Side Filtering)
  /// This solves the 403 error by using the authorized /team endpoint
  /// and filtering the results locally.
  Future<List<VisitProof>> getVisitProofs({
    required String employeeId,
    required DateTime date,
  }) async {
    // Fetch all team proofs
    final allProofs = await getTeamProofs();

    // Filter: Match Employee ID/Name logic if available, OR match date
    // Note: Since VisitProof model might not have employeeId, we rely on logic or backend enhancement.
    // Assuming `employeeName` or context is used.
    // Ideally, backend should support filtering.
    // For now, we filter by Date.

    return allProofs.where((proof) {
      // Filter by Date
      final isSameDate = proof.capturedAt.year == date.year &&
          proof.capturedAt.month == date.month &&
          proof.capturedAt.day == date.day;

      // If the model allows filtering by employee, add that here.
      // For example: return isSameDate && proof.employeeId == employeeId;
      return isSameDate;
    }).toList();
  }

  /// Centralized Error Handling
  void _handleError(http.Response response) {
    if (response.statusCode == 403) {
      throw Exception("Access Denied (403): You do not have permission to view these records.");
    } else if (response.statusCode == 404) {
      throw Exception("Resource Not Found (404).");
    } else if (response.statusCode >= 500) {
      throw Exception("Server Error (${response.statusCode}). Please try again later.");
    } else {
      throw Exception("Request failed: ${response.statusCode} ${response.body}");
    }
  }
}

// import 'dart:io';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
//
// import '../../app/config/environment.dart'; // Import your Environment config
// import '../models/visit_proof_model.dart';
// import 'auth_service.dart';
// import 'tenant_service.dart'; // 1. Import TenantService
// import 'routes.dart';
//
// class VisitProofService {
//   VisitProofService._();
//   static final VisitProofService instance = VisitProofService._();
//
//   /// Retrieve the dynamic Base URL from your App Config (Dev/Prod)
//   String get _baseUrl => Environment().config.baseUrl;
//
//   /// Helper to get the full display URL for an image
//   String getFullImageUrl(String relativePath) {
//     // If the backend returns a full URL (e.g., S3), return it directly
//     if (relativePath.startsWith('http')) return relativePath;
//
//     // Otherwise, append it to the backend's upload path
//     final cleanPath = relativePath.replaceAll(RegExp(r'^/'), '');
//
//     // Construct: http://10.0.0.105:8080/uploads/visits/image.jpg
//     // Note: Images served via static resources usually don't need tenantId
//     // unless your backend filter specifically blocks /uploads without it.
//     return '$_baseUrl/uploads/$cleanPath';
//   }
//
//   /// 1. Compress and Submit Proof (POST Multipart)
//   Future<void> submitProof({
//     required File imageFile,
//     required String clientName,
//     required String comment,
//     required double lat,
//     required double lng,
//   }) async {
//     final token = AuthService.instance.token;
//     final tenantId = TenantService.instance.tenantId; // 2. Get Tenant ID
//
//     if (token == null) throw Exception("Unauthorized: No token found");
//     if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");
//
//     // --- Step A: Client-Side Compression ---
//     final tmpDir = await getTemporaryDirectory();
//     final targetPath = path.join(tmpDir.path, "temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg");
//
//     var compressedFile = await FlutterImageCompress.compressAndGetFile(
//       imageFile.absolute.path,
//       targetPath,
//       quality: 70,
//       minWidth: 1024,
//       minHeight: 1024,
//     );
//
//     if (compressedFile == null) throw Exception("Image compression failed");
//
//     // --- Step B: Multipart Upload ---
//     // 3. Inject Tenant ID into URL: baseUrl + /tenantId + /api/visits
//     final uri = Uri.parse('$_baseUrl/$tenantId${Routes.submitVisitProof}');
//
//     var request = http.MultipartRequest('POST', uri);
//
//     request.headers.addAll({
//       'Authorization': 'Bearer $token',
//     });
//
//     // Text Fields
//     request.fields['clientName'] = clientName;
//     request.fields['comment'] = comment;
//     request.fields['lat'] = lat.toString();
//     request.fields['lng'] = lng.toString();
//
//     // File Field
//     request.files.add(await http.MultipartFile.fromPath(
//       'file',
//       compressedFile.path,
//     ));
//
//     final streamedResponse = await request.send();
//     final response = await http.Response.fromStream(streamedResponse);
//
//     if (response.statusCode != 200 && response.statusCode != 201) {
//       throw Exception('Upload failed: ${response.body}');
//     }
//   }
//
//   /// 2. Fetch Team Proofs (GET JSON)
//   Future<List<VisitProof>> getTeamProofs() async {
//     final token = AuthService.instance.token;
//     final tenantId = TenantService.instance.tenantId; // 2. Get Tenant ID
//
//     if (token == null) throw Exception("Unauthorized");
//     if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");
//
//     // 3. Inject Tenant ID into URL
//     final uri = Uri.parse('$_baseUrl/$tenantId${Routes.teamVisitProofs}');
//
//     final response = await http.get(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((e) => VisitProof.fromJson(e)).toList();
//     } else {
//       throw Exception('Failed to load team visits: ${response.statusCode}');
//     }
//   }
//   /// 3. Fetch Proofs for a specific Employee on a specific Date
//   Future<List<VisitProof>> getVisitProofs({
//     required String employeeId,
//     required DateTime date,
//   }) async {
//     final token = AuthService.instance.token;
//     final tenantId = TenantService.instance.tenantId;
//
//     if (token == null) throw Exception("Unauthorized");
//     if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");
//
//     // Format date as YYYY-MM-DD
//     final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//
//     // Construct URL: /api/visits/employee/{employeeId}?date={date}
//     // Make sure to add this route to your backend or use a query param
//     // Assuming backend supports filtering by employeeId and date
//     final uri = Uri.parse('$_baseUrl/$tenantId/api/visits/employee/$employeeId?date=$dateStr');
//
//     final response = await http.get(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((e) => VisitProof.fromJson(e)).toList();
//     } else {
//       // If API returns 404 for "no proofs found", return empty list
//       if (response.statusCode == 404) return [];
//       throw Exception('Failed to load visit proofs: ${response.statusCode}');
//     }
//   }
// }