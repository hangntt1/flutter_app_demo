
import 'package:cloud_firestore/cloud_firestore.dart';

import '../enum/noti_status.dart';

class Notify {
  final String id;

  final String title;

  final NotiStatus status;
  final bool isRead;
  final bool isImportant;

  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName; // adminId

  final String formId;

  final DateTime createdAt;

  Notify({
    required this.id,
    required this.title,
    required this.status,
    required this.isRead,
    required this.isImportant,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.formId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'status': status.name,
      'isRead': isRead,
      'isImportant': isImportant,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'formId': formId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  factory Notify.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    return Notify(
      id: doc.id,
      title: map['title'],
      status: NotiStatus.values.byName(map['status']),
      isRead: map['isRead'],
      isImportant: map['isImportant'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      receiverId: map['receiverId'],
      receiverName: map['receiverName'],
      formId: map['formId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
