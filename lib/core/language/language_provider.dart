import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../storage/hive_storage.dart';

part 'language_provider.g.dart';

/// Supported languages with native display names.
class AppLanguage {
  final String code;
  final String nativeName;
  final String englishName;

  const AppLanguage(this.code, this.nativeName, this.englishName);

  Locale get locale => Locale(code);
}

class AppLanguages {
  AppLanguages._();

  static const all = [
    // Western European
    AppLanguage('en', 'English', 'English'),
    AppLanguage('de', 'Deutsch', 'German'),
    AppLanguage('fr', 'Français', 'French'),
    AppLanguage('it', 'Italiano', 'Italian'),
    AppLanguage('es', 'Español', 'Spanish'),
    AppLanguage('nl', 'Nederlands', 'Dutch'),
    AppLanguage('pt', 'Português', 'Portuguese'),
    // Nordic
    AppLanguage('da', 'Dansk', 'Danish'),
    AppLanguage('sv', 'Svenska', 'Swedish'),
    AppLanguage('fi', 'Suomi', 'Finnish'),
    AppLanguage('nb', 'Norsk bokmål', 'Norwegian'),
    // Central & Eastern European
    AppLanguage('pl', 'Polski', 'Polish'),
    AppLanguage('cs', 'Čeština', 'Czech'),
    AppLanguage('sk', 'Slovenčina', 'Slovak'),
    AppLanguage('hu', 'Magyar', 'Hungarian'),
    AppLanguage('ro', 'Română', 'Romanian'),
    AppLanguage('bg', 'Български', 'Bulgarian'),
    AppLanguage('hr', 'Hrvatski', 'Croatian'),
    AppLanguage('sl', 'Slovenščina', 'Slovenian'),
    // Baltic
    AppLanguage('lt', 'Lietuvių', 'Lithuanian'),
    AppLanguage('lv', 'Latviešu', 'Latvian'),
    AppLanguage('et', 'Eesti', 'Estonian'),
    // Southern European
    AppLanguage('el', 'Ελληνικά', 'Greek'),
  ];

  static AppLanguage? byCode(String code) {
    for (final l in all) {
      if (l.code == code) return l;
    }
    return null;
  }

  /// Detect best language from system locale.
  static AppLanguage fromSystem() {
    final sysLocale = ui.PlatformDispatcher.instance.locale;
    return byCode(sysLocale.languageCode) ?? all.first; // fallback: English
  }
}

@Riverpod(keepAlive: true)
class ActiveLanguage extends _$ActiveLanguage {
  static const _storageKey = 'active_language_code';

  @override
  AppLanguage build() {
    // Priority 1: active profile's language
    final profile = ref.watch(activeProfileProvider);
    if (profile?.languageCode != null) {
      final fromProfile = AppLanguages.byCode(profile!.languageCode!);
      if (fromProfile != null) return fromProfile;
    }

    // Priority 2: persisted setting (legacy / migration)
    final storage = ref.watch(hiveStorageProvider);
    final saved = storage.getSetting(_storageKey) as String?;
    if (saved != null) {
      return AppLanguages.byCode(saved) ?? AppLanguages.fromSystem();
    }
    return AppLanguages.fromSystem();
  }

  Future<void> select(AppLanguage language) async {
    // Update legacy storage
    final storage = ref.read(hiveStorageProvider);
    await storage.putSetting(_storageKey, language.code);

    // Update active profile if it exists
    final profile = ref.read(activeProfileProvider);
    if (profile != null) {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        profile.copyWith(languageCode: language.code),
      );
      ref.read(activeProfileProvider.notifier).refresh();
    }

    state = language;
  }
}
