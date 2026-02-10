import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    // Prefer API_BASE_URL, fallback to VITE_RIMUN_API_URL, then default
        // Prefer API_BASE_URL, fallback to VITE_RIMUN_API_URL, then default.
        // Guard dotenv access for tests where dotenv may be uninitialized.
        String? envUrl;
        try {
          if (dotenv.isInitialized) {
            envUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['VITE_RIMUN_API_URL'];
          }
        } catch (_) {
          envUrl = null;
        }
        return (envUrl != null && envUrl.isNotEmpty)
            ? envUrl
            : 'http://127.0.0.1:8081';
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<bool> health() async {
    final res = await _client.get(_uri('/health'));
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['status'] == 'ok';
  }

  Future<List<Forum>> getForums() async {
    final res = await _client.get(_uri('/forums'));
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
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch committees: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Committee.fromJson(e as Map<String, dynamic>))
        .toList();
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
      if (isAmbassador != null)
        'is_ambassador': isAmbassador ? 'true' : 'false',
      if (updatedSince != null)
        'updated_since': updatedSince.toUtc().toIso8601String(),
      if (limit != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
    };

    final res = await _client.get(_uri('/delegates', query));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch delegates: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Delegate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Delegate?> getDelegateById(String personId) async {
    final res = await _client.get(_uri('/delegates/$personId'));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch delegate $personId: ${res.statusCode}');
    }
    final obj = jsonDecode(res.body) as Map<String, dynamic>;
    return Delegate.fromJson(obj);
  }
}
