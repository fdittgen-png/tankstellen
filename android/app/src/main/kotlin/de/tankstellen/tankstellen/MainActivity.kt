package de.tankstellen.tankstellen

import de.tankstellen.tankstellen.autorecord.BackgroundAdapterChannel
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

        // Hands-free auto-record bridge (#1004 phase 2b-1). Same
        // rationale as Obd2ClassicPlugin: the channel is app-internal
        // and never shipped to pub.dev. The Dart side
        // (AndroidBackgroundAdapterListener) talks to this engine via
        // the MethodChannel + EventChannel registered here; the
        // foreground service that the channel starts on demand owns
        // its own GATT client.
        BackgroundAdapterChannel.registerWith(flutterEngine, applicationContext)
    }
}
