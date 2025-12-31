import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': 'user', // mặc định
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _db.collection('users').doc(cred.user!.uid).get();

      if (!doc.exists) return '';

      return doc.data()?['role'] ?? '';
    } catch (e) {
      print('Login error: $e');
      return '';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> getLeaveInfo(String id) async {

    final doc = await _db.collection('users').doc(id).get();
    final data = doc.data() ?? {};

    return {
      'userName': data['name'] ?? "",
      'used': (data['totalLeaveUsed'] ?? 0) as int,
      'remaining': (data['remainingAnnualLeave'] ?? 12) as int,
    };
  }

  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    return doc.data()?['role'] == 'admin';
  }

}
