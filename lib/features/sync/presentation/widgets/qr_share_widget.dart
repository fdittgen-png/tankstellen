import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/sync/sync_provider.dart';

/// Generates a QR code containing the database credentials for sharing.
///
/// Used by database owners to let family/friends join their database.
/// The QR contains `{"url":"...","key":"..."}` which is parsed by the
/// setup screen's QR scanner.
class QrShareWidget extends ConsumerWidget {
  const QrShareWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    if (!syncState.isConfigured || syncState.supabaseUrl == null || syncState.supabaseAnonKey == null) {
      return const SizedBox.shrink();
    }

    final qrData = jsonEncode({
      'url': syncState.supabaseUrl,
      'key': syncState.supabaseAnonKey,
    });

    final theme = Theme.of(context);

    return Column(
      children: [
        Text('Share your database', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Others can scan this QR code to connect',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
            Clipboard.setData(ClipboardData(text: qrData));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connection data copied')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy as text'),
        ),
      ],
    );
  }
}
