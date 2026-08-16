// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
package de.tankstellen.tankstellen

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Pre-Android-13 notification-action relay for the trip media tile
 * (#3729). Runs in the app process (the tile only exists while the
 * process does — no foreground service), so it can hand the action id
 * straight to [TripMediaTileChannel] without any IPC detour. Not
 * exported: only our own PendingIntents target it.
 */
class TripMediaActionReceiver : BroadcastReceiver() {
    companion object {
        const val EXTRA_ACTION = "trip_media_action"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(EXTRA_ACTION) ?: return
        TripMediaTileChannel.sendAction(id)
    }
}
