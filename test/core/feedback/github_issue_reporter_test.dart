import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tankstellen/core/feedback/github_issue_reporter.dart';

void main() {
  group('GithubIssueReporter', () {
    late _FakeClient client;
    late GithubIssueReporter reporter;

    setUp(() {
      client = _FakeClient();
      reporter = GithubIssueReporter(
        httpClient: client,
        token: 'test-token',
        repoOwner: 'fdittgen-png',
        repoName: 'tankstellen',
      );
    });

    test('successful POST returns the html_url of the created issue',
        () async {
      client.responses.add(
        _ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/123',
            'number': 123,
          },
        ),
      );

      final url = await reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: 'ESSENCE 1.85 E/L',
        parsedFields: const <String, String?>{'fuelType': 'E10'},
        userCorrections: const <String, String?>{},
        imageBytes: Uint8List.fromList(List<int>.filled(128, 0x42)),
      );

      expect(
        url.toString(),
        'https://github.com/fdittgen-png/tankstellen/issues/123',
      );
      expect(client.requests, hasLength(1));
      final req = client.requests.single;
      expect(req.method, 'POST');
      expect(
        req.url.toString(),
        'https://api.github.com/repos/fdittgen-png/tankstellen/issues',
      );
      expect(req.headers['Authorization'], 'Bearer test-token');
      expect(req.headers['Accept'], 'application/vnd.github+json');
    });

    test('401 unauthorized throws GithubReporterException with statusCode 401',
        () async {
      client.responses.add(
        _ok(
          statusCode: 401,
          body: {'message': 'Bad credentials'},
        ),
      );

      await expectLater(
        reporter.reportBadScan(
          kind: ScanKind.receipt,
          rawOcrText: 'x',
          parsedFields: const {},
          userCorrections: const {},
          imageBytes: Uint8List.fromList(const [1, 2, 3]),
        ),
        throwsA(isA<GithubReporterException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test(
        '403 with X-RateLimit-Remaining: 0 throws rate-limit exception',
        () async {
      client.responses.add(
        _ok(
          statusCode: 403,
          body: {'message': 'API rate limit exceeded'},
          headers: {'x-ratelimit-remaining': '0'},
        ),
      );

      final future = reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: 'x',
        parsedFields: const {},
        userCorrections: const {},
        imageBytes: Uint8List.fromList(const [1, 2, 3]),
      );

      await expectLater(
        future,
        throwsA(
          isA<GithubReporterException>()
              .having((e) => e.message, 'message',
                  contains('rate limit')),
        ),
      );
    });

    test(
        '422 validation error retries POST once without labels and succeeds',
        () async {
      client.responses
        ..add(_ok(
          statusCode: 422,
          body: {'message': 'Validation Failed'},
        ))
        ..add(_ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/44',
          },
        ));

      final url = await reporter.reportBadScan(
        kind: ScanKind.pumpDisplay,
        rawOcrText: 'x',
        parsedFields: const {},
        userCorrections: const {},
        imageBytes: Uint8List.fromList(const [1, 2, 3]),
      );

      expect(url.path, endsWith('/44'));
      expect(client.requests, hasLength(2));

      final firstBody =
          jsonDecode(client.requests[0].body) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(client.requests[1].body) as Map<String, dynamic>;
      expect(firstBody.containsKey('labels'), isTrue,
          reason: 'first attempt sends labels');
      expect(secondBody.containsKey('labels'), isFalse,
          reason: 'retry omits labels');
    });

    test('image bytes are base64-embedded into the issue body as markdown',
        () async {
      client.responses.add(
        _ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/1',
          },
        ),
      );

      final bytes = Uint8List.fromList(const [0xDE, 0xAD, 0xBE, 0xEF]);
      await reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: 'raw',
        parsedFields: const {'a': 'b'},
        userCorrections: const {'a': 'c'},
        imageBytes: bytes,
      );

      final payload =
          jsonDecode(client.requests.single.body) as Map<String, dynamic>;
      final body = payload['body'] as String;
      expect(body, contains('## Raw OCR text'));
      expect(body, contains('## Parsed fields'));
      expect(body, contains('## User corrections'));
      expect(
        body,
        contains('![scan](data:image/jpeg;base64,${base64Encode(bytes)})'),
      );
    });

    test('100KB image body stays under 65,000 chars (truncates when needed)',
        () async {
      client.responses.add(
        _ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/2',
          },
        ),
      );

      final bytes = Uint8List.fromList(List<int>.filled(100 * 1024, 0x41));
      await reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: 'x',
        parsedFields: const {},
        userCorrections: const {},
        imageBytes: bytes,
      );

      final payload =
          jsonDecode(client.requests.single.body) as Map<String, dynamic>;
      final body = payload['body'] as String;
      expect(body.length, lessThan(65000));
      expect(body, contains('[image too large to embed]'));
      expect(body, isNot(contains('data:image/jpeg;base64,AAAA')));
    });

    test('scan kind drives the issue title', () async {
      client.responses
        ..add(_ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/1',
          },
        ))
        ..add(_ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/2',
          },
        ));

      await reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: 'x',
        parsedFields: const {},
        userCorrections: const {},
        imageBytes: Uint8List.fromList(const [1]),
      );
      await reporter.reportBadScan(
        kind: ScanKind.pumpDisplay,
        rawOcrText: 'x',
        parsedFields: const {},
        userCorrections: const {},
        imageBytes: Uint8List.fromList(const [1]),
      );

      final receipt =
          jsonDecode(client.requests[0].body) as Map<String, dynamic>;
      final pump =
          jsonDecode(client.requests[1].body) as Map<String, dynamic>;
      expect(receipt['title'], '[Scan] Receipt OCR failure');
      expect(pump['title'], '[Scan] Pump display OCR failure');
    });

    test('sanitizes ANSI escape sequences and control chars from OCR text',
        () async {
      client.responses.add(
        _ok(
          statusCode: 201,
          body: {
            'html_url':
                'https://github.com/fdittgen-png/tankstellen/issues/9',
          },
        ),
      );

      await reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: '\x1B[31mRED\x1B[0m\x00NUL\x07BEL',
        parsedFields: const {},
        userCorrections: const {},
        imageBytes: Uint8List.fromList(const [1]),
      );

      final payload =
          jsonDecode(client.requests.single.body) as Map<String, dynamic>;
      final body = payload['body'] as String;
      expect(body, contains('REDNULBEL'));
      expect(body, isNot(contains('\x1B')));
      expect(body, isNot(contains('\x00')));
    });
  });
}

// -----------------------------------------------------------------------------
// Test doubles

http.Response _ok({
  required int statusCode,
  required Map<String, Object?> body,
  Map<String, String>? headers,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: headers ?? const {},
  );
}

class _CapturedRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  _CapturedRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });
}

class _FakeClient extends http.BaseClient {
  final List<http.Response> responses = <http.Response>[];
  final List<_CapturedRequest> requests = <_CapturedRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String body = '';
    if (request is http.Request) {
      body = request.body;
    }
    requests.add(_CapturedRequest(
      method: request.method,
      url: request.url,
      headers: Map<String, String>.from(request.headers),
      body: body,
    ));

    if (requests.length > responses.length) {
      throw StateError(
        'FakeClient: no response queued for request #${requests.length}',
      );
    }
    final response = responses[requests.length - 1];
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
