// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
package de.tankstellen.tankstellen

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.SystemClock
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android side of the app-internal `tankstellen/live_activity` channel
 * (#3729) — renders the live trip surface as a REAL media session +
 * MediaStyle notification, which is the only path to the system media
 * pill on the lock screen and the shade's media carousel (the RTL2-style
 * card). A plain ongoing notification (#3722/#3724, the Dart-side
 * fallback) can never get that treatment.
 *
 * Contract mirror of `ios/Runner/LiveActivityBridge.swift`:
 *  - `start` / `update` args: {title, body, paused, startedAtEpochMs,
 *    pauseLabel, resumeLabel, stopLabel} — strings arrive pre-localized
 *    from the Dart ARB pipeline; this class is a dumb renderer.
 *  - `end`: releases the session and cancels the notification, so the
 *    pill disappears the moment the recording stops.
 *  - Outbound `tripAction` invocations carry the SAME action ids the
 *    Dart tile uses (`trip_pause` / `trip_resume` / `trip_stop`) — the
 *    controller feeds them into the existing NotificationTapDispatcher
 *    round-trip, so ONE Dart listener serves both tile flavors.
 *
 * PlaybackState mapping: recording = STATE_PLAYING (position ticks from
 * startedAtEpochMs), on-hold = STATE_PAUSED. Android 13+ derives the
 * media controls from these states/actions, not from notification
 * actions — the pre-13 notification actions are still added for older
 * shades. Stop rides a custom action (13+ shows it in the expanded
 * card) plus ACTION_STOP for headset/route stops.
 */
object TripMediaTileChannel {
    private const val CHANNEL_NAME = "tankstellen/live_activity"
    private const val NOTIFICATION_ID = 37290 // #3729
    private const val NOTIFICATION_CHANNEL_ID = "trip_recording_media"
    // System-settings-only label; English literal by the same convention
    // as every other notification channel name in this app.
    private const val NOTIFICATION_CHANNEL_LABEL = "Trip recording controls"

    private const val ACTION_PAUSE = "trip_pause"
    private const val ACTION_RESUME = "trip_resume"
    private const val ACTION_STOP = "trip_stop"

    private var channel: MethodChannel? = null
    private var session: MediaSessionCompat? = null
    private var appContext: Context? = null
    private var artwork: Bitmap? = null

    fun registerWith(engine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "start", "update" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                        show(args)
                        result.success(true)
                    }
                    "end" -> {
                        end()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                // Never-throw contract: a broken tile must never take the
                // recorder down. Report as a plain channel error; the Dart
                // side degrades to the notification fallback.
                result.error("trip_media_tile", t.toString(), null)
            }
        }
    }

    private fun show(args: Map<String, Any?>) {
        val context = appContext ?: return
        val title = args["title"] as? String ?: ""
        val body = args["body"] as? String ?: ""
        val paused = args["paused"] as? Boolean ?: false
        val startedAtEpochMs = (args["startedAtEpochMs"] as? Number)?.toLong()
            ?: System.currentTimeMillis()
        val stopLabel = args["stopLabel"] as? String ?: "Stop"
        val pauseLabel = args["pauseLabel"] as? String ?: "Pause"
        val resumeLabel = args["resumeLabel"] as? String ?: "Resume"

        val s = session ?: MediaSessionCompat(context, "trip_recording").also {
            it.setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() = sendAction(ACTION_RESUME)
                override fun onPause() = sendAction(ACTION_PAUSE)
                override fun onStop() = sendAction(ACTION_STOP)
                override fun onCustomAction(action: String?, extras: android.os.Bundle?) {
                    if (action == ACTION_STOP) sendAction(ACTION_STOP)
                }
            })
            session = it
        }

        val elapsedMs = (System.currentTimeMillis() - startedAtEpochMs).coerceAtLeast(0)
        val state = PlaybackStateCompat.Builder()
            .setActions(
                (if (paused) PlaybackStateCompat.ACTION_PLAY else PlaybackStateCompat.ACTION_PAUSE)
                    or PlaybackStateCompat.ACTION_PLAY_PAUSE
                    or PlaybackStateCompat.ACTION_STOP
            )
            .addCustomAction(
                PlaybackStateCompat.CustomAction.Builder(
                    ACTION_STOP, stopLabel, R.drawable.ic_trip_stop
                ).build()
            )
            .setState(
                if (paused) PlaybackStateCompat.STATE_PAUSED
                else PlaybackStateCompat.STATE_PLAYING,
                elapsedMs,
                if (paused) 0f else 1f,
                SystemClock.elapsedRealtime()
            )
            .build()
        s.setPlaybackState(state)
        s.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, body)
                .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, appIcon(context))
                .build()
        )
        s.isActive = true

        ensureNotificationChannel(context)
        val tapIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        val contentIntent = tapIntent?.let {
            PendingIntent.getActivity(
                context, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        // Pre-Android-13 shades render these notification actions (13+
        // derives controls from the PlaybackState instead). The intents
        // route through the in-process TripMediaActionReceiver — the
        // notification only lives while the app process does (no FGS), so
        // an in-process receiver is always reachable.
        val playPause = if (paused) {
            NotificationCompat.Action(
                android.R.drawable.ic_media_play, resumeLabel,
                actionIntent(context, ACTION_RESUME, 1)
            )
        } else {
            NotificationCompat.Action(
                android.R.drawable.ic_media_pause, pauseLabel,
                actionIntent(context, ACTION_PAUSE, 1)
            )
        }
        val stop = NotificationCompat.Action(
            R.drawable.ic_trip_stop, stopLabel,
            actionIntent(context, ACTION_STOP, 2)
        )

        val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setLargeIcon(appIcon(context))
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setShowWhen(true)
            .setWhen(startedAtEpochMs)
            .addAction(playPause)
            .addAction(stop)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(s.sessionToken)
                    .setShowActionsInCompactView(0, 1)
            )
            .build()
        // POST_NOTIFICATIONS is requested by the existing Dart-side
        // permission flow; if the user declined, notify() is a no-op and
        // the Dart fallback path fails identically — consistent surface.
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    private fun end() {
        appContext?.let { NotificationManagerCompat.from(it).cancel(NOTIFICATION_ID) }
        session?.let {
            it.isActive = false
            it.release()
        }
        session = null
    }

    /** Route one tile action back to Dart. Internal-visible so the
     *  notification-action receiver can call it in-process. */
    internal fun sendAction(id: String) {
        channel?.invokeMethod("tripAction", id)
    }

    private fun actionIntent(
        context: Context,
        actionId: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = android.content.Intent(context, TripMediaActionReceiver::class.java)
            .setAction("de.tankstellen.trip_media.$actionId")
            .putExtra(TripMediaActionReceiver.EXTRA_ACTION, actionId)
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun ensureNotificationChannel(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        if (manager.getNotificationChannel(NOTIFICATION_CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_LABEL,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
        )
    }

    /** Launcher icon as a bitmap — adaptive icons need the draw-to-canvas
     *  path; `BitmapFactory.decodeResource` returns null for them. */
    private fun appIcon(context: Context): Bitmap? {
        artwork?.let { return it }
        return try {
            val drawable = context.packageManager.getApplicationIcon(context.packageName)
            val bmp = Bitmap.createBitmap(
                drawable.intrinsicWidth.coerceAtLeast(1),
                drawable.intrinsicHeight.coerceAtLeast(1),
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            artwork = bmp
            bmp
        } catch (_: Throwable) {
            null
        }
    }
}
