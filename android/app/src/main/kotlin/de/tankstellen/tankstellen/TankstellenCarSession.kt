// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import de.tankstellen.tankstellen.car.CarDataBridge
import de.tankstellen.tankstellen.car.CarLocationSource
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
 * FGS-avoidance. Both Search and Radar fetch live through it.
 *
 * ## Live in-car GPS lifecycle (v2 PHASE-3 / slice 4, #2990)
 * The session also owns [CarLocationSource]: started on Session CREATED
 * (which primes the location permission IN-CAR via
 * `CarContext.requestPermissions` when it isn't already granted) and stopped
 * on Session DESTROYED — location runs ONLY while an Auto session is active,
 * still with zero foreground services.
 */
class TankstellenCarSession : Session() {
    init {
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onCreate(owner: LifecycleOwner) {
                // carContext is available once the session is created.
                CarDataBridge.create(carContext)
                CarLocationSource.start(carContext)
            }

            override fun onDestroy(owner: LifecycleOwner) {
                CarLocationSource.stop()
                CarDataBridge.destroy()
            }
        })
    }

    override fun onCreateScreen(intent: Intent): Screen {
        return MenuScreen(carContext)
    }
}
