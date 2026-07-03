// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_initializer.dart';
import 'app/widgets/animated_splash.dart';

/// App entry point. The cold-start sequence lives in [AppInitializer], which
/// runs the bootstrap → storage → services → optional → runApp phases and
/// hands control to Flutter once the container is wired.
///
/// Before kicking off init we paint a [SplashHost] (#795 phase 2) so the
/// user sees branded motion the moment the native splash fades — the
/// second `runApp` inside `AppInitializer._launch` replaces this root with
/// the real `TankstellenApp` tree once init is done.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // #3272 — bare scope (`missing_provider_scope`); no provider is read
  // pre-init, the real container arrives with the second runApp.
  runApp(const ProviderScope(child: SplashHost()));
  await AppInitializer.run(
    appBuilder: (_) => const TankstellenApp(),
  );
}
