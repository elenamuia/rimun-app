import '../api/api_client.dart';
import '../api/models.dart' as api;

class RimunApiService {
  RimunApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<bool> isServerHealthy() => _client.health();
  Future<List<api.Forum>> getForums() => _client.getForums();
  Future<List<api.Committee>> getCommittees({int? limit, int? offset}) =>
      _client.getCommittees(limit: limit, offset: offset);
  Future<List<api.Delegate>> getDelegates({
    int? sessionId,
    int? delegationId,
    int? committeeId,
    String? countryCode,
    int? schoolId,
    String? statusApplication,
    String? statusHousing,
    bool? isAmbassador,
    DateTime? updatedSince,
    int? limit,
    int? offset,
  }) => _client.getDelegates(
    sessionId: sessionId,
    delegationId: delegationId,
    committeeId: committeeId,
    countryCode: countryCode,
    schoolId: schoolId,
    statusApplication: statusApplication,
    statusHousing: statusHousing,
    isAmbassador: isAmbassador,
    updatedSince: updatedSince,
    limit: limit,
    offset: offset,
  );

  Future<api.Delegate?> getDelegateById(String personId) =>
      _client.getDelegateById(personId);
}
