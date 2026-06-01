// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_params_provider.dart';

/// #2592 — the three route-planning search params default from the active
/// profile (the same fields the profile-edit sheet writes) and clamp the
/// per-search override to the same ranges as the profile sliders.
class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

ProviderContainer _containerWith(UserProfile? profile) {
  return ProviderContainer(
    overrides: [activeProfileProvider.overrideWith(() => _FixedProfile(profile))],
  );
}

void main() {
  group('RouteSegmentSearchParam (#2592)', () {
    test('defaults to the profile routeSegmentKm', () {
      final c = _containerWith(
        const UserProfile(id: 'p', name: 'P', routeSegmentKm: 120),
      );
      addTearDown(c.dispose);
      expect(c.read(routeSegmentSearchParamProvider), 120);
    });

    test('falls back to 50 when no profile', () {
      final c = _containerWith(null);
      addTearDown(c.dispose);
      expect(c.read(routeSegmentSearchParamProvider), 50.0);
    });

    test('clamps to 50..1000', () {
      final c = _containerWith(const UserProfile(id: 'p', name: 'P'));
      addTearDown(c.dispose);
      final notifier = c.read(routeSegmentSearchParamProvider.notifier);
      notifier.set(10);
      expect(c.read(routeSegmentSearchParamProvider), 50.0);
      notifier.set(5000);
      expect(c.read(routeSegmentSearchParamProvider), 1000.0);
      notifier.set(300);
      expect(c.read(routeSegmentSearchParamProvider), 300.0);
    });
  });

  group('RouteDetourSearchParam (#2592)', () {
    test('defaults to the profile routeDetourBudgetKm', () {
      final c = _containerWith(
        const UserProfile(id: 'p', name: 'P', routeDetourBudgetKm: 12),
      );
      addTearDown(c.dispose);
      expect(c.read(routeDetourSearchParamProvider), 12);
    });

    test('falls back to 5 when no profile', () {
      final c = _containerWith(null);
      addTearDown(c.dispose);
      expect(c.read(routeDetourSearchParamProvider), 5.0);
    });

    test('clamps to 2..25', () {
      final c = _containerWith(const UserProfile(id: 'p', name: 'P'));
      addTearDown(c.dispose);
      final notifier = c.read(routeDetourSearchParamProvider.notifier);
      notifier.set(0);
      expect(c.read(routeDetourSearchParamProvider), 2.0);
      notifier.set(99);
      expect(c.read(routeDetourSearchParamProvider), 25.0);
    });
  });

  group('MinRouteSavingSearchParam (#2592)', () {
    test('defaults to the profile minRouteSavingPerLiter', () {
      final c = _containerWith(
        const UserProfile(id: 'p', name: 'P', minRouteSavingPerLiter: 0.1),
      );
      addTearDown(c.dispose);
      expect(c.read(minRouteSavingSearchParamProvider), 0.1);
    });

    test('falls back to 0 when no profile', () {
      final c = _containerWith(null);
      addTearDown(c.dispose);
      expect(c.read(minRouteSavingSearchParamProvider), 0.0);
    });

    test('clamps to 0..0.30', () {
      final c = _containerWith(const UserProfile(id: 'p', name: 'P'));
      addTearDown(c.dispose);
      final notifier = c.read(minRouteSavingSearchParamProvider.notifier);
      notifier.set(-1);
      expect(c.read(minRouteSavingSearchParamProvider), 0.0);
      notifier.set(1.0);
      expect(c.read(minRouteSavingSearchParamProvider), 0.30);
    });
  });
}
