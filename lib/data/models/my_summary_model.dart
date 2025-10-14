class MySummary {
  final String? leaveBalance;   // "8.5 / 15"
  final int? pendingRequests;   // 2
  final String? daysThisWeek;   // "3.0 / 5"
  final String? upcomingShift;  // "09:00"

  MySummary({this.leaveBalance, this.pendingRequests, this.daysThisWeek, this.upcomingShift});

  factory MySummary.fromJson(Map<String, dynamic> j) => MySummary(
    leaveBalance: j['leaveBalance'] as String?,
    pendingRequests: j['pendingRequests'] is num
        ? (j['pendingRequests'] as num).toInt()
        : j['pendingRequests'] as int?,
    daysThisWeek: j['daysThisWeek'] as String?,
    upcomingShift: j['upcomingShift'] as String?,
  );
}
