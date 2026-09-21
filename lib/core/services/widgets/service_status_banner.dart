// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../error/error_localizer.dart';
import '../../error/recovery_message.dart';
import '../../error/widgets/recovery_message_view.dart';
import '../../error/exceptions.dart';
import '../../feedback/github_issue_reporter/error_report_payload.dart';
import '../../feedback/github_issue_reporter/error_reporter.dart';
import '../../feedback/github_issue_reporter/error_reporter_context.dart';
import '../service_result.dart';
import '../surface_state.dart';

/// Displays a banner when data comes from cache or fallback services.
class ServiceStatusBanner extends StatelessWidget {
  final ServiceResult<dynamic> result;

  const ServiceStatusBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // #4134 — one model decides the state; this widget only renders it.
    final state = surfaceStateOf(result);
    final style = SurfaceStateStyle.of(context, state);
    if (style == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final message = switch (state) {
      SurfaceState.offline => '${l10n.offlineLabel} — ${result.freshnessLabel}',
      SurfaceState.degraded => _localizedFallbackSummary(result, l10n),
      SurfaceState.full => '',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: style.background,
      child: Row(
        children: [
          Icon(style.icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Builds the "X unavailable. Using Y." banner message using the active
/// localization, falling back to the untranslated [ServiceResult.fallbackSummary].
String _localizedFallbackSummary(
  ServiceResult<dynamic> result,
  AppLocalizations l10n,
) {
  if (result.errors.isEmpty) return '';
  final failedNames = result.errors.map((e) => e.source.displayName).join(', ');
  final current = result.source.displayName;
  return l10n.fallbackSummary(failedNames, current);
}

/// Shows error when the entire service chain failed.
///
/// #4141 — this screen is now a [RecoveryMessage] rendered by
/// [RecoveryMessageView], so it answers the four questions in order
/// instead of three. The one it could not answer before is the one that
/// matters most: "can I continue". A user told that saved stations and
/// their fill-up history still work does not conclude the app is broken.
///
/// The existing title/hint strings are reused verbatim rather than
/// re-split, because they are shared with other surfaces; some of the
/// hints carry a suggestion as well as a consequence, which #4144 can
/// tease apart. What is new here is the continuity line and the fact
/// that a site with no offered action no longer compiles.
class ServiceChainErrorWidget extends StatelessWidget {
  final Object error;

  /// #4141 — required. The contract says a failure must offer a way out,
  /// and every call site already passed one; making it optional only
  /// left room for a future screen with nothing to tap.
  final VoidCallback onRetry;

  /// Reporter used by the "Report this issue" button. Defaults to a
  /// real [ErrorReporter] that opens a consent dialog and launches the
  /// browser. Tests inject a fake.
  final ErrorReporter? reporter;

  /// Optional country code to include in the report (e.g. `GB`).
  final String? countryCode;

  /// What the user was doing when the error occurred (e.g. `GPS search`).
  final String? searchContext;

  /// Network connectivity at time of error (e.g. `wifi`, `mobile`, `none`).
  final String? networkState;

  /// Stack trace from the catch site, if available.
  final StackTrace? stackTrace;

  const ServiceChainErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.reporter,
    this.countryCode,
    this.searchContext,
    this.networkState,
    this.stackTrace,
  });

  /// Extract a short, user-friendly title from the error.
  String _title(AppLocalizations l10n) {
    if (error is NoApiKeyException || error is NoEvApiKeyException) {
      return l10n.errorTitleApiKey;
    }
    if (error is LocationException) {
      return l10n.errorTitleLocation;
    }
    if (error is ProviderUnavailableException) {
      return l10n.errorTitleProviderUnavailable;
    }
    return l10n.noResults;
  }

  /// Which of the six failures this is.
  ///
  /// #4141 — one classification feeding BOTH the hint and the
  /// continuity line. They used to be two independent `if` ladders in
  /// the making, which is how a screen ends up telling a user their
  /// route failed and that their route still works.
  _ChainFailure _classify() {
    // #4348 — typed first: its message must never be sniffed into a
    // "connection" hint that promises a retry will help.
    if (error is ProviderUnavailableException) {
      return _ChainFailure.providerUnavailable;
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('no stations found') ||
        msg.contains('keine tankstellen')) {
      return _ChainFailure.noStations;
    }
    if (msg.contains('api key') ||
        error is NoApiKeyException ||
        error is NoEvApiKeyException) {
      return _ChainFailure.apiKey;
    }
    if (msg.contains('location') ||
        msg.contains('gps') ||
        error is LocationException) {
      return _ChainFailure.location;
    }
    if (msg.contains('timeout') || msg.contains('connection')) {
      return _ChainFailure.connection;
    }
    if (msg.contains('route') ||
        msg.contains('osrm') ||
        msg.contains('routing')) {
      return _ChainFailure.routing;
    }
    return _ChainFailure.unclassified;
  }

  String _hint(AppLocalizations l10n) => switch (_classify()) {
        _ChainFailure.noStations => l10n.errorHintNoStations,
        _ChainFailure.apiKey => l10n.errorHintApiKey,
        _ChainFailure.location => l10n.locationDenied,
        _ChainFailure.connection => l10n.errorHintConnection,
        _ChainFailure.routing => l10n.errorHintRouting,
        _ChainFailure.providerUnavailable => l10n.errorProviderUnavailable,
        _ChainFailure.unclassified => l10n.errorHintFallback,
      };

  /// The "can I continue" line (#4141) — one per failure, never omitted.
  String _stillWorks(AppLocalizations l10n) => switch (_classify()) {
        _ChainFailure.noStations => l10n.recoveryStillWorksNoStations,
        _ChainFailure.apiKey => l10n.recoveryStillWorksApiKey,
        _ChainFailure.location => l10n.recoveryStillWorksLocation,
        _ChainFailure.connection => l10n.recoveryStillWorksConnection,
        _ChainFailure.routing => l10n.recoveryStillWorksRouting,
        _ChainFailure.providerUnavailable =>
          l10n.recoveryStillWorksProviderUnavailable,
        _ChainFailure.unclassified => l10n.recoveryStillWorksFallback,
      };

  /// An empty search is not a degradation — nothing failed and nothing
  /// is missing. Every other case is the app continuing with less.
  RecoveryImpact get _impact => _classify() == _ChainFailure.noStations
      ? RecoveryImpact.unaffected
      : RecoveryImpact.degraded;

  /// Extract technical details for the expandable section.
  ///
  /// Domain exceptions go through [ErrorLocalizer] so the user sees the
  /// translated message; unknown errors stay as their raw [toString] so the
  /// expandable section still carries useful debug info.
  List<String> _technicalDetails(AppLocalizations l10n) {
    String render(Object e) =>
        e is AppException ? ErrorLocalizer.localize(e, l10n) : e.toString();

    if (error is ServiceChainExhaustedException) {
      final chain = error as ServiceChainExhaustedException;
      // i18n-ignore: developer diagnostic — this is the expandable
      // technical-details section, intentionally raw for debugging.
      return chain.errors
          .map((e) => '${e.source.displayName}: ${e.message}')
          .toList();
    }
    return [render(error)];
  }

  /// Builds the payload and hands off to the injected [ErrorReporter].
  ///
  /// The reporter shows its own consent dialog before launching the
  /// browser, so this method never sends anything off-device on its
  /// own — the user still has to confirm.
  void _onReportPressed(BuildContext context) {
    final payload = ErrorReportPayload.fromError(
      error,
      appVersion: ErrorReporterContext.currentAppVersion(),
      platform: ErrorReporterContext.currentPlatform(),
      locale: ErrorReporterContext.currentLocale(context),
      countryCode: countryCode,
      networkState: networkState,
      searchContext: searchContext,
      stackTrace: stackTrace,
    );
    unawaited(
      (reporter ?? const ErrorReporter()).reportError(context, payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportable = ErrorReportPayload.assessReportability(error).reportable;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: RecoveryMessageView(
          message: RecoveryMessage(
            whatHappened: _title(l10n),
            whyItMatters: _hint(l10n),
            impact: _impact,
            whatStillWorks: _stillWorks(l10n),
            primaryAction: RecoveryAction(
              label: l10n.retry,
              onInvoke: onRetry,
              icon: Icons.refresh,
            ),
            // #1606 — no report CTA for errors that should never become a
            // GitHub issue: designed-in stop-gap messages tied to a
            // tracked issue, and transient connectivity failures. The
            // hint already tells the user what to do in those cases.
            secondaryAction: reportable
                ? RecoveryAction(
                    label: l10n.reportThisIssue,
                    onInvoke: () => _onReportPressed(context),
                    icon: Icons.bug_report_outlined,
                  )
                : null,
            diagnostic: _technicalDetails(l10n),
          ),
        ),
      ),
    );
  }
}

/// The failures this screen distinguishes (#4141, #4348). An enum rather
/// than a chain of `if`s repeated per rendered line, so a new failure
/// cannot reach one line and miss another.
enum _ChainFailure {
  noStations,
  apiKey,
  location,
  connection,
  routing,

  /// #4348 — the country's provider is declared dead; structural, so no
  /// "check your connection" hint.
  providerUnavailable,
  unclassified,
}
