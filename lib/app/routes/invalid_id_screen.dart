import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fallback widget shown when a deep link supplies an id that fails
/// [isValidStationId] or otherwise fails to hydrate. Centralised so every
/// route file that builds an id-keyed screen renders the same UX.
Widget invalidIdScreen(BuildContext context, String path) {
  return Scaffold(
    appBar: AppBar(title: const Text('Invalid link')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'The link "$path" is not valid.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Home'),
          ),
        ],
      ),
    ),
  );
}
