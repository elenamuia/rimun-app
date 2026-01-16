class Student {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String school;
  final String country;
  final String delegation;
  final String committee;

  /// 🔹 Ruolo logico (true = Secretariat, false = Delegate)
  final bool isSecretariat;

  Student({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.school,
    required this.country,
    this.delegation = '',
    this.committee = '',
    this.isSecretariat = false, // default: Delegate
  });

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      email: data['email'] ?? '',
      school: data['school'] ?? '',
      country: data['country'] ?? '',
      delegation: data['delegation'] ?? '',
      committee: data['committee'] ?? '',
      isSecretariat: data['isSecretariat'] ?? false,
    );
  }

  /// 🔹 Role testuale per UI
  String get role => isSecretariat ? 'Secretariat' : 'Delegate';
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
  final List<String> recipients;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.recipients = const [],
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