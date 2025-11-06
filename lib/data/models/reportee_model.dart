// lib/data/models/reportee_model.dart
class ReporteeModel {
  final String employeeId;
  final String fullName;
  final String department;
  final String jobTitle;

  ReporteeModel({
    required this.employeeId,
    required this.fullName,
    required this.department,
    required this.jobTitle,
  });

  // Factory to parse the JSON response you provided
  factory ReporteeModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely navigate the nested JSON
    T? safeGet<T>(Map<String, dynamic> map, List<String> keys) {
      dynamic val = map;
      for (var key in keys) {
        if (val is Map<String, dynamic> && val.containsKey(key)) {
          val = val[key];
        } else {
          return null;
        }
      }
      return val as T?;
    }

    return ReporteeModel(
      employeeId: json['employeeId'] as String? ?? 'N/A',
      fullName: safeGet<String>(json, ['personalInfo', 'fullName']) ?? 'N/A',
      department: safeGet<String>(json, ['organizationalInfo', 'jobContextDetails', 'departmentName']) ?? 'N/A',
      jobTitle: safeGet<String>(json, ['organizationalInfo', 'jobContextDetails', 'jobGradeBand']) ?? 'N/A',
    );
  }
}