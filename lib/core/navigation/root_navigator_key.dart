// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

/// The root [Navigator]'s key, handed to the app's `GoRouter`
/// (`routerProvider`).
///
/// Code mounted **above** the navigator in the widget tree — e.g.
/// `CountrySwitchListener`, which lives in `MaterialApp.router`'s
/// `builder:` callback — has no `Navigator` ancestor in its own
/// `BuildContext`, so `showDialog` there throws (#1971).
///
/// Such code reaches a navigator-bearing context via
/// `rootNavigatorKey.currentState?.overlay?.context`: the overlay sits
/// *below* the navigator, so `Navigator.of` resolves correctly.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRootNavigator');
