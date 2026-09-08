// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — the guide, offline, opened at the exact object the reader
// tapped a `?` beside.
//
// Two ways in. With an `anchor`, the screen scrolls to the heading that
// anchor names in the reader's language — an exact answer. Without one,
// it opens at the top. There is deliberately no third mode: a fuzzy
// text match that lands near the answer is worse than the top of the
// guide, because it looks like it worked.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/help_providers.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({this.anchor, super.key});

  /// The object to open at, from `HelpAnchor`. Null opens the top.
  final String? anchor;

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _toc = TocController();
  bool _jumped = false;

  /// Scroll to the heading [anchor] names. Runs once: a rebuild while
  /// the reader is scrolling must not yank them back.
  void _jump(Map<String, String> anchors) {
    if (_jumped || widget.anchor == null) return;
    final heading = anchors[widget.anchor];
    if (heading == null || heading.isEmpty) return;
    final index = _toc.tocList.indexWhere(
      (t) => t.node.build().toPlainText().trim() == heading,
    );
    if (index < 0) return;
    _jumped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toc.jumpToIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final document = ref.watch(helpDocumentProvider(language));
    final anchors = ref.watch(helpAnchorsProvider(language)).value;
    if (anchors != null) _jump(anchors);

    return PageScaffold(
      title: l10n.helpTitle,
      bodyPadding: EdgeInsets.zero,
      body: document.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // The guide is a bundled asset: it cannot be missing unless the
        // build is broken, so this says which asset rather than
        // apologising.
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.helpUnavailable(helpAssetFor(language))),
          ),
        ),
        data: (markdown) => MarkdownWidget(
          data: markdown,
          tocController: _toc,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        ),
      ),
    );
  }
}
