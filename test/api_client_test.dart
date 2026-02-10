import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rimun_app/api/api_client.dart';
import 'package:rimun_app/api/models.dart' as api;

void main() {
  group('ApiClient', () {
    test('health returns true when status ok', () async {
      http.Request? captured;
      final client = ApiClient(
        client: MockClient((req) async {
          captured = req;
          expect(req.url.path, '/health');
          return http.Response(jsonEncode({'status': 'ok'}), 200,
              headers: {'content-type': 'application/json'});
        }),
      );

      final ok = await client.health();
      expect(ok, isTrue);
      expect(captured, isNotNull);
    });

    test('getForums parses list', () async {
      final client = ApiClient(
        client: MockClient((req) async {
          expect(req.url.path, '/forums');
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'acronym': 'GA',
                'name': 'General Assembly',
                'description': 'desc',
                'image_path': null,
                'created_at': '2025-01-01T00:00:00Z',
                'updated_at': '2025-01-02T00:00:00Z',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final forums = await client.getForums();
      expect(forums, hasLength(1));
      expect(forums.first, isA<api.Forum>());
      expect(forums.first.acronym, 'GA');
    });

    test('getCommittees includes limit/offset query', () async {
      http.Request? captured;
      final client = ApiClient(
        client: MockClient((req) async {
          captured = req;
          expect(req.url.path, '/committees');
          return http.Response(
            jsonEncode([
              {'id': 10, 'name': 'GA3', 'forum_acronym': 'GA'}
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final committees = await client.getCommittees(limit: 20, offset: 5);
      expect(committees, hasLength(1));
      expect(committees.first.name, 'GA3');
      expect(captured!.url.queryParameters['limit'], '20');
      expect(captured!.url.queryParameters['offset'], '5');
    });

    test('getDelegates maps filters to query', () async {
      http.Request? captured;
      final client = ApiClient(
        client: MockClient((req) async {
          captured = req;
          expect(req.url.path, '/delegates');
          return http.Response(
            jsonEncode([
              {
                'person_id': 10000,
                'full_name': 'Alice Doe',
                'country_code': 'IT',
                'committee_id': 10,
                'committee_name': 'GA3',
                'forum_acronym': 'GA',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final since = DateTime.utc(2025, 1, 1);
      final delegates = await client.getDelegates(
        sessionId: 1,
        delegationId: 2,
        committeeId: 3,
        countryCode: 'IT',
        schoolId: 4,
        statusApplication: 'accepted',
        statusHousing: 'not-required',
        isAmbassador: true,
        updatedSince: since,
        limit: 50,
        offset: 0,
      );

      expect(delegates, hasLength(1));
      expect(delegates.first.personId, 10000);
      final qp = captured!.url.queryParameters;
      expect(qp['session_id'], '1');
      expect(qp['delegation_id'], '2');
      expect(qp['committee_id'], '3');
      expect(qp['country_code'], 'IT');
      expect(qp['school_id'], '4');
      expect(qp['status_application'], 'accepted');
      expect(qp['status_housing'], 'not-required');
      expect(qp['is_ambassador'], 'true');
      expect(qp['updated_since'], since.toIso8601String());
      expect(qp['limit'], '50');
      expect(qp['offset'], '0');
    });

    test('getDelegateById returns null on 404', () async {
      final client = ApiClient(
        client: MockClient((req) async {
          expect(req.url.path, '/delegates/999');
          return http.Response('Not found', 404);
        }),
      );

      final d = await client.getDelegateById('999');
      expect(d, isNull);
    });
  });
}
