// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session
import de.tankstellen.tankstellen.car.MenuScreen

/**
 * Car session that creates the root screen for Android Auto.
 *
 * v1 (#2948 / epic #2946) — the root is the [MenuScreen] (Search + Radar),
 * which renders the SharedPreferences-fed station lists the Flutter app writes
 * after each in-app search / radar run. The retired [NearbyStationsScreen]
 * (favorites-only `ListTemplate`) is superseded; the live headless-engine
 * bridge is the v2 rewrite (#2947).
 */
class TankstellenCarSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        return MenuScreen(carContext)
    }
}
