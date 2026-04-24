package de.tankstellen.tankstellen

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Shared rendering for both home-screen widgets (#713 continuation).
 *
 * Each widget provider owns its own Android receiver class (so existing
 * pinned widgets survive upgrades), but both now render the same two
 * modes — favorites or nearest — and the user can flip between them
 * with the mode-toggle button in the header. The choice is persisted
 * per appWidgetId in SharedPreferences under `widget_mode_<id>`.
 *
 * Station rows deep-link into the app via a `tankstellenwidget://station?id=<id>`
 * URI. The home_widget plugin catches the launch action, forwards the URI
 * to Flutter, and the router navigates to the station-detail screen.
 */
object StationWidgetRenderer {

    const val PREFS_NAME = "HomeWidgetPreferences"
    private const val MODE_KEY_PREFIX = "widget_mode_"
    private const val COLOR_KEY_PREFIX = "color_"
    private const val DEFAULT_COLOR_SCHEME = "system"

    const val MODE_FAVORITES = "favorites"
    const val MODE_NEAREST = "nearest"

    const val ACTION_TOGGLE_MODE = "de.tankstellen.fuelprices.TOGGLE_MODE"
    const val ACTION_OPEN_APP = "de.tankstellen.fuelprices.OPEN_APP"
    const val ACTION_REFRESH = "de.tankstellen.fuelprices.REFRESH"

    const val EXTRA_APP_WIDGET_ID = "appWidgetId"

    /**
     * Read the persisted mode for [appWidgetId], defaulting to [defaultMode]
     * (so the favorites provider starts in favorites mode and the nearest
     * provider starts in nearest mode on first render).
     */
    fun getMode(context: Context, appWidgetId: Int, defaultMode: String): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$MODE_KEY_PREFIX$appWidgetId", defaultMode) ?: defaultMode
    }

    /**
     * Read the persisted color scheme for [appWidgetId]. Phase 1 of #607
     * — the configure activity that writes this key lands in #610; for
     * now the key is simply absent and we fall back to "system", which
     * maps to the existing drawable/widget_background.xml pair.
     *
     * Valid identifiers (kept in sync with
     * lib/features/widget/data/widget_color_schemes.dart and
     * android/app/src/main/res/values/widget_color_schemes.xml):
     * `system`, `light`, `dark`, `blue`, `green`, `orange`.
     */
    fun getColorScheme(context: Context, appWidgetId: Int): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$COLOR_KEY_PREFIX$appWidgetId", DEFAULT_COLOR_SCHEME)
            ?: DEFAULT_COLOR_SCHEME
    }

    /**
     * Map a color-scheme identifier to its drawable resource. `system`,
     * `light`, `dark`, and any unknown value fall back to the default
     * widget_background drawable (which already provides light/dark
     * variants via the drawable-night/ folder).
     */
    fun drawableForScheme(scheme: String): Int = when (scheme) {
        "blue" -> R.drawable.widget_background_blue
        "green" -> R.drawable.widget_background_green
        "orange" -> R.drawable.widget_background_orange
        else -> R.drawable.widget_background
    }

    /** Flip the persisted mode for [appWidgetId] and return the new value. */
    fun toggleMode(context: Context, appWidgetId: Int, currentDefault: String): String {
        val current = getMode(context, appWidgetId, currentDefault)
        val next = if (current == MODE_FAVORITES) MODE_NEAREST else MODE_FAVORITES
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString("$MODE_KEY_PREFIX$appWidgetId", next)
            .apply()
        return next
    }

    /**
     * Render the widget for the given [appWidgetId] using the persisted
     * mode (or [defaultMode] if not yet set). [providerClass] is passed so
     * toggle + refresh intents target the correct provider — both
     * FuelPriceWidgetProvider and NearestWidgetProvider use this renderer.
     */
    fun render(
        context: Context,
        appWidgetId: Int,
        defaultMode: String,
        providerClass: Class<*>,
    ): RemoteViews {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val mode = getMode(context, appWidgetId, defaultMode)
        // #610 — per-widget profile id, when the configure activity has
        // persisted one. Read here (not inside buildRow) so one render pass
        // resolves it once; the value is purely diagnostic for Kotlin —
        // the Dart side has already filtered the JSON to the right profile.
        val profileId = prefs.getString("profile_$appWidgetId", null)

        val stationsJson: String
        val updatedAt: String?
        val emptyText: Int
        val nameRes: Int
        // #609 — nearest-widget flags the data source: 'no_gps' when the
        // app has never obtained a fix, 'no_network' when the search API
        // is unreachable and no prior payload exists, 'isStale' when we
        // are showing a previous successful payload as a fallback.
        var emptyReason = ""
        var isStale = false
        if (mode == MODE_FAVORITES) {
            stationsJson = prefs.getString("stations_json", "[]") ?: "[]"
            updatedAt = prefs.getString("updated_at", null)
            emptyText = R.string.widget_empty
            nameRes = R.string.widget_name
        } else {
            stationsJson = prefs.getString("nearest_json", "[]") ?: "[]"
            updatedAt = prefs.getString("nearest_updated_at", null)
            emptyText = R.string.nearest_widget_empty
            nameRes = R.string.nearest_widget_name
            emptyReason = prefs.getString("nearest_empty_reason", "") ?: ""
            isStale = prefs.getBoolean("nearest_is_stale", false)
        }

        val views = RemoteViews(context.packageName, R.layout.station_widget_layout)

        // Header — title reflects active mode.
        views.setTextViewText(R.id.widget_title, context.getString(nameRes))

        // Mode-toggle icon: a star for favorites, a pin for nearest.
        views.setImageViewResource(
            R.id.widget_mode_toggle,
            if (mode == MODE_FAVORITES) android.R.drawable.btn_star_big_on
            else android.R.drawable.ic_menu_mylocation,
        )
        views.setOnClickPendingIntent(
            R.id.widget_mode_toggle,
            buildBroadcast(
                context,
                providerClass,
                ACTION_TOGGLE_MODE,
                requestCode = appWidgetId * 10 + 1,
                extraAppWidgetId = appWidgetId,
            ),
        )

        // Refresh icon — re-renders from cache and opens the app so the
        // Flutter side can pull fresh prices.
        views.setOnClickPendingIntent(
            R.id.widget_refresh,
            buildBroadcast(
                context,
                providerClass,
                ACTION_REFRESH,
                requestCode = appWidgetId * 10 + 2,
                extraAppWidgetId = appWidgetId,
            ),
        )

        // Tapping the widget chrome (not a row) opens the app with no
        // station context so the user lands on whatever their usual
        // landing screen is.
        views.setOnClickPendingIntent(
            R.id.widget_root,
            buildActivity(context, uri = null, requestCode = appWidgetId * 10 + 3),
        )

        // #607 phase 1 — apply the per-widget color scheme on top of
        // the layout-XML default background. The configure activity
        // that persists `color_<appWidgetId>` ships in #610; until then
        // getColorScheme() returns "system", which maps back to the
        // existing widget_background drawable.
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            drawableForScheme(getColorScheme(context, appWidgetId)),
        )

        val stations = try {
            JSONArray(stationsJson)
        } catch (e: Exception) {
            JSONArray()
        }

        if (stations.length() == 0) {
            // #609 — surface a concrete hint when the list is empty because
            // we don't know the user's location yet (no GPS fix). Falls
            // back to the generic localised empty string otherwise.
            val emptyString = when (emptyReason) {
                "no_gps" -> "Turn on location in the app to see nearby stations"
                "no_network" -> context.getString(emptyText)
                else -> context.getString(emptyText)
            }
            views.setTextViewText(R.id.widget_empty, emptyString)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            views.setViewVisibility(R.id.station_list, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_empty, View.GONE)
            views.setViewVisibility(R.id.station_list, View.VISIBLE)
            views.removeAllViews(R.id.station_list)

            val count = minOf(stations.length(), 3)
            for (i in 0 until count) {
                val station = stations.getJSONObject(i)
                val row = buildRow(context, station, appWidgetId, i, profileId)
                views.addView(R.id.station_list, row)
            }
        }

        if (updatedAt != null) {
            try {
                val fmt = SimpleDateFormat("HH:mm", Locale.getDefault())
                // #609 — prefix a stale dot when we're showing a prior
                // payload (network outage fallback). Mirrors the "cache"
                // freshness hint the app shows in the search list.
                val stamp = fmt.format(Date())
                views.setTextViewText(
                    R.id.widget_updated_at,
                    if (isStale) "• $stamp" else stamp,
                )
            } catch (e: Exception) {
                views.setTextViewText(R.id.widget_updated_at, "")
            }
        } else {
            views.setTextViewText(R.id.widget_updated_at, "")
        }

        return views
    }

    private fun buildRow(
        context: Context,
        station: JSONObject,
        appWidgetId: Int,
        index: Int,
        profileId: String? = null,
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.widget_station_row)

        row.setTextViewText(
            R.id.station_name,
            station.optString("brand", station.optString("name", "Station")),
        )

        // #609 — the real-search payload writes `distanceKm`; the legacy
        // favorites payload still uses `distance_km`. Support both so the
        // Kotlin widget survives either data producer.
        val distanceKm = station.optDouble(
            "distanceKm",
            station.optDouble("distance_km", Double.NaN),
        )
        if (!distanceKm.isNaN()) {
            row.setTextViewText(
                R.id.station_distance,
                String.format(Locale.getDefault(), "%.1f km", distanceKm),
            )
            row.setViewVisibility(R.id.station_distance, View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.station_distance, View.GONE)
        }

        val street = station.optString("street", "")
        val postCode = station.optString("postCode", "")
        val place = station.optString("place", "")
        val addressParts = mutableListOf<String>()
        if (street.isNotBlank()) addressParts.add(street)
        val cityLine = listOf(postCode, place)
            .filter { it.isNotBlank() }
            .joinToString(" ")
        if (cityLine.isNotBlank()) addressParts.add(cityLine)
        row.setTextViewText(R.id.station_address, addressParts.joinToString(", "))

        val currency = station.optString("currency", "")
        val prefCode = station.optString("preferred_fuel_code", "")
        val prefPrice = station.optDouble("preferred_fuel_price", Double.NaN)
        val fallbackE10 = station.optDouble("e10", Double.NaN)
        // #609 — when the Flutter builder sent a pre-formatted price
        // (nearest real-search payload), prefer that over the raw double
        // so decimals + currency match the search-results list exactly.
        val formattedPrice = station.optString("priceFormatted", "")
        val (label, priceText) = when {
            prefCode.isNotBlank() && formattedPrice.isNotBlank() ->
                prefCode.uppercase(Locale.getDefault()) to
                    "$formattedPrice $currency".trim()
            prefCode.isNotBlank() && !prefPrice.isNaN() ->
                prefCode.uppercase(Locale.getDefault()) to
                    String.format(Locale.getDefault(), "%.3f %s", prefPrice, currency).trim()
            !fallbackE10.isNaN() -> "E10" to
                String.format(Locale.getDefault(), "%.3f %s", fallbackE10, currency).trim()
            else -> "" to "--"
        }
        row.setTextViewText(R.id.station_main_label, label)
        row.setTextViewText(R.id.station_main_price, priceText)

        val isOpen = station.optBoolean("isOpen", false)
        row.setTextViewText(
            R.id.station_status,
            if (isOpen) "● Open" else "○ Closed",
        )

        // Tap the row → open the station detail screen. The id comes from
        // the JSON produced by HomeWidgetService.
        val stationId = station.optString("id", "")
        // #753 diagnostic — one log per bound row so `adb logcat -s
        // TankstellenWidget` during repro shows exactly which id was
        // wired to which visual row. No control-flow change.
        android.util.Log.d(
            "TankstellenWidget",
            "buildRow widgetId=$appWidgetId index=$index id=$stationId brand=${station.optString("brand", "")} profile=${profileId ?: "active"}",
        )
        if (stationId.isNotBlank()) {
            val uri = Uri.parse("tankstellenwidget://station?id=$stationId")
            row.setOnClickPendingIntent(
                R.id.station_row_root,
                buildActivity(
                    context,
                    uri = uri,
                    requestCode = appWidgetId * 100 + index,
                ),
            )
        }

        return row
    }

    private fun buildBroadcast(
        context: Context,
        providerClass: Class<*>,
        action: String,
        requestCode: Int,
        extraAppWidgetId: Int,
    ): PendingIntent {
        val intent = Intent(context, providerClass).apply {
            this.action = action
            putExtra(EXTRA_APP_WIDGET_ID, extraAppWidgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Build a PendingIntent that launches MainActivity with [uri]. Uses
     * HomeWidgetLaunchIntent's well-known action so the home_widget
     * Flutter plugin catches the URI and forwards it as a
     * `widgetClicked` stream event + `initiallyLaunchedFromHomeWidget`
     * value on cold start.
     */
    private fun buildActivity(
        context: Context,
        uri: Uri?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            data = uri
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
