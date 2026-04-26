import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard — every country StationService implementation
/// must use HTTPS for its upstream data feed. Plaintext feeds let an
/// on-path attacker inject malicious price/station rows (CSV with
/// bogus coordinates, XML with redirects, etc.); the integrity check
/// on our side only validates header schemas, not content (#728).
///
/// This scans the lib/features/station_services/ tree, reading each
/// file and failing if any URL-shaped string literal uses the `http:`
/// scheme. Tolerated: `http://schemas.*`, `http://www.w3.org/*`, and
/// similar XML/schema namespace URIs that aren't fetched at runtime.
void main() {
  test('every StationService uses HTTPS for its upstream feed (#728)', () {
    final dir = Directory('lib/features/station_services');
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_station_service.dart'))
        .toList();
    expect(files, isNotEmpty,
        reason: 'no station services found — wrong working directory?');

    final offenders = <String>[];
    // Match any http:// URL inside a string literal (either quote style).
    final plainUrlRe = RegExp(
      "'http://[^']+'" '|' '"http://[^"]+"',
      caseSensitive: false,
    );
    final allowlistRe = RegExp(
        r'schemas?\.|w3\.org|xmlns|dtd|xsl',
        caseSensitive: false);

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = plainUrlRe.firstMatch(lines[i]);
        if (match == null) continue;
        final url = match.group(0)!;
        if (allowlistRe.hasMatch(url)) continue;
        offenders.add('${file.path}:${i + 1}: $url');
      }
    }
    expect(offenders, isEmpty,
        reason:
            'Plaintext HTTP URLs in station services:\n${offenders.join('\n')}');
  });
}
