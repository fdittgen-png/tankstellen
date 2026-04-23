import 'package:flutter/widgets.dart';

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
  runApp(const SplashHost());
  await AppInitializer.run(
    appBuilder: (_) => const TankstellenApp(),
  );
}
