package de.tankstellen.tankstellen

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

/**
 * Car session that creates the root screen for Android Auto.
 */
class TankstellenCarSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        return NearbyStationsScreen(carContext)
    }
}
