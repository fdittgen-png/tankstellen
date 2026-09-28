// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/route_origin.dart';

part 'route_origin_status_provider.g.dart';

/// What the "current position" start is doing right now (#4432).
///
/// The start field used to have two states — a coordinate, or a
/// transient "GPS error" snackbar — so a driver waiting for a cold lock
/// saw nothing happen, and one whose permission was refused was told
/// nothing they could act on. This is the third state that was missing:
/// acquiring, or failed for a NAMED reason with its remedy.
@immutable
class RouteOriginStatus {
  const RouteOriginStatus.idle()
      : locating = false,
        failure = null,
        age = Duration.zero;

  const RouteOriginStatus.locating()
      : locating = true,
        failure = null,
        age = Duration.zero;

  const RouteOriginStatus.failed(RouteOriginFailure this.failure,
      {this.age = Duration.zero})
      : locating = false;

  final bool locating;
  final RouteOriginFailure? failure;

  /// For [RouteOriginFailure.staleFix]: how long ago the sample in use
  /// was measured.
  final Duration age;

  bool get isIdle => !locating && failure == null;

  @override
  bool operator ==(Object other) =>
      other is RouteOriginStatus &&
      other.locating == locating &&
      other.failure == failure &&
      other.age == age;

  @override
  int get hashCode => Object.hash(locating, failure, age);
}

/// Screen-scoped: lives while the route form shows it, and never
/// persists — a failure from an earlier visit is not this visit's news.
@riverpod
class RouteOriginStatusController extends _$RouteOriginStatusController {
  @override
  RouteOriginStatus build() => const RouteOriginStatus.idle();

  void locating() => state = const RouteOriginStatus.locating();

  /// Adopt the outcome of one acquisition: a fresh fix clears the
  /// state, anything else names why it is not one.
  void settle(ResolvedRouteOrigin origin) {
    final failure = origin.failure;
    state = failure == null
        ? const RouteOriginStatus.idle()
        : RouteOriginStatus.failed(failure, age: origin.age);
  }

  void clear() => state = const RouteOriginStatus.idle();
}
