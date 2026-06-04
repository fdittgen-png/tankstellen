// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../error/exceptions.dart';

/// Error-classification helpers for [StationServiceChain] (#2842).
///
/// Extracted verbatim from the chain so the orchestration file stays under the
/// 400-line cap. Behaviour is unchanged: the chain still routes transience by
/// [FailureKind] (#2255) and still preserves the pre-#2255 classification for
/// exceptions constructed without an explicit kind.

/// Resolve the [FailureKind] for [e], preserving the pre-#2255 classification
/// for exceptions that predate typed kinds (or were constructed without one).
/// When [ApiException.kind] is explicitly set (anything but
/// [FailureKind.unknown]) it wins; otherwise we fall back to the legacy
/// signals — HTTP status (5xx → network, matching the old transient-5xx
/// rule) then the Dio-type message prefix stamped by `throwApiException`.
FailureKind effectiveFailureKind(ApiException e) {
  if (e.kind != FailureKind.unknown) return e.kind;
  final code = e.statusCode;
  if (code != null) {
    final fromStatus = failureKindFromStatus(code);
    if (fromStatus != FailureKind.unknown) return fromStatus;
  }
  final msg = e.message;
  if (msg.startsWith('connectionTimeout') ||
      msg.startsWith('receiveTimeout') ||
      msg.startsWith('sendTimeout')) {
    return FailureKind.timeout;
  }
  if (msg.startsWith('connectionError')) return FailureKind.network;
  return FailureKind.unknown;
}

/// `true` when [e] is a transient failure a single short retry could
/// plausibly recover from. Routes on [FailureKind] (#2255) instead of
/// sniffing the English [ApiException.message] prefix:
/// network / timeout / rateLimited → transient;
/// auth / notFound / parse / unsupported / unknown → terminal.
bool isTransientFailure(ApiException e) {
  switch (effectiveFailureKind(e)) {
    case FailureKind.network:
    case FailureKind.timeout:
    case FailureKind.rateLimited:
      return true;
    case FailureKind.auth:
    case FailureKind.notFound:
    case FailureKind.parse:
    case FailureKind.unsupported:
    case FailureKind.unknown:
      return false;
  }
}
