import '../../constants/app_constants.dart';
import 'error_report_payload.dart';

/// Pure functions that turn an [ErrorReportPayload] into the title,
/// markdown body, and pre-populated GitHub issue URL.
///
/// All methods are pure and deterministic, so they are trivially
/// unit-testable without network or UI.
class ErrorReportFormatter {
  const ErrorReportFormatter._();

  static const String _labels = 'type/bug,needs-triage';

  /// Short, single-line title suitable for a GitHub issue.
  ///
  /// Falls back to `bug: <errorType>` if neither a source nor a status
  /// code are available on the payload.
  static String buildTitle(ErrorReportPayload p) {
    final parts = <String>['bug'];
    if (p.sourceLabel != null && p.sourceLabel!.isNotEmpty) {
      parts.add(p.sourceLabel!);
    } else if (p.countryCode != null && p.countryCode!.isNotEmpty) {
      parts.add(p.countryCode!.toUpperCase());
    }

    final prefix = parts.join(': ');
    final suffix = _titleSuffix(p);
    return '$prefix — $suffix';
  }

  static String _titleSuffix(ErrorReportPayload p) {
    if (p.statusCode != null) {
      return '${p.errorType} (HTTP ${p.statusCode})';
    }
    if (p.errorMessage.length <= 60) return p.errorMessage;
    return p.errorType;
  }

  /// Markdown body, matching the shape of the project's Bug Report
  /// issue template. Contains no PII — only error type, sanitized
  /// message, status code, fallback chain, app version, locale, and
  /// platform.
  static String buildBody(ErrorReportPayload p) {
    final buf = StringBuffer();
    buf.writeln('## What happened');
    buf.writeln();
    buf.writeln('```');
    buf.writeln(p.errorMessage);
    buf.writeln('```');
    buf.writeln();
    buf.writeln('## Environment');
    buf.writeln();
    buf.writeln('- **App version:** ${p.appVersion}');
    buf.writeln('- **Platform:** ${p.platform}');
    buf.writeln('- **Locale:** ${p.locale}');
    if (p.countryCode != null && p.countryCode!.isNotEmpty) {
      buf.writeln('- **Country API:** ${p.countryCode!.toUpperCase()}');
    }
    if (p.sourceLabel != null && p.sourceLabel!.isNotEmpty) {
      buf.writeln('- **Source:** ${p.sourceLabel}');
    }
    buf.writeln('- **Error type:** `${p.errorType}`');
    if (p.statusCode != null) {
      buf.writeln('- **HTTP status:** ${p.statusCode}');
    }
    buf.writeln('- **Captured at:** ${p.capturedAt.toUtc().toIso8601String()}');
    buf.writeln();

    if (p.fallbackChain.isNotEmpty) {
      buf.writeln('## Fallback chain');
      buf.writeln();
      for (final entry in p.fallbackChain) {
        buf.writeln('- $entry');
      }
      buf.writeln();
    }

    // Diagnostic context — helps triage without a repro (#524).
    final hasContext = p.networkState != null || p.searchContext != null;
    if (hasContext) {
      buf.writeln('## Context');
      buf.writeln();
      if (p.networkState != null) {
        buf.writeln('- **Network:** ${p.networkState}');
      }
      if (p.searchContext != null) {
        buf.writeln('- **Action:** ${p.searchContext}');
      }
      buf.writeln();
    }

    if (p.stackExcerpt != null && p.stackExcerpt!.isNotEmpty) {
      buf.writeln('<details><summary>Stack trace (app frames only)</summary>');
      buf.writeln();
      buf.writeln('```');
      buf.writeln(p.stackExcerpt);
      buf.writeln('```');
      buf.writeln();
      buf.writeln('</details>');
      buf.writeln();
    }

    buf.writeln('## Steps to reproduce');
    buf.writeln();
    buf.writeln('<!-- Add any context about what you were doing -->');
    buf.writeln();
    buf.writeln('---');
    buf.writeln(
      '_Reported via the in-app error dialog. No GPS, API keys, or '
      'personal data are included in this report._',
    );
    return buf.toString();
  }

  /// Builds the fully-qualified GitHub issue-new URL with title, body,
  /// and labels pre-filled.
  ///
  /// We intentionally do **not** pass `template=bug_report.yml` —
  /// GitHub's issue-new page silently ignores `body=` whenever a
  /// template is specified, because template mode prefills from
  /// per-field query params whose keys match the template's `id:`s
  /// (`description`, `steps`, `expected`, etc.). Since our `buildBody`
  /// already produces a self-contained Markdown body, dropping the
  /// template lets the full payload reach the form verbatim.
  static Uri buildIssueUrl(ErrorReportPayload p) {
    final base = Uri.parse('${AppConstants.githubRepoUrl}/issues/new');
    return base.replace(queryParameters: <String, String>{
      'labels': _labels,
      'title': buildTitle(p),
      'body': buildBody(p),
    });
  }
}
