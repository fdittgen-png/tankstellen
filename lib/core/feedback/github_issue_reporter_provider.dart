import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'github_issue_reporter.dart';

part 'github_issue_reporter_provider.g.dart';

/// Secure-storage key for the user's GitHub Personal Access Token used
/// by the bad-scan reporter. The token is never logged and never sent
/// anywhere except `api.github.com` via [GithubIssueReporter].
///
/// TODO(#952 phase 3): add a settings UI that lets the user paste a
/// token + a consent dialog before we make any API call. Until then
/// the token is always null and the reporter falls back to SharePlus.
const String kGithubFeedbackTokenKey = 'gh_feedback_token';

/// Hard-coded target repository for bad-scan reports. The OCR-failure
/// issues are always filed against this project's own repo, so there
/// is no reason to make this configurable.
const String kGithubFeedbackRepoOwner = 'fdittgen-png';
const String kGithubFeedbackRepoName = 'tankstellen';

/// Shared HTTP client for the feedback reporter. Kept alive for the
/// lifetime of the app so repeated reports don't spawn a fresh
/// connection pool each time.
@Riverpod(keepAlive: true)
http.Client githubFeedbackHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// Reads the stored PAT from [FlutterSecureStorage] at [kGithubFeedbackTokenKey]
/// and composes a [GithubIssueReporter] against the project repo.
///
/// Returns `null` when no token is configured — the UI must fall back
/// to the existing SharePlus path in that case (phase 2 behaviour).
///
/// The reporter is cached for the app lifetime so a single token lookup
/// serves every bad-scan submission in the session.
@Riverpod(keepAlive: true)
Future<GithubIssueReporter?> githubIssueReporter(Ref ref) async {
  String? token;
  try {
    const storage = FlutterSecureStorage();
    token = await storage.read(key: kGithubFeedbackTokenKey);
  } catch (e, st) {
    // Secure storage can fail on some Android devices (keystore corruption,
    // biometric reset). Treat any failure as "no token" so the UI falls
    // back to SharePlus instead of bubbling up a platform error.
    debugPrint('githubIssueReporterProvider: secure-storage read failed: $e\n$st');
    return null;
  }

  if (token == null || token.isEmpty) {
    return null;
  }

  return GithubIssueReporter(
    httpClient: ref.watch(githubFeedbackHttpClientProvider),
    token: token,
    repoOwner: kGithubFeedbackRepoOwner,
    repoName: kGithubFeedbackRepoName,
  );
}
