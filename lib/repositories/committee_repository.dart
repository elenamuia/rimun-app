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
