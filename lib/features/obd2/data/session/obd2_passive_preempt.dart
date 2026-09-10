// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// #3244 — close-by-identity teardown for [Obd2ConnectionService].
///
/// #4035 (epic #4032) — the rule itself lives in [Obd2DirectChannelSlot]
/// now, which owns the pointer privately; this stays as the call site's
/// name so the connect paths read the same as before.
Future<void> _teardownDirectChannel(
  Obd2ConnectionService svc,
  ElmByteChannel channel,
) =>
    svc._directChannel.releaseOwn(channel);
