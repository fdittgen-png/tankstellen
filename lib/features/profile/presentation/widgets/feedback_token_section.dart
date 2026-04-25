import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/feedback/github_issue_reporter_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Settings section for managing the optional GitHub PAT used by the
/// bad-scan reporter (#952 phase 3).
///
/// The token is stored under [kGithubFeedbackTokenKey] in
/// [FlutterSecureStorage] (Android Keystore / iOS Keychain). It never
/// leaves the device except in the `Authorization: Bearer …` header
/// of the request to `api.github.com`.
///
/// The UI is intentionally minimal: paste / clear. There is no PAT
/// creation flow — the description deep-links the user to GitHub's
/// own token UI on demand.
class FeedbackTokenSection extends ConsumerStatefulWidget {
  /// Test seam: lets widget tests inject a fake `FlutterSecureStorage`
  /// without touching the platform channel. Production code passes
  /// `null` and the widget constructs `const FlutterSecureStorage()`.
  @visibleForTesting
  final FlutterSecureStorage? storage;

  const FeedbackTokenSection({super.key, this.storage});

  @override
  ConsumerState<FeedbackTokenSection> createState() =>
      _FeedbackTokenSectionState();
}

class _FeedbackTokenSectionState extends ConsumerState<FeedbackTokenSection> {
  bool _hasToken = false;
  bool _loading = true;

  FlutterSecureStorage get _storage =>
      widget.storage ?? const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final value = await _storage.read(key: kGithubFeedbackTokenKey);
      if (!mounted) return;
      setState(() {
        _hasToken = value != null && value.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      debugPrint('FeedbackTokenSection: secure-storage read failed: $e');
      if (!mounted) return;
      setState(() {
        _hasToken = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l?.feedbackTokenDescription ??
                'To automatically open a GitHub ticket from a failed scan, '
                    'paste a GitHub PAT (`public_repo` scope on the tankstellen '
                    'repository). Otherwise manual sharing remains available.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _hasToken ? Icons.check_circle : Icons.cancel_outlined,
                size: 16,
                color: _hasToken ? Colors.green : theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                _loading
                    ? '…'
                    : _hasToken
                        ? (l?.feedbackTokenStatusSet ?? 'Token configured')
                        : (l?.feedbackTokenStatusUnset ?? 'No token'),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (_hasToken)
                TextButton(
                  onPressed: _loading ? null : _clearToken,
                  child: Text(l?.feedbackTokenClear ?? 'Clear'),
                ),
              FilledButton(
                onPressed: _loading ? null : _setToken,
                child: Text(l?.feedbackTokenSet ?? 'Set'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setToken() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const _TokenInputDialog(),
    );

    if (result == null) return;
    final scrubbed = result.trim();
    if (scrubbed.isEmpty) return;

    try {
      await _storage.write(
        key: kGithubFeedbackTokenKey,
        value: scrubbed,
      );
    } catch (e) {
      debugPrint('FeedbackTokenSection: secure-storage write failed: $e');
      return;
    }

    // Invalidate the reporter so the next bad-scan submission picks
    // up the freshly stored PAT instead of the cached null.
    ref.invalidate(githubIssueReporterProvider);
    await _refresh();
  }

  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: kGithubFeedbackTokenKey);
    } catch (e) {
      debugPrint('FeedbackTokenSection: secure-storage delete failed: $e');
    }
    ref.invalidate(githubIssueReporterProvider);
    await _refresh();
  }
}

/// PAT-input dialog. Implemented as a `StatefulWidget` so the
/// `TextEditingController` and `FocusNode` lifecycles are managed by
/// the framework — solves widget-test focus-disposal assertion errors
/// triggered when callers dispose the controller manually right after
/// `Navigator.pop`.
class _TokenInputDialog extends StatefulWidget {
  const _TokenInputDialog();

  @override
  State<_TokenInputDialog> createState() => _TokenInputDialogState();
}

class _TokenInputDialogState extends State<_TokenInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l?.feedbackTokenDialogTitle ?? 'GitHub PAT'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(
          labelText: l?.feedbackTokenFieldLabel ?? 'Personal Access Token',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l?.save ?? 'Save'),
        ),
      ],
    );
  }
}
