import '../services/rimun_api_service.dart';
import '../services/committee_service.dart';
import '../api/models.dart' as api;

class CommitteeWithFloor {
  final api.Committee committee;
  final FloorLevel? floor;

  CommitteeWithFloor(this.committee, this.floor);
}

class CommitteeRepository {
  CommitteeRepository({
    RimunApiService? apiService,
    CommitteeService? committeeService,
  }) : _api = apiService ?? RimunApiService(),
       _csv = committeeService ?? CommitteeService();

  final RimunApiService _api;
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

    final j = await api.getPersonProfile(personId: me.personId, sessionId: active.sessionId);

    String s(dynamic v) => (v ?? '').toString();

    return ProfileData(
      personId: me.personId,
      fullName: s(j['full_name']),
      email: me.email,
      group: s(j['confirmed_group_name']),  // e.g. "delegate", "secretariat"
      role: s(j['confirmed_role_name']),    // e.g. "Delegate", "Secretary General"
      school: s(j['school_name']),
      country: s(j['country_name']),
      delegation: s(j['delegation_name']),
      committee: s(j['committee_name']),
      forumAcronym: s(j['forum_acronym']),
      isAmbassador: (j['is_ambassador'] as bool?) ?? false,
    );
  }
}