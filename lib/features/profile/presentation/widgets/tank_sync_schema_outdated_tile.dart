// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sync/schema_drift_notice.dart';
import '../../../../core/sync/schema_verifier.dart';
import '../../../../l10n/app_localizations.dart';

/// #3560 — the "self-host schema outdated" warning tile in the TankSync
/// settings section.
///
/// The outdated-schema flag used to render only inside the sync WIZARD —
/// a screen nobody reopens after setup — while every sync run silently
/// degraded (and, before #3560, ERROR-logged). This tile is the ambient
/// surface: zero-height until either signal fires, then an amber warning
/// row that opens the wizard (which renders the update SQL + per-table
/// status).
///
/// Two independent signals, either sufficient:
///  * [SchemaDriftNotice] — a sync run hit the drift THIS session
///    (server rejected a column/table), live via its ValueNotifier;
///  * [SchemaVerifier.isSchemaOutdated] — the recorded `tanksync_meta`
///    version is behind this build's expected version (probed once per
///    tile mount; cheap select, cached errors degrade to false).
class TankSyncSchemaOutdatedTile extends StatefulWidget {
  const TankSyncSchemaOutdatedTile({super.key});

  @override
  State<TankSyncSchemaOutdatedTile> createState() =>
      _TankSyncSchemaOutdatedTileState();
}

class _TankSyncSchemaOutdatedTileState
    extends State<TankSyncSchemaOutdatedTile> {
  late final Future<bool> _verifierOutdated;

  @override
  void initState() {
    super.initState();
    _verifierOutdated = SchemaVerifier.isSchemaOutdated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _verifierOutdated,
      builder: (context, verifier) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: SchemaDriftNotice.instance.tables,
          builder: (context, drifted, _) {
            final outdated = (verifier.data ?? false) || drifted.isNotEmpty;
            if (!outdated) return const SizedBox.shrink();
            final l = AppLocalizations.of(context);
            final theme = Theme.of(context);
            return ListTile(
              key: const Key('tankSyncSchemaOutdatedTile'),
              leading: Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(l.tankSyncSchemaOutdatedTitle),
              subtitle: Text(l.tankSyncSchemaOutdatedSubtitle),
              onTap: () => context.push(RoutePaths.syncSetup),
            );
          },
        );
      },
    );
  }
}
