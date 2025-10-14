class TimesheetEntry {
  final String date;
  final String projectName;
  final String taskDescription;
  final double hoursLogged;
  final String status;

  TimesheetEntry({
    required this.date,
    required this.projectName,
    required this.taskDescription,
    required this.hoursLogged,
    required this.status,
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    return TimesheetEntry(
      date: json['date'] as String,
      projectName: json['projectName'] as String,
      taskDescription: json['taskDescription'] as String,
      hoursLogged: (json['hoursLogged'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}