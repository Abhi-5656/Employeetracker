class DashboardSummary {
  final String employeeName;
  final String todayDate;
  final String? checkInTime; // Nullable if the user hasn't checked in
  final String? checkOutTime; // Nullable
  final int pendingTasks;
  final double leaveBalance;

  DashboardSummary({
    required this.employeeName,
    required this.todayDate,
    this.checkInTime,
    this.checkOutTime,
    required this.pendingTasks,
    required this.leaveBalance,
  });

  // Factory constructor to create a DashboardSummary from JSON
  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      employeeName: json['employeeName'] as String,
      todayDate: json['todayDate'] as String,
      checkInTime: json['checkInTime'] as String?,
      checkOutTime: json['checkOutTime'] as String?,
      pendingTasks: json['pendingTasks'] as int,
      leaveBalance: (json['leaveBalance'] as num).toDouble(),
    );
  }
}