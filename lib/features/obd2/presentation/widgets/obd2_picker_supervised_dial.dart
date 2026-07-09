// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/error_logger.dart';
import '../../data/obd2_link_supervisor.dart';
import '../../data/obd2_service.dart';
import '../../providers/obd2_reconnect_provider.dart';

/// #3527 — the adapter picker's supervised one-shot dial.
///
/// The picker connects to a user-chosen device, so there is no
/// reuse-live-first here: [Obd2LinkSupervisor.connectWith] tears down any
/// old link and makes the dialed service THE supervised one, joining the
/// supervisor's single-flight machinery (there is no second dial path).
/// When the reconnect graph can't resolve (widget tests without the obd2
/// overrides) the dial degrades to a bare direct call — the legacy path.
Future<Obd2Service?> obd2PickerSupervisedDial(
  ProviderContainer container,
  Obd2LinkDialer dial,
) async {
  Obd2LinkSupervisor? sup;
  try {
    sup = container.read(obd2ReconnectProvider.notifier).supervisor;
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
      'where': 'obd2AdapterPicker: supervisor resolve failed',
    }));
  }
  return sup != null ? await sup.connectWith(dial) : await dial();
}
