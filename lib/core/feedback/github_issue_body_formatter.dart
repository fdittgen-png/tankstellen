import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'github_issue_reporter.dart' show ScanKind;

/// Pure string-formatting helpers used by [GithubIssueReporter] to
/// build the markdown body of a bad-scan issue. Split out of
/// `github_issue_reporter.dart` so the reporter shell stays focused on
/// HTTP + rate-limit handling.
///
/// All members are static — the formatter is stateless. Callers pass
/// in the scan payload and get back a markdown string ready to POST.
class GithubIssueBodyFormatter {
  GithubIssueBodyFormatter._();

  /// Absolute ceiling for the issue body. GitHub's own limit is
  /// 65,536 chars — we keep a small safety margin.
  static const int maxBodyLength = 65000;

  /// Builds the markdown body for a bad-scan issue. Embeds the OCR
  /// text, parsed fields, user corrections, and a base64-encoded image
  /// (with EXIF stripped on a best-effort basis).
  static String buildBody({
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
    buffer.writeln('- ${scanKindLabel(kind)}');
    buffer.writeln();

    if (userNote != null && userNote.trim().isNotEmpty) {
      buffer.writeln('## User note');
      buffer.writeln();
      buffer.writeln(sanitize(userNote.trim()));
      buffer.writeln();
    }

    buffer.writeln('## Raw OCR text');
    buffer.writeln();
    buffer.writeln('```');
    buffer.writeln(sanitize(rawOcrText));
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Parsed fields');
    buffer.writeln();
    buffer.write(fieldTable(parsedFields));
    buffer.writeln();

    buffer.writeln('## User corrections');
    buffer.writeln();
    buffer.write(fieldTable(userCorrections));
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
    if (textSoFar + base64Image.length + wrapperLength > maxBodyLength) {
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
  static _ExifStripResult _stripExif(Uint8List bytes) {
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

  static String scanKindLabel(ScanKind kind) {
    switch (kind) {
      case ScanKind.receipt:
        return 'Receipt';
      case ScanKind.pumpDisplay:
        return 'Pump display';
    }
  }

  static String fieldTable(Map<String, String?> fields) {
    if (fields.isEmpty) {
      return '_(none)_\n';
    }
    final buffer = StringBuffer();
    buffer.writeln('| Field | Value |');
    buffer.writeln('| --- | --- |');
    for (final entry in fields.entries) {
      final key = sanitizeCell(entry.key);
      final value = entry.value == null || entry.value!.isEmpty
          ? '_(empty)_'
          : sanitizeCell(entry.value!);
      buffer.writeln('| $key | $value |');
    }
    return buffer.toString();
  }

  /// Strips ANSI escapes, control characters (except `\n` and `\t`),
  /// and anything else that would break markdown rendering.
  static String sanitize(String input) {
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

  /// Like [sanitize] but also escapes characters that break markdown
  /// table cells (pipes and embedded newlines).
  static String sanitizeCell(String input) {
    return sanitize(input).replaceAll('\n', ' ').replaceAll('|', r'\|');
  }
}

/// Internal carrier for [GithubIssueBodyFormatter._stripExif].
/// `stripped == true` means the bytes have been re-encoded with an
/// empty EXIF block; `false` means decoding/encoding failed and the
/// original bytes are returned.
@immutable
class _ExifStripResult {
  final Uint8List bytes;
  final bool stripped;

  const _ExifStripResult({required this.bytes, required this.stripped});
}
