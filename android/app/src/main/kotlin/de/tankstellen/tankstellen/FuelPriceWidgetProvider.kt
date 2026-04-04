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
 * Android home screen widget showing favorite station fuel prices.
 *
 * Data is stored in SharedPreferences by the Flutter side (via home_widget package)
 * and read here for rendering. The background WorkManager task refreshes prices
 * hourly and triggers widget updates.
 */
class FuelPriceWidgetProvider : AppWidgetProvider() {

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
        // Handle tap → open app
        if (intent.action == ACTION_OPEN_APP) {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            }
        }
    }

    companion object {
        private const val ACTION_OPEN_APP = "de.tankstellen.fuelprices.OPEN_APP"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stationsJson = prefs.getString("stations_json", "[]") ?: "[]"
            val updatedAt = prefs.getString("updated_at", null)

            val views = RemoteViews(context.packageName, R.layout.fuel_widget_layout)

            // Set up tap-to-open-app on the whole widget
            val openIntent = Intent(context, FuelPriceWidgetProvider::class.java).apply {
                action = ACTION_OPEN_APP
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Parse stations
            val stations = try {
                JSONArray(stationsJson)
            } catch (e: Exception) {
                JSONArray()
            }

            if (stations.length() == 0) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setViewVisibility(R.id.station_list, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setViewVisibility(R.id.station_list, View.VISIBLE)

                // Clear existing rows
                views.removeAllViews(R.id.station_list)

                // Add up to 3 station rows
                val count = minOf(stations.length(), 3)
                for (i in 0 until count) {
                    val station = stations.getJSONObject(i)
                    val row = RemoteViews(context.packageName, R.layout.widget_station_row)

                    row.setTextViewText(R.id.station_name, station.optString("name", "Station"))

                    val e10 = station.optDouble("e10", Double.NaN)
                    val diesel = station.optDouble("diesel", Double.NaN)

                    row.setTextViewText(
                        R.id.station_e10,
                        if (!e10.isNaN()) String.format("%.3f", e10) else "--"
                    )
                    row.setTextViewText(
                        R.id.station_diesel,
                        if (!diesel.isNaN()) String.format("%.3f", diesel) else "--"
                    )

                    views.addView(R.id.station_list, row)
                }
            }

            // Update timestamp
            if (updatedAt != null) {
                try {
                    val fmt = SimpleDateFormat("HH:mm", Locale.getDefault())
                    views.setTextViewText(R.id.widget_updated_at, fmt.format(Date()))
                } catch (e: Exception) {
                    views.setTextViewText(R.id.widget_updated_at, "")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
