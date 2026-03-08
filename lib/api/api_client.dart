import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    Future<String?> Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  final http.Client _client;
  final Future<String?> Function()? _tokenProvider;

  String get _baseUrl {
    // Guard dotenv access for tests where dotenv may be uninitialized.
    String? envUrl;
    try {
      if (dotenv.isInitialized) {
        envUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['VITE_RIMUN_API_URL'];
      }
    } catch (_) {
      envUrl = null;
    }
    return (envUrl != null && envUrl.isNotEmpty) ? envUrl : 'http://127.0.0.1:8081';
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';

    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ----------------
  // Existing endpoints
  // ----------------
  Future<bool> health() async {
    final res = await _client.get(_uri('/health'));
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['status'] == 'ok';
  }

  Future<List<Forum>> getForums() async {
    final res = await _client.get(_uri('/forums'), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch forums: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Forum.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Committee>> getCommittees({int? limit, int? offset}) async {
    final res = await _client.get(
      _uri('/committees', {
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      }),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch committees: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Committee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Delegate>> getDelegates({
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
  }) async {
    final query = <String, String>{
      if (sessionId != null) 'session_id': '$sessionId',
      if (delegationId != null) 'delegation_id': '$delegationId',
      if (committeeId != null) 'committee_id': '$committeeId',
      if (countryCode != null) 'country_code': countryCode,
      if (schoolId != null) 'school_id': '$schoolId',
      if (statusApplication != null) 'status_application': statusApplication,
      if (statusHousing != null) 'status_housing': statusHousing,
      if (isAmbassador != null) 'is_ambassador': isAmbassador ? 'true' : 'false',
      if (updatedSince != null) 'updated_since': updatedSince.toUtc().toIso8601String(),
      if (limit != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
    };

    final res = await _client.get(_uri('/delegates', query), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch delegates: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Delegate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Delegate?> getDelegateById(String personId) async {
    final res = await _client.get(_uri('/delegates/$personId'), headers: await _headers());
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch delegate $personId: ${res.statusCode}');
    }
    final obj = jsonDecode(res.body) as Map<String, dynamic>;
    return Delegate.fromJson(obj);
  }

  // ----------------
  // General profile endpoints (new)
  // ----------------

  /// GET /auth/me
  /// Expected: { "person_id": 123, "email": "...", ... }
  Future<Map<String, dynamic>> me() async {
    final res = await _client.get(_uri('/auth/me'), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch /auth/me: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /sessions/active
  /// Expected: { "id": 1, ... } OR { "session_id": 1, ... }
  Future<Map<String, dynamic>> getActiveSession() async {
    final res = await _client.get(_uri('/sessions/active'), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch /sessions/active: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /people/{personId}/profile?session_id=...
  /// Expected: joined profile payload (names + confirmed_group/role + school/delegation/committee/forum/country)
  Future<Map<String, dynamic>> getPersonProfile({
    required int personId,
    required int sessionId,
  }) async {
    final res = await _client.get(
      _uri('/people/$personId/profile', {'session_id': '$sessionId'}),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch /people/$personId/profile: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Convenience: one call from the UI to build the general profile.
  /// Returns: { me: {...}, session: {...}, profile: {...} }
  Future<Map<String, dynamic>> getMyGeneralProfile() async {
    final meObj = await me();

    final personId = (meObj['person_id'] ?? 0) as int;
    if (personId <= 0) {
      throw Exception('Invalid person_id from /auth/me');
    }

    final sessionObj = await getActiveSession();
    final sessionIdRaw = sessionObj['id'] ?? sessionObj['session_id'];
    final sessionId = (sessionIdRaw ?? 0) as int;
    if (sessionId <= 0) {
      throw Exception('Invalid session id from /sessions/active');
    }

    final profileObj = await getPersonProfile(personId: personId, sessionId: sessionId);

    return {
      'me': meObj,
      'session': sessionObj,
      'profile': profileObj,
    };
  }
}