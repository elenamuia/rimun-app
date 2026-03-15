import '../api/api_client.dart';
import '../api/models.dart';

// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String Function() getToken; // returns the Firebase JWT

  ApiService({required this.baseUrl, required this.getToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${getToken()}',
  };

  // --- Profile ---
  Future<PersonProfileDTO> getMyPersonProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/profiles/me/person'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException(res.statusCode, res.body);
    return PersonProfileDTO.fromJson(jsonDecode(res.body));
  }

  // --- Timeline ---
  Future<List<TimelineEvent>> listTimelineEvents() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/timeline/events'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException(res.statusCode, res.body);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => TimelineEvent.fromJson(e)).toList();
  }

  // --- News Posts ---
  Future<List<PostWithAuthor>> listPosts() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/news/posts'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException(res.statusCode, res.body);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => PostWithAuthor.fromJson(e)).toList();
  }

  Future<void> updatePost({
    required int postId,
    required String title,
    required String body,
    bool isForSchools = false,
    bool isForPersons = true,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/v2/news/posts/$postId'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'body': body,
        'is_for_schools': isForSchools,
        'is_for_persons': isForPersons,
      }),
    );
    if (res.statusCode != 200) throw ApiException(res.statusCode, res.body);
  }

  Future<void> deletePost(int postId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/v2/news/posts/$postId'),
      headers: _headers,
    );
    if (res.statusCode != 204) throw ApiException(res.statusCode, res.body);
  }

  Future<PostWithAuthor> createPost({
    required String title,
    required String body,
    bool isForSchools = false,
    bool isForPersons = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/news/posts'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'body': body,
        'is_for_schools': isForSchools,
        'is_for_persons': isForPersons,
      }),
    );
    if (res.statusCode != 201) throw ApiException(res.statusCode, res.body);
    return PostWithAuthor.fromJson(jsonDecode(res.body));
  }

  Future<ProfileData> getMyProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/profiles/me/person'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException(res.statusCode, res.body);
    return ProfileData.fromPersonProfileJson(jsonDecode(res.body));
  }

  Future<List<Committee>> fetchAllCommittees() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v2/forums'));
    final forums = jsonDecode(response.body) as List;

    // Flatten: each forum has a "committees" array
    return forums
        .expand((f) => (f['committees'] as List?) ?? [])
        .map((c) => Committee.fromJson(c))
        .toList();
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v2/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult.fromJson(json);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}
