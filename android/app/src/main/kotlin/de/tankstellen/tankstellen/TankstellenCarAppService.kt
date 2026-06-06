// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.SessionInfo
import androidx.car.app.validation.HostValidator

/**
 * Android Auto / Automotive car app service for Tankstellen (epic #2946).
 *
 * A POI [CarAppService] that serves a car-optimised list+map UI for nearby fuel
 * stations. It is a BOUND service the Android Auto / Automotive host binds via
 * the `androidx.car.app.category.POI` intent-filter (declared in the `play`
 * source set only) — it never starts itself as a foreground service, so it
 * carries no FOREGROUND_SERVICE permission (#1498).
 *
 * ## Architecture
 * - [CarAppService] creates one [TankstellenCarSession] per host connection.
 * - The session's root is [de.tankstellen.tankstellen.car.MenuScreen]
 *   (Search + Radar), which pushes
 *   [de.tankstellen.tankstellen.car.SearchScreen] /
 *   [de.tankstellen.tankstellen.car.RadarScreen]
 *   (each a `PlaceListMapTemplate` over [de.tankstellen.tankstellen.car.CarStation]).
 * - Data sources (v2 SLICE 1, #2947): the Search screen fetches LIVE through a
 *   headless Flutter engine via [de.tankstellen.tankstellen.car.CarDataBridge]
 *   (created/destroyed with the session lifecycle, no FGS). Radar still renders
 *   the v1 SharedPreferences snapshot the in-app radar wrote (slice 2 wires its
 *   live fetch).
 *
 * ## Limitations
 * - Android Auto templates limit UI to lists + detail views.
 * - The host caps list length on most head units.
 * - No custom rendering (no Canvas; the host draws the POI map).
 */
class TankstellenCarAppService : CarAppService() {

    override fun createHostValidator(): HostValidator {
        // Allow all hosts in debug builds for testing
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        }

        // In release, only allow known Android Auto host packages
        return HostValidator.Builder(applicationContext)
            .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
            .build()
    }

    override fun onCreateSession(sessionInfo: SessionInfo): Session {
        return TankstellenCarSession()
    }
}
