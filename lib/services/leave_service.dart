import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../enum/noti_status.dart';
import '../enum/status.dart';
import '../models/leave_request.dart';

class LeaveService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static Future<void> addLeaveRequest(LeaveRequest leave) async {
    final doc = FirebaseFirestore.instance
        .collection('leaveRequests')
        .doc(leave.id); // dùng id có sẵn

    await doc.set(leave.toMap());
  }

  Future<List<LeaveRequest>> fetchLeaveRequests({
    required bool isAdmin,
  }) async {
    Query query = _db.collection('leaveRequests');

    if (!isAdmin) {
      query = query.where(
        'userId',
        isEqualTo: _auth.currentUser!.uid,
      );
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return LeaveRequest.fromDoc(doc);
    }).toList();
  }

  ///Lấy chi tiết đơn
  Future<LeaveRequest> getLeaveDetail(String leaveId) async {
    final doc =
        await _db.collection('leaveRequests').doc(leaveId).get();

    if (!doc.exists) {
      throw Exception('Không tìm thấy đơn xin nghỉ');
    }

    return LeaveRequest.fromDoc(doc);
  }

  ///Cập nhật đơn
  Future<void> updateLeave({
    required String leaveId,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
  }) async {
    await _db.collection('leaveRequests').doc(leaveId).update({
      'reason': reason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      'status': Status.pending.name, // reset lại chờ duyệt
    });
  }

  //Hủy đơn 
  Future<void> cancelLeave(String leaveId) async {
    await _db.collection('leaveRequests').doc(leaveId).update({
      'status': Status.cancel.name,
    });
  }

  //duyêt đơn 
  Future<void> approveLeave(String leaveId, String userId, int totalDays) async {
    await _db.collection('leaveRequests').doc(leaveId).update({
      'status': Status.approved.name,
    });

    final notiSnapshot = await _db
        .collection('notifications')
        .where('formId', isEqualTo: leaveId)
        .get();

    for (final doc in notiSnapshot.docs) {
      await doc.reference.update({
        'status': NotiStatus.approved.name,
      });
    }

    final doc = await _db.collection('users').doc(userId).get();
    final data = doc.data() ?? {};

    final int totalLeaveUsed = (data['totalLeaveUsed'] ?? 0) as int;
    final int remainingAnnualLeave = (data['remainingAnnualLeave'] ?? 12) as int;

    final int newTotalLeaveUsed = totalLeaveUsed + totalDays;
    int newRemainingAnnualLeave = remainingAnnualLeave - totalDays;
    if (newRemainingAnnualLeave < 0) {
      newRemainingAnnualLeave = 0;
    }

    await _db.collection('users').doc(userId).update({
      'totalLeaveUsed': newTotalLeaveUsed,
      'remainingAnnualLeave': newRemainingAnnualLeave,
    });
  }

  //Từ chối 
  Future<void> rejectLeave(String leaveId) async {
    await _db.collection('leaveRequests').doc(leaveId).update({
      'status': Status.rejected.name,
    });

    final notiSnapshot = await _db
        .collection('notifications')
        .where('formId', isEqualTo: leaveId)
        .get();

    for (final doc in notiSnapshot.docs) {
      await doc.reference.update({
        'status': NotiStatus.rejected.name,
      });
    }
  }
}
