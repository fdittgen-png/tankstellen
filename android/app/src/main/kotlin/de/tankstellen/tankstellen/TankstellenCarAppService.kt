package de.tankstellen.tankstellen

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.SessionInfo
import androidx.car.app.validation.HostValidator

/**
 * Android Auto car app service for Tankstellen.
 *
 * Provides a car-optimized UI for browsing nearby fuel stations,
 * viewing prices, and navigating to stations. Communicates with
 * the Flutter app via MethodChannel through [CarDataBridge].
 *
 * ## Architecture
 * - CarAppService creates Sessions (one per connection)
 * - Each Session creates a NearbyScreen as the root
 * - Screens use CarDataBridge to fetch data from the Flutter/Dart side
 * - Navigation actions launch Google Maps / Waze via Intent
 *
 * ## Limitations
 * - Android Auto templates limit UI to lists + detail views
 * - Max 6 items per list on most head units
 * - No custom rendering (no Canvas, no Maps in POI template)
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
