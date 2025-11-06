class Routes {
  // Login
  static String get login   => 'api/auth/login';
  static String get refresh => 'api/auth/refresh';
  static String get me      => 'api/auth/me';

  // 🎯 NEW ROUTES FOR NOTIFICATIONS
  /// GET /api/notifications/targeted/user/{userId}/all?page=0&size=20
  static String notificationsAll(String userId, {int page = 0, int size = 20})
  => '/api/notifications/targeted/user/$userId/all?page=$page&size=$size';

  /// GET /api/notifications/targeted/user/{userId}/unread/count
  static String notificationsUnreadCount(String userId)
  => '/api/notifications/targeted/user/$userId/unread/count';

  static String mySummary(String employeeId) => '/api/dashboard/my-summary/$employeeId';
  static String employeeById(String employeeId) => '/api/employees/$employeeId';
  // static String employeeByEmail(String email) => '/api/employees/$email';
  static String employeeByEmail(String email) => '/api/employees?email=$email';


  static String dashboardAttendance(String employeeId) => '/api/dashboard/attendance/$employeeId';
  static String dashboardSummary(String employeeId) => '/api/dashboard/my-summary/$employeeId';
  static String employeeShiftRoster(String employeeId, String startYmd, String endYmd)
  => '/api/employee/shifts/employee-shift-roster/$employeeId?startDate=$startYmd&endDate=$endYmd';


  // 🎯 NEW ROUTE: Attendance Timesheet Data
  static String attendanceTimesheetData(String employeeId) => '/api/dashboard/attendance-timesheet/$employeeId';
  // ADD THIS:
  static String leaveAndHolidays(String employeeId)
  => '/api/dashboard/leave-and-holidays/$employeeId';

  // ✅ ADD THIS
  static String get applyLeave => '/api/leave-requests/apply';

  static String timesheetsRange(String employeeId, String startYmd, String endYmd) =>
      '/api/wfm/timesheets/employee/$employeeId/range?startDate=$startYmd&endDate=$endYmd';

  // ⭐ NEW LOCATION TRACKING ROUTE
  static String get trackLocation => '/api/wfm/location/track';

  // --- 👇 ADD THIS NEW ROUTE ---

  /// GET /api/assignments/employee-groups/scoped-employees/me
  /// Fetches the list of employees who report to the current user.
  static String get getReportees => '/api/assignments/employee-groups/scoped-employees/me';

  // --- 👇 ADD THIS NEW ROUTE ---

  /// GET /api/tracking/query/path/latest/{employeeId}
  static String getLatestReporteePath(String employeeId) =>
      '/api/tracking/query/path/latest/$employeeId';

  // 🎯 ADD THIS NEW ROUTE
  /// GET /api/tracking/query/path/for-date/{employeeId}?date=YYYY-MM-DD
  static String getReporteePathForDate(String employeeId, String ymd) =>
      '/api/tracking/query/path/for-date/$employeeId?date=$ymd';

  /// GET /api/employee/shifts/employee-shift-roster/{employeeId}?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
  // static String employeeShiftRoster(
  //     String employeeId, {
  //       required String startDate,
  //       required String endDate,
  //     }) =>
  //     '/api/employee/shifts/employee-shift-roster/$employeeId'
  //         '?startDate=$startDate&endDate=$endDate';

// If your “assigned shift” uses another endpoint, add it here later.
// Example shape:
// static String assignedShiftForDate(String empId, String ymd) =>
//     '/api/shifts/assigned/$empId?date=$ymd';
}
