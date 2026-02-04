class Forum {
  final int id;
  final String acronym;
  final String name;
  final String description;
  final String? imagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Forum({
    required this.id,
    required this.acronym,
    required this.name,
    required this.description,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory Forum.fromJson(Map<String, dynamic> j) => Forum(
    id: (j['id'] ?? 0) as int,
    acronym: (j['acronym'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    imagePath: j['image_path']?.toString(),
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'])
        : null,
    updatedAt: j['updated_at'] != null
        ? DateTime.tryParse(j['updated_at'])
        : null,
  );
}

class Committee {
  final int id;
  final String name;
  final String? forumAcronym;

  Committee({required this.id, required this.name, this.forumAcronym});

  factory Committee.fromJson(Map<String, dynamic> j) => Committee(
    id: (j['id'] ?? 0) as int,
    name: (j['name'] ?? '').toString(),
    forumAcronym: j['forum_acronym']?.toString(),
  );
}

class Delegate {
  final int personId;
  final String fullName;
  final String? name;
  final String? surname;
  final String? picturePath;
  final String? phoneNumber;
  final String? allergies;
  final String? countryCode;
  final String? countryName;
  final int? sessionId;
  final String? sessionEdition;
  final int? committeeId;
  final String? committeeName;
  final String? forumAcronym;
  final int? delegationId;
  final String? delegationName;
  final int? schoolId;
  final String? schoolName;
  final String? statusApplication;
  final String? statusHousing;
  final bool? isAmbassador;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  Delegate({
    required this.personId,
    required this.fullName,
    this.name,
    this.surname,
    this.picturePath,
    this.phoneNumber,
    this.allergies,
    this.countryCode,
    this.countryName,
    this.sessionId,
    this.sessionEdition,
    this.committeeId,
    this.committeeName,
    this.forumAcronym,
    this.delegationId,
    this.delegationName,
    this.schoolId,
    this.schoolName,
    this.statusApplication,
    this.statusHousing,
    this.isAmbassador,
    this.updatedAt,
    this.createdAt,
  });

  factory Delegate.fromJson(Map<String, dynamic> j) => Delegate(
    personId: (j['person_id'] ?? 0) as int,
    fullName: (j['full_name'] ?? '').toString(),
    name: j['name']?.toString(),
    surname: j['surname']?.toString(),
    picturePath: j['picture_path']?.toString(),
    phoneNumber: j['phone_number']?.toString(),
    allergies: j['allergies']?.toString(),
    countryCode: j['country_code']?.toString(),
    countryName: j['country_name']?.toString(),
    sessionId: j['session_id'] as int?,
    sessionEdition: j['session_edition']?.toString(),
    committeeId: j['committee_id'] as int?,
    committeeName: j['committee_name']?.toString(),
    forumAcronym: j['forum_acronym']?.toString(),
    delegationId: j['delegation_id'] as int?,
    delegationName: j['delegation_name']?.toString(),
    schoolId: j['school_id'] as int?,
    schoolName: j['school_name']?.toString(),
    statusApplication: j['status_application']?.toString(),
    statusHousing: j['status_housing']?.toString(),
    isAmbassador: j['is_ambassador'] as bool?,
    updatedAt: j['updated_at'] != null
        ? DateTime.tryParse(j['updated_at'])
        : null,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'])
        : null,
  );
}
