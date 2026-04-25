import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// What kind of scan produced the failing OCR output — determines the
/// issue title.
enum ScanKind {
  receipt,
  pumpDisplay,
}

extension ScanKindLabel on ScanKind {
  String get title {
    switch (this) {
      case ScanKind.receipt:
        return '[Scan] Receipt OCR failure';
      case ScanKind.pumpDisplay:
        return '[Scan] Pump display OCR failure';
    }
  }
}

/// Thrown when the GitHub REST API call fails in a way the caller needs
/// to know about (auth error, rate limit, network, server error). The
/// UI uses this to decide whether to fall back to SharePlus.
class GithubReporterException implements Exception {
  final String message;
  final int? statusCode;

  const GithubReporterException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'GithubReporterException: $message'
      : 'GithubReporterException($statusCode): $message';
}

/// Creates a GitHub issue from a failed OCR scan.
///
/// Phase 1 scope: the network service only. UI integration
/// ([bad_scan_report_sheet] swap) ships in phase 2; EXIF stripping +
/// consent dialog ship in phase 3.
///
/// The issue body bundles the raw OCR text, the parsed fields the app
/// extracted, the corrections the user typed, and a base64-embedded
/// screenshot/photo of the scan. GitHub renders `data:image/...` URIs
/// in markdown so the photo appears inline.
///
/// Phase 3 (#952) — EXIF location tags are stripped before encoding.
/// If decoding fails (corrupt input, unsupported format) we fall back
/// to passing raw bytes through and add a marker in the issue body so
/// triage knows the image may carry metadata.
class GithubIssueReporter {
  final http.Client _httpClient;
  final String _token;
  final String _repoOwner;
  final String _repoName;

  /// Absolute ceiling for the issue body. GitHub's own limit is
  /// 65,536 chars — we keep a small safety margin.
  static const int _maxBodyLength = 65000;

  /// If `X-RateLimit-Remaining` drops below this threshold we refuse
  /// to submit so the UI can fall back to SharePlus without burning
  /// the last few calls on retries.
  static const int _rateLimitFloor = 5;

  GithubIssueReporter({
    required http.Client httpClient,
    required String token,
    required String repoOwner,
    required String repoName,
  })  : _httpClient = httpClient,
        _token = token,
        _repoOwner = repoOwner,
        _repoName = repoName;

  /// Creates a GitHub issue and returns the `html_url` of the created
  /// issue.
  ///
  /// Throws [GithubReporterException] on auth failures, rate-limit
  /// exhaustion, network errors, or server errors.
  ///
  /// If the repo doesn't have one of the requested labels (422
  /// Unprocessable Entity) the call is retried once without labels so
  /// a missing `from-app` label doesn't block the submission.
  Future<Uri> reportBadScan({
    required ScanKind kind,
    required String rawOcrText,
    required Map<String, String?> parsedFields,
    required Map<String, String?> userCorrections,
    required Uint8List imageBytes,
    String? userNote,
  }) async {
    final body = _buildBody(
      kind: kind,
      rawOcrText: rawOcrText,
      parsedFields: parsedFields,
      userCorrections: userCorrections,
      imageBytes: imageBytes,
      userNote: userNote,
    );

    final title = kind.title;
    const labels = <String>['type/bug', 'area/scan', 'from-app'];

    try {
      final response = await _postIssue(title: title, body: body, labels: labels);

      if (response.statusCode == 422) {
        // Most likely cause: one of the labels isn't defined in the
        // repo. Retry without labels so submission still succeeds.
        final retry = await _postIssue(
          title: title,
          body: body,
          labels: const [],
        );
        return _parseResponse(retry);
      }

      return _parseResponse(response);
    } on GithubReporterException {
      rethrow;
    } catch (e) {
      debugPrint('GithubIssueReporter network failure: $e');
      throw GithubReporterException('network error: $e');
    }
  }

  Future<http.Response> _postIssue({
    required String title,
    required String body,
    required List<String> labels,
  }) {
    final uri = Uri.parse(
      'https://api.github.com/repos/$_repoOwner/$_repoName/issues',
    );
    final payload = <String, Object?>{
      'title': title,
      'body': body,
      if (labels.isNotEmpty) 'labels': labels,
    };
    return _httpClient.post(
      uri,
      headers: <String, String>{
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      body: jsonEncode(payload),
    );
  }

  Uri _parseResponse(http.Response response) {
    _checkRateLimit(response);

    if (response.statusCode == 401) {
      throw const GithubReporterException(
        'authentication failed (invalid token)',
        statusCode: 401,
      );
    }
    if (response.statusCode == 403) {
      throw GithubReporterException(
        'access forbidden: ${response.reasonPhrase ?? 'rate limited'}',
        statusCode: 403,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GithubReporterException(
        'unexpected status ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final htmlUrl = json['html_url'] as String?;
    if (htmlUrl == null || htmlUrl.isEmpty) {
      throw const GithubReporterException(
        'response missing html_url',
      );
    }
    return Uri.parse(htmlUrl);
  }

  void _checkRateLimit(http.Response response) {
    final remaining = response.headers['x-ratelimit-remaining'];
    if (remaining == null) return;
    final value = int.tryParse(remaining);
    if (value == null) return;
    if (value < _rateLimitFloor) {
      throw GithubReporterException(
        'rate limit nearly exhausted (remaining: $value)',
        statusCode: response.statusCode,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Body construction

  String _buildBody({
    required ScanKind kind,
    required String rawOcrText,
    required Map<String, String?> parsedFields,
    required Map<String, String?> userCorrections,
    required Uint8List imageBytes,
    String? userNote,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('## Scan kind');
    buffer.writeln();
    buffer.writeln('- ${_scanKindLabel(kind)}');
    buffer.writeln();

    if (userNote != null && userNote.trim().isNotEmpty) {
      buffer.writeln('## User note');
      buffer.writeln();
      buffer.writeln(_sanitize(userNote.trim()));
      buffer.writeln();
    }

    buffer.writeln('## Raw OCR text');
    buffer.writeln();
    buffer.writeln('```');
    buffer.writeln(_sanitize(rawOcrText));
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Parsed fields');
    buffer.writeln();
    buffer.write(_fieldTable(parsedFields));
    buffer.writeln();

    buffer.writeln('## User corrections');
    buffer.writeln();
    buffer.write(_fieldTable(userCorrections));
    buffer.writeln();

    final stripResult = _stripExif(imageBytes);
    if (!stripResult.stripped) {
      buffer.writeln('## Notes');
      buffer.writeln();
      buffer.writeln(
        '_[note: EXIF strip failed, raw bytes uploaded]_',
      );
      buffer.writeln();
    }

    buffer.writeln('## Scan image');
    buffer.writeln();

    final textSoFar = buffer.length;
    final base64Image = base64Encode(stripResult.bytes);
    // ~30 chars of markdown wrapper around the base64 payload
    // (`![scan](data:image/jpeg;base64,)`).
    const wrapperLength = 32;
    if (textSoFar + base64Image.length + wrapperLength > _maxBodyLength) {
      buffer.writeln('_[image too large to embed]_');
    } else {
      buffer.writeln('![scan](data:image/jpeg;base64,$base64Image)');
    }

    return buffer.toString();
  }

  /// Decodes the input, drops the EXIF block (location, timestamps,
  /// device id), and re-encodes as JPEG. On any failure the original
  /// bytes are returned with `stripped == false` so the caller can
  /// annotate the issue body but still ship the image.
  _ExifStripResult _stripExif(Uint8List bytes) {
    if (bytes.isEmpty) {
      return _ExifStripResult(bytes: bytes, stripped: false);
    }
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return _ExifStripResult(bytes: bytes, stripped: false);
      }
      // Replace any populated ExifData with an empty one — drops GPS,
      // timestamps, camera model, and any maker notes.
      decoded.exif = img.ExifData();
      final encoded = img.encodeJpg(decoded, quality: 85);
      return _ExifStripResult(bytes: encoded, stripped: true);
    } catch (e) {
      debugPrint('GithubIssueReporter EXIF strip failed: $e');
      return _ExifStripResult(bytes: bytes, stripped: false);
    }
  }

  String _scanKindLabel(ScanKind kind) {
    switch (kind) {
      case ScanKind.receipt:
        return 'Receipt';
      case ScanKind.pumpDisplay:
        return 'Pump display';
    }
  }

  String _fieldTable(Map<String, String?> fields) {
    if (fields.isEmpty) {
      return '_(none)_\n';
    }
    final buffer = StringBuffer();
    buffer.writeln('| Field | Value |');
    buffer.writeln('| --- | --- |');
    for (final entry in fields.entries) {
      final key = _sanitizeCell(entry.key);
      final value = entry.value == null || entry.value!.isEmpty
          ? '_(empty)_'
          : _sanitizeCell(entry.value!);
      buffer.writeln('| $key | $value |');
    }
    return buffer.toString();
  }

  /// Strips ANSI escapes, control characters (except `\n` and `\t`),
  /// and anything else that would break markdown rendering.
  String _sanitize(String input) {
    // Remove ANSI CSI sequences (ESC [ ... letter).
    final withoutAnsi = input.replaceAll(
      RegExp(r'\x1B\[[0-9;]*[A-Za-z]'),
      '',
    );
    // Strip control chars except tab (\x09) and newline (\x0A).
    return withoutAnsi.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );
  }

  /// Like [_sanitize] but also escapes characters that break markdown
  /// table cells (pipes and embedded newlines).
  String _sanitizeCell(String input) {
    return _sanitize(input).replaceAll('\n', ' ').replaceAll('|', r'\|');
  }
}

/// Internal carrier returned by [_stripExif]. `stripped == true` means
/// the bytes have been re-encoded with an empty EXIF block; `false`
/// means decoding/encoding failed and the original bytes are returned.
@immutable
class _ExifStripResult {
  final Uint8List bytes;
  final bool stripped;

  const _ExifStripResult({required this.bytes, required this.stripped});
}
