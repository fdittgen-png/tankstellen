import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../error/error_localizer.dart';
import '../../error/exceptions.dart';
import '../../error_reporting/error_report_payload.dart';
import '../../error_reporting/error_reporter.dart';
import '../../error_reporting/error_reporter_context.dart';
import '../service_result.dart';

/// Displays a banner when data comes from cache or fallback services.
class ServiceStatusBanner extends StatelessWidget {
  final ServiceResult result;

  const ServiceStatusBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.isStale && !result.hadFallbacks) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final Color backgroundColor;
    final IconData icon;
    final String message;

    if (result.isStale) {
      backgroundColor = theme.colorScheme.errorContainer;
      icon = Icons.cloud_off;
      message =
          '${l10n?.offlineLabel ?? 'Offline'} — ${result.freshnessLabel}';
    } else if (result.hadFallbacks) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      icon = Icons.info_outline;
      message = _localizedFallbackSummary(result, l10n);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Builds the "X unavailable. Using Y." banner message using the active
/// localization, falling back to the untranslated [ServiceResult.fallbackSummary].
String _localizedFallbackSummary(ServiceResult result, AppLocalizations? l10n) {
  if (result.errors.isEmpty) return '';
  final failedNames = result.errors.map((e) => e.source.displayName).join(', ');
  final current = result.source.displayName;
  return l10n?.fallbackSummary(failedNames, current) ??
      result.fallbackSummary;
}

/// Shows error when the entire service chain failed.
/// Formats errors for humans — never shows raw Dart objects.
class ServiceChainErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  /// Reporter used by the "Report this issue" button. Defaults to a
  /// real [ErrorReporter] that opens a consent dialog and launches the
  /// browser. Tests inject a fake.
  final ErrorReporter? reporter;

  /// Optional country code to include in the report (e.g. `GB`).
  final String? countryCode;

  const ServiceChainErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.reporter,
    this.countryCode,
  });

  /// Extract a short, user-friendly title from the error.
  String _title(AppLocalizations? l10n) {
    if (error is NoApiKeyException || error is NoEvApiKeyException) {
      return l10n?.errorTitleApiKey ?? 'API key required';
    }
    if (error is LocationException) {
      return l10n?.errorTitleLocation ?? 'Location unavailable';
    }
    return l10n?.noResults ?? 'No stations found.';
  }

  /// Extract actionable hint text from the error chain.
  String _hint(AppLocalizations? l10n) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('no stations found') ||
        msg.contains('keine tankstellen')) {
      return l10n?.errorHintNoStations ??
          'Try increasing the search radius or search a different location.';
    }
    if (msg.contains('api key') ||
        error is NoApiKeyException ||
        error is NoEvApiKeyException) {
      return l10n?.errorHintApiKey ?? 'Configure your API key in Settings.';
    }
    if (msg.contains('location') ||
        msg.contains('gps') ||
        error is LocationException) {
      return l10n?.locationDenied ??
          'Location unavailable. Try searching by postal code or city name.';
    }
    if (msg.contains('timeout') || msg.contains('connection')) {
      return l10n?.errorHintConnection ??
          'Check your internet connection and try again.';
    }
    if (msg.contains('route') ||
        msg.contains('osrm') ||
        msg.contains('routing')) {
      return l10n?.errorHintRouting ??
          'Route calculation failed. Check your internet connection and try again.';
    }
    return l10n?.errorHintFallback ??
        'Try again or search by postal code / city name.';
  }

  /// Extract technical details for the expandable section.
  ///
  /// Domain exceptions go through [ErrorLocalizer] so the user sees the
  /// translated message; unknown errors stay as their raw [toString] so the
  /// expandable section still carries useful debug info.
  List<String> _technicalDetails(AppLocalizations? l10n) {
    String render(Object e) =>
        e is AppException ? ErrorLocalizer.localize(e, l10n) : e.toString();

    if (error is ServiceChainExhaustedException) {
      final chain = error as ServiceChainExhaustedException;
      return chain.errors.map((e) {
        if (e is ServiceError) {
          return '${e.source.displayName}: ${e.message}';
        }
        return render(e);
      }).toList();
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
    );
    (reporter ?? const ErrorReporter()).reportError(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _title(l10n),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _hint(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.retry ?? 'Try again'),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _onReportPressed(context),
              icon: const Icon(Icons.bug_report_outlined, size: 18),
              label: Text(l10n?.reportThisIssue ?? 'Report this issue'),
            ),
            const SizedBox(height: 12),
            // Expandable technical details
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  l10n?.detailsLabel ?? 'Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: _technicalDetails(l10n)
                    .map((d) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: Text(
                            d,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
