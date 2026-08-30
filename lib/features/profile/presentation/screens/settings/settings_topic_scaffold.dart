// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../core/widgets/section_header.dart';

/// Shared chrome of every Settings topic screen (#3884): a
/// [PageScaffold] whose body is a plain scrolling list of the existing
/// section widgets, each under a [SettingsGroupHeader] — expanded, no
/// collapsed foldables. Same compact padding the root used (#530).
class SettingsTopicScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsTopicScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          ...children,
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }
}

/// Plain group heading inside a topic screen — the #2521 shape (primary-
/// tinted 16 dp leading icon, zero outer padding) with an optional
/// trailing widget (a `ScopeBadge`) and a 4 dp gap below.
class SettingsGroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SettingsGroupHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SectionHeader(
        leadingIcon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Muted explanatory paragraph used for "this is elsewhere" hints on
/// topic screens (consumption off, voice announcements off, delete-all
/// lives in the Privacy Dashboard, …).
class SettingsHintText extends StatelessWidget {
  final String text;

  const SettingsHintText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
