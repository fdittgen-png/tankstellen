// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
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
    private const val VARIANT_KEY_PREFIX = "variant_"
    private const val DEFAULT_COLOR_SCHEME = "system"
    private const val DEFAULT_VARIANT = "default"

    const val MODE_FAVORITES = "favorites"
    const val MODE_NEAREST = "nearest"

    /** Default content variant: only the current price line. */
    const val VARIANT_DEFAULT = "default"

    /**
     * Predictive content variant (#1121). Adds a compact "best time" line
     * under each row when the Dart side wrote `predictive_*` fields into
     * the station JSON. Renderer falls back to [VARIANT_DEFAULT] for any
     * row that lacks those fields.
     */
    const val VARIANT_PREDICTIVE = "predictive"

    const val ACTION_TOGGLE_MODE = "de.tankstellen.fuelprices.TOGGLE_MODE"
    const val ACTION_OPEN_APP = "de.tankstellen.fuelprices.OPEN_APP"
    // #2600 — ACTION_REFRESH re-introduced as a BROADCAST to the
    // provider (NOT an Activity PendingIntent). Tapping the refresh icon
    // must not launch the app: the provider's onReceive enqueues the
    // existing `widgetRefreshScan` WorkManager task (#2412) which
    // re-fetches prices and re-renders the widget in place. The old #1801
    // rationale (a broadcast can't `startActivity` on Android 10+) is
    // moot — refresh deliberately does not start an activity at all.
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
        // #2106 — global `default_color` (set by Flutter
        // `home_widget_service` from the active profile's
        // `widgetColorScheme`) is the new source of truth. The
        // per-widget `color_<id>` value is kept as a fallback so the
        // Reconfigure activity's existing overrides keep working for
        // users who tuned a single widget.
        val perWidget = prefs.getString("$COLOR_KEY_PREFIX$appWidgetId", null)
        if (perWidget != null) return perWidget
        return prefs.getString("default_color", DEFAULT_COLOR_SCHEME)
            ?: DEFAULT_COLOR_SCHEME
    }

    /**
     * Read the persisted content variant for [appWidgetId] (#1121). Defaults
     * to [VARIANT_DEFAULT] on first render so existing widgets keep their
     * original look until the user opts into predictive nudges via the
     * configure activity.
     *
     * Valid identifiers (kept in sync with
     * `lib/features/widget/data/widget_variants.dart`): `default`,
     * `predictive`.
     */
    fun getVariant(context: Context, appWidgetId: Int): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // #2106 — see [getColorScheme]; mirrored fallback chain
        // (per-widget override wins, global default fills the gap).
        val perWidget = prefs.getString("$VARIANT_KEY_PREFIX$appWidgetId", null)
        if (perWidget != null) return perWidget
        return prefs.getString("default_variant", DEFAULT_VARIANT)
            ?: DEFAULT_VARIANT
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
        // #1121 — content variant (default vs predictive). Resolved once
        // per render and forwarded to `buildRow`; rows without predictive
        // fields automatically fall back to the default appearance.
        val variant = getVariant(context, appWidgetId)

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

        // Refresh icon (#2600) — a BROADCAST to this provider's
        // ACTION_REFRESH. onReceive enqueues the existing on-device
        // `widgetRefreshScan` WorkManager task (#2412) which re-fetches
        // prices and re-renders the widget in place. NO app launch: the
        // old #1801 / #1961 Activity PendingIntent + `tankstellenwidget://
        // refresh` marker URI cold-launched the app to refresh, which the
        // user reported as a bug. The provider dims the glyph (alpha) while
        // the scan is in flight; the next render restores it to full alpha.
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
        // Restore the refresh glyph to full opacity on every fresh render —
        // the transient "refreshing…" dim set by onReceive is cleared once
        // the scan posts new data and the widget re-renders.
        views.setInt(R.id.widget_refresh, "setImageAlpha", 255)

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
                val row = buildRow(context, station, appWidgetId, i, profileId, variant)
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

    /**
     * #2600 — transient "refreshing…" affordance. Dims the refresh glyph
     * to ~40% opacity via a lightweight `partiallyUpdateAppWidget` so the
     * user gets immediate feedback that the in-place refresh broadcast was
     * received, without rebuilding the whole RemoteViews tree (which would
     * need a fresh data read). The dim is cleared on the next full [render]
     * (it always resets the alpha to 255) once the scan posts new prices.
     *
     * A partial update that targets only `widget_refresh` is safe even
     * when the layout was last committed by a different render pass — the
     * RemoteViews here only carries the one alpha mutation.
     */
    fun setRefreshing(context: Context, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.station_widget_layout)
            views.setInt(R.id.widget_refresh, "setImageAlpha", 100)
            AppWidgetManager.getInstance(context)
                .partiallyUpdateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            // Best-effort visual only — never let the affordance block the
            // scan enqueue that actually refreshes the data.
            android.util.Log.d("TankstellenWidget", "setRefreshing failed: $e")
        }
    }

    private fun buildRow(
        context: Context,
        station: JSONObject,
        appWidgetId: Int,
        index: Int,
        profileId: String? = null,
        variant: String = VARIANT_DEFAULT,
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
        // #2600 — colour-code the price (the redesign's primary anchor).
        // The Dart builder flags the cheapest priced row in the rendered
        // set with `isCheapest` (sorted by distance, so the cheapest is
        // not necessarily first). Cheapest → green; every other priced row
        // → the high-contrast default. Both `@color` resources have a
        // values-night/ variant so the hue stays legible on dark launchers.
        val isCheapest = station.optBoolean("isCheapest", false)
        val priceColorRes =
            if (isCheapest) R.color.widget_price_cheap
            else R.color.widget_price_default
        row.setTextColor(
            R.id.station_main_price,
            getColorCompat(context, priceColorRes),
        )

        val isOpen = station.optBoolean("isOpen", false)
        row.setTextViewText(
            R.id.station_status,
            if (isOpen) "● Open" else "○ Closed",
        )
        // #2600 — the status pill carried no explicit colour, so it
        // inherited the launcher theme's default text colour, which could
        // be near-invisible on the dark-navy widget background. Pin it:
        // open → the cheap green, closed → the dim secondary.
        row.setTextColor(
            R.id.station_status,
            getColorCompat(
                context,
                if (isOpen) R.color.widget_price_cheap
                else R.color.widget_text_secondary,
            ),
        )

        // #1121 — predictive nudge line. Render only when the user selected
        // the predictive variant AND the Dart side attached `predictive_*`
        // fields. Either condition false → fall back to the default
        // appearance (the layout's default visibility is GONE).
        val predictiveLabel = station.optString("predictive_best_label", "")
        val predictiveBestPrice =
            station.optDouble("predictive_best_price", Double.NaN)
        if (
            variant == VARIANT_PREDICTIVE &&
            predictiveLabel.isNotBlank() &&
            !predictiveBestPrice.isNaN()
        ) {
            val nowText = if (!prefPrice.isNaN()) {
                String.format(Locale.getDefault(), "%.3f %s", prefPrice, currency).trim()
            } else if (!fallbackE10.isNaN()) {
                String.format(Locale.getDefault(), "%.3f %s", fallbackE10, currency).trim()
            } else {
                ""
            }
            val bestText =
                String.format(Locale.getDefault(), "%.3f %s", predictiveBestPrice, currency).trim()
            // Format: "now €1.84/L · best Tue 6-8 PM ~€1.79/L".
            // The predictor's `recommendation` already contains the day +
            // hour-range phrasing.
            val composed = if (nowText.isNotBlank()) {
                "now $nowText · $predictiveLabel ~$bestText"
            } else {
                "$predictiveLabel ~$bestText"
            }
            row.setTextViewText(R.id.station_predictive, composed)
            row.setViewVisibility(R.id.station_predictive, View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.station_predictive, View.GONE)
        }

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
            // #1961 — build the URI with Uri.Builder so the station id is
            // percent-encoded. String-interpolating it raw let an id
            // containing `&`, `+`, `%`, `#` or a space corrupt the query
            // — the Flutter parser then opened the wrong station or none.
            val uri = Uri.Builder()
                .scheme("tankstellenwidget")
                .authority("station")
                .appendQueryParameter("id", stationId)
                .build()
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

    /**
     * #2600 — resolve a `@color` resource to an ARGB int for
     * [RemoteViews.setTextColor]. Goes through [ContextCompat] so the
     * correct values/ vs values-night/ variant is picked up from the
     * launcher's current UI mode.
     */
    private fun getColorCompat(context: Context, colorRes: Int): Int =
        ContextCompat.getColor(context, colorRes)

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
            // #2157 — explicit SINGLE_TOP makes the singleTop manifest
            // launchMode semantics explicit at the intent level too;
            // some OEM ROMs were dropping warm-tap onNewIntent without
            // it (Stream listener never fired → no navigation).
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK
                    or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    or Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
