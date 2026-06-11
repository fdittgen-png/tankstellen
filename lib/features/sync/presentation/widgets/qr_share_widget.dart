// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Generates a QR code containing the database credentials for sharing.
///
/// Used by database owners to let family/friends join their database.
/// The QR contains `{"url":"...","key":"..."}` which is parsed by the
/// setup screen's QR scanner.
///
/// When the sharing user has an **email account** (#3080), the payload also
/// carries `"email":"..."` so the scanning device can *adopt* this identity
/// (join the same account) instead of only connecting to the database. The
/// email key is **omitted** for anonymous users, so a legacy (email-less) QR
/// still parses on every reader and a new QR stays backward-compatible.
class QrShareWidget extends ConsumerWidget {
  const QrShareWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    if (!syncState.isConfigured ||
        syncState.supabaseUrl == null ||
        syncState.supabaseAnonKey == null) {
      return const SizedBox.shrink();
    }

    final qrData = jsonEncode({
      'url': syncState.supabaseUrl,
      'key': syncState.supabaseAnonKey,
      // Only present for an email account — anonymous users omit it so the
      // payload stays identical to the legacy url+key shape (#3080).
      if (syncState.hasEmail) 'email': syncState.userEmail,
    });

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        Text(l.qrShareTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          l.qrShareSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(data: qrData, version: QrVersions.auto, size: 200),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: qrData)));
            SnackBarHelper.show(
              context,
              AppLocalizations.of(context).connectionDataCopied,
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: Text(l.qrShareCopyAsText),
        ),
      ],
    );
  }
}
