// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Libre / F-Droid no-op stub for `sentry_flutter` (#3492, epic #3473).
///
/// Provides the exact Dart surface the app compiles against so
/// `app_initializer.dart` (the `SentryFlutter.init` call) and
/// `pii_scrubber.dart` (`scrubSentryEvent`) build on the libre flavor, while
/// carrying NO native `io.sentry` code. It is never reached at runtime on
/// libre: `SentryFlutter.init` is gated on `!AppFlavor.isLibre` (and there is
/// no baked DSN), so this only needs to COMPILE.
library;

import 'dart:async';

/// The `beforeSend` hook signature — mirrors the real typedef closely enough
/// for the app's `options.beforeSend = (event, hint) => ...` assignment.
typedef BeforeSendCallback = FutureOr<SentryEvent?> Function(
  SentryEvent event,
  Hint hint,
);

/// Opaque hint object passed to [BeforeSendCallback]. Unused by the app.
class Hint {
  const Hint();
}

/// No-op stand-in for `SentryUser` (only assigned `null` by the scrubber).
class SentryUser {
  const SentryUser();
}

/// No-op stand-in for `SentryRequest` (only assigned `null` by the scrubber).
class SentryRequest {
  const SentryRequest();
}

/// Value stand-in for `SentryMessage` — the scrubber reads/writes [formatted].
class SentryMessage {
  SentryMessage(this.formatted);

  String? formatted;
}

/// Value stand-in for `SentryException` — the scrubber writes [value].
class SentryException {
  SentryException({this.value});

  String? value;
}

/// Value stand-in for `Breadcrumb` — the scrubber reads/writes [message].
class Breadcrumb {
  Breadcrumb({this.message});

  String? message;
}

/// Value stand-in for `SentryEvent` — the scrubber mutates these fields.
class SentryEvent {
  SentryEvent();

  SentryUser? user;
  SentryRequest? request;
  SentryMessage? message;
  List<SentryException>? exceptions;
  List<Breadcrumb>? breadcrumbs;
}

/// No-op stand-in for `SentryFlutterOptions` — the app sets these fields inside
/// the `SentryFlutter.init` configure callback.
class SentryFlutterOptions {
  String? dsn;
  double tracesSampleRate = 0;
  String? environment;
  String? release;
  BeforeSendCallback? beforeSend;
}

/// No-op stand-in for `SentryFlutter`. `init` runs the optional [appRunner] and
/// otherwise does nothing — no native SDK, no network, no `io.sentry`.
abstract final class SentryFlutter {
  static Future<void> init(
    FutureOr<void> Function(SentryFlutterOptions options) optionsConfiguration, {
    FutureOr<void> Function()? appRunner,
  }) async {
    // Deliberately does NOT invoke optionsConfiguration — the libre build has
    // no Sentry backend, and running the app's configure callback would touch
    // only stub fields. Run the app runner if one was supplied.
    if (appRunner != null) await appRunner();
  }
}
