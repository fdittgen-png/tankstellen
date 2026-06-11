// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/sync/trip_shares_sync.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/logging/error_logger.dart';

/// Hook for handing a freshly-minted share link to the OS share sheet
/// (#2240). Production uses `SharePlus.instance.share`; widget tests
/// substitute a fake via [debugTripShareLinkSinkOverride] to assert the
/// outgoing link text without launching the OS share sheet. Mirrors the
/// seam in `obd2_breadcrumb_overlay.dart`.
typedef TripShareLinkSink = Future<void> Function(ShareParams params);

/// Test-only override for the link share sink.
@visibleForTesting
TripShareLinkSink? debugTripShareLinkSinkOverride;

/// Test-only override for the wire layer used by the share sheet, so a
/// widget test can drive the create / list / revoke flows without a
/// live Supabase client.
@visibleForTesting
TripShareWire? debugTripShareWireOverride;

/// The minimal wire surface the share sheet depends on — defaults to
/// the real [TripSharesSync] static methods. Extracted to an injectable
/// object so widget tests can fake each call deterministically.
class TripShareWire {
  const TripShareWire();

  Future<TripShareResult> shareWithEmail(String tripId, String email) =>
      TripSharesSync.shareWithEmail(tripId, email);

  Future<String?> createShareLink(String tripId) =>
      TripSharesSync.createShareLink(tripId);

  Future<List<TripShare>> listSharesForTrip(String tripId) =>
      TripSharesSync.listSharesForTrip(tripId);

  Future<void> revoke(String shareId) => TripSharesSync.revoke(shareId);
}

/// Open the cross-account trip-sharing sheet (#2240) for [tripId].
Future<void> showTripShareSheet(BuildContext context, String tripId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => TripShareSheet(tripId: tripId),
  );
}

/// Bottom sheet that lets the user share a recorded trip with another
/// TankSync account — either by email (direct account-to-account) or by
/// minting a claim link — and revoke existing shares (#2240).
class TripShareSheet extends StatefulWidget {
  final String tripId;

  const TripShareSheet({super.key, required this.tripId});

  @override
  State<TripShareSheet> createState() => _TripShareSheetState();
}

class _TripShareSheetState extends State<TripShareSheet> {
  final _emailController = TextEditingController();
  TripShareWire get _wire =>
      debugTripShareWireOverride ?? const TripShareWire();

  bool _busy = false;
  List<TripShare> _shares = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reloadShares());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _reloadShares() async {
    final shares = await _wire.listSharesForTrip(widget.tripId);
    if (!mounted) return;
    setState(() => _shares = shares);
  }

  Future<void> _onShareEmail(AppLocalizations l) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _busy) return;
    setState(() => _busy = true);
    final result = await _wire.shareWithEmail(widget.tripId, email);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case TripShareResult.shared:
        _emailController.clear();
        SnackBarHelper.showSuccess(context, l.tripShareSuccess);
        await _reloadShares();
      case TripShareResult.recipientNotFound:
        SnackBarHelper.showError(context, l.tripShareRecipientNotFound);
      case TripShareResult.notAuthenticated:
      case TripShareResult.failed:
        SnackBarHelper.showError(context, l.tripShareError);
    }
  }

  Future<void> _onCreateLink(AppLocalizations l) async {
    if (_busy) return;
    setState(() => _busy = true);
    final token = await _wire.createShareLink(widget.tripId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (token == null) {
      SnackBarHelper.showError(context, l.tripShareError);
      return;
    }
    // The deep link the recipient taps to claim the share. The host is
    // the app's universal-link domain; the claim route reads `token`.
    final link =
        'https://sparkilo.app/share/trip?token=$token'; // i18n-ignore: URL
    final sink =
        debugTripShareLinkSinkOverride ??
        (params) => SharePlus.instance.share(params).then((_) {});
    try {
      await sink(ShareParams(text: link));
    } catch (e, st) {
      unawaited(
        errorLogger.log(
          ErrorLayer.ui,
          e,
          st,
          context: const {'where': 'TripShareSheet share link'},
        ),
      );
    }
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, l.tripShareLinkCreated);
    await _reloadShares();
  }

  Future<void> _onRevoke(AppLocalizations l, TripShare share) async {
    await _wire.revoke(share.id);
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, l.tripShareRevoked);
    await _reloadShares();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.tripShareSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l.tripShareSheetSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('trip_share_email_field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.tripShareEmailLabel,
                hintText: l.tripShareEmailHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => unawaited(_onShareEmail(l)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('trip_share_send_button'),
                    onPressed: _busy ? null : () => unawaited(_onShareEmail(l)),
                    icon: const Icon(Icons.send),
                    label: Text(l.tripShareSendButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('trip_share_create_link_button'),
                    onPressed: _busy ? null : () => unawaited(_onCreateLink(l)),
                    icon: const Icon(Icons.link),
                    label: Text(l.tripShareCreateLinkButton),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.tripShareExistingTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (_shares.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.tripShareExistingEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._shares.map(
                (s) => _ShareRow(
                  key: Key('trip_share_row_${s.id}'),
                  share: s,
                  l: l,
                  onRevoke: () => unawaited(_onRevoke(l, s)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final TripShare share;
  final AppLocalizations l;
  final VoidCallback onRevoke;

  const _ShareRow({
    super.key,
    required this.share,
    required this.l,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final isLink = share.sharedWithId == null && share.shareToken != null;
    final label = isLink
        ? (l.tripShareLinkRecipient)
        : (l.tripShareDirectRecipient);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isLink ? Icons.link : Icons.person_outline),
      title: Text(label),
      trailing: IconButton(
        key: Key('trip_share_revoke_${share.id}'),
        icon: const Icon(Icons.close),
        tooltip: l.tripShareRevokeTooltip,
        onPressed: onRevoke,
      ),
    );
  }
}
