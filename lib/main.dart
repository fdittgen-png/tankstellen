import 'app/app.dart';
import 'app/app_initializer.dart';

/// App entry point. The cold-start sequence lives in [AppInitializer], which
/// runs the bootstrap → storage → services → optional → runApp phases and
/// hands control to Flutter once the container is wired.
Future<void> main() async {
  await AppInitializer.run(
    appBuilder: (_) => const TankstellenApp(),
  );
}
