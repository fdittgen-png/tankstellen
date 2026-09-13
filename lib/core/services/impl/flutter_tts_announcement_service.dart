// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui' show Locale;

import '../../logging/app_log.dart';
import '../../telemetry/health_counters.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../l10n/app_localizations.dart';
import '../../logging/error_logger.dart';
import '../voice_announcement_service.dart';

/// Platform TTS implementation using [FlutterTts].
///
/// Delegates to the native speech engine on Android/iOS. Volume is tied
/// to the media channel so the system silent/vibrate mode is respected
/// automatically.
class FlutterTtsAnnouncementService implements VoiceAnnouncementService {
  FlutterTtsAnnouncementService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  /// App language code the spoken text + native voice are bound to (#2762).
  /// Defaults to English until [setAppLocale] is wired from the provider.
  String _languageCode = 'en';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setSharedInstance(true);
    // #3504 — navigation-guidance audio attributes: cues DUCK music instead
    // of stopping it, and never talk over the telephony stream during an
    // active call (the field screenshots were taken mid-call). On iOS this
    // maps to the playback category with duckOthers; Android to
    // USAGE_ASSISTANCE_NAVIGATION_GUIDANCE with transient-may-duck focus.
    // Best-effort: an engine without the API just keeps the default mix.
    try {
      await _tts.setAudioAttributesForNavigation();
    } catch (e, st) {
      // Best-effort — an engine without the API keeps the default mix.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'FlutterTtsAnnouncementService: navigation audio attrs',
      }));
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Push the selected locale's voice to the native engine so the first
    // line isn't spoken with the device-default (usually English) voice.
    await _applyTtsLanguage(_languageCode);
    _initialized = true;
  }

  @override
  Future<void> announce(AnnouncementCandidate candidate) async {
    if (!_initialized) {
      debugPrint('VoiceAnnouncement: TTS not initialized, skipping');
      return;
    }
    final text = _formatAnnouncement(candidate);
    await _tts.speak(text);
  }

  @override
  Future<void> speakLine(String text) async {
    if (!_initialized) {
      debugPrint('VoiceAnnouncement: TTS not initialized, skipping');
      return;
    }
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
    _initialized = false;
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  @override
  Future<void> setAppLocale(String languageCode) async {
    _languageCode = languageCode;
    // Re-apply to the native engine immediately when it's already up; on a
    // cold start [initialize] applies it. A no-op before init is fine — the
    // stored code is used at init time.
    if (_initialized) {
      await _applyTtsLanguage(languageCode);
    }
  }

  /// True when the last [_applyTtsLanguage] could not find a voice for the
  /// selected language (#4127).
  ///
  /// The announcement TEXT is always the selected locale's, so a missing
  /// voice does not mean "speaks English" — it means the device voice
  /// reads FOREIGN text, which is the one outcome worse than either
  /// language. Callers use this to stay silent rather than produce
  /// gibberish, and the voice settings use it to name the language to
  /// install.
  bool get languageVoiceMissing => _languageVoiceMissing;
  bool _languageVoiceMissing = false;

  /// Push the BCP-47 voice for [languageCode] to the native engine,
  /// falling back gracefully if that locale's voice is unavailable so a
  /// missing voice never crashes an announcement (#2762).
  ///
  /// #4127 — the result used to be discarded: `setLanguage` failing was
  /// logged with `debugPrint` (silenced in release) and the engine kept
  /// the DEVICE voice, so a phone with no French voice read French text
  /// in English. The engine is asked whether it HAS the voice now, the
  /// region-less tag is tried as a second chance (engines often register
  /// a generic `fr` without a region), and a genuine miss is recorded
  /// rather than whispered.
  Future<void> _applyTtsLanguage(String languageCode) async {
    final candidates = <String>{
      _ttsLocaleFor(languageCode),
      languageCode.toLowerCase(),
    };
    for (final tag in candidates) {
      // The probe can VETO a candidate; it can never block one.
      //
      // Only an EXPLICIT false means "this engine has no such voice".
      // `isLanguageAvailable` is `Future<dynamic>`: a plugin or platform
      // that answers null, a non-bool, or throws is saying "I do not
      // know", and treating that as unavailable would lose the voice on
      // every such platform — a worse regression than the bug being
      // fixed. Unknown therefore falls through to the attempt below,
      // which is exactly the behaviour that was already correct.
      var vetoed = false;
      try {
        vetoed = await _tts.isLanguageAvailable(tag) == false;
      } catch (e, st) {
        debugPrint('VoiceAnnouncement: isLanguageAvailable("$tag") '
            'unavailable, attempting anyway: $e');
        debugPrintStack(stackTrace: st);
      }
      if (vetoed) continue;
      try {
        await setLanguage(tag);
        _languageVoiceMissing = false;
        return;
      } catch (e, st) {
        log.warn('VoiceAnnouncement: setLanguage("$tag") failed',
            error: e, stack: st, layer: ErrorLayer.other);
      }
    }
    // No voice for the selected language. Visible, not whispered: the
    // alternative is the device voice reading text it cannot pronounce.
    _languageVoiceMissing = true;
    log.warn(
      'VoiceAnnouncement: no TTS voice for "$languageCode" — announcements '
      'would read ${languageCode.toUpperCase()} text in the device voice',
      layer: ErrorLayer.other,
    );
    healthCounters.increment('voice.languageUnavailable');
  }

  /// Map an app language code to a TTS BCP-47 tag. Covers the explicit
  /// region cases users notice most; anything else falls back to
  /// `<code>-<CODE>` (e.g. `it` -> `it-IT`), which the native engines
  /// resolve for every shipped locale.
  @visibleForTesting
  static String ttsLocaleFor(String languageCode) =>
      _ttsLocaleForImpl(languageCode);

  String _ttsLocaleFor(String languageCode) =>
      _ttsLocaleForImpl(languageCode);

  static String _ttsLocaleForImpl(String languageCode) {
    const explicit = <String, String>{
      'en': 'en-US',
      'de': 'de-DE',
      'fr': 'fr-FR',
      'pt': 'pt-PT',
      'nb': 'nb-NO',
      'el': 'el-GR',
      'cs': 'cs-CZ',
      'sv': 'sv-SE',
      'da': 'da-DK',
      // #4127 — the two shipped languages whose code is NOT their
      // country code, so the `<code>-<CODE>` fallback below invents a
      // locale that no engine has: `sl-SL` and `et-ET`. Both silently
      // took the setLanguage-failed path, leaving the device voice to
      // read Slovenian / Estonian text.
      //
      // `et` was found by the locale table test, not by reading the
      // code — which is the argument for the table.
      'sl': 'sl-SI',
      'et': 'et-EE',
    };
    final code = languageCode.toLowerCase();
    return explicit[code] ?? '$code-${code.toUpperCase()}';
  }

  /// Resolve [AppLocalizations] for the app's SELECTED locale.
  ///
  /// This fires from a background / approach announcement context, not a
  /// widget tree, so there is no `BuildContext` to read — [lookupAppLocalizations]
  /// returns the bindings for an arbitrary [Locale]. Falls back to English
  /// if the code is somehow unsupported.
  AppLocalizations _localizations() {
    try {
      return lookupAppLocalizations(Locale(_languageCode));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  /// Build the spoken text for a candidate in the SELECTED locale (#2762).
  ///
  /// The numeric formatting (distance to one decimal place, the
  /// whole-euro/cents split) stays here; the WORDS ("kilometers ahead",
  /// "euros") come from the [AppLocalizations.voiceStationAnnouncement] ARB
  /// key resolved for the app's selected locale, so a French user hears the
  /// sentence in French.
  String _formatAnnouncement(AnnouncementCandidate candidate) {
    final name = candidate.station.brand.isNotEmpty
        ? candidate.station.brand
        : candidate.station.name;
    final dist = candidate.distanceKm.toStringAsFixed(1);
    final priceParts = candidate.price.toStringAsFixed(2).split('.');
    return _localizations().voiceStationAnnouncement(
      name,
      dist,
      candidate.fuelType,
      priceParts[0],
      priceParts[1],
    );
  }
}
