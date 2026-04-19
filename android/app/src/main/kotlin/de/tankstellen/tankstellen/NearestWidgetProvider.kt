package de.tankstellen.tankstellen

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Android home screen widget showing nearest stations with fuel prices and distance.
 *
 * Data is stored in SharedPreferences by the Flutter side (via home_widget package)
 * and read here for rendering. The background WorkManager task refreshes prices
 * and recalculates distances hourly.
 */
class NearestWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_OPEN_APP -> {
                val launchIntent =
                    context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(launchIntent)
                }
            }
            ACTION_REFRESH -> {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(
                    android.content.ComponentName(context, NearestWidgetProvider::class.java)
                )
                for (id in ids) updateWidget(context, mgr, id)
                val launchIntent =
                    context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(launchIntent)
                }
            }
        }
    }

    companion object {
        private const val ACTION_OPEN_APP = "de.tankstellen.fuelprices.OPEN_NEAREST"
        private const val ACTION_REFRESH = "de.tankstellen.fuelprices.REFRESH_NEAREST"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stationsJson = prefs.getString("nearest_json", "[]") ?: "[]"
            val updatedAt = prefs.getString("nearest_updated_at", null)

            val views = RemoteViews(context.packageName, R.layout.nearest_widget_layout)

            // Set up tap-to-open-app on the whole widget
            val openIntent = Intent(context, NearestWidgetProvider::class.java).apply {
                action = ACTION_OPEN_APP
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 1, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.nearest_widget_root, pendingIntent)

            // Refresh button — re-renders from cache and opens the app.
            val refreshIntent = Intent(context, NearestWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            }
            val refreshPending = PendingIntent.getBroadcast(
                context, 2, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.nearest_refresh, refreshPending)

            // Parse stations
            val stations = try {
                JSONArray(stationsJson)
            } catch (e: Exception) {
                JSONArray()
            }

            if (stations.length() == 0) {
                views.setViewVisibility(R.id.nearest_empty, View.VISIBLE)
                views.setViewVisibility(R.id.nearest_station_list, View.GONE)
            } else {
                views.setViewVisibility(R.id.nearest_empty, View.GONE)
                views.setViewVisibility(R.id.nearest_station_list, View.VISIBLE)

                // Clear existing rows
                views.removeAllViews(R.id.nearest_station_list)

                // Add up to 3 station rows
                val count = minOf(stations.length(), 3)
                for (i in 0 until count) {
                    val station = stations.getJSONObject(i)
                    val row = RemoteViews(context.packageName, R.layout.nearest_station_row)

                    // Brand / name
                    row.setTextViewText(
                        R.id.nearest_station_name,
                        station.optString("brand",
                            station.optString("name", "Station")),
                    )

                    // Distance
                    val distanceKm = station.optDouble("distance_km", Double.NaN)
                    row.setTextViewText(
                        R.id.nearest_station_distance,
                        if (!distanceKm.isNaN())
                            String.format(Locale.getDefault(), "%.1f km", distanceKm)
                        else "--",
                    )

                    // Address
                    val street = station.optString("street", "")
                    val postCode = station.optString("postCode", "")
                    val place = station.optString("place", "")
                    val addressParts = mutableListOf<String>()
                    if (street.isNotBlank()) addressParts.add(street)
                    val cityLine = listOf(postCode, place).filter { it.isNotBlank() }.joinToString(" ")
                    if (cityLine.isNotBlank()) addressParts.add(cityLine)
                    row.setTextViewText(R.id.nearest_station_address, addressParts.joinToString(", "))

                    // Main fuel price — profile-preferred, fallback to e10
                    val currency = station.optString("currency", "")
                    val prefCode = station.optString("preferred_fuel_code", "")
                    val prefPrice = station.optDouble("preferred_fuel_price", Double.NaN)
                    val fallbackE10 = station.optDouble("e10", Double.NaN)
                    val (label, price) = when {
                        prefCode.isNotBlank() && !prefPrice.isNaN() ->
                            prefCode.uppercase(Locale.getDefault()) to prefPrice
                        !fallbackE10.isNaN() -> "E10" to fallbackE10
                        else -> "" to Double.NaN
                    }
                    row.setTextViewText(R.id.nearest_station_main_label, label)
                    row.setTextViewText(
                        R.id.nearest_station_main_price,
                        if (!price.isNaN())
                            String.format(Locale.getDefault(), "%.3f %s", price, currency).trim()
                        else "--",
                    )

                    val isOpen = station.optBoolean("isOpen", false)
                    row.setTextViewText(
                        R.id.nearest_station_status,
                        if (isOpen) "● Open" else "○ Closed",
                    )

                    views.addView(R.id.nearest_station_list, row)
                }
            }

            // Update timestamp
            if (updatedAt != null) {
                try {
                    val fmt = SimpleDateFormat("HH:mm", Locale.getDefault())
                    views.setTextViewText(R.id.nearest_updated_at, fmt.format(Date()))
                } catch (e: Exception) {
                    views.setTextViewText(R.id.nearest_updated_at, "")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
