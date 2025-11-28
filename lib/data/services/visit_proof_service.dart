import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../app/config/environment.dart'; // Import your Environment config
import '../models/visit_proof_model.dart';
import 'auth_service.dart';
import 'tenant_service.dart'; // 1. Import TenantService
import 'routes.dart';

class VisitProofService {
  VisitProofService._();
  static final VisitProofService instance = VisitProofService._();

  /// Retrieve the dynamic Base URL from your App Config (Dev/Prod)
  String get _baseUrl => Environment().config.baseUrl;

  /// Helper to get the full display URL for an image
  String getFullImageUrl(String relativePath) {
    // If the backend returns a full URL (e.g., S3), return it directly
    if (relativePath.startsWith('http')) return relativePath;

    // Otherwise, append it to the backend's upload path
    final cleanPath = relativePath.replaceAll(RegExp(r'^/'), '');

    // Construct: http://10.0.0.105:8080/uploads/visits/image.jpg
    // Note: Images served via static resources usually don't need tenantId
    // unless your backend filter specifically blocks /uploads without it.
    return '$_baseUrl/uploads/$cleanPath';
  }

  /// 1. Compress and Submit Proof (POST Multipart)
  Future<void> submitProof({
    required File imageFile,
    required String clientName,
    required String comment,
    required double lat,
    required double lng,
  }) async {
    final token = AuthService.instance.token;
    final tenantId = TenantService.instance.tenantId; // 2. Get Tenant ID

    if (token == null) throw Exception("Unauthorized: No token found");
    if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");

    // --- Step A: Client-Side Compression ---
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

    // --- Step B: Multipart Upload ---
    // 3. Inject Tenant ID into URL: baseUrl + /tenantId + /api/visits
    final uri = Uri.parse('$_baseUrl/$tenantId${Routes.submitVisitProof}');

    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Text Fields
    request.fields['clientName'] = clientName;
    request.fields['comment'] = comment;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();

    // File Field
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      compressedFile.path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  /// 2. Fetch Team Proofs (GET JSON)
  Future<List<VisitProof>> getTeamProofs() async {
    final token = AuthService.instance.token;
    final tenantId = TenantService.instance.tenantId; // 2. Get Tenant ID

    if (token == null) throw Exception("Unauthorized");
    if (tenantId == null) throw Exception("System Error: Tenant ID is missing.");

    // 3. Inject Tenant ID into URL
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
      throw Exception('Failed to load team visits: ${response.statusCode}');
    }
  }
}