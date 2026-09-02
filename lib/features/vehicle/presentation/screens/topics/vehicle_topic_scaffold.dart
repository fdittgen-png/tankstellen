// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/widgets/page_scaffold.dart';

/// Shared chrome of every Edit-vehicle topic screen (#3900): a
/// [PageScaffold] whose body is a plain scrolling list of the existing
/// section cards — the same shape the Settings topic screens took in
/// #3884, kept inside the vehicle feature so the boundary gate stays
/// clean.
class VehicleTopicScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const VehicleTopicScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 16),
        children: children,
      ),
    );
  }
}
