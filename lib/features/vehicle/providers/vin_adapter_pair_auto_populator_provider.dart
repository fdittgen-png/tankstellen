// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/error_logger.dart';
import '../../obd2/api.dart';
import '../data/vin_adapter_pair_auto_populator.dart';
import 'vin_decoder_provider.dart';

/// Provider for the post-pair VIN auto-population orchestrator (#1399).
///
/// Exposed as a plain [Provider] (not `@riverpod`) so widget tests can
/// override it with a fake [VinAdapterPairAutoPopulator] subclass — the
/// edit-vehicle-screen tests pre-canned a fake [VinReaderService] this
/// way and we follow the same shape.
final vinAdapterPairAutoPopulatorProvider =
    Provider<VinAdapterPairAutoPopulator>(
  (ref) {
    // #3527 — resolve THE link supervisor; degrade to null (legacy
    // direct dial) when the reconnect graph can't resolve (widget-test
    // scope without the obd2 overrides).
    Obd2LinkSupervisor? linkSupervisor;
    try {
      linkSupervisor = ref.read(obd2ReconnectProvider.notifier).supervisor;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'vinAdapterPairAutoPopulatorProvider: supervisor resolve '
            'failed',
      }));
    }
    return VinAdapterPairAutoPopulator(
      connection: ref.watch(obd2ConnectionProvider),
      decoder: ref.watch(consentAwareVinDecoderProvider),
      linkSupervisor: linkSupervisor,
    );
  },
);
