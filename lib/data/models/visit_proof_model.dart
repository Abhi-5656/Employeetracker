import 'dart:convert';

class VisitProof {
  final int id;
  final String clientName;
  final String comment;
  final String proofImageUrl;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final String? employeeName; // Useful for managers viewing team data

  VisitProof({
    required this.id,
    required this.clientName,
    required this.comment,
    required this.proofImageUrl,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    this.employeeName,
  });

  factory VisitProof.fromJson(Map<String, dynamic> json) {
    return VisitProof(
      id: json['id'] ?? 0,
      clientName: json['clientName'] ?? '',
      comment: json['comment'] ?? '',
      proofImageUrl: json['proofImageUrl'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'])
          : DateTime.now(),
      employeeName: json['employeeName'],
    );
  }
}