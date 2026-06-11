// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/telemetry/models/error_trace.dart';
import '../../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../l10n/app_localizations.dart';

/// Raw, in-app viewer of the buffered error traces (#2248).
///
/// Reads straight off [traceStorageProvider] — the same buffer the
/// privacy dashboard / Developer tools export action serialises — and
/// renders each trace as an expandable tile (type + message + timestamp,
/// expanding to the stack trace). Read-only; clearing / exporting live on
/// the Developer tools screen that pushes this one. Gated behind
/// Developer / Debug mode by its only entry point.
class ErrorLogViewerScreen extends ConsumerWidget {
  const ErrorLogViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final traces = ref.watch(traceStorageProvider).getAll();

    return PageScaffold(
      title: l.developerToolsViewErrorLog,
      bodyPadding: EdgeInsets.zero,
      body: traces.isEmpty
          ? Center(
              child: Text(
                l.developerToolsErrorLogEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: traces.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _TraceTile(trace: traces[index]),
            ),
    );
  }
}

class _TraceTile extends StatelessWidget {
  final ErrorTrace trace;

  const _TraceTile({required this.trace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      key: Key('errorTrace_${trace.id}'),
      dense: true,
      leading: const Icon(Icons.error_outline, size: 20),
      title: Text(
        trace.errorType,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${trace.timestamp.toIso8601String()} — ${trace.errorMessage}',
        style: theme.textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            trace.stackTrace,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace', // i18n-ignore: font family name
            ),
          ),
        ),
      ],
    );
  }
}
