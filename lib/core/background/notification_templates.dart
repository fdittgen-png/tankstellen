// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:ui' as ui;

import '../../l10n/app_localizations.dart';
import '../country/country_config.dart';

/// #2306 — localized notification copy resolved IN THE MAIN ISOLATE and
/// handed to the WorkManager background isolate.
///
/// ## Why this exists
/// The background price-refresh task runs in an OS-spawned isolate with
/// **no `BuildContext`**, so it cannot call `AppLocalizations.of(context)`.
/// Reading `Platform.localeName` in the isolate is also wrong: it reflects
/// the *device* locale, not the in-app language the user picked (a French
/// user on a German phone would get German alerts).
///
/// The fix: the main isolate — which knows the active in-app locale —
/// resolves the ARB notification templates ahead of time and persists
/// them through the same Hive settings channel the isolate already uses
/// for everything else (API key, favourites, alerts). The isolate reads
/// the templates back and only interpolates the runtime values (station
/// name, price, fuel grade) it computes locally.
///
/// Templates keep their `{placeholder}` tokens verbatim; interpolation is
/// a literal string replace so it works without `intl` message lookups in
/// the isolate.
class BackgroundNotificationTemplates {
  /// `{station} - {fuelType}` — per-station price-alert notification title.
  final String priceAlertTitle;

  /// `{price} {currency} (target: {target} {currency})` — per-station body.
  final String priceAlertBody;

  /// `{fuelLabel} dropped at nearby stations` — velocity-drop title.
  final String velocityTitle;

  /// `{count} stations dropped by up to {cents}¢ in the last hour` — body.
  final String velocityBody;

  /// `{label}: {count} stations ≤ {threshold} {currency}` — radius title.
  final String radiusGroupedTitle;

  /// `+ {count} more` — trailing line of the radius body when truncated.
  final String radiusGroupedMore;

  /// Default currency symbol — the euro — used when a render call does not
  /// supply a per-alert currency (the fallback / legacy path).
  ///
  /// #2864 — the BG scan now spans every country, so the currency is no longer
  /// a single market value: it is resolved **per alert** from the alert's
  /// country (`CountryConfig.byCode(code).currencySymbol`) and passed to each
  /// render call. This field stays as the safe default (euro) for when no
  /// country resolves, so DE / EUR-zone behaviour is byte-identical.
  final String currencySymbol;

  const BackgroundNotificationTemplates({
    required this.priceAlertTitle,
    required this.priceAlertBody,
    required this.velocityTitle,
    required this.velocityBody,
    required this.radiusGroupedTitle,
    required this.radiusGroupedMore,
    required this.currencySymbol,
  });

  /// Hive settings key under which the JSON blob is stored.
  static const storageKey = 'bg_notification_templates';

  /// The euro sign — the only currency the BG isolate's Tankerkönig
  /// scope touches today. // i18n-ignore: currency symbol, not prose.
  static const _euro = '€';

  /// Build the templates from a resolved [AppLocalizations] instance.
  ///
  /// Call this in the MAIN isolate where the active locale is known
  /// (see [resolveForActiveLocale]).
  factory BackgroundNotificationTemplates.fromL10n(AppLocalizations l) {
    return BackgroundNotificationTemplates(
      priceAlertTitle: l.priceAlertNotificationTitle('{station}', '{fuelType}'),
      priceAlertBody:
          l.priceAlertNotificationBody('{price}', '{currency}', '{target}'),
      velocityTitle: l.velocityAlertNotificationTitle('{fuelLabel}'),
      velocityBody: l.velocityAlertNotificationBody('{count}', '{cents}'),
      radiusGroupedTitle: l.radiusAlertGroupedTitle(
          '{label}', '{count}', '{threshold}', '{currency}'),
      radiusGroupedMore: l.radiusAlertGroupedMore('{count}'),
      currencySymbol: _euro,
    );
  }

  /// Resolve templates for [languageCode] (e.g. the active in-app
  /// language). Falls back to the platform locale, then English, mirroring
  /// the resolution order Flutter's `Localizations` would apply.
  ///
  /// `lookupAppLocalizations` is a pure synchronous constructor — it needs
  /// no widget binding — so this is safe to call from any isolate.
  factory BackgroundNotificationTemplates.resolveForLanguage(
      String? languageCode) {
    final code = (languageCode == null || languageCode.isEmpty)
        ? ui.PlatformDispatcher.instance.locale.languageCode
        : languageCode;
    AppLocalizations l;
    try {
      l = lookupAppLocalizations(ui.Locale(code));
    } catch (_) {
      l = lookupAppLocalizations(const ui.Locale('en'));
    }
    return BackgroundNotificationTemplates.fromL10n(l);
  }

  Map<String, dynamic> toJson() => {
        'priceAlertTitle': priceAlertTitle,
        'priceAlertBody': priceAlertBody,
        'velocityTitle': velocityTitle,
        'velocityBody': velocityBody,
        'radiusGroupedTitle': radiusGroupedTitle,
        'radiusGroupedMore': radiusGroupedMore,
        'currencySymbol': currencySymbol,
      };

  String encode() => jsonEncode(toJson());

  /// Decode a previously [encode]d blob. Returns `null` when the blob is
  /// missing or malformed so callers can fall back to live resolution.
  static BackgroundNotificationTemplates? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return BackgroundNotificationTemplates(
        priceAlertTitle: map['priceAlertTitle'] as String,
        priceAlertBody: map['priceAlertBody'] as String,
        velocityTitle: map['velocityTitle'] as String,
        velocityBody: map['velocityBody'] as String,
        radiusGroupedTitle: map['radiusGroupedTitle'] as String,
        radiusGroupedMore: map['radiusGroupedMore'] as String,
        currencySymbol: map['currencySymbol'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Rendering helpers (run in the background isolate) ──────────────

  /// Per-station price-alert title: `<station> - <fuelGrade>`.
  String renderPriceAlertTitle({
    required String station,
    required String fuelType,
  }) =>
      _fill(priceAlertTitle, {'station': station, 'fuelType': fuelType});

  /// Per-station price-alert body: current price + the user's target, both
  /// with the alert's currency symbol.
  ///
  /// #2864 — [currency] is the per-alert symbol resolved from the alert's
  /// country; it defaults to [currencySymbol] (euro) when the caller has no
  /// country to resolve.
  String renderPriceAlertBody({
    required String price,
    required String target,
    String? currency,
  }) =>
      _fill(priceAlertBody, {
        'price': price,
        'currency': currency ?? currencySymbol,
        'target': target,
      });

  /// Velocity-drop title.
  String renderVelocityTitle({required String fuelLabel}) =>
      _fill(velocityTitle, {'fuelLabel': fuelLabel});

  /// Velocity-drop body.
  String renderVelocityBody({required int count, required int cents}) =>
      _fill(velocityBody, {'count': '$count', 'cents': '$cents'});

  /// Radius-alert grouped title.
  ///
  /// #2864 — [currency] is the per-alert symbol resolved from the radius
  /// centre's country; defaults to [currencySymbol] (euro) when unresolved.
  String renderRadiusTitle({
    required String label,
    required int count,
    required String threshold,
    String? currency,
  }) =>
      _fill(radiusGroupedTitle, {
        'label': label,
        'count': '$count',
        'threshold': threshold,
        'currency': currency ?? currencySymbol,
      });

  /// Trailing `+ N more` line of the radius body.
  String renderRadiusMore({required int count}) =>
      _fill(radiusGroupedMore, {'count': '$count'});

  /// Resolve the currency symbol for [countryCode] from its [CountryConfig]
  /// (#2864), falling back to this template's default ([currencySymbol], euro)
  /// when the code is null or unregistered.
  ///
  /// This is the one place the BG render paths turn a derived alert country
  /// into a currency symbol, so a GB radius alert reads `£`, an AR per-station
  /// alert reads `$`, and a prefix-less DE id stays `€`.
  String currencyForCountry(String? countryCode) {
    if (countryCode == null) return currencySymbol;
    return Countries.byCode(countryCode)?.currencySymbol ?? currencySymbol;
  }

  /// Literal-replace every `{key}` token. ARB placeholders never overlap,
  /// so order does not matter.
  static String _fill(String template, Map<String, String> values) {
    var out = template;
    values.forEach((k, v) {
      out = out.replaceAll('{$k}', v);
    });
    return out;
  }
}
