// lib/models.dart
class Student {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String school;
  final String country;
  final String committee;

  Student({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.school,
    required this.country,
    this.committee = 'TBD',
  });

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: data['name'] ?? 'Studente',
      surname: data['surname'] ?? '',
      email: data['email'] ?? '',
      school: data['school'] ?? '',
      country: data['country'] ?? '',
      committee: data['committee'] ?? 'TBD',
    );
  }
}

class EventItem {
  final String id;
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;

  EventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  factory EventItem.fromMap(String id, Map<String, dynamic> data) {
    return EventItem(
      id: id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      startTime: (data['startTime'] as DateTime?) ?? DateTime.now(),
      endTime: (data['endTime'] as DateTime?) ?? DateTime.now(),
    );
  }
}

class Notice {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory Notice.fromMap(String id, Map<String, dynamic> data) {
    return Notice(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as DateTime?) ?? DateTime.now(),
    );
  }
}