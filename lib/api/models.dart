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
  final int sessionId;
  final int forumId;
  final int size;

  Committee({required this.id, required this.name, required this.sessionId, required this.forumId, required this.size});

  factory Committee.fromJson(Map<String, dynamic> j) => Committee(
    id: (j['id'] ?? 0) as int,
    name: (j['name'] ?? '').toString(),
    sessionId: (j['session_id'] ?? 0) as int,
    forumId: (j['forum_id'] ?? 0) as int,
    size: (j['size'] ?? 0) as int,
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


// In api/models.dart — add to your existing models file

class ProfileData {
  final String fullName;
  final String email;
  final String role;
  final String group;
  final String school;    // may be empty if not resolved
  final String country;
  final String delegation; // may be empty if not resolved
  final String committee;  // may be empty if not resolved
  final String picturePath;
  final bool isSecretariat;

  ProfileData({
    required this.fullName,
    required this.email,
    required this.role,
    required this.group,
    required this.school,
    required this.country,
    required this.delegation,
    required this.committee,
    required this.picturePath,
    required this.isSecretariat,
  });

  /// Build from the raw API JSON of GET /api/v2/profiles/me/person
  factory ProfileData.fromPersonProfileJson(Map<String, dynamic> json) {
    final app = json['application'] as Map<String, dynamic>?;

    final confirmedGroup = app?['confirmed_group_name'] as String? ?? '';
    final requestedGroup = app?['requested_group_name'] as String? ?? '';
    final group = confirmedGroup.isNotEmpty ? confirmedGroup : requestedGroup;

    final confirmedRole = app?['confirmed_role_name'] as String? ?? '';
    final requestedRole = app?['requested_role_name'] as String? ?? '';
    final role = confirmedRole.isNotEmpty ? confirmedRole : requestedRole;

    final country = json['country'] as Map<String, dynamic>?;
    final account = json['account'] as Map<String, dynamic>?;

    return ProfileData(
      fullName: json['full_name'] as String? ?? '',
      email: account?['email'] as String? ?? '',
      role: role,
      group: group,
      school: '',       // not available in PersonProfileDTO — see note below
      country: country?['name'] as String? ?? '',
      delegation: '',   // only delegation_id available — see note below
      committee: '',    // only committee_id available — see note below
      picturePath: json['picture_path'] as String? ?? '',
      isSecretariat: group.toLowerCase() == 'secretariat',
    );
  }
}




class PersonProfileDTO {
  final int id;
  final String name;
  final String surname;
  final String fullName;
  final List<PermissionResourceDTO> permissions;

  PersonProfileDTO({
    required this.id,
    required this.name,
    required this.surname,
    required this.fullName,
    required this.permissions,
  });

  factory PersonProfileDTO.fromJson(Map<String, dynamic> json) {
    return PersonProfileDTO(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
      fullName: json['full_name'] as String,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => PermissionResourceDTO.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Check if user has staff/admin permissions (can manage posts)
  bool get canManagePosts =>
      permissions.any((p) => p.resourceName == 'news' || p.resourceName == 'posts');
}

class PermissionResourceDTO {
  final String resourceName;

  PermissionResourceDTO({required this.resourceName});

  factory PermissionResourceDTO.fromJson(Map<String, dynamic> json) {
    return PermissionResourceDTO(
      resourceName: json['resource_name'] as String? ?? '',
    );
  }
}



class PostWithAuthor {
  final int id;
  final String title;
  final String body;
  final bool isForPersons;
  final bool isForSchools;
  final String createdAt;
  final String? updatedAt;
  final String? authorName;   // "Name Surname" from author object
  final String? authorRole;   // from author_role.name

  PostWithAuthor({
    required this.id,
    required this.title,
    required this.body,
    required this.isForPersons,
    required this.isForSchools,
    required this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorRole,
  });

  factory PostWithAuthor.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final role = json['author_role'] as Map<String, dynamic>?;
    return PostWithAuthor(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      isForPersons: json['is_for_persons'] ?? false,
      isForSchools: json['is_for_schools'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      authorName: author != null ? '${author['name']} ${author['surname']}' : null,
      authorRole: role?['name'],
    );
  }
}

class PersonRefInfo {
  final int id;
  final String name;
  final String surname;

  PersonRefInfo({required this.id, required this.name, required this.surname});

  factory PersonRefInfo.fromJson(Map<String, dynamic> json) {
    return PersonRefInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
    );
  }
}

class LoginResult {
  final String token;
  final int accountId;
  final String email;
  final bool isSchool;
  final bool isAdmin;
  final PersonProfileDTO? person;
  // final SchoolProfileDTO? school;  // add when needed

  LoginResult({
    required this.token,
    required this.accountId,
    required this.email,
    required this.isSchool,
    required this.isAdmin,
    this.person,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>;
    final personJson = json['person'] as Map<String, dynamic>?;
    return LoginResult(
      token: json['token'] as String,
      accountId: account['id'] as int,
      email: account['email'] as String,
      isSchool: account['is_school'] as bool? ?? false,
      isAdmin: account['is_admin'] as bool? ?? false,
      person: personJson != null ? PersonProfileDTO.fromJson(personJson) : null,
    );
  }
}

class TimelineEvent {
  final int id;
  final String type;
  final String name;
  final String date;
  final String? description;
  final String? picturePath;
  final String? documentPath;

  TimelineEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.date,
    this.description,
    this.picturePath,
    this.documentPath,
  });
  DateTime? get dateTime => DateTime.tryParse(date);

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      description: json['description'],
      picturePath: json['picture_path'],
      documentPath: json['document_path'],
    );
  }
}