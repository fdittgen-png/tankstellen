// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import de.tankstellen.tankstellen.car.CarDataBridge
import de.tankstellen.tankstellen.car.MenuScreen

/**
 * Car session that creates the root screen for Android Auto.
 *
 * The root is the [MenuScreen] (Search + Radar), which pushes the Search /
 * Radar list screens.
 *
 * ## Live data bridge lifecycle (v2 SLICE 1, #2947 / epic #2946)
 * The session owns the headless [CarDataBridge] engine lifecycle: it is created
 * on Session CREATED and destroyed (engine destroyed + evicted from the cache)
 * on Session DESTROYED, via a [DefaultLifecycleObserver] on the session
 * lifecycle. The engine therefore lives ONLY for the duration of the bound car
 * connection — never in a started / foreground service — preserving the #1498
 * FGS-avoidance. The Search screen fetches live through it; Radar stays on the
 * v1 SharedPreferences snapshot this slice (slice 2 wires its live fetch).
 */
class TankstellenCarSession : Session() {
    init {
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onCreate(owner: LifecycleOwner) {
                // carContext is available once the session is created.
                CarDataBridge.create(carContext)
            }

            override fun onDestroy(owner: LifecycleOwner) {
                CarDataBridge.destroy()
            }
        })
    }

    override fun onCreateScreen(intent: Intent): Screen {
        return MenuScreen(carContext)
    }
}
