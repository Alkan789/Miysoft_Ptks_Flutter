class AttendanceData {
  final String? checkInTime;
  final String? checkOutTime;

  AttendanceData({this.checkInTime, this.checkOutTime});

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;

  factory AttendanceData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AttendanceData(); // Boş veri
    }
    return AttendanceData(
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
    );
  }
}