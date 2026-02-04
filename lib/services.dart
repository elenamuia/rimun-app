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
      return Student(
        id: uid,
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
  FirebaseFirestore? _db;

  ScheduleService() {
    try {
      _db = FirebaseFirestore.instance;
    } catch (_) {
      _db = null;
    }
  }

  Future<List<EventItem>> getTodayEventsForStudent(String studentId) async {
    if (_db == null) {
      // In tests or unsupported envs, return empty list gracefully
      return [];
    }
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db!
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
  FirebaseFirestore? _db;

  NoticeService() {
    try {
      _db = FirebaseFirestore.instance;
    } catch (_) {
      _db = null;
    }
  }

  String _normalizeType(dynamic raw) {
    final t = (raw ?? 'ordinary').toString().trim().toLowerCase();
    if (t == 'alert' || t == 'info' || t == 'ordinary') return t;
    return 'ordinary';
  }

  Stream<List<Notice>> listenNotices() {
    if (_db == null) {
      // In tests or unsupported envs, provide an empty stream
      return Stream.value(<Notice>[]);
    }
    return _db!
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return Notice(
              id: doc.id,
              title: data['title'] ?? '',
              body: data['body'] ?? '',
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              recipients:
                  (data['recipients'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
              // ✅ NEW: type
              type: _normalizeType(data['type']),
            );
          }).toList(),
        );
  }

  /// ✅ stream filtrato per utente
  Stream<List<Notice>> listenNoticesForStudent(Student student) {
    return listenNotices().map((all) {
      if (student.isSecretariat) return all;
      final myGroup = student.committee.trim();
      return all.where((n) {
        if (n.recipients.isEmpty) return true; // broadcast a tutti
        if (myGroup.isEmpty) return false;
        return n.recipients.contains(myGroup);
      }).toList();
    });
  }

  Future<void> createNotice({
    required Student author,
    required String title,
    required String body,
    required List<String> recipients,
    required String type, // ✅ NEW
  }) async {
    if (_db == null) {
      throw StateError('Firestore unavailable');
    }
    await _db!.collection('notices').add({
      'title': title,
      'body': body,
      'recipients': recipients,
      'type': _normalizeType(type), // ✅ NEW
      'createdAt': Timestamp.now(),
      'authorId': author.id,
      'authorName': '${author.name} ${author.surname}'.trim(),
      'authorEmail': author.email,
    });
  }

  /// ✅ delete
  Future<void> deleteNotice(String noticeId) async {
    if (_db == null) {
      throw StateError('Firestore unavailable');
    }
    await _db!.collection('notices').doc(noticeId).delete();
  }

  Future<void> updateNotice({
    required String noticeId,
    required String title,
    required String body,
    required List<String> recipients,
    required String type, // ✅ NEW
  }) async {
    if (_db == null) {
      throw StateError('Firestore unavailable');
    }
    await _db!.collection('notices').doc(noticeId).update({
      'title': title,
      'body': body,
      'recipients': recipients,
      'type': _normalizeType(type), // ✅ NEW
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<Notice>> listenNewsForStudent(Student student) {
    // Solo ordinary → schermata News
    return listenNoticesForStudent(
      student,
    ).map((all) => all.where((n) => n.type == 'ordinary').toList());
  }

  Stream<List<Notice>> listenHomeNoticesForStudent(Student student) {
    // Solo alert/info → schermata Home (Today)
    return listenNoticesForStudent(student).map(
      (all) => all.where((n) => n.type == 'alert' || n.type == 'info').toList(),
    );
  }
}
