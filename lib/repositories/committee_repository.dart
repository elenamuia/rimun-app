import '../api/api_client.dart';
import '../api/models.dart' as api;
import '../api/models.dart' show ProfileData;
import '../services/committee_service.dart';

class CommitteeWithFloor {
  final api.Committee committee;
  final FloorLevel? floor;

  CommitteeWithFloor(this.committee, this.floor);
}

class CommitteeRepository {
  CommitteeRepository({
    required ApiClient apiClient,
    CommitteeService? committeeService,
  }) : _api = apiClient,
       _csv = committeeService ?? CommitteeService();

  final ApiClient _api;
  final CommitteeService _csv;

  /// Fetch committees from API and enrich with floor info from CSV assets.
  Future<List<CommitteeWithFloor>> fetchCommitteesWithFloor({
    int? limit,
    int? offset,
  }) async {
    final committees = await _api.getCommittees(limit: limit, offset: offset);
    final csv = await _csv.loadCommittees();
    final floorMap = csv.committeeToFloor;

    return committees
        .map((c) => CommitteeWithFloor(c, floorMap[c.name]))
        .toList();
  }
}

class ProfileRepository {
  final ApiClient api;
  ProfileRepository(this.api);

  Future<ProfileData> load() async {
    final me = await api.me();
    final active = await api.getActiveSession();

    final personId = (me['person_id'] ?? 0) as int;
    final sessionId = (active['session_id'] ?? active['id'] ?? 0) as int;
    final j = await api.getPersonProfile(
      personId: personId,
      sessionId: sessionId,
    );

    String s(dynamic v) => (v ?? '').toString();
    final group = s(j['confirmed_group_name']);

    return ProfileData(
      fullName: s(j['full_name']),
      email: s(me['email']),
      group: group,
      role: s(j['confirmed_role_name']),
      school: s(j['school_name']),
      country: s(j['country_name']),
      delegation: s(j['delegation_name']),
      committee: s(j['committee_name']),
      picturePath: s(j['picture_path']),
      isSecretariat: group.toLowerCase() == 'secretariat',
    );
  }
}
