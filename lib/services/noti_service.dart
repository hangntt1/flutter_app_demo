import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  /// Lấy admin duy nhất
  static Future<Map<String, String>> getAdminInfo() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Không tìm thấy admin');
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    return {
      'id': doc.id,
      'name': data['name'],
    };
  }

  /// Tạo notification
  static Future<void> createNotification(Notify noti) async {
    await _db
        .collection('notifications')
        .doc(noti.id)
        .set(noti.toMap());
  }

  Future<List<Notify>> fetchNotifies({
    required String id,
  }) async {
    Query query = _db.collection('notifications')
      .where('receiverId', isEqualTo: id);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return Notify.fromDoc(doc);
    }).toList();
  }

  Future<void> markAsRead(String notiId) async {
    await _db.collection('notifications').doc(notiId).update({
      'isRead': true,
    });
  }

  Future<void> toggleImportant(String notiId, bool current) async {
    await _db.collection('notifications').doc(notiId).update({
      'isImportant': !current,
    });
  }

}
