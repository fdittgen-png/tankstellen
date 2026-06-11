// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../l10n/app_localizations.dart';

/// Fallback widget shown when a deep link supplies an id that fails
/// [isValidStationId] or otherwise fails to hydrate. Centralised so every
/// route file that builds an id-keyed screen renders the same UX.
Widget invalidIdScreen(BuildContext context, String path) {
  final l = AppLocalizations.of(context);
  return Scaffold(
    appBar: AppBar(title: Text(l?.invalidLinkTitle ?? 'Invalid link')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l?.invalidLinkBody(path) ?? 'The link "$path" is not valid.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(RoutePaths.search),
            child: Text(l?.home ?? 'Home'),
          ),
        ],
      ),
    ),
  );
}
