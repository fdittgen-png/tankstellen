import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/impl/flutter_tts_announcement_service.dart';
import 'package:tankstellen/core/services/voice_announcement_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

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
  String fuelType = 'Diesel',
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

  group('announce()', () {
    test('skips speak when not initialized', () async {
      await service.announce(_candidate());

      verifyNever(() => tts.speak(any()));
    });

    test('speaks formatted text after initialize', () async {
      await service.initialize();

      await service.announce(_candidate(
        fuelType: 'Diesel',
        price: 1.42,
        distanceKm: 1.2,
      ));

      // testStation has brand "STAR" and price 1.42 splits to "1" / "42".
      verify(() => tts.speak('STAR, 1.2 kilometers ahead, Diesel 1 euro 42'))
          .called(1);
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
        fuelType: 'E10',
        price: 1.79,
        distanceKm: 0.5,
      ));

      verify(() => tts.speak('Shell, 0.5 kilometers ahead, E10 1 euro 79'))
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
        fuelType: 'Diesel',
        price: 1.50,
        distanceKm: 0.5,
      ));

      verify(() => tts.speak(
              'Independent Garage, 0.5 kilometers ahead, Diesel 1 euro 50'))
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

      // 1.05 -> "1 euro 05" (zero-padded cents from toStringAsFixed(2)).
      verify(() => tts.speak(any(that: endsWith('1 euro 05')))).called(1);
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
}
