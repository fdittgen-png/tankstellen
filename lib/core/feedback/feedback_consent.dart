import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Tri-state consent for the GitHub bad-scan reporter (#952 phase 3).
///
/// `unset` — user has never been asked. The UI must show the
/// [FeedbackConsentDialog] before submitting an issue.
///
/// `granted` — user agreed. Subsequent reports submit silently
/// without re-prompting.
///
/// `denied` — user explicitly opted out. Subsequent reports fall
/// back to the SharePlus path without re-prompting.
enum FeedbackConsentState {
  unset,
  granted,
  denied,
}

/// Persistent storage for [FeedbackConsentState], backed by
/// `shared_preferences` so the choice survives app restarts but is
/// trivial to wipe via the system "Clear app data" affordance.
///
/// The key is versioned (`v1`) so a future schema change can ignore
/// pre-existing values without colliding.
class FeedbackConsent {
  /// Storage key. Versioned so we can introduce a v2 schema later
  /// without coupling to historical values.
  static const String storageKey = 'feedback_github_consent_v1';

  static const String _granted = 'granted';
  static const String _denied = 'denied';
  static const String _unset = 'unset';

  /// Reads the current consent. Defaults to [FeedbackConsentState.unset]
  /// for any unrecognised stored value (forward-compat).
  static Future<FeedbackConsentState> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      switch (raw) {
        case _granted:
          return FeedbackConsentState.granted;
        case _denied:
          return FeedbackConsentState.denied;
        case _unset:
        case null:
        default:
          return FeedbackConsentState.unset;
      }
    } catch (e, st) {
      debugPrint('FeedbackConsent.read failed: $e\n$st');
      return FeedbackConsentState.unset;
    }
  }

  /// Persists the consent. The "later" choice is intentionally not
  /// represented here — the dialog returns without calling [write].
  static Future<void> write(FeedbackConsentState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (state) {
        case FeedbackConsentState.granted:
          await prefs.setString(storageKey, _granted);
          return;
        case FeedbackConsentState.denied:
          await prefs.setString(storageKey, _denied);
          return;
        case FeedbackConsentState.unset:
          await prefs.remove(storageKey);
          return;
      }
    } catch (e, st) {
      debugPrint('FeedbackConsent.write failed: $e\n$st');
    }
  }
}

/// Result of [FeedbackConsentDialog]. Distinct from [FeedbackConsentState]
/// because "later" must NOT mutate persisted state — the dialog will be
/// shown again on the next attempt.
enum FeedbackConsentChoice {
  granted,
  denied,
  later,
}

/// One-time consent dialog asking the user to allow the bad-scan
/// reporter to file a public GitHub issue with the receipt photo and
/// the OCR text. No PII (location, account id) is sent.
///
/// The caller awaits the dialog's `Future<FeedbackConsentChoice?>`:
///   - `granted` → submit the issue.
///   - `denied`  → fall back to SharePlus, persist the denial.
///   - `later`   → fall back to SharePlus, do NOT persist.
///   - `null`    → user dismissed the dialog (back / barrier tap),
///                 treated as `later`.
class FeedbackConsentDialog extends StatelessWidget {
  const FeedbackConsentDialog({super.key});

  /// Convenience: shows the dialog as a modal and returns the user's
  /// choice. The caller is responsible for persisting the result via
  /// [FeedbackConsent.write] when the choice is `granted` or `denied`.
  static Future<FeedbackConsentChoice> show(BuildContext context) async {
    final result = await showDialog<FeedbackConsentChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const FeedbackConsentDialog(),
    );
    return result ?? FeedbackConsentChoice.later;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        l?.feedbackConsentTitle ?? 'Send report to GitHub?',
      ),
      content: Text(
        l?.feedbackConsentBody ??
            'This creates a public ticket on our GitHub repository with '
                'your photo and the OCR text. No personal data (location, '
                'account id) is sent. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(FeedbackConsentChoice.later),
          child: Text(l?.feedbackConsentLater ?? 'Later'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(FeedbackConsentChoice.denied),
          child: Text(l?.feedbackConsentCancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(FeedbackConsentChoice.granted),
          child: Text(l?.feedbackConsentContinue ?? 'Continue'),
        ),
      ],
    );
  }
}
