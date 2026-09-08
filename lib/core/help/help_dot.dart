// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — the little `?` beside a control. One tap opens the bundled
// guide at the heading that control's anchor names.
//
// It is a plain widget rather than a feature-flagged one: a question
// mark that answers a question is not a feature to switch off, and a
// reader who cannot find the answer stops looking rather than
// complaining.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../navigation/app_routes.dart';

class HelpDot extends StatelessWidget {
  const HelpDot(this.anchor, {super.key});

  /// The object this symbol documents, from `HelpAnchor`.
  final String anchor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: ValueKey('help-dot-$anchor'),
      tooltip: AppLocalizations.of(context).helpOpenGuide,
      visualDensity: VisualDensity.compact,
      iconSize: 17,
      color: scheme.primary.withValues(alpha: .75),
      icon: const Icon(Icons.help_outline),
      onPressed: () => context.push(
        Uri(
          path: RoutePaths.help,
          queryParameters: {'anchor': anchor},
        ).toString(),
      ),
    );
  }
}

/// A section header with the `?` at the end of it, for a control whose
/// row has no free slot for one.
class HelpDotTitle extends StatelessWidget {
  const HelpDotTitle(this.text, this.anchor, {this.style, super.key});

  final String text;
  final String anchor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Flexible(child: Text(text, style: style)),
          HelpDot(anchor),
        ],
      );
}
