class WorkLocationDto {
  final String? name;
  WorkLocationDto({this.name});
  factory WorkLocationDto.fromJson(Map<String, dynamic> j)
  => WorkLocationDto(name: j['name'] as String?);
}

class EmployeeProfile {
  final String? employeeId;
  final String? fullName;
  final WorkLocationDto? workLocation;

  EmployeeProfile({this.employeeId, this.fullName, this.workLocation});

  factory EmployeeProfile.fromJson(Map<String, dynamic> j) => EmployeeProfile(
    employeeId: j['employeeId'] as String?,
    fullName: j['fullName'] as String?,
    workLocation: j['workLocation'] == null
        ? null
        : WorkLocationDto.fromJson(j['workLocation'] as Map<String, dynamic>),
  );
}
