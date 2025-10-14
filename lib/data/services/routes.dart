class Routes {
  // Login
  static String get login   => 'api/auth/login';
  static String get refresh => 'api/auth/refresh';
  static String get me      => 'api/auth/me';

  static String mySummary(String employeeId) => '/api/dashboard/my-summary/$employeeId';
  static String employeeById(String employeeId) => '/api/employees/$employeeId';
  // static String employeeByEmail(String email) => '/api/employees/$email';
  static String employeeByEmail(String email) => '/api/employees?email=$email';


  static String dashboardAttendance(String employeeId) => '/api/dashboard/attendance/$employeeId';
  static String dashboardSummary(String employeeId) => '/api/dashboard/my-summary/$employeeId';
  static String employeeShiftRoster(String employeeId, String startYmd, String endYmd)
  => '/api/employee/shifts/employee-shift-roster/$employeeId?startDate=$startYmd&endDate=$endYmd';

  // ADD THIS:
  static String leaveAndHolidays(String employeeId)
  => '/api/dashboard/leave-and-holidays/$employeeId';

  // ✅ ADD THIS
  static String get applyLeave => '/api/leave-requests/apply';
// If your “assigned shift” uses another endpoint, add it here later.
// Example shape:
// static String assignedShiftForDate(String empId, String ymd) =>
//     '/api/shifts/assigned/$empId?date=$ymd';
}
