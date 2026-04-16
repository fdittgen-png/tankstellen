@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tankstellen/core/constants/app_constants.dart';

/// Verifies that every user-facing URL constant in [AppConstants] is
/// reachable (returns HTTP 2xx or 3xx). Tagged `network` so it only
/// runs in CI jobs / manual invocations with network access:
///
///   flutter test --tags=network
///
/// The default CI step runs `--exclude-tags=network`, so this test
/// does NOT block offline PR checks.
void main() {
  group('External URLs reachable (#539)', () {
    /// URLs the app opens in the user's browser. A 404 on any of
    /// these is a visible broken link the user sees after tapping a
    /// Settings tile or About entry.
    final urlsToCheck = <String, String>{
      'privacyPolicyUrl': AppConstants.privacyPolicyUrl,
      'githubRepoUrl': AppConstants.githubRepoUrl,
      'githubIssuesUrl': AppConstants.githubIssuesUrl,
      'tankerkoenigRegistrationUrl': AppConstants.tankerkoenigRegistrationUrl,
      'paypalUrl': AppConstants.paypalUrl,
      'revolutUrl': AppConstants.revolutUrl,
    };

    for (final entry in urlsToCheck.entries) {
      test('${entry.key} responds with 2xx or 3xx', () async {
        final response = await http.head(
          Uri.parse(entry.value),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => http.Response('timeout', 408),
        );
        expect(
          response.statusCode,
          lessThan(400),
          reason: '${entry.key} (${entry.value}) returned '
              'HTTP ${response.statusCode} — broken link',
        );
      });
    }
  });
}
