// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/impl/flutter_tts_announcement_service.dart';
import 'package:tankstellen/core/services/voice_announcement_service.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../fixtures/stations.dart';

class _MockFlutterTts extends Mock implements FlutterTts {}

/// Stub all FlutterTts setters used by the service so [when] calls succeed.
void _stubAllSetters(_MockFlutterTts tts) {
  when(() => tts.setSharedInstance(any())).thenAnswer((_) async => 1);
  when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
  when(() => tts.setVolume(any())).thenAnswer((_) async => 1);
  when(() => tts.setPitch(any())).thenAnswer((_) async => 1);
  when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
  when(() => tts.speak(any())).thenAnswer((_) async => 1);
  when(() => tts.stop()).thenAnswer((_) async => 1);
}

AnnouncementCandidate _candidate({
  Station? station,
  FuelType fuelType = FuelType.diesel,
  double price = 1.659,
  double distanceKm = 1.5,
}) {
  return AnnouncementCandidate(
    station: station ?? testStation,
    fuelType: fuelType,
    price: price,
    distanceKm: distanceKm,
  );
}

void main() {
  late _MockFlutterTts tts;
  late FlutterTtsAnnouncementService service;

  setUp(() {
    tts = _MockFlutterTts();
    _stubAllSetters(tts);
    service = FlutterTtsAnnouncementService(tts: tts);
  });

  group('constructor', () {
    test('uses provided FlutterTts instance for delegation', () async {
      await service.stop();
      verify(() => tts.stop()).called(1);
    });

    test('default constructor (no tts arg) constructs once binding ready',
        () {
      // FlutterTts wires a platform method-call handler in its constructor,
      // which requires the binding. Make sure that, in a properly initialised
      // test environment, no-arg construction succeeds.
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(() => FlutterTtsAnnouncementService(), returnsNormally);
    });
  });

  group('initialize()', () {
    test('first call configures shared instance, rate, volume, and pitch',
        () async {
      await service.initialize();

      verify(() => tts.setSharedInstance(true)).called(1);
      verify(() => tts.setSpeechRate(0.5)).called(1);
      verify(() => tts.setVolume(1.0)).called(1);
      verify(() => tts.setPitch(1.0)).called(1);
    });

    test('pushes a BCP-47 voice for the bound locale on init (#2762)',
        () async {
      // Default locale is English until setAppLocale wires the real one.
      await service.initialize();

      verify(() => tts.setLanguage('en-US')).called(1);
    });

    test('uses the selected app locale for the native voice on init (#2762)',
        () async {
      // The provider calls setAppLocale BEFORE the engine warms up; the
      // stored code must drive the native voice at init time.
      await service.setAppLocale('fr');

      await service.initialize();

      verify(() => tts.setLanguage('fr-FR')).called(1);
    });

    test('subsequent calls are no-ops (idempotent)', () async {
      await service.initialize();
      clearInteractions(tts);

      await service.initialize();

      verifyNever(() => tts.setSharedInstance(any()));
      verifyNever(() => tts.setSpeechRate(any()));
      verifyNever(() => tts.setVolume(any()));
      verifyNever(() => tts.setPitch(any()));
    });
  });

  group('setAppLocale() (#2762)', () {
    test('re-applies the native voice immediately when already initialized',
        () async {
      await service.initialize();
      clearInteractions(tts);

      await service.setAppLocale('de');

      verify(() => tts.setLanguage('de-DE')).called(1);
    });

    test('does not crash when the native locale is unavailable (fallback)',
        () async {
      // Simulate an engine that rejects an unavailable voice.
      when(() => tts.setLanguage(any())).thenThrow(Exception('no voice'));

      // initialize() applies the locale; the failure must be swallowed so
      // the service still comes up and can speak with the default voice.
      await expectLater(service.initialize(), completes);

      await service.setAppLocale('fr');
      // A localized announce must still work despite the voice failure.
      when(() => tts.speak(any())).thenAnswer((_) async => 1);
      await expectLater(service.announce(_candidate()), completes);
    });
  });

  group('announce()', () {
    test('skips speak when not initialized', () async {
      await service.announce(_candidate());

      verifyNever(() => tts.speak(any()));
    });

    test('speaks the localized (English) text after initialize', () async {
      await service.initialize();

      await service.announce(_candidate(
        fuelType: FuelType.diesel,
        price: 1.42,
        distanceKm: 1.2,
      ));

      // testStation has brand "STAR" and price 1.42 splits to "1" / "42".
      // Words now come from the ARB key voiceStationAnnouncement (en).
      verify(() => tts.speak('STAR, 1.2 kilometers ahead, Diesel 1 euros 42'))
          .called(1);
    });

    test('speaks the FRENCH sentence when bound to the fr locale (#2762)',
        () async {
      await service.setAppLocale('fr');
      await service.initialize();

      await service.announce(_candidate(
        fuelType: FuelType.diesel,
        price: 1.42,
        distanceKm: 1.2,
      ));

      // FR ARB value: "{name}, à {distanceKm} kilomètres, {fuelType} ...".
      verify(() => tts.speak('STAR, à 1.2 kilomètres, Diesel 1 euros 42'))
          .called(1);
      // And NOT the hardcoded English wording.
      verifyNever(
          () => tts.speak(any(that: contains('kilometers ahead'))));
    });

    test('speaks the GERMAN grade name, not displayName\'s hybrid (#4301)',
        () async {
      await service.setAppLocale('de');
      await service.initialize();

      await service.announce(_candidate(
        fuelType: FuelType.lpg,
        price: 1.42,
        distanceKm: 1.2,
      ));

      // The grade is the probe: German says `Autogas (LPG)` where
      // FuelType.displayName says `GPL / LPG`. The two cases above use
      // Diesel, which is byte-identical in en, fr AND displayName — so
      // neither of them could ever have caught a label that skipped the
      // localizer, and this announcement is SPOKEN, which made it the
      // worst place in the app to pronounce a French product name.
      verify(() => tts.speak(any(that: contains('Autogas (LPG)')))).called(1);
      verifyNever(() => tts.speak(any(that: contains('GPL / LPG'))));
    });

    test('uses brand when brand is non-empty', () async {
      await service.initialize();

      const brandedStation = Station(
        id: 'b1',
        name: 'Some Long Forecourt Name',
        brand: 'Shell',
        street: 'Hauptstr.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        dist: 0.5,
        isOpen: true,
      );

      await service.announce(_candidate(
        station: brandedStation,
        fuelType: FuelType.e10,
        price: 1.79,
        distanceKm: 0.5,
      ));

      // #4301 — `Super E10`, not `E10`: the grade now comes from the ARB
      // (`fuelNameE10`) instead of a literal the test happened to pass in.
      verify(() =>
              tts.speak('Shell, 0.5 kilometers ahead, Super E10 1 euros 79'))
          .called(1);
    });

    test('falls back to station.name when brand is empty', () async {
      await service.initialize();

      const unbrandedStation = Station(
        id: 'u1',
        name: 'Independent Garage',
        brand: '',
        street: 'Hauptstr.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        dist: 0.5,
        isOpen: true,
      );

      await service.announce(_candidate(
        station: unbrandedStation,
        fuelType: FuelType.diesel,
        price: 1.50,
        distanceKm: 0.5,
      ));

      verify(() => tts.speak(
              'Independent Garage, 0.5 kilometers ahead, Diesel 1 euros 50'))
          .called(1);
    });

    test('formats distance to one decimal place', () async {
      await service.initialize();

      await service.announce(_candidate(
        distanceKm: 2.0,
        price: 1.60,
      ));

      // 2.0 must print as "2.0", not "2".
      verify(() => tts.speak(any(that: contains('2.0 kilometers ahead'))))
          .called(1);
    });

    test('rounds distance to one decimal place', () async {
      await service.initialize();

      await service.announce(_candidate(distanceKm: 1.234));

      verify(() => tts.speak(any(that: contains('1.2 kilometers ahead'))))
          .called(1);
    });

    test('splits price into whole-euro and cents on the decimal point',
        () async {
      await service.initialize();

      await service.announce(_candidate(price: 1.05));

      // 1.05 -> "1 euros 05" (zero-padded cents from toStringAsFixed(2)).
      verify(() => tts.speak(any(that: endsWith('1 euros 05')))).called(1);
    });
  });

  group('stop()', () {
    test('delegates to FlutterTts.stop', () async {
      await service.stop();

      verify(() => tts.stop()).called(1);
    });
  });

  group('dispose()', () {
    test('stops the engine and resets initialized flag', () async {
      await service.initialize();
      await service.announce(_candidate(price: 1.50));
      verify(() => tts.speak(any())).called(1);

      await service.dispose();
      verify(() => tts.stop()).called(1);

      // After dispose, announce must no-op again until re-initialized.
      clearInteractions(tts);
      await service.announce(_candidate(price: 1.50));
      verifyNever(() => tts.speak(any()));
    });
  });

  group('setLanguage()', () {
    test('delegates to FlutterTts.setLanguage with the supplied code',
        () async {
      await service.setLanguage('en-US');

      verify(() => tts.setLanguage('en-US')).called(1);
    });
  });

  group('#4127 — a missing voice is reported, never whispered', () {
    test('an explicit false vetoes the region tag and falls back to the '
        'bare language code', () async {
      when(() => tts.isLanguageAvailable('fr-FR'))
          .thenAnswer((_) async => false);
      when(() => tts.isLanguageAvailable('fr')).thenAnswer((_) async => true);

      await service.setAppLocale('fr');
      await service.initialize();

      // Engines often register a generic voice with no region; trying it
      // is the difference between French and the device voice reading
      // French.
      verifyNever(() => tts.setLanguage('fr-FR'));
      verify(() => tts.setLanguage('fr')).called(greaterThanOrEqualTo(1));
      expect(service.languageVoiceMissing, isFalse);
    });

    test('no voice at all is RECORDED — the alternative is the device '
        'voice reading foreign text', () async {
      when(() => tts.isLanguageAvailable(any())).thenAnswer((_) async => false);

      await service.setAppLocale('fr');
      await service.initialize();

      verifyNever(() => tts.setLanguage(any()));
      expect(service.languageVoiceMissing, isTrue,
          reason: 'French text in an English voice is worse than either '
              'language; callers need to know so they can stay silent');
    });

    test('an UNKNOWN answer still attempts the voice — a probe may veto, '
        'never block', () async {
      // null / non-bool / throwing all mean "I do not know". Treating
      // that as unavailable would lose the voice on every platform whose
      // plugin does not answer definitively.
      when(() => tts.isLanguageAvailable(any())).thenAnswer((_) async => null);

      await service.setAppLocale('de');
      await service.initialize();

      verify(() => tts.setLanguage('de-DE')).called(greaterThanOrEqualTo(1));
      expect(service.languageVoiceMissing, isFalse);
    });
  });

}
