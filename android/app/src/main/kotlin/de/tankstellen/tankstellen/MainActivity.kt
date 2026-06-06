// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import de.tankstellen.tankstellen.autorecord.BackgroundAdapterChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * Picture-in-Picture bridge (#1884). Lets the Dart trip-recording
     * screen drop the app into a floating PiP tile — manually via a
     * minimise affordance, or automatically when the user leaves the
     * app mid-recording. The channel is app-internal; PiP is inherently
     * Activity-bound, so — unlike [Obd2ClassicPlugin] /
     * [BackgroundAdapterChannel], which are context-only `object`s —
     * this handler lives on the Activity itself.
     */
    private var pipChannel: MethodChannel? = null

    /**
     * Whether [onUserLeaveHint] should auto-enter PiP. The Dart side
     * flips this true while a trip is recording and the recording
     * screen is foreground, false otherwise — so leaving the app from
     * an unrelated screen never shrinks the wrong UI into the tile.
     */
    private var autoEnterPip = false

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

        // Public file-export bridge (#2014). Routes exports to the
        // device's MediaStore.Downloads collection so the user can
        // find them via Files / any file manager — the previous
        // app-private save target was invisible.
        PublicFileExporterChannel.registerWith(flutterEngine, applicationContext)

        // GMS-free inbound share-intent receiver (#2735). Same app-internal
        // channel pattern as the bridges above — replaces the third-party
        // share_handler plugin so the F-Droid build pulls no extra share
        // dependency that could drag in Play Services. Register BEFORE
        // replaying the launch intent below so a cold-launch SEND is cached
        // for the Dart getInitialShare probe.
        ShareIntentChannel.registerWith(flutterEngine, applicationContext)
        // Replay the intent that launched this activity — a cold-launch SEND
        // (the user picked Sparkilo from another app's share sheet) arrives
        // as the launch intent, not via onNewIntent.
        ShareIntentChannel.handleIntent(intent)

        // Picture-in-Picture bridge (#1884).
        val pip = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PIP_CHANNEL,
        )
        pip.setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> result.success(enterPip())
                "setAutoEnter" -> {
                    autoEnterPip = call.arguments as? Boolean ?: false
                    result.success(null)
                }
                "bringToFront" -> result.success(bringToFront())
                else -> result.notImplemented()
            }
        }
        pipChannel = pip
    }

    /**
     * Fires when the user leaves the activity (Home / Recents). When a
     * trip is recording — and the recording screen has opted in via
     * `setAutoEnter` — drop into PiP instead of going fully background,
     * mirroring Google Maps' navigation tile.
     */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoEnterPip) enterPip()
    }

    /**
     * Relays PiP enter/exit to Dart so [TripRecordingScreen] can swap
     * between its full layout and the compact glanceable tile.
     */
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    /**
     * Enter PiP with a wide tile aspect ratio. No-op (returns false) on
     * API < 26, where PiP is unavailable — the app simply stays
     * foreground, and the Dart side treats a false result as "PiP not
     * entered". Wrapped because [enterPictureInPictureMode] can throw
     * [IllegalStateException] when the activity is in a state that
     * forbids the transition.
     */
    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(2, 1))
                .build()
            enterPictureInPictureMode(params)
        } catch (e: IllegalStateException) {
            false
        }
    }

    /**
     * Bring the app back to the foreground in full screen (#2964). Tapping
     * the body of the floating PiP tile calls this — the user expects a tap
     * on the little window to restore the full Sparkilo app, mirroring how
     * Google Maps' navigation tile expands.
     *
     * Re-launches THIS activity via the package launch intent with
     * `REORDER_TO_FRONT | NEW_TASK | SINGLE_TOP`, which reorders the
     * EXISTING task to the front rather than cold-starting a fresh instance
     * — so the live recording / engine state is preserved. Because the
     * activity is `singleTop` with `taskAffinity=""`, the OS routes this
     * through [onNewIntent] on the running instance and leaves PiP, restoring
     * the full window.
     *
     * Wrapped in a best-effort try: a failed reorder just leaves the user in
     * PiP (they can still use the system expand control), never crashes.
     * Returns false when the launch intent can't be resolved or the start
     * throws — the Dart side treats that as "not restored".
     */
    private fun bringToFront(): Boolean {
        return try {
            val launch = packageManager.getLaunchIntentForPackage(packageName)
                ?: return false
            launch.addFlags(
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            startActivity(launch)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Forwards new intents to `getIntent()` so the `home_widget` plugin
     * (and any other plugin that reads the current launch intent on
     * demand) sees the URI from the latest widget tap rather than the
     * one that originally cold-started the activity.
     *
     * Without `setIntent(intent)` the `home_widget` plugin's
     * `widgetClicked` stream still fires via its NewIntent listener,
     * but warm-click probes that fall back to
     * `activity?.intent?.data` (e.g. some side-channel diagnostics)
     * keep returning stale data. Calling `setIntent` keeps the two
     * paths consistent and matches the home_widget README's
     * recommended host-side wiring.
     */
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        // #2735 — a warm-share SEND (app already running, the user picked
        // Sparkilo from another app's share sheet) arrives here on this
        // singleTop activity. Forward it to the GMS-free receiver, which
        // emits it on the EventChannel the Dart ShareReceiptListener
        // subscribes to. A non-SEND intent (widget deep-link, etc.) is a
        // no-op for the receiver and falls through unchanged.
        ShareIntentChannel.handleIntent(intent)
        super.onNewIntent(intent)
    }

    companion object {
        private const val PIP_CHANNEL = "tankstellen/pip"
    }
}
