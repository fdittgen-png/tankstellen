// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../alerts/presentation/widgets/alerts_body.dart';

/// The "Price alerts" tab of the Favorites screen.
///
/// #3905 — renders the alerts page content ([AlertsBody]: stats strip,
/// station-alert section, zone-alert section, last-checked footer)
/// DIRECTLY. Before, the tab showed its own duplicate empty state plus a
/// "Radius alerts & statistics" card (#1701) that opened a second,
/// near-identical screen — the zone-alert form was two taps away and the
/// same hint appeared twice. The standalone `/alerts` route still exists
/// for deep links and renders the same body.
class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) => const AlertsBody();
}
