class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String busNumber;
  final DateTime timestamp;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.busNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'busNumber': busNumber,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      busNumber: map['busNumber'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
