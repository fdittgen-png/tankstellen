import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/features/setup/presentation/widgets/country_language_step.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/globe_illustration.dart';

import '../../../../helpers/pump_app.dart';

/// Recording fake for ActiveLanguage that captures every `select` call
/// without touching profile/storage providers.
class _RecordingActiveLanguage extends ActiveLanguage {
  _RecordingActiveLanguage(this._initial);

  final AppLanguage _initial;
  final List<AppLanguage> selectCalls = [];

  @override
  AppLanguage build() => _initial;

  @override
  Future<void> select(AppLanguage language) async {
    selectCalls.add(language);
    state = language;
  }
}

/// Recording fake for ActiveCountry that captures every `select` call
/// without touching profile/storage providers.
class _RecordingActiveCountry extends ActiveCountry {
  _RecordingActiveCountry(this._initial);

  final CountryConfig _initial;
  final List<CountryConfig> selectCalls = [];

  @override
  CountryConfig build() => _initial;

  @override
  Future<void> select(CountryConfig country) async {
    selectCalls.add(country);
    state = country;
  }
}

void main() {
  group('CountryLanguageStep', () {
    late _RecordingActiveLanguage languageNotifier;
    late _RecordingActiveCountry countryNotifier;

    List<Object> overridesFor({
      AppLanguage? initialLanguage,
      CountryConfig? initialCountry,
    }) {
      languageNotifier =
          _RecordingActiveLanguage(initialLanguage ?? AppLanguages.all.first);
      countryNotifier =
          _RecordingActiveCountry(initialCountry ?? Countries.germany);
      return [
        activeLanguageProvider.overrideWith(() => languageNotifier),
        activeCountryProvider.overrideWith(() => countryNotifier),
      ];
    }

    testWidgets('renders globe illustration plus language and country sections',
        (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(),
      );

      expect(find.byType(GlobeIllustration), findsOneWidget);
      // Section headings come from l10n; pumpApp uses English locale.
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
    });

    testWidgets('renders one ChoiceChip for every supported language',
        (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(),
      );

      for (final lang in AppLanguages.all) {
        expect(
          find.text(lang.nativeName),
          findsOneWidget,
          reason: 'missing chip for ${lang.code}',
        );
      }
    });

    testWidgets('marks the current language chip as selected', (tester) async {
      final french =
          AppLanguages.byCode('fr') ?? AppLanguages.all.first;
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(initialLanguage: french),
      );

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text(french.nativeName),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);

      // Only one language chip should be selected at a time. Sanity-check
      // a different language is NOT selected.
      final english = AppLanguages.byCode('en')!;
      final englishChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text(english.nativeName),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(englishChip.selected, isFalse);
    });

    testWidgets('tapping a language chip calls notifier.select once',
        (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(
          initialLanguage: AppLanguages.byCode('en')!,
        ),
      );

      final target = AppLanguages.byCode('de')!;
      await tester.ensureVisible(find.text(target.nativeName));
      await tester.pumpAndSettle();
      await tester.tap(find.text(target.nativeName));
      await tester.pumpAndSettle();

      expect(languageNotifier.selectCalls, hasLength(1));
      expect(languageNotifier.selectCalls.single.code, target.code);
      expect(countryNotifier.selectCalls, isEmpty);
    });

    testWidgets('marks the current country chip as selected', (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(initialCountry: Countries.france),
      );

      final label = '${Countries.france.flag} ${Countries.france.name}';
      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('tapping a country chip calls notifier.select once',
        (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(initialCountry: Countries.germany),
      );

      const target = Countries.france;
      final label = '${target.flag} ${target.name}';
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(countryNotifier.selectCalls, hasLength(1));
      expect(countryNotifier.selectCalls.single.code, target.code);
      expect(languageNotifier.selectCalls, isEmpty);
    });

    testWidgets(
        'country chips render with the flag emoji from CountryConfig',
        (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(),
      );

      // Spot-check a handful of countries across the supported set.
      for (final country in [
        Countries.germany,
        Countries.france,
        Countries.italy,
        Countries.unitedKingdom,
      ]) {
        expect(
          find.text('${country.flag} ${country.name}'),
          findsOneWidget,
          reason: 'missing chip for ${country.code}',
        );
      }
    });

    testWidgets(
        'exposes selected-state Semantics labels so screen readers announce '
        'the active language and country', (tester) async {
      final french = AppLanguages.byCode('fr')!;
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(
          initialLanguage: french,
          initialCountry: Countries.france,
        ),
      );

      expect(
        find.bySemanticsLabel(
          RegExp('Language ${french.nativeName}, selected'),
        ),
        findsAtLeast(1),
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Country ${Countries.france.name}, selected'),
        ),
        findsAtLeast(1),
      );
    });

    testWidgets(
        'country info card shows the active country flag, name, and api '
        'provider',
        (tester) async {
      await pumpApp(
        tester,
        const CountryLanguageStep(),
        overrides: overridesFor(initialCountry: Countries.germany),
      );

      // Card heading shows the country name.
      expect(find.text(Countries.germany.name), findsAtLeast(1));
      // Data row shows the upstream provider.
      expect(
        find.text('Data: ${Countries.germany.apiProvider}'),
        findsOneWidget,
      );
      // Germany is one of the few countries that requires an API key.
      expect(find.text('API key required'), findsOneWidget);
    });
  });

}
