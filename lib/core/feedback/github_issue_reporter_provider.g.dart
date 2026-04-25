// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_issue_reporter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared HTTP client for the feedback reporter. Kept alive for the
/// lifetime of the app so repeated reports don't spawn a fresh
/// connection pool each time.

@ProviderFor(githubFeedbackHttpClient)
final githubFeedbackHttpClientProvider = GithubFeedbackHttpClientProvider._();

/// Shared HTTP client for the feedback reporter. Kept alive for the
/// lifetime of the app so repeated reports don't spawn a fresh
/// connection pool each time.

final class GithubFeedbackHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Shared HTTP client for the feedback reporter. Kept alive for the
  /// lifetime of the app so repeated reports don't spawn a fresh
  /// connection pool each time.
  GithubFeedbackHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubFeedbackHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubFeedbackHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return githubFeedbackHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$githubFeedbackHttpClientHash() =>
    r'a7d0b14debaffa1a721add8c2a84fdec17b2b366';

/// Reads the stored PAT from [FlutterSecureStorage] at [kGithubFeedbackTokenKey]
/// and composes a [GithubIssueReporter] against the project repo.
///
/// Returns `null` when no token is configured — the UI must fall back
/// to the existing SharePlus path in that case (phase 2 behaviour).
///
/// The reporter is cached for the app lifetime so a single token lookup
/// serves every bad-scan submission in the session.

@ProviderFor(githubIssueReporter)
final githubIssueReporterProvider = GithubIssueReporterProvider._();

/// Reads the stored PAT from [FlutterSecureStorage] at [kGithubFeedbackTokenKey]
/// and composes a [GithubIssueReporter] against the project repo.
///
/// Returns `null` when no token is configured — the UI must fall back
/// to the existing SharePlus path in that case (phase 2 behaviour).
///
/// The reporter is cached for the app lifetime so a single token lookup
/// serves every bad-scan submission in the session.

final class GithubIssueReporterProvider
    extends
        $FunctionalProvider<
          AsyncValue<GithubIssueReporter?>,
          GithubIssueReporter?,
          FutureOr<GithubIssueReporter?>
        >
    with
        $FutureModifier<GithubIssueReporter?>,
        $FutureProvider<GithubIssueReporter?> {
  /// Reads the stored PAT from [FlutterSecureStorage] at [kGithubFeedbackTokenKey]
  /// and composes a [GithubIssueReporter] against the project repo.
  ///
  /// Returns `null` when no token is configured — the UI must fall back
  /// to the existing SharePlus path in that case (phase 2 behaviour).
  ///
  /// The reporter is cached for the app lifetime so a single token lookup
  /// serves every bad-scan submission in the session.
  GithubIssueReporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubIssueReporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubIssueReporterHash();

  @$internal
  @override
  $FutureProviderElement<GithubIssueReporter?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GithubIssueReporter?> create(Ref ref) {
    return githubIssueReporter(ref);
  }
}

String _$githubIssueReporterHash() =>
    r'ac9ca8e61618130edef9ccc0ff13a7a6b6d26070';
