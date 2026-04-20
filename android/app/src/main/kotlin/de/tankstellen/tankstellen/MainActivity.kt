package de.tankstellen.tankstellen

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the in-repo OBD2 Classic BT plugin (#763). Placed
        // here rather than a separate FlutterPlugin class to keep the
        // Android module free of extra Gradle artefacts; the plugin is
        // app-internal and never shipped to pub.dev.
        Obd2ClassicPlugin.registerWith(flutterEngine, applicationContext)
    }
}
