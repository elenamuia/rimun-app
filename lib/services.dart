// lib/services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Student> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final doc = await _db.collection('students').doc(uid).get();
    if (!doc.exists) {
      // fallback minimale
      return Student(id: uid,
        name: cred.user!.email ?? 'Studente',
        surname: '',
        email: email,
        school: '',
        country: '',
        );
    }

    final data = doc.data()!;
    return Student.fromMap(doc.id, {
      'name': data['name'],
      'email': data['email'],
    });
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();
}

class ScheduleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<EventItem>> getTodayEventsForStudent(String studentId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        // se vuoi filtrare per delegazione/comitato:
        // .where('students', arrayContains: studentId)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return EventItem(
        id: doc.id,
        title: data['title'] ?? '',
        location: data['location'] ?? '',
        startTime: (data['startTime'] as Timestamp).toDate(),
        endTime: (data['endTime'] as Timestamp).toDate(),
      );
    }).toList();
  }
}

class NoticeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Notice>> listenNotices() {
    return _db
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return Notice(
                id: doc.id,
                title: data['title'] ?? '',
                body: data['body'] ?? '',
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            }).toList());
  }
}
