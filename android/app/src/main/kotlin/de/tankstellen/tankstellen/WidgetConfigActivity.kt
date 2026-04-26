package de.tankstellen.tankstellen

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.RadioButton
import android.widget.RadioGroup
import org.json.JSONArray

/**
 * Per-widget configure activity (#610). Launched by the framework when the
 * user drops a new widget on the home screen, and again if they tap the
 * widget's "Reconfigure" entry on Android 12+.
 *
 * Scope — phase 2 of #607 (Phase 1 shipped the color-scheme drawables + the
 * Kotlin `getColorScheme`/`drawableForScheme` helpers in #922). This activity
 * persists the user's choice of profile + color scheme under
 * `profile_<appWidgetId>` / `color_<appWidgetId>` in `HomeWidgetPreferences`,
 * then triggers a render so the widget reflects the selection immediately.
 *
 * TEMP: the layout + strings are a minimal placeholder so the feature is
 * functional. Design polish (proper spacing, themed colors, previews) lands
 * in a follow-up PR.
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID

    private lateinit var profileGroup: RadioGroup
    private lateinit var colorGroup: RadioGroup
    private lateinit var variantGroup: RadioGroup

    // profile-id indexed by the RadioButton view id we assigned.
    private val profileIdByViewId = mutableMapOf<Int, String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Required contract: if the user backs out without saving, the
        // framework must NOT place the widget.
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.widget_config_activity)

        profileGroup = findViewById(R.id.widget_config_profile_group)
        colorGroup = findViewById(R.id.widget_config_color_group)
        variantGroup = findViewById(R.id.widget_config_variant_group)

        val prefs = getSharedPreferences(
            StationWidgetRenderer.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        val currentProfile = prefs.getString("profile_$appWidgetId", null)
        val currentColor = StationWidgetRenderer.getColorScheme(this, appWidgetId)
        val currentVariant = StationWidgetRenderer.getVariant(this, appWidgetId)

        populateProfiles(prefs, currentProfile)
        selectColorScheme(currentColor)
        selectVariant(currentVariant)

        findViewById<Button>(R.id.widget_config_save).setOnClickListener {
            onSavePressed()
        }
        findViewById<Button>(R.id.widget_config_cancel).setOnClickListener {
            finish()
        }
    }

    private fun populateProfiles(
        prefs: android.content.SharedPreferences,
        currentProfileId: String?,
    ) {
        val json = prefs.getString("widget_profiles_json", null)
        val parsed: JSONArray = try {
            if (json.isNullOrEmpty()) JSONArray() else JSONArray(json)
        } catch (e: Exception) {
            android.util.Log.d("TankstellenWidget", "config: profiles parse failed: $e")
            JSONArray()
        }

        if (parsed.length() == 0) {
            // No profiles published yet — offer a single "default" entry so
            // the user can still save a color scheme.
            addProfileButton(id = "default", name = "Default", checked = true)
            return
        }

        var hasCheck = false
        for (i in 0 until parsed.length()) {
            val p = parsed.optJSONObject(i) ?: continue
            val id = p.optString("id")
            val name = p.optString("name", id).ifBlank { id }
            if (id.isBlank()) continue
            val isCurrent = currentProfileId != null && currentProfileId == id
            addProfileButton(id = id, name = name, checked = isCurrent)
            if (isCurrent) hasCheck = true
        }
        if (!hasCheck && profileGroup.childCount > 0) {
            (profileGroup.getChildAt(0) as? RadioButton)?.isChecked = true
        }
    }

    private fun addProfileButton(id: String, name: String, checked: Boolean) {
        val rb = RadioButton(this).apply {
            text = name
            this.id = View.generateViewId()
            isChecked = checked
        }
        profileIdByViewId[rb.id] = id
        profileGroup.addView(rb)
    }

    private fun selectColorScheme(scheme: String) {
        val viewId = when (scheme) {
            "light" -> R.id.widget_config_color_light
            "dark" -> R.id.widget_config_color_dark
            "blue" -> R.id.widget_config_color_blue
            "green" -> R.id.widget_config_color_green
            "orange" -> R.id.widget_config_color_orange
            else -> R.id.widget_config_color_system
        }
        colorGroup.check(viewId)
    }

    private fun selectedColorScheme(): String = when (colorGroup.checkedRadioButtonId) {
        R.id.widget_config_color_light -> "light"
        R.id.widget_config_color_dark -> "dark"
        R.id.widget_config_color_blue -> "blue"
        R.id.widget_config_color_green -> "green"
        R.id.widget_config_color_orange -> "orange"
        else -> "system"
    }

    private fun selectVariant(variant: String) {
        val viewId = when (variant) {
            StationWidgetRenderer.VARIANT_PREDICTIVE ->
                R.id.widget_config_variant_predictive
            else -> R.id.widget_config_variant_default
        }
        variantGroup.check(viewId)
    }

    private fun selectedVariant(): String = when (variantGroup.checkedRadioButtonId) {
        R.id.widget_config_variant_predictive ->
            StationWidgetRenderer.VARIANT_PREDICTIVE
        else -> StationWidgetRenderer.VARIANT_DEFAULT
    }

    private fun selectedProfileId(): String? {
        val id = profileGroup.checkedRadioButtonId
        if (id == View.NO_ID) return null
        return profileIdByViewId[id]
    }

    private fun onSavePressed() {
        val profileId = selectedProfileId()
        val colorScheme = selectedColorScheme()
        val variant = selectedVariant()

        val editor = getSharedPreferences(
            StationWidgetRenderer.PREFS_NAME,
            Context.MODE_PRIVATE,
        ).edit()
        if (profileId != null) {
            editor.putString("profile_$appWidgetId", profileId)
        }
        editor.putString("color_$appWidgetId", colorScheme)
        editor.putString("variant_$appWidgetId", variant)
        editor.apply()

        // Render immediately so the user sees the new colors / profile.
        val manager = AppWidgetManager.getInstance(this)
        val views = StationWidgetRenderer.render(
            context = this,
            appWidgetId = appWidgetId,
            defaultMode = StationWidgetRenderer.MODE_FAVORITES,
            providerClass = FuelPriceWidgetProvider::class.java,
        )
        manager.updateAppWidget(appWidgetId, views)

        val result = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, result)
        finish()
    }
}
