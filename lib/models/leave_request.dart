import 'package:cloud_firestore/cloud_firestore.dart';

import '../enum/status.dart';

class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final Status status;
  final DateTime createdAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'reason': reason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  factory LeaveRequest.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return LeaveRequest(
      id: doc.id,
      userId: map['userId'],
      userName: map['userName'],
      reason: map['reason'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalDays: (map['totalDays'] as num).toInt(),
      status: Status.values.byName(map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
