import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_it.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fi'),
    Locale('fr'),
    Locale('hr'),
    Locale('hu'),
    Locale('it'),
    Locale('lt'),
    Locale('lv'),
    Locale('nb'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('sk'),
    Locale('sl'),
    Locale('sv'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel Prices'**
  String get appTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @gpsLocation.
  ///
  /// In en, this message translates to:
  /// **'GPS Location'**
  String get gpsLocation;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get zipCode;

  /// No description provided for @zipCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10115'**
  String get zipCodeHint;

  /// No description provided for @fuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get fuelType;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get searchRadius;

  /// No description provided for @searchNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby stations'**
  String get searchNearby;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// No description provided for @searchCriteriaTitle.
  ///
  /// In en, this message translates to:
  /// **'Search criteria'**
  String get searchCriteriaTitle;

  /// No description provided for @searchCriteriaOpen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchCriteriaOpen;

  /// No description provided for @searchCriteriaRadiusBadge.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String searchCriteriaRadiusBadge(String km);

  /// No description provided for @searchCriteriaTapToSearch.
  ///
  /// In en, this message translates to:
  /// **'Tap to start searching'**
  String get searchCriteriaTapToSearch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No stations found.'**
  String get noResults;

  /// No description provided for @startSearch.
  ///
  /// In en, this message translates to:
  /// **'Search to find fuel stations.'**
  String get startSearch;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distance(String distance);

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @prices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHours;

  /// No description provided for @open24h.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get open24h;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @apiKeySetup.
  ///
  /// In en, this message translates to:
  /// **'API key setup'**
  String get apiKeySetup;

  /// No description provided for @apiKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Register once for a free API key.'**
  String get apiKeyDescription;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get register;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Fuel Prices'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the cheapest fuel near you.'**
  String get welcomeSubtitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// No description provided for @preferredFuel.
  ///
  /// In en, this message translates to:
  /// **'Preferred fuel'**
  String get preferredFuel;

  /// No description provided for @defaultRadius.
  ///
  /// In en, this message translates to:
  /// **'Default radius'**
  String get defaultRadius;

  /// No description provided for @landingScreen.
  ///
  /// In en, this message translates to:
  /// **'Start screen'**
  String get landingScreen;

  /// No description provided for @homeZip.
  ///
  /// In en, this message translates to:
  /// **'Home postal code'**
  String get homeZip;

  /// No description provided for @newProfile.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get newProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @countryChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch country?'**
  String get countryChangeTitle;

  /// No description provided for @countryChangeBody.
  ///
  /// In en, this message translates to:
  /// **'Switching to {country} will change:'**
  String countryChangeBody(String country);

  /// No description provided for @countryChangeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get countryChangeCurrency;

  /// No description provided for @countryChangeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get countryChangeDistance;

  /// No description provided for @countryChangeVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get countryChangeVolume;

  /// No description provided for @countryChangePricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price format'**
  String get countryChangePricePerUnit;

  /// No description provided for @countryChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Existing favorites and fill-up logs are not rewritten; only new entries use the new units.'**
  String get countryChangeNote;

  /// No description provided for @countryChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get countryChangeConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source (MIT License)'**
  String get openSource;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code on GitHub'**
  String get sourceCode;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @noFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on a station to save it as a favorite.'**
  String get noFavoritesHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — sample data shown.'**
  String get demoMode;

  /// No description provided for @setupLiveData.
  ///
  /// In en, this message translates to:
  /// **'Set up for live data'**
  String get setupLiveData;

  /// No description provided for @freeNoKey.
  ///
  /// In en, this message translates to:
  /// **'Free — no key needed'**
  String get freeNoKey;

  /// No description provided for @apiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key required'**
  String get apiKeyRequired;

  /// No description provided for @skipWithoutKey.
  ///
  /// In en, this message translates to:
  /// **'Continue without key'**
  String get skipWithoutKey;

  /// No description provided for @dataTransparency.
  ///
  /// In en, this message translates to:
  /// **'Data transparency'**
  String get dataTransparency;

  /// No description provided for @storageAndCache.
  ///
  /// In en, this message translates to:
  /// **'Storage & cache'**
  String get storageAndCache;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get clearAllData;

  /// No description provided for @errorLog.
  ///
  /// In en, this message translates to:
  /// **'Error log'**
  String get errorLog;

  /// No description provided for @stationsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} stations found'**
  String stationsFound(int count);

  /// No description provided for @whatIsShared.
  ///
  /// In en, this message translates to:
  /// **'What is shared — and with whom?'**
  String get whatIsShared;

  /// No description provided for @gpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'GPS coordinates'**
  String get gpsCoordinates;

  /// No description provided for @gpsReason.
  ///
  /// In en, this message translates to:
  /// **'Sent with every location search to find nearby stations.'**
  String get gpsReason;

  /// No description provided for @postalCodeData.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCodeData;

  /// No description provided for @postalReason.
  ///
  /// In en, this message translates to:
  /// **'Converted to coordinates via geocoding service.'**
  String get postalReason;

  /// No description provided for @mapViewport.
  ///
  /// In en, this message translates to:
  /// **'Map viewport'**
  String get mapViewport;

  /// No description provided for @mapReason.
  ///
  /// In en, this message translates to:
  /// **'Map tiles are loaded from the tile server. No personal data is transmitted.'**
  String get mapReason;

  /// No description provided for @apiKeyData.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyData;

  /// No description provided for @apiKeyReason.
  ///
  /// In en, this message translates to:
  /// **'Your personal key is sent with every API request. It is linked to your email.'**
  String get apiKeyReason;

  /// No description provided for @notShared.
  ///
  /// In en, this message translates to:
  /// **'NOT shared:'**
  String get notShared;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get searchHistory;

  /// No description provided for @favoritesData.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesData;

  /// No description provided for @profileNames.
  ///
  /// In en, this message translates to:
  /// **'Profile names'**
  String get profileNames;

  /// No description provided for @homeZipData.
  ///
  /// In en, this message translates to:
  /// **'Home ZIP'**
  String get homeZipData;

  /// No description provided for @usageData.
  ///
  /// In en, this message translates to:
  /// **'Usage data'**
  String get usageData;

  /// No description provided for @privacyBanner.
  ///
  /// In en, this message translates to:
  /// **'This app has no server. All data stays on your device. No analytics, no tracking, no ads.'**
  String get privacyBanner;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage usage on this device'**
  String get storageUsage;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @profilesStored.
  ///
  /// In en, this message translates to:
  /// **'profiles stored'**
  String get profilesStored;

  /// No description provided for @stationsMarked.
  ///
  /// In en, this message translates to:
  /// **'stations marked'**
  String get stationsMarked;

  /// No description provided for @cachedResponses.
  ///
  /// In en, this message translates to:
  /// **'cached responses'**
  String get cachedResponses;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @cacheManagement.
  ///
  /// In en, this message translates to:
  /// **'Cache management'**
  String get cacheManagement;

  /// No description provided for @cacheDescription.
  ///
  /// In en, this message translates to:
  /// **'The cache stores API responses for faster loading and offline access.'**
  String get cacheDescription;

  /// No description provided for @stationSearch.
  ///
  /// In en, this message translates to:
  /// **'Station search'**
  String get stationSearch;

  /// No description provided for @stationDetails.
  ///
  /// In en, this message translates to:
  /// **'Station details'**
  String get stationDetails;

  /// No description provided for @priceQuery.
  ///
  /// In en, this message translates to:
  /// **'Price query'**
  String get priceQuery;

  /// No description provided for @zipGeocoding.
  ///
  /// In en, this message translates to:
  /// **'Postal code geocoding'**
  String get zipGeocoding;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes'**
  String minutes(int n);

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{n} hours'**
  String hours(int n);

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'Cached search results and prices will be deleted. Profiles, favorites and settings are preserved.'**
  String get clearCacheBody;

  /// No description provided for @clearCacheButton.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCacheButton;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all profiles, favorites, API key, settings, and cache. The app will reset.'**
  String get deleteAllBody;

  /// No description provided for @deleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllButton;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @cacheEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cache is empty'**
  String get cacheEmpty;

  /// No description provided for @noStorage.
  ///
  /// In en, this message translates to:
  /// **'No storage used'**
  String get noStorage;

  /// No description provided for @apiKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Free registration. Data from government price transparency agencies.'**
  String get apiKeyNote;

  /// No description provided for @apiKeyFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid format — expected UUID (8-4-4-4-12)'**
  String get apiKeyFormatError;

  /// No description provided for @supportProject.
  ///
  /// In en, this message translates to:
  /// **'Support this project'**
  String get supportProject;

  /// No description provided for @supportDescription.
  ///
  /// In en, this message translates to:
  /// **'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.'**
  String get supportDescription;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug / Suggest a feature'**
  String get reportBug;

  /// No description provided for @reportThisIssue.
  ///
  /// In en, this message translates to:
  /// **'Report this issue'**
  String get reportThisIssue;

  /// No description provided for @reportConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report to GitHub?'**
  String get reportConsentTitle;

  /// No description provided for @reportConsentBody.
  ///
  /// In en, this message translates to:
  /// **'This will open a public GitHub issue with the error details below. No GPS coordinates, API keys, or personal data are included.'**
  String get reportConsentBody;

  /// No description provided for @reportConsentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub'**
  String get reportConsentConfirm;

  /// No description provided for @reportConsentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportConsentCancel;

  /// No description provided for @configProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get configProfileSection;

  /// No description provided for @configActiveProfile.
  ///
  /// In en, this message translates to:
  /// **'Active profile'**
  String get configActiveProfile;

  /// No description provided for @configPreferredFuel.
  ///
  /// In en, this message translates to:
  /// **'Preferred fuel'**
  String get configPreferredFuel;

  /// No description provided for @configCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get configCountry;

  /// No description provided for @configRouteSegment.
  ///
  /// In en, this message translates to:
  /// **'Route segment'**
  String get configRouteSegment;

  /// No description provided for @configApiKeysSection.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get configApiKeysSection;

  /// No description provided for @configTankerkoenigKey.
  ///
  /// In en, this message translates to:
  /// **'Tankerkoenig API key'**
  String get configTankerkoenigKey;

  /// No description provided for @configApiKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configApiKeyConfigured;

  /// No description provided for @configApiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set (demo mode)'**
  String get configApiKeyNotSet;

  /// No description provided for @configApiKeyCommunity.
  ///
  /// In en, this message translates to:
  /// **'Default (community key)'**
  String get configApiKeyCommunity;

  /// No description provided for @searchLocationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Address, postal code or city'**
  String get searchLocationPlaceholder;

  /// No description provided for @configEvKey.
  ///
  /// In en, this message translates to:
  /// **'EV charging API key'**
  String get configEvKey;

  /// No description provided for @configEvKeyCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom key'**
  String get configEvKeyCustom;

  /// No description provided for @configEvKeyShared.
  ///
  /// In en, this message translates to:
  /// **'Default (shared)'**
  String get configEvKeyShared;

  /// No description provided for @configCloudSyncSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get configCloudSyncSection;

  /// No description provided for @configTankSyncConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get configTankSyncConnected;

  /// No description provided for @configTankSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get configTankSyncDisabled;

  /// No description provided for @configAuthMode.
  ///
  /// In en, this message translates to:
  /// **'Auth mode'**
  String get configAuthMode;

  /// No description provided for @configAuthEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (persistent)'**
  String get configAuthEmail;

  /// No description provided for @configAuthAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous (device-only)'**
  String get configAuthAnonymous;

  /// No description provided for @configDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get configDatabase;

  /// No description provided for @configPrivacySummary.
  ///
  /// In en, this message translates to:
  /// **'Privacy summary'**
  String get configPrivacySummary;

  /// No description provided for @configPrivacySummarySynced.
  ///
  /// In en, this message translates to:
  /// **'• Favorites, alerts, and ignored stations are synced to your private database\n• GPS position and API keys never leave your device\n• {authNote}'**
  String configPrivacySummarySynced(Object authNote);

  /// No description provided for @configPrivacySummaryLocal.
  ///
  /// In en, this message translates to:
  /// **'• All data is stored locally on this device only\n• No data is sent to any server\n• API keys encrypted in device secure storage'**
  String get configPrivacySummaryLocal;

  /// No description provided for @configAuthNoteEmail.
  ///
  /// In en, this message translates to:
  /// **'Email account enables cross-device access'**
  String get configAuthNoteEmail;

  /// No description provided for @configAuthNoteAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous account — data tied to this device'**
  String get configAuthNoteAnonymous;

  /// No description provided for @configNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get configNone;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @fuels.
  ///
  /// In en, this message translates to:
  /// **'Fuels'**
  String get fuels;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @highway.
  ///
  /// In en, this message translates to:
  /// **'Highway'**
  String get highway;

  /// No description provided for @localStation.
  ///
  /// In en, this message translates to:
  /// **'Local station'**
  String get localStation;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get lastUpdate;

  /// No description provided for @automate24h.
  ///
  /// In en, this message translates to:
  /// **'24h/24 — Automate'**
  String get automate24h;

  /// No description provided for @refreshPrices.
  ///
  /// In en, this message translates to:
  /// **'Refresh prices'**
  String get refreshPrices;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. You can search by postal code.'**
  String get locationDenied;

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode. Configure API key in settings for live prices.'**
  String get demoModeBanner;

  /// No description provided for @sortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sortDistance;

  /// No description provided for @sortOpen24h.
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get sortOpen24h;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @sortPriceDistance.
  ///
  /// In en, this message translates to:
  /// **'Price/km'**
  String get sortPriceDistance;

  /// No description provided for @cheap.
  ///
  /// In en, this message translates to:
  /// **'cheap'**
  String get cheap;

  /// No description provided for @expensive.
  ///
  /// In en, this message translates to:
  /// **'expensive'**
  String get expensive;

  /// No description provided for @stationsOnMap.
  ///
  /// In en, this message translates to:
  /// **'{count} stations'**
  String stationsOnMap(int count);

  /// No description provided for @loadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Loading favorites...\nSearch for stations first to save data.'**
  String get loadingFavorites;

  /// No description provided for @reportPrice.
  ///
  /// In en, this message translates to:
  /// **'Report price'**
  String get reportPrice;

  /// No description provided for @whatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get whatsWrong;

  /// No description provided for @correctPrice.
  ///
  /// In en, this message translates to:
  /// **'Correct price (e.g. 1.459)'**
  String get correctPrice;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you!'**
  String get reportSent;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared.'**
  String get cacheCleared;

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get yourPosition;

  /// No description provided for @positionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Position unknown'**
  String get positionUnknown;

  /// No description provided for @distancesFromCenter.
  ///
  /// In en, this message translates to:
  /// **'Distances from search center'**
  String get distancesFromCenter;

  /// No description provided for @autoUpdatePosition.
  ///
  /// In en, this message translates to:
  /// **'Auto-update position'**
  String get autoUpdatePosition;

  /// No description provided for @autoUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'Refresh GPS position before each search'**
  String get autoUpdateDescription;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @switchProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Country changed'**
  String get switchProfileTitle;

  /// No description provided for @switchProfilePrompt.
  ///
  /// In en, this message translates to:
  /// **'You are now in {country}. Switch to profile \"{profile}\"?'**
  String switchProfilePrompt(String country, String profile);

  /// No description provided for @switchedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Switched to profile \"{profile}\" ({country})'**
  String switchedToProfile(String profile, String country);

  /// No description provided for @noProfileForCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'No profile for this country'**
  String get noProfileForCountryTitle;

  /// No description provided for @noProfileForCountry.
  ///
  /// In en, this message translates to:
  /// **'You are in {country}, but no profile is configured for it. Create one in Settings.'**
  String noProfileForCountry(String country);

  /// No description provided for @autoSwitchProfile.
  ///
  /// In en, this message translates to:
  /// **'Auto-switch profile'**
  String get autoSwitchProfile;

  /// No description provided for @autoSwitchDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically switch profile when crossing borders'**
  String get autoSwitchDescription;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchProfile;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @profileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountry;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @settingsStorageDetail.
  ///
  /// In en, this message translates to:
  /// **'API key, active profile'**
  String get settingsStorageDetail;

  /// No description provided for @allFuels.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFuels;

  /// No description provided for @priceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price Alerts'**
  String get priceAlerts;

  /// No description provided for @noPriceAlerts.
  ///
  /// In en, this message translates to:
  /// **'No price alerts'**
  String get noPriceAlerts;

  /// No description provided for @noPriceAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Create an alert from a station\'s detail page.'**
  String get noPriceAlertsHint;

  /// No description provided for @alertDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert \"{name}\" deleted'**
  String alertDeleted(String name);

  /// No description provided for @createAlert.
  ///
  /// In en, this message translates to:
  /// **'Create Price Alert'**
  String get createAlert;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price: {price}'**
  String currentPrice(String price);

  /// No description provided for @targetPrice.
  ///
  /// In en, this message translates to:
  /// **'Target price (EUR)'**
  String get targetPrice;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a price'**
  String get enterPrice;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @priceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Price too high'**
  String get priceTooHigh;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @alertCreated.
  ///
  /// In en, this message translates to:
  /// **'Price alert created'**
  String get alertCreated;

  /// No description provided for @wrongE5Price.
  ///
  /// In en, this message translates to:
  /// **'Wrong Super E5 price'**
  String get wrongE5Price;

  /// No description provided for @wrongE10Price.
  ///
  /// In en, this message translates to:
  /// **'Wrong Super E10 price'**
  String get wrongE10Price;

  /// No description provided for @wrongDieselPrice.
  ///
  /// In en, this message translates to:
  /// **'Wrong Diesel price'**
  String get wrongDieselPrice;

  /// No description provided for @wrongStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Shown as open, but closed'**
  String get wrongStatusOpen;

  /// No description provided for @wrongStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Shown as closed, but open'**
  String get wrongStatusClosed;

  /// No description provided for @searchAlongRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Along route'**
  String get searchAlongRouteLabel;

  /// No description provided for @searchEvStations.
  ///
  /// In en, this message translates to:
  /// **'Search to find EV charging stations'**
  String get searchEvStations;

  /// No description provided for @allStations.
  ///
  /// In en, this message translates to:
  /// **'All stations'**
  String get allStations;

  /// No description provided for @bestStops.
  ///
  /// In en, this message translates to:
  /// **'Best stops'**
  String get bestStops;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @noStationsAlongRoute.
  ///
  /// In en, this message translates to:
  /// **'No stations found along route'**
  String get noStationsAlongRoute;

  /// No description provided for @evOperational.
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get evOperational;

  /// No description provided for @evStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unknown'**
  String get evStatusUnknown;

  /// No description provided for @evConnectors.
  ///
  /// In en, this message translates to:
  /// **'Connectors ({count} points)'**
  String evConnectors(int count);

  /// No description provided for @evNoConnectors.
  ///
  /// In en, this message translates to:
  /// **'No connector details available'**
  String get evNoConnectors;

  /// No description provided for @evUsageCost.
  ///
  /// In en, this message translates to:
  /// **'Usage cost'**
  String get evUsageCost;

  /// No description provided for @evPricingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pricing not available from provider'**
  String get evPricingUnavailable;

  /// No description provided for @evLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get evLastUpdated;

  /// No description provided for @evUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get evUnknown;

  /// No description provided for @evDataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Data from OpenChargeMap (community-sourced)'**
  String get evDataAttribution;

  /// No description provided for @evStatusDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Status may not reflect real-time availability. Tap refresh to get the latest data.'**
  String get evStatusDisclaimer;

  /// No description provided for @evNavigateToStation.
  ///
  /// In en, this message translates to:
  /// **'Navigate to station'**
  String get evNavigateToStation;

  /// No description provided for @evRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get evRefreshStatus;

  /// No description provided for @evStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get evStatusUpdated;

  /// No description provided for @evStationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh — station not found nearby'**
  String get evStationNotFound;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @gpsError.
  ///
  /// In en, this message translates to:
  /// **'GPS error'**
  String get gpsError;

  /// No description provided for @couldNotResolve.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve start or destination'**
  String get couldNotResolve;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @cityAddressOrGps.
  ///
  /// In en, this message translates to:
  /// **'City, address, or GPS'**
  String get cityAddressOrGps;

  /// No description provided for @cityOrAddress.
  ///
  /// In en, this message translates to:
  /// **'City or address'**
  String get cityOrAddress;

  /// No description provided for @useGps.
  ///
  /// In en, this message translates to:
  /// **'Use GPS'**
  String get useGps;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopN.
  ///
  /// In en, this message translates to:
  /// **'Stop {n}'**
  String stopN(int n);

  /// No description provided for @addStop.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get addStop;

  /// No description provided for @searchAlongRoute.
  ///
  /// In en, this message translates to:
  /// **'Search along route'**
  String get searchAlongRoute;

  /// No description provided for @cheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get cheapest;

  /// No description provided for @nStations.
  ///
  /// In en, this message translates to:
  /// **'{count} stations'**
  String nStations(int count);

  /// No description provided for @nBest.
  ///
  /// In en, this message translates to:
  /// **'{count} best'**
  String nBest(int count);

  /// No description provided for @fuelPricesTankerkoenig.
  ///
  /// In en, this message translates to:
  /// **'Fuel prices (Tankerkoenig)'**
  String get fuelPricesTankerkoenig;

  /// No description provided for @requiredForFuelSearch.
  ///
  /// In en, this message translates to:
  /// **'Required for fuel price search in Germany'**
  String get requiredForFuelSearch;

  /// No description provided for @evChargingOpenChargeMap.
  ///
  /// In en, this message translates to:
  /// **'EV Charging (OpenChargeMap)'**
  String get evChargingOpenChargeMap;

  /// No description provided for @customKey.
  ///
  /// In en, this message translates to:
  /// **'Custom key'**
  String get customKey;

  /// No description provided for @appDefaultKey.
  ///
  /// In en, this message translates to:
  /// **'App default key'**
  String get appDefaultKey;

  /// No description provided for @optionalOverrideKey.
  ///
  /// In en, this message translates to:
  /// **'Optional: override the built-in app key with your own'**
  String get optionalOverrideKey;

  /// No description provided for @requiredForEvSearch.
  ///
  /// In en, this message translates to:
  /// **'Required for EV charging station search'**
  String get requiredForEvSearch;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @fuelPricesApiKey.
  ///
  /// In en, this message translates to:
  /// **'Fuel prices API Key'**
  String get fuelPricesApiKey;

  /// No description provided for @tankerkoenigApiKey.
  ///
  /// In en, this message translates to:
  /// **'Tankerkoenig API Key'**
  String get tankerkoenigApiKey;

  /// No description provided for @evChargingApiKey.
  ///
  /// In en, this message translates to:
  /// **'EV Charging API Key'**
  String get evChargingApiKey;

  /// No description provided for @openChargeMapApiKey.
  ///
  /// In en, this message translates to:
  /// **'OpenChargeMap API Key'**
  String get openChargeMapApiKey;

  /// No description provided for @routeSegment.
  ///
  /// In en, this message translates to:
  /// **'Route segment'**
  String get routeSegment;

  /// No description provided for @showCheapestEveryNKm.
  ///
  /// In en, this message translates to:
  /// **'Show cheapest station every {km} km along route'**
  String showCheapestEveryNKm(int km);

  /// No description provided for @avoidHighways.
  ///
  /// In en, this message translates to:
  /// **'Avoid highways'**
  String get avoidHighways;

  /// No description provided for @avoidHighwaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Route calculation avoids toll roads and highways'**
  String get avoidHighwaysDesc;

  /// No description provided for @showFuelStations.
  ///
  /// In en, this message translates to:
  /// **'Show fuel stations'**
  String get showFuelStations;

  /// No description provided for @showFuelStationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Include gas, diesel, LPG, CNG stations'**
  String get showFuelStationsDesc;

  /// No description provided for @showEvStations.
  ///
  /// In en, this message translates to:
  /// **'Show EV charging stations'**
  String get showEvStations;

  /// No description provided for @showEvStationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Include electric charging stations in search results'**
  String get showEvStationsDesc;

  /// No description provided for @noStationsAlongThisRoute.
  ///
  /// In en, this message translates to:
  /// **'No stations found along this route.'**
  String get noStationsAlongThisRoute;

  /// No description provided for @fuelCostCalculator.
  ///
  /// In en, this message translates to:
  /// **'Fuel Cost Calculator'**
  String get fuelCostCalculator;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get distanceKm;

  /// No description provided for @consumptionL100km.
  ///
  /// In en, this message translates to:
  /// **'Consumption (L/100km)'**
  String get consumptionL100km;

  /// No description provided for @fuelPriceEurL.
  ///
  /// In en, this message translates to:
  /// **'Fuel price (EUR/L)'**
  String get fuelPriceEurL;

  /// No description provided for @tripCost.
  ///
  /// In en, this message translates to:
  /// **'Trip Cost'**
  String get tripCost;

  /// No description provided for @fuelNeeded.
  ///
  /// In en, this message translates to:
  /// **'Fuel needed'**
  String get fuelNeeded;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get totalCost;

  /// No description provided for @enterCalcValues.
  ///
  /// In en, this message translates to:
  /// **'Enter distance, consumption, and price to calculate trip cost'**
  String get enterCalcValues;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price History'**
  String get priceHistory;

  /// No description provided for @noPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'No price history yet'**
  String get noPriceHistory;

  /// No description provided for @noHourlyData.
  ///
  /// In en, this message translates to:
  /// **'No hourly data'**
  String get noHourlyData;

  /// No description provided for @noStatistics.
  ///
  /// In en, this message translates to:
  /// **'No statistics available'**
  String get noStatistics;

  /// No description provided for @statMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statMin;

  /// No description provided for @statMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statMax;

  /// No description provided for @statAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get statAvg;

  /// No description provided for @showAllFuelTypes.
  ///
  /// In en, this message translates to:
  /// **'Show all fuel types'**
  String get showAllFuelTypes;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @connectTankSync.
  ///
  /// In en, this message translates to:
  /// **'Connect TankSync'**
  String get connectTankSync;

  /// No description provided for @disconnectTankSync.
  ///
  /// In en, this message translates to:
  /// **'Disconnect TankSync'**
  String get disconnectTankSync;

  /// No description provided for @viewMyData.
  ///
  /// In en, this message translates to:
  /// **'View my data'**
  String get viewMyData;

  /// No description provided for @optionalCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Optional cloud sync for alerts, favorites, and push notifications'**
  String get optionalCloudSync;

  /// No description provided for @tapToUpdateGps.
  ///
  /// In en, this message translates to:
  /// **'Tap to update GPS position'**
  String get tapToUpdateGps;

  /// No description provided for @gpsAutoUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'GPS position is acquired automatically when you search. You can also update it manually here.'**
  String get gpsAutoUpdateHint;

  /// No description provided for @clearGpsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear the stored GPS position? You can update it again at any time.'**
  String get clearGpsConfirm;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @deleteAllServerData.
  ///
  /// In en, this message translates to:
  /// **'Delete all server data'**
  String get deleteAllServerData;

  /// No description provided for @deleteServerDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all server data?'**
  String get deleteServerDataConfirm;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteEverything;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All server data deleted'**
  String get allDataDeleted;

  /// No description provided for @disconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect TankSync?'**
  String get disconnectConfirm;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @myServerData.
  ///
  /// In en, this message translates to:
  /// **'My server data'**
  String get myServerData;

  /// No description provided for @anonymousUuid.
  ///
  /// In en, this message translates to:
  /// **'Anonymous UUID'**
  String get anonymousUuid;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @syncedData.
  ///
  /// In en, this message translates to:
  /// **'Synced data'**
  String get syncedData;

  /// No description provided for @pushTokens.
  ///
  /// In en, this message translates to:
  /// **'Push tokens'**
  String get pushTokens;

  /// No description provided for @priceReports.
  ///
  /// In en, this message translates to:
  /// **'Price reports'**
  String get priceReports;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get totalItems;

  /// No description provided for @estimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated size'**
  String get estimatedSize;

  /// No description provided for @viewRawJson.
  ///
  /// In en, this message translates to:
  /// **'View raw data as JSON'**
  String get viewRawJson;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON (clipboard)'**
  String get exportJson;

  /// No description provided for @jsonCopied.
  ///
  /// In en, this message translates to:
  /// **'JSON copied to clipboard'**
  String get jsonCopied;

  /// No description provided for @rawDataJson.
  ///
  /// In en, this message translates to:
  /// **'Raw data (JSON)'**
  String get rawDataJson;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @upgradeToEmail.
  ///
  /// In en, this message translates to:
  /// **'Create email account'**
  String get upgradeToEmail;

  /// No description provided for @savedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Saved Routes'**
  String get savedRoutes;

  /// No description provided for @noSavedRoutes.
  ///
  /// In en, this message translates to:
  /// **'No saved routes'**
  String get noSavedRoutes;

  /// No description provided for @noSavedRoutesHint.
  ///
  /// In en, this message translates to:
  /// **'Search along a route and save it for quick access later.'**
  String get noSavedRoutesHint;

  /// No description provided for @saveRoute.
  ///
  /// In en, this message translates to:
  /// **'Save route'**
  String get saveRoute;

  /// No description provided for @routeName.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get routeName;

  /// No description provided for @itineraryDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String itineraryDeleted(String name);

  /// No description provided for @loadingRoute.
  ///
  /// In en, this message translates to:
  /// **'Loading route: {name}'**
  String loadingRoute(String name);

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed. Please try again.'**
  String get refreshFailed;

  /// No description provided for @deleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get deleteProfileTitle;

  /// No description provided for @deleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'This profile and its settings will be permanently deleted. This cannot be undone.'**
  String get deleteProfileBody;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get deleteProfileConfirm;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoConnection;

  /// No description provided for @errorApiKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key. Check your settings.'**
  String get errorApiKey;

  /// No description provided for @errorLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location.'**
  String get errorLocation;

  /// No description provided for @errorNoApiKey.
  ///
  /// In en, this message translates to:
  /// **'No API key configured. Go to Settings to add one.'**
  String get errorNoApiKey;

  /// No description provided for @errorAllServicesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load data. Check your connection and try again.'**
  String get errorAllServicesFailed;

  /// No description provided for @errorCache.
  ///
  /// In en, this message translates to:
  /// **'Local data error. Try clearing the cache.'**
  String get errorCache;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnknown;

  /// No description provided for @onboardingWelcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Set up the app in a few quick steps.'**
  String get onboardingWelcomeHint;

  /// No description provided for @onboardingApiKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Register for a free API key, or skip to explore the app with demo data.'**
  String get onboardingApiKeyDescription;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'All set!'**
  String get onboardingComplete;

  /// No description provided for @onboardingCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'You can change these settings anytime in your profile.'**
  String get onboardingCompleteHint;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingFinish;

  /// No description provided for @crossBorderNearby.
  ///
  /// In en, this message translates to:
  /// **'{country} is nearby'**
  String crossBorderNearby(String country);

  /// No description provided for @crossBorderDistance.
  ///
  /// In en, this message translates to:
  /// **'~{km} km to border'**
  String crossBorderDistance(int km);

  /// No description provided for @crossBorderAvgPrice.
  ///
  /// In en, this message translates to:
  /// **'Avg here: {price} EUR ({count} stations)'**
  String crossBorderAvgPrice(String price, int count);

  /// No description provided for @allPricesView.
  ///
  /// In en, this message translates to:
  /// **'All prices'**
  String get allPricesView;

  /// No description provided for @compactView.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compactView;

  /// No description provided for @switchToAllPricesView.
  ///
  /// In en, this message translates to:
  /// **'Switch to all-prices view'**
  String get switchToAllPricesView;

  /// No description provided for @switchToCompactView.
  ///
  /// In en, this message translates to:
  /// **'Switch to compact view'**
  String get switchToCompactView;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get unavailable;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @gdprTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Privacy'**
  String get gdprTitle;

  /// No description provided for @gdprSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This app respects your privacy. Choose which data you want to share. You can change these settings anytime.'**
  String get gdprSubtitle;

  /// No description provided for @gdprLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get gdprLocationTitle;

  /// No description provided for @gdprLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Your coordinates are sent to the fuel price API to find nearby stations. Location data is never stored on a server and is not used for tracking.'**
  String get gdprLocationDescription;

  /// No description provided for @gdprLocationShort.
  ///
  /// In en, this message translates to:
  /// **'Find nearby fuel stations using your location'**
  String get gdprLocationShort;

  /// No description provided for @gdprErrorReportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Reporting'**
  String get gdprErrorReportingTitle;

  /// No description provided for @gdprErrorReportingDescription.
  ///
  /// In en, this message translates to:
  /// **'Anonymous crash reports help improve the app. No personal data is included. Reports are sent via Sentry only when configured.'**
  String get gdprErrorReportingDescription;

  /// No description provided for @gdprErrorReportingShort.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous crash reports to improve the app'**
  String get gdprErrorReportingShort;

  /// No description provided for @gdprCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get gdprCloudSyncTitle;

  /// No description provided for @gdprCloudSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync favorites and alerts across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.'**
  String get gdprCloudSyncDescription;

  /// No description provided for @gdprCloudSyncShort.
  ///
  /// In en, this message translates to:
  /// **'Sync favorites and alerts across devices'**
  String get gdprCloudSyncShort;

  /// No description provided for @gdprLegalBasis.
  ///
  /// In en, this message translates to:
  /// **'Legal basis: Art. 6(1)(a) GDPR (Consent). You can withdraw consent anytime in Settings.'**
  String get gdprLegalBasis;

  /// No description provided for @gdprAcceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept All'**
  String get gdprAcceptAll;

  /// No description provided for @gdprAcceptSelected.
  ///
  /// In en, this message translates to:
  /// **'Accept Selected'**
  String get gdprAcceptSelected;

  /// No description provided for @gdprSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can change your privacy choices at any time.'**
  String get gdprSettingsHint;

  /// No description provided for @routeSaved.
  ///
  /// In en, this message translates to:
  /// **'Route saved!'**
  String get routeSaved;

  /// No description provided for @routeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save route'**
  String get routeSaveFailed;

  /// No description provided for @sqlCopied.
  ///
  /// In en, this message translates to:
  /// **'SQL copied to clipboard'**
  String get sqlCopied;

  /// No description provided for @connectionDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Connection data copied'**
  String get connectionDataCopied;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted. Local data preserved.'**
  String get accountDeleted;

  /// No description provided for @switchedToAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Switched to anonymous session'**
  String get switchedToAnonymous;

  /// No description provided for @failedToSwitch.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch: {error}'**
  String failedToSwitch(String error);

  /// No description provided for @topicUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Topic URL copied'**
  String get topicUrlCopied;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get testNotificationSent;

  /// No description provided for @testNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send test notification'**
  String get testNotificationFailed;

  /// No description provided for @pushUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update push notification setting'**
  String get pushUpdateFailed;

  /// No description provided for @connectedAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Connected as guest'**
  String get connectedAsGuest;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get accountCreated;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in!'**
  String get signedIn;

  /// No description provided for @stationHidden.
  ///
  /// In en, this message translates to:
  /// **'{name} hidden'**
  String stationHidden(String name);

  /// No description provided for @removedFromFavoritesName.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from favorites'**
  String removedFromFavoritesName(String name);

  /// No description provided for @invalidApiKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key: {error}'**
  String invalidApiKey(String error);

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code format'**
  String get invalidQrCode;

  /// No description provided for @invalidQrCodeTankSync.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code — expected TankSync format'**
  String get invalidQrCodeTankSync;

  /// No description provided for @tankSyncConnected.
  ///
  /// In en, this message translates to:
  /// **'TankSync connected!'**
  String get tankSyncConnected;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed — data refreshed'**
  String get syncCompleted;

  /// No description provided for @deviceCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Device code copied'**
  String get deviceCodeCopied;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @invalidPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid {length}-digit {label}'**
  String invalidPostalCode(String length, String label);

  /// No description provided for @freshnessAgo.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get freshnessAgo;

  /// No description provided for @freshnessStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get freshnessStale;

  /// No description provided for @freshnessBadgeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Data freshness: {age}'**
  String freshnessBadgeSemantics(String age);

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordReqMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordReqMinLength;

  /// No description provided for @passwordReqUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least 1 uppercase letter'**
  String get passwordReqUppercase;

  /// No description provided for @passwordReqLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least 1 lowercase letter'**
  String get passwordReqLowercase;

  /// No description provided for @passwordReqDigit.
  ///
  /// In en, this message translates to:
  /// **'At least 1 number'**
  String get passwordReqDigit;

  /// No description provided for @passwordReqSpecial.
  ///
  /// In en, this message translates to:
  /// **'At least 1 special character'**
  String get passwordReqSpecial;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet all requirements'**
  String get passwordTooWeak;

  /// No description provided for @brandFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get brandFilterAll;

  /// No description provided for @brandFilterNoHighway.
  ///
  /// In en, this message translates to:
  /// **'No highway'**
  String get brandFilterNoHighway;

  /// No description provided for @swipeTutorialMessage.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to navigate, swipe left to remove'**
  String get swipeTutorialMessage;

  /// No description provided for @swipeTutorialDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get swipeTutorialDismiss;

  /// No description provided for @alertStatsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alertStatsActive;

  /// No description provided for @alertStatsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get alertStatsToday;

  /// No description provided for @alertStatsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get alertStatsThisWeek;

  /// No description provided for @privacyDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Dashboard'**
  String get privacyDashboardTitle;

  /// No description provided for @privacyDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, export, or delete your data'**
  String get privacyDashboardSubtitle;

  /// No description provided for @privacyDashboardBanner.
  ///
  /// In en, this message translates to:
  /// **'Your data belongs to you. Here you can see everything this app stores, export it, or delete it.'**
  String get privacyDashboardBanner;

  /// No description provided for @privacyLocalData.
  ///
  /// In en, this message translates to:
  /// **'Data on this device'**
  String get privacyLocalData;

  /// No description provided for @privacyIgnoredStations.
  ///
  /// In en, this message translates to:
  /// **'Ignored stations'**
  String get privacyIgnoredStations;

  /// No description provided for @privacyRatings.
  ///
  /// In en, this message translates to:
  /// **'Station ratings'**
  String get privacyRatings;

  /// No description provided for @privacyPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history stations'**
  String get privacyPriceHistory;

  /// No description provided for @privacyProfiles.
  ///
  /// In en, this message translates to:
  /// **'Search profiles'**
  String get privacyProfiles;

  /// No description provided for @privacyItineraries.
  ///
  /// In en, this message translates to:
  /// **'Saved routes'**
  String get privacyItineraries;

  /// No description provided for @privacyCacheEntries.
  ///
  /// In en, this message translates to:
  /// **'Cache entries'**
  String get privacyCacheEntries;

  /// No description provided for @privacyApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key stored'**
  String get privacyApiKey;

  /// No description provided for @privacyEvApiKey.
  ///
  /// In en, this message translates to:
  /// **'EV API key stored'**
  String get privacyEvApiKey;

  /// No description provided for @privacyEstimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated storage'**
  String get privacyEstimatedSize;

  /// No description provided for @privacySyncedData.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync (TankSync)'**
  String get privacySyncedData;

  /// No description provided for @privacySyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync is disabled. All data stays on this device only.'**
  String get privacySyncDisabled;

  /// No description provided for @privacySyncMode.
  ///
  /// In en, this message translates to:
  /// **'Sync mode'**
  String get privacySyncMode;

  /// No description provided for @privacySyncUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get privacySyncUserId;

  /// No description provided for @privacySyncDescription.
  ///
  /// In en, this message translates to:
  /// **'When sync is enabled, favorites, alerts, ignored stations, and ratings are also stored on the TankSync server.'**
  String get privacySyncDescription;

  /// No description provided for @privacyViewServerData.
  ///
  /// In en, this message translates to:
  /// **'View server data'**
  String get privacyViewServerData;

  /// No description provided for @privacyExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export all data as JSON'**
  String get privacyExportButton;

  /// No description provided for @privacyExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported to clipboard'**
  String get privacyExportSuccess;

  /// No description provided for @privacyExportCsvButton.
  ///
  /// In en, this message translates to:
  /// **'Export all data as CSV'**
  String get privacyExportCsvButton;

  /// No description provided for @privacyExportCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV data exported to clipboard'**
  String get privacyExportCsvSuccess;

  /// No description provided for @privacyDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get privacyDeleteButton;

  /// Button that copies recorded error traces to the clipboard. count = number of traces buffered.
  ///
  /// In en, this message translates to:
  /// **'Copy error log to clipboard ({count})'**
  String privacyCopyErrorLog(int count);

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:\n\n- All favorites and station data\n- All search profiles\n- All price alerts\n- All price history\n- All cached data\n- Your API key\n- All app settings\n\nThe app will reset to its initial state. This action cannot be undone.'**
  String get privacyDeleteBody;

  /// No description provided for @privacyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get privacyDeleteConfirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @amenityShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get amenityShop;

  /// No description provided for @amenityCarWash.
  ///
  /// In en, this message translates to:
  /// **'Car Wash'**
  String get amenityCarWash;

  /// No description provided for @amenityAirPump.
  ///
  /// In en, this message translates to:
  /// **'Air'**
  String get amenityAirPump;

  /// No description provided for @amenityToilet.
  ///
  /// In en, this message translates to:
  /// **'WC'**
  String get amenityToilet;

  /// No description provided for @amenityRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get amenityRestaurant;

  /// No description provided for @amenityAtm.
  ///
  /// In en, this message translates to:
  /// **'ATM'**
  String get amenityAtm;

  /// No description provided for @amenityWifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get amenityWifi;

  /// No description provided for @amenityEv.
  ///
  /// In en, this message translates to:
  /// **'EV'**
  String get amenityEv;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodContactless.
  ///
  /// In en, this message translates to:
  /// **'Contactless'**
  String get paymentMethodContactless;

  /// No description provided for @paymentMethodFuelCard.
  ///
  /// In en, this message translates to:
  /// **'Fuel Card'**
  String get paymentMethodFuelCard;

  /// No description provided for @paymentMethodApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get paymentMethodApp;

  /// Button label to open a branded station payment app
  ///
  /// In en, this message translates to:
  /// **'Pay with {app}'**
  String payWithApp(String app);

  /// Fuel consumption number on the eco-score badge
  ///
  /// In en, this message translates to:
  /// **'{value} L/100 km'**
  String ecoScoreConsumption(String value);

  /// Eco-score badge tooltip explaining the 3-fill-up window
  ///
  /// In en, this message translates to:
  /// **'Compared to the rolling average over your last 3 fill-ups ({avg} L/100 km).'**
  String ecoScoreTooltip(String avg);

  /// TalkBack / VoiceOver label for the eco-score badge
  ///
  /// In en, this message translates to:
  /// **'Consumption {value} L/100 km, {delta} versus your rolling average'**
  String ecoScoreSemantics(String value, String delta);

  /// No description provided for @drivingMode.
  ///
  /// In en, this message translates to:
  /// **'Driving Mode'**
  String get drivingMode;

  /// No description provided for @drivingExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get drivingExit;

  /// No description provided for @drivingNearestStation.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get drivingNearestStation;

  /// No description provided for @drivingTapToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get drivingTapToUnlock;

  /// No description provided for @drivingSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Notice'**
  String get drivingSafetyTitle;

  /// No description provided for @drivingSafetyMessage.
  ///
  /// In en, this message translates to:
  /// **'Do not operate the app while driving. Pull over to a safe location before interacting with the screen. The driver is responsible for safe operation of the vehicle at all times.'**
  String get drivingSafetyMessage;

  /// No description provided for @drivingSafetyAccept.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get drivingSafetyAccept;

  /// No description provided for @voiceAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Announcements'**
  String get voiceAnnouncementsTitle;

  /// No description provided for @voiceAnnouncementsDescription.
  ///
  /// In en, this message translates to:
  /// **'Announce nearby cheap stations while driving'**
  String get voiceAnnouncementsDescription;

  /// No description provided for @voiceAnnouncementsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable voice announcements'**
  String get voiceAnnouncementsEnabled;

  /// No description provided for @voiceAnnouncementThreshold.
  ///
  /// In en, this message translates to:
  /// **'Only below {price}'**
  String voiceAnnouncementThreshold(String price);

  /// No description provided for @voiceAnnouncementCheapFuel.
  ///
  /// In en, this message translates to:
  /// **'{station}, {distance} kilometers ahead, {fuelType} {price}'**
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  );

  /// No description provided for @voiceAnnouncementProximityRadius.
  ///
  /// In en, this message translates to:
  /// **'Announcement radius'**
  String get voiceAnnouncementProximityRadius;

  /// No description provided for @voiceAnnouncementCooldown.
  ///
  /// In en, this message translates to:
  /// **'Repeat interval'**
  String get voiceAnnouncementCooldown;

  /// No description provided for @nearestStations.
  ///
  /// In en, this message translates to:
  /// **'Nearest stations'**
  String get nearestStations;

  /// No description provided for @nearestStationsHint.
  ///
  /// In en, this message translates to:
  /// **'Find the closest stations using your current location'**
  String get nearestStationsHint;

  /// No description provided for @consumptionLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel consumption'**
  String get consumptionLogTitle;

  /// No description provided for @consumptionLogMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Consumption log'**
  String get consumptionLogMenuTitle;

  /// No description provided for @consumptionLogMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track fill-ups and calculate L/100km'**
  String get consumptionLogMenuSubtitle;

  /// No description provided for @consumptionStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Consumption stats'**
  String get consumptionStatsTitle;

  /// No description provided for @addFillUp.
  ///
  /// In en, this message translates to:
  /// **'Add fill-up'**
  String get addFillUp;

  /// No description provided for @noFillUpsTitle.
  ///
  /// In en, this message translates to:
  /// **'No fill-ups yet'**
  String get noFillUpsTitle;

  /// No description provided for @noFillUpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log your first fill-up to start tracking consumption.'**
  String get noFillUpsSubtitle;

  /// No description provided for @fillUpDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fillUpDate;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get liters;

  /// No description provided for @odometerKm.
  ///
  /// In en, this message translates to:
  /// **'Odometer (km)'**
  String get odometerKm;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @stationPreFilled.
  ///
  /// In en, this message translates to:
  /// **'Station pre-filled'**
  String get stationPreFilled;

  /// No description provided for @statAvgConsumption.
  ///
  /// In en, this message translates to:
  /// **'Avg L/100km'**
  String get statAvgConsumption;

  /// No description provided for @statAvgCostPerKm.
  ///
  /// In en, this message translates to:
  /// **'Avg cost/km'**
  String get statAvgCostPerKm;

  /// No description provided for @statTotalLiters.
  ///
  /// In en, this message translates to:
  /// **'Total liters'**
  String get statTotalLiters;

  /// No description provided for @statTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get statTotalSpent;

  /// No description provided for @statFillUpCount.
  ///
  /// In en, this message translates to:
  /// **'Fill-ups'**
  String get statFillUpCount;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @fieldInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get fieldInvalidNumber;

  /// No description provided for @carbonDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Carbon dashboard'**
  String get carbonDashboardTitle;

  /// No description provided for @carbonEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get carbonEmptyTitle;

  /// No description provided for @carbonEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log fill-ups to see your carbon dashboard.'**
  String get carbonEmptySubtitle;

  /// No description provided for @carbonSummaryTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get carbonSummaryTotalCost;

  /// No description provided for @carbonSummaryTotalCo2.
  ///
  /// In en, this message translates to:
  /// **'Total CO2'**
  String get carbonSummaryTotalCo2;

  /// No description provided for @monthlyCostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly costs'**
  String get monthlyCostsTitle;

  /// No description provided for @monthlyEmissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly CO2 emissions'**
  String get monthlyEmissionsTitle;

  /// No description provided for @vehiclesTitle.
  ///
  /// In en, this message translates to:
  /// **'My vehicles'**
  String get vehiclesTitle;

  /// No description provided for @vehiclesMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'My vehicles'**
  String get vehiclesMenuTitle;

  /// No description provided for @vehiclesMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Battery, connectors, charging preferences'**
  String get vehiclesMenuSubtitle;

  /// No description provided for @vehiclesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your car to filter by connector and estimate charging costs.'**
  String get vehiclesEmptyMessage;

  /// No description provided for @vehiclesWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'My vehicles (optional)'**
  String get vehiclesWizardTitle;

  /// No description provided for @vehiclesWizardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your car to pre-fill the consumption log and enable EV connector filters. You can skip this and add vehicles later.'**
  String get vehiclesWizardSubtitle;

  /// No description provided for @vehiclesWizardNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No vehicle configured yet.'**
  String get vehiclesWizardNoneYet;

  /// No description provided for @vehiclesWizardYoursList.
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{1 vehicle} other{{count} vehicles}}:'**
  String vehiclesWizardYoursList(int count);

  /// No description provided for @vehiclesWizardSkipHint.
  ///
  /// In en, this message translates to:
  /// **'Skip to finish setup — you can add vehicles anytime from Settings.'**
  String get vehiclesWizardSkipHint;

  /// No description provided for @fillUpVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get fillUpVehicleLabel;

  /// No description provided for @fillUpVehicleNone.
  ///
  /// In en, this message translates to:
  /// **'No vehicle'**
  String get fillUpVehicleNone;

  /// No description provided for @fillUpVehicleRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle is required'**
  String get fillUpVehicleRequired;

  /// No description provided for @reportScanError.
  ///
  /// In en, this message translates to:
  /// **'Report scan error'**
  String get reportScanError;

  /// No description provided for @pickStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a station'**
  String get pickStationTitle;

  /// No description provided for @pickStationHelper.
  ///
  /// In en, this message translates to:
  /// **'Start the fill-up from a known station so prices, brand and fuel type fill themselves in.'**
  String get pickStationHelper;

  /// No description provided for @pickStationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite stations yet — add some from Search or Favorites, or skip and fill in manually.'**
  String get pickStationEmpty;

  /// No description provided for @pickStationSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip — add without a station'**
  String get pickStationSkip;

  /// No description provided for @scanPump.
  ///
  /// In en, this message translates to:
  /// **'Scan pump'**
  String get scanPump;

  /// No description provided for @scanPayment.
  ///
  /// In en, this message translates to:
  /// **'Scan payment QR'**
  String get scanPayment;

  /// No description provided for @qrPaymentBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get qrPaymentBeneficiary;

  /// No description provided for @qrPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get qrPaymentAmount;

  /// No description provided for @qrPaymentEpcTitle.
  ///
  /// In en, this message translates to:
  /// **'SEPA payment'**
  String get qrPaymentEpcTitle;

  /// No description provided for @qrPaymentEpcEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fields decoded'**
  String get qrPaymentEpcEmpty;

  /// No description provided for @qrPaymentOpenInBank.
  ///
  /// In en, this message translates to:
  /// **'Open in bank app'**
  String get qrPaymentOpenInBank;

  /// No description provided for @qrPaymentLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'No app available to open this code'**
  String get qrPaymentLaunchFailed;

  /// No description provided for @qrPaymentUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised code'**
  String get qrPaymentUnknownTitle;

  /// No description provided for @qrPaymentCopyRaw.
  ///
  /// In en, this message translates to:
  /// **'Copy raw text'**
  String get qrPaymentCopyRaw;

  /// No description provided for @qrPaymentCopiedRaw.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get qrPaymentCopiedRaw;

  /// No description provided for @qrPaymentReport.
  ///
  /// In en, this message translates to:
  /// **'Report this scan'**
  String get qrPaymentReport;

  /// No description provided for @qrPaymentEpcCopied.
  ///
  /// In en, this message translates to:
  /// **'Bank details copied — paste into your banking app'**
  String get qrPaymentEpcCopied;

  /// No description provided for @qrScannerGuidance.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a QR code'**
  String get qrScannerGuidance;

  /// No description provided for @qrScannerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan QR codes.'**
  String get qrScannerPermissionDenied;

  /// No description provided for @qrScannerPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Open settings to grant it.'**
  String get qrScannerPermissionPermanentlyDenied;

  /// No description provided for @qrScannerRetryPermission.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get qrScannerRetryPermission;

  /// No description provided for @qrScannerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get qrScannerOpenSettings;

  /// No description provided for @qrScannerTimeout.
  ///
  /// In en, this message translates to:
  /// **'No QR code detected. Move closer or try again.'**
  String get qrScannerTimeout;

  /// No description provided for @qrScannerRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get qrScannerRetry;

  /// No description provided for @torchOn.
  ///
  /// In en, this message translates to:
  /// **'Turn flash on'**
  String get torchOn;

  /// No description provided for @torchOff.
  ///
  /// In en, this message translates to:
  /// **'Turn flash off'**
  String get torchOff;

  /// No description provided for @obdNoAdapter.
  ///
  /// In en, this message translates to:
  /// **'No OBD2 adapter in range'**
  String get obdNoAdapter;

  /// No description provided for @obdOdometerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not read odometer'**
  String get obdOdometerUnavailable;

  /// No description provided for @obdPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Grant Bluetooth permission in system settings'**
  String get obdPermissionDenied;

  /// No description provided for @obdAdapterUnresponsive.
  ///
  /// In en, this message translates to:
  /// **'Adapter didn\'t answer — turn the ignition on and retry'**
  String get obdAdapterUnresponsive;

  /// No description provided for @obdPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an OBD2 adapter'**
  String get obdPickerTitle;

  /// No description provided for @obdPickerScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for adapters…'**
  String get obdPickerScanning;

  /// No description provided for @obdPickerConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get obdPickerConnecting;

  /// No description provided for @themeSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettingTitle;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeModeSystem;

  /// No description provided for @tripRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording trip'**
  String get tripRecordingTitle;

  /// No description provided for @tripSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get tripSummaryTitle;

  /// No description provided for @tripMetricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get tripMetricDistance;

  /// No description provided for @tripMetricSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get tripMetricSpeed;

  /// No description provided for @tripMetricFuelUsed.
  ///
  /// In en, this message translates to:
  /// **'Fuel used'**
  String get tripMetricFuelUsed;

  /// No description provided for @tripMetricAvgConsumption.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get tripMetricAvgConsumption;

  /// No description provided for @tripMetricElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get tripMetricElapsed;

  /// No description provided for @tripMetricOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get tripMetricOdometer;

  /// No description provided for @tripStop.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get tripStop;

  /// No description provided for @tripPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get tripPause;

  /// No description provided for @tripResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get tripResume;

  /// No description provided for @tripBannerRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording trip'**
  String get tripBannerRecording;

  /// No description provided for @tripBannerPaused.
  ///
  /// In en, this message translates to:
  /// **'Trip paused — tap to resume'**
  String get tripBannerPaused;

  /// No description provided for @navConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get navConsumption;

  /// No description provided for @vehicleBaselineSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Baseline calibration'**
  String get vehicleBaselineSectionTitle;

  /// No description provided for @vehicleBaselineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No samples yet — start an OBD2 trip to begin learning this vehicle\'s fuel profile.'**
  String get vehicleBaselineEmpty;

  /// No description provided for @vehicleBaselineProgress.
  ///
  /// In en, this message translates to:
  /// **'Learned from samples across driving situations.'**
  String get vehicleBaselineProgress;

  /// No description provided for @vehicleBaselineReset.
  ///
  /// In en, this message translates to:
  /// **'Reset driving-situation baseline'**
  String get vehicleBaselineReset;

  /// No description provided for @vehicleBaselineResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset driving-situation baseline?'**
  String get vehicleBaselineResetConfirmTitle;

  /// No description provided for @vehicleBaselineResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This wipes every learned sample for this vehicle. You\'ll drift back to the cold-start defaults until new trips refill the profile.'**
  String get vehicleBaselineResetConfirmBody;

  /// No description provided for @vehicleAdapterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter'**
  String get vehicleAdapterSectionTitle;

  /// No description provided for @vehicleAdapterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No adapter paired. Pair one so the app can reconnect automatically next time.'**
  String get vehicleAdapterEmpty;

  /// No description provided for @vehicleAdapterUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unknown adapter'**
  String get vehicleAdapterUnnamed;

  /// No description provided for @vehicleAdapterPair.
  ///
  /// In en, this message translates to:
  /// **'Pair adapter'**
  String get vehicleAdapterPair;

  /// No description provided for @vehicleAdapterForget.
  ///
  /// In en, this message translates to:
  /// **'Forget adapter'**
  String get vehicleAdapterForget;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementFirstTrip.
  ///
  /// In en, this message translates to:
  /// **'First trip'**
  String get achievementFirstTrip;

  /// No description provided for @achievementFirstTripDesc.
  ///
  /// In en, this message translates to:
  /// **'Record your first OBD2 trip.'**
  String get achievementFirstTripDesc;

  /// No description provided for @achievementFirstFillUp.
  ///
  /// In en, this message translates to:
  /// **'First fill-up'**
  String get achievementFirstFillUp;

  /// No description provided for @achievementFirstFillUpDesc.
  ///
  /// In en, this message translates to:
  /// **'Log your first fill-up.'**
  String get achievementFirstFillUpDesc;

  /// No description provided for @achievementTenTrips.
  ///
  /// In en, this message translates to:
  /// **'10 trips'**
  String get achievementTenTrips;

  /// No description provided for @achievementTenTripsDesc.
  ///
  /// In en, this message translates to:
  /// **'Record 10 OBD2 trips.'**
  String get achievementTenTripsDesc;

  /// No description provided for @achievementZeroHarsh.
  ///
  /// In en, this message translates to:
  /// **'Smooth driver'**
  String get achievementZeroHarsh;

  /// No description provided for @achievementZeroHarshDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a trip of 10 km or more with no harsh braking or acceleration.'**
  String get achievementZeroHarshDesc;

  /// No description provided for @achievementEcoWeek.
  ///
  /// In en, this message translates to:
  /// **'Eco week'**
  String get achievementEcoWeek;

  /// No description provided for @achievementEcoWeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Drive 7 consecutive days with at least one smooth trip each day.'**
  String get achievementEcoWeekDesc;

  /// No description provided for @achievementPriceWin.
  ///
  /// In en, this message translates to:
  /// **'Price win'**
  String get achievementPriceWin;

  /// No description provided for @achievementPriceWinDesc.
  ///
  /// In en, this message translates to:
  /// **'Log a fill-up that beats the station\'s 30-day average by 5 % or more.'**
  String get achievementPriceWinDesc;

  /// No description provided for @syncBaselinesToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Share learned vehicle profiles'**
  String get syncBaselinesToggleTitle;

  /// No description provided for @syncBaselinesToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload per-vehicle consumption baselines so a second device can reuse them.'**
  String get syncBaselinesToggleSubtitle;

  /// No description provided for @obd2StatusConnected.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter: connected'**
  String get obd2StatusConnected;

  /// No description provided for @obd2StatusAttempting.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter: connecting'**
  String get obd2StatusAttempting;

  /// No description provided for @obd2StatusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter: unreachable'**
  String get obd2StatusUnreachable;

  /// No description provided for @obd2StatusPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter: Bluetooth permission needed'**
  String get obd2StatusPermissionDenied;

  /// No description provided for @obd2StatusConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to record a trip.'**
  String get obd2StatusConnectedBody;

  /// No description provided for @obd2StatusAttemptingBody.
  ///
  /// In en, this message translates to:
  /// **'Connecting in the background…'**
  String get obd2StatusAttemptingBody;

  /// No description provided for @obd2StatusUnreachableBody.
  ///
  /// In en, this message translates to:
  /// **'Adapter out of range or already in use by another app.'**
  String get obd2StatusUnreachableBody;

  /// No description provided for @obd2StatusPermissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Grant Bluetooth permission in system settings to reconnect automatically.'**
  String get obd2StatusPermissionDeniedBody;

  /// No description provided for @obd2StatusNoAdapter.
  ///
  /// In en, this message translates to:
  /// **'No adapter paired'**
  String get obd2StatusNoAdapter;

  /// No description provided for @obd2StatusForget.
  ///
  /// In en, this message translates to:
  /// **'Forget adapter'**
  String get obd2StatusForget;

  /// No description provided for @tripHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistoryTitle;

  /// No description provided for @tripHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get tripHistoryEmptyTitle;

  /// No description provided for @tripHistoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect an OBD2 adapter and record a trip to start building your driving history.'**
  String get tripHistoryEmptySubtitle;

  /// No description provided for @tripHistoryUnknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get tripHistoryUnknownDate;

  /// No description provided for @situationIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get situationIdle;

  /// No description provided for @situationStopAndGo.
  ///
  /// In en, this message translates to:
  /// **'Stop & go'**
  String get situationStopAndGo;

  /// No description provided for @situationUrban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get situationUrban;

  /// No description provided for @situationHighway.
  ///
  /// In en, this message translates to:
  /// **'Highway'**
  String get situationHighway;

  /// No description provided for @situationDecel.
  ///
  /// In en, this message translates to:
  /// **'Decelerating'**
  String get situationDecel;

  /// No description provided for @situationClimbing.
  ///
  /// In en, this message translates to:
  /// **'Climbing / loaded'**
  String get situationClimbing;

  /// No description provided for @situationHardAccel.
  ///
  /// In en, this message translates to:
  /// **'Hard accel'**
  String get situationHardAccel;

  /// No description provided for @situationFuelCut.
  ///
  /// In en, this message translates to:
  /// **'Fuel cut — coast'**
  String get situationFuelCut;

  /// DEPRECATED (#1185): replaced by tripSaveRecording. Retained for parity with non-EN locales until the orphan-key sweep lands.
  ///
  /// In en, this message translates to:
  /// **'Save as fill-up'**
  String get tripSaveAsFillUp;

  /// Trip-summary CTA: persists a TripHistoryEntry only — no fill-up created. (#1185)
  ///
  /// In en, this message translates to:
  /// **'Save trip'**
  String get tripSaveRecording;

  /// No description provided for @tripDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get tripDiscard;

  /// No description provided for @obdOdometerRead.
  ///
  /// In en, this message translates to:
  /// **'Odometer read: {km} km'**
  String obdOdometerRead(int km);

  /// No description provided for @vehicleFuelNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get vehicleFuelNotSet;

  /// No description provided for @wizardVehicleTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get wizardVehicleTapToEdit;

  /// No description provided for @wizardVehicleDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get wizardVehicleDefaultBadge;

  /// No description provided for @profileDefaultVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Default vehicle (optional)'**
  String get profileDefaultVehicleLabel;

  /// No description provided for @profileDefaultVehicleNone.
  ///
  /// In en, this message translates to:
  /// **'No default'**
  String get profileDefaultVehicleNone;

  /// No description provided for @profileFuelFromVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Fuel type is derived from your default vehicle. Clear the vehicle to pick a fuel directly.'**
  String get profileFuelFromVehicleHint;

  /// No description provided for @consumptionNoVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle first'**
  String get consumptionNoVehicleTitle;

  /// No description provided for @consumptionNoVehicleBody.
  ///
  /// In en, this message translates to:
  /// **'Fill-ups are attributed to a vehicle. Add your car to start logging consumption.'**
  String get consumptionNoVehicleBody;

  /// No description provided for @vehicleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get vehicleAdd;

  /// No description provided for @vehicleAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get vehicleAddTitle;

  /// No description provided for @vehicleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get vehicleEditTitle;

  /// No description provided for @vehicleDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle?'**
  String get vehicleDeleteTitle;

  /// No description provided for @vehicleDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your profiles?'**
  String vehicleDeleteMessage(String name);

  /// No description provided for @vehicleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get vehicleNameLabel;

  /// No description provided for @vehicleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Tesla Model 3'**
  String get vehicleNameHint;

  /// No description provided for @vehicleTypeCombustion.
  ///
  /// In en, this message translates to:
  /// **'Combustion'**
  String get vehicleTypeCombustion;

  /// No description provided for @vehicleTypeHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get vehicleTypeHybrid;

  /// No description provided for @vehicleTypeEv.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get vehicleTypeEv;

  /// No description provided for @vehicleEvSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get vehicleEvSectionTitle;

  /// No description provided for @vehicleCombustionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Combustion'**
  String get vehicleCombustionSectionTitle;

  /// No description provided for @vehicleBatteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery capacity (kWh)'**
  String get vehicleBatteryLabel;

  /// No description provided for @vehicleMaxChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max charging power (kW)'**
  String get vehicleMaxChargeLabel;

  /// No description provided for @vehicleConnectorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Supported connectors'**
  String get vehicleConnectorsLabel;

  /// No description provided for @vehicleMinSocLabel.
  ///
  /// In en, this message translates to:
  /// **'Min SoC %'**
  String get vehicleMinSocLabel;

  /// No description provided for @vehicleMaxSocLabel.
  ///
  /// In en, this message translates to:
  /// **'Max SoC %'**
  String get vehicleMaxSocLabel;

  /// No description provided for @vehicleTankLabel.
  ///
  /// In en, this message translates to:
  /// **'Tank capacity (L)'**
  String get vehicleTankLabel;

  /// No description provided for @vehiclePreferredFuelLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred fuel'**
  String get vehiclePreferredFuelLabel;

  /// No description provided for @connectorType2.
  ///
  /// In en, this message translates to:
  /// **'Type 2'**
  String get connectorType2;

  /// No description provided for @connectorCcs.
  ///
  /// In en, this message translates to:
  /// **'CCS'**
  String get connectorCcs;

  /// No description provided for @connectorChademo.
  ///
  /// In en, this message translates to:
  /// **'CHAdeMO'**
  String get connectorChademo;

  /// No description provided for @connectorTesla.
  ///
  /// In en, this message translates to:
  /// **'Tesla'**
  String get connectorTesla;

  /// No description provided for @connectorSchuko.
  ///
  /// In en, this message translates to:
  /// **'Schuko'**
  String get connectorSchuko;

  /// No description provided for @connectorType1.
  ///
  /// In en, this message translates to:
  /// **'Type 1'**
  String get connectorType1;

  /// No description provided for @connectorThreePin.
  ///
  /// In en, this message translates to:
  /// **'3-pin'**
  String get connectorThreePin;

  /// No description provided for @evShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show EV stations'**
  String get evShowOnMap;

  /// No description provided for @evAvailableOnly.
  ///
  /// In en, this message translates to:
  /// **'Available only'**
  String get evAvailableOnly;

  /// No description provided for @evMinPower.
  ///
  /// In en, this message translates to:
  /// **'Min power'**
  String get evMinPower;

  /// No description provided for @evMaxPower.
  ///
  /// In en, this message translates to:
  /// **'Max power'**
  String get evMaxPower;

  /// No description provided for @evOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get evOperator;

  /// No description provided for @evLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get evLastUpdate;

  /// No description provided for @evStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get evStatusAvailable;

  /// No description provided for @evStatusOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get evStatusOccupied;

  /// No description provided for @evStatusOutOfOrder.
  ///
  /// In en, this message translates to:
  /// **'Out of order'**
  String get evStatusOutOfOrder;

  /// No description provided for @openOnlyFilter.
  ///
  /// In en, this message translates to:
  /// **'Open only'**
  String get openOnlyFilter;

  /// No description provided for @saveAsDefaults.
  ///
  /// In en, this message translates to:
  /// **'Save as my defaults'**
  String get saveAsDefaults;

  /// No description provided for @criteriaSavedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Saved as defaults'**
  String get criteriaSavedToProfile;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'No active profile'**
  String get profileNotFound;

  /// No description provided for @updatingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Updating your favorites...'**
  String get updatingFavorites;

  /// No description provided for @fetchingLatestPrices.
  ///
  /// In en, this message translates to:
  /// **'Fetching the latest prices'**
  String get fetchingLatestPrices;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noDataAvailable;

  /// No description provided for @configAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Configuration & Privacy'**
  String get configAndPrivacy;

  /// No description provided for @searchToSeeMap.
  ///
  /// In en, this message translates to:
  /// **'Search to see stations on the map'**
  String get searchToSeeMap;

  /// No description provided for @evPowerAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get evPowerAny;

  /// No description provided for @evPowerKw.
  ///
  /// In en, this message translates to:
  /// **'{kw} kW+'**
  String evPowerKw(int kw);

  /// No description provided for @sectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get sectionProfile;

  /// No description provided for @sectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sectionLocation;

  /// No description provided for @tooltipBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tooltipBack;

  /// No description provided for @tooltipClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tooltipClose;

  /// No description provided for @tooltipClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search input'**
  String get tooltipClearSearch;

  /// No description provided for @tooltipUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use GPS location'**
  String get tooltipUseGps;

  /// No description provided for @tooltipShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get tooltipShowPassword;

  /// No description provided for @tooltipHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get tooltipHidePassword;

  /// No description provided for @evConnectorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available connectors'**
  String get evConnectorsLabel;

  /// No description provided for @evConnectorsNone.
  ///
  /// In en, this message translates to:
  /// **'No connector information'**
  String get evConnectorsNone;

  /// No description provided for @switchToEmail.
  ///
  /// In en, this message translates to:
  /// **'Switch to email'**
  String get switchToEmail;

  /// No description provided for @switchToEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep data, add sign-in from other devices'**
  String get switchToEmailSubtitle;

  /// No description provided for @switchToAnonymousAction.
  ///
  /// In en, this message translates to:
  /// **'Switch to anonymous'**
  String get switchToAnonymousAction;

  /// No description provided for @switchToAnonymousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep local data, use new anonymous session'**
  String get switchToAnonymousSubtitle;

  /// No description provided for @linkDevice.
  ///
  /// In en, this message translates to:
  /// **'Link device'**
  String get linkDevice;

  /// No description provided for @shareDatabase.
  ///
  /// In en, this message translates to:
  /// **'Share database'**
  String get shareDatabase;

  /// No description provided for @disconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectAction;

  /// No description provided for @disconnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop syncing (local data kept)'**
  String get disconnectSubtitle;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all server data permanently'**
  String get deleteAccountSubtitle;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get localOnly;

  /// No description provided for @localOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: sync favorites, alerts, and ratings across devices'**
  String get localOnlySubtitle;

  /// No description provided for @setupCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Set up cloud sync'**
  String get setupCloudSync;

  /// No description provided for @disconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect TankSync?'**
  String get disconnectTitle;

  /// No description provided for @disconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync will be disabled. Your local data (favorites, alerts, history) is preserved on this device. Server data is not deleted.'**
  String get disconnectBody;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all your data from the server (favorites, alerts, ratings, routes). Local data on this device is preserved.\n\nThis cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @switchToAnonymousTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to anonymous?'**
  String get switchToAnonymousTitle;

  /// No description provided for @switchToAnonymousBody.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of your email account and continue with a new anonymous session.\n\nYour local data (favorites, alerts) is kept on this device and will be synced to the new anonymous account.'**
  String get switchToAnonymousBody;

  /// No description provided for @switchAction.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchAction;

  /// No description provided for @helpBannerCriteria.
  ///
  /// In en, this message translates to:
  /// **'Your profile defaults are pre-filled. Adjust criteria below to refine your search.'**
  String get helpBannerCriteria;

  /// No description provided for @helpBannerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Set a price threshold for a station. You\'ll be notified when prices drop below it. Checks run every 30 minutes.'**
  String get helpBannerAlerts;

  /// No description provided for @helpBannerConsumption.
  ///
  /// In en, this message translates to:
  /// **'Log every fill-up to track your real-world consumption and CO₂ footprint. Swipe left to delete an entry.'**
  String get helpBannerConsumption;

  /// No description provided for @helpBannerVehicles.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicles so fill-ups and fuel preferences default correctly. The first vehicle becomes your default.'**
  String get helpBannerVehicles;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingZipHelper.
  ///
  /// In en, this message translates to:
  /// **'Used when GPS is unavailable'**
  String get onboardingZipHelper;

  /// No description provided for @onboardingRadiusHelper.
  ///
  /// In en, this message translates to:
  /// **'Larger radius = more results'**
  String get onboardingRadiusHelper;

  /// No description provided for @onboardingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'These settings are stored only on your device and never shared.'**
  String get onboardingPrivacy;

  /// No description provided for @onboardingLandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get onboardingLandingTitle;

  /// No description provided for @onboardingLandingHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which screen opens when you launch the app.'**
  String get onboardingLandingHint;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// No description provided for @obdConnect.
  ///
  /// In en, this message translates to:
  /// **'OBD-II'**
  String get obdConnect;

  /// No description provided for @stationTypeFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get stationTypeFuel;

  /// No description provided for @stationTypeEv.
  ///
  /// In en, this message translates to:
  /// **'EV'**
  String get stationTypeEv;

  /// No description provided for @brandFilterHighway.
  ///
  /// In en, this message translates to:
  /// **'Highway'**
  String get brandFilterHighway;

  /// No description provided for @ratingModeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get ratingModeLocal;

  /// No description provided for @ratingModePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get ratingModePrivate;

  /// No description provided for @ratingModeShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get ratingModeShared;

  /// No description provided for @ratingDescLocal.
  ///
  /// In en, this message translates to:
  /// **'Ratings saved on this device only'**
  String get ratingDescLocal;

  /// No description provided for @ratingDescPrivate.
  ///
  /// In en, this message translates to:
  /// **'Synced with your database (not visible to others)'**
  String get ratingDescPrivate;

  /// No description provided for @ratingDescShared.
  ///
  /// In en, this message translates to:
  /// **'Visible to all users of your database'**
  String get ratingDescShared;

  /// No description provided for @errorNoEvApiKey.
  ///
  /// In en, this message translates to:
  /// **'OpenChargeMap API key not configured. Add one in Settings to search EV charging stations.'**
  String get errorNoEvApiKey;

  /// No description provided for @errorUpstreamCertExpired.
  ///
  /// In en, this message translates to:
  /// **'The data provider ({host}) is serving an expired or invalid TLS certificate. The app cannot load data from this source until the provider fixes it. Please contact {host}.'**
  String errorUpstreamCertExpired(String host);

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// No description provided for @fallbackSummary.
  ///
  /// In en, this message translates to:
  /// **'{failed} unavailable. Using {current}.'**
  String fallbackSummary(String failed, String current);

  /// No description provided for @errorTitleApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key required'**
  String get errorTitleApiKey;

  /// No description provided for @errorTitleLocation.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get errorTitleLocation;

  /// No description provided for @errorHintNoStations.
  ///
  /// In en, this message translates to:
  /// **'Try increasing the search radius or search a different location.'**
  String get errorHintNoStations;

  /// No description provided for @errorHintApiKey.
  ///
  /// In en, this message translates to:
  /// **'Configure your API key in Settings.'**
  String get errorHintApiKey;

  /// No description provided for @errorHintConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get errorHintConnection;

  /// No description provided for @errorHintRouting.
  ///
  /// In en, this message translates to:
  /// **'Route calculation failed. Check your internet connection and try again.'**
  String get errorHintRouting;

  /// No description provided for @errorHintFallback.
  ///
  /// In en, this message translates to:
  /// **'Try again or search by postal code / city name.'**
  String get errorHintFallback;

  /// No description provided for @alertsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your alerts'**
  String get alertsLoadErrorTitle;

  /// No description provided for @alertsBackgroundCheckErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert background check failed'**
  String get alertsBackgroundCheckErrorTitle;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @showKey.
  ///
  /// In en, this message translates to:
  /// **'Show key'**
  String get showKey;

  /// No description provided for @hideKey.
  ///
  /// In en, this message translates to:
  /// **'Hide key'**
  String get hideKey;

  /// No description provided for @syncOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'TankSync is optional'**
  String get syncOptionalTitle;

  /// No description provided for @syncOptionalDescription.
  ///
  /// In en, this message translates to:
  /// **'Your app works fully without cloud sync. TankSync lets you sync favorites, alerts, and ratings across devices using Supabase (free tier available).'**
  String get syncOptionalDescription;

  /// No description provided for @syncHowToConnectQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you like to connect?'**
  String get syncHowToConnectQuestion;

  /// No description provided for @syncCreateOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'Create my own database'**
  String get syncCreateOwnTitle;

  /// No description provided for @syncCreateOwnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free Supabase project — we\'ll guide you step by step'**
  String get syncCreateOwnSubtitle;

  /// No description provided for @syncJoinExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Join an existing database'**
  String get syncJoinExistingTitle;

  /// No description provided for @syncJoinExistingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code from the database owner or paste credentials'**
  String get syncJoinExistingSubtitle;

  /// No description provided for @syncChooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose your account type'**
  String get syncChooseAccountType;

  /// No description provided for @syncAccountTypeAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get syncAccountTypeAnonymous;

  /// No description provided for @syncAccountTypeAnonymousDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant, no email needed. Data tied to this device.'**
  String get syncAccountTypeAnonymousDesc;

  /// No description provided for @syncAccountTypeEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Account'**
  String get syncAccountTypeEmail;

  /// No description provided for @syncAccountTypeEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in from any device. Recover data if phone is lost.'**
  String get syncAccountTypeEmailDesc;

  /// No description provided for @syncHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get syncHaveAccountSignIn;

  /// No description provided for @syncCreateNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get syncCreateNewAccount;

  /// No description provided for @syncTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get syncTestConnection;

  /// No description provided for @syncTestingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get syncTestingConnection;

  /// No description provided for @syncConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get syncConnectButton;

  /// No description provided for @syncConnectingButton.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get syncConnectingButton;

  /// No description provided for @syncDatabaseReady.
  ///
  /// In en, this message translates to:
  /// **'Database ready!'**
  String get syncDatabaseReady;

  /// No description provided for @syncDatabaseNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Database needs setup'**
  String get syncDatabaseNeedsSetup;

  /// No description provided for @syncTableStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get syncTableStatusOk;

  /// No description provided for @syncTableStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get syncTableStatusMissing;

  /// No description provided for @syncSqlEditorInstructions.
  ///
  /// In en, this message translates to:
  /// **'Copy the SQL below and run it in your Supabase SQL Editor (Dashboard → SQL Editor → New Query → Paste → Run)'**
  String get syncSqlEditorInstructions;

  /// No description provided for @syncCopySqlButton.
  ///
  /// In en, this message translates to:
  /// **'Copy SQL to clipboard'**
  String get syncCopySqlButton;

  /// No description provided for @syncRecheckSchemaButton.
  ///
  /// In en, this message translates to:
  /// **'Re-check schema'**
  String get syncRecheckSchemaButton;

  /// No description provided for @syncDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get syncDoneButton;

  /// No description provided for @syncSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String syncSignedInAs(String email);

  /// No description provided for @syncEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data syncs across all devices with this email.'**
  String get syncEmailDescription;

  /// No description provided for @syncSwitchToAnonymousTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to anonymous'**
  String get syncSwitchToAnonymousTitle;

  /// No description provided for @syncSwitchToAnonymousDesc.
  ///
  /// In en, this message translates to:
  /// **'Continue without email, new anonymous session'**
  String get syncSwitchToAnonymousDesc;

  /// No description provided for @syncGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Anonymous, no email needed.'**
  String get syncGuestDescription;

  /// No description provided for @syncOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get syncOrDivider;

  /// No description provided for @syncHowToSyncQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you like to sync?'**
  String get syncHowToSyncQuestion;

  /// No description provided for @syncOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'Your app works fully offline. Cloud sync is optional.'**
  String get syncOfflineDescription;

  /// No description provided for @syncModeCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Tankstellen Community'**
  String get syncModeCommunityTitle;

  /// No description provided for @syncModeCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share favorites & ratings with all users'**
  String get syncModeCommunitySubtitle;

  /// No description provided for @syncModePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Database'**
  String get syncModePrivateTitle;

  /// No description provided for @syncModePrivateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your own Supabase — full data control'**
  String get syncModePrivateSubtitle;

  /// No description provided for @syncModeGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a Group'**
  String get syncModeGroupTitle;

  /// No description provided for @syncModeGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Family or friends shared database'**
  String get syncModeGroupSubtitle;

  /// No description provided for @syncPrivacyShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get syncPrivacyShared;

  /// No description provided for @syncPrivacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get syncPrivacyPrivate;

  /// No description provided for @syncPrivacyGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get syncPrivacyGroup;

  /// No description provided for @syncStayOfflineButton.
  ///
  /// In en, this message translates to:
  /// **'Stay offline'**
  String get syncStayOfflineButton;

  /// No description provided for @syncSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected!'**
  String get syncSuccessTitle;

  /// No description provided for @syncSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data will now sync automatically.'**
  String get syncSuccessDescription;

  /// No description provided for @syncWizardTitleConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect TankSync'**
  String get syncWizardTitleConnect;

  /// No description provided for @syncSetupTitleYourDatabase.
  ///
  /// In en, this message translates to:
  /// **'Your database'**
  String get syncSetupTitleYourDatabase;

  /// No description provided for @syncSetupTitleJoinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join a group'**
  String get syncSetupTitleJoinGroup;

  /// No description provided for @syncSetupTitleAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get syncSetupTitleAccount;

  /// No description provided for @syncWizardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get syncWizardBack;

  /// No description provided for @syncWizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get syncWizardNext;

  /// No description provided for @syncWizardStepOfSteps.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String syncWizardStepOfSteps(int current, int total);

  /// No description provided for @syncWizardCreateSupabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Supabase project'**
  String get syncWizardCreateSupabaseTitle;

  /// No description provided for @syncWizardCreateSupabaseInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Tap \"Open Supabase\" below\n2. Create a free account (if you don\'t have one)\n3. Click \"New Project\"\n4. Choose a name and region\n5. Wait ~2 minutes for it to start'**
  String get syncWizardCreateSupabaseInstructions;

  /// No description provided for @syncWizardOpenSupabase.
  ///
  /// In en, this message translates to:
  /// **'Open Supabase'**
  String get syncWizardOpenSupabase;

  /// No description provided for @syncWizardEnableAnonTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Anonymous Sign-ins'**
  String get syncWizardEnableAnonTitle;

  /// No description provided for @syncWizardEnableAnonInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. In your Supabase dashboard:\n   Authentication → Providers\n2. Find \"Anonymous Sign-ins\"\n3. Toggle it ON\n4. Click \"Save\"'**
  String get syncWizardEnableAnonInstructions;

  /// No description provided for @syncWizardOpenAuthSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Auth Settings'**
  String get syncWizardOpenAuthSettings;

  /// No description provided for @syncWizardCopyCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy your credentials'**
  String get syncWizardCopyCredentialsTitle;

  /// No description provided for @syncWizardCopyCredentialsInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Go to Settings → API in your dashboard\n2. Copy the \"Project URL\"\n3. Copy the \"anon public\" key\n4. Paste them below'**
  String get syncWizardCopyCredentialsInstructions;

  /// No description provided for @syncWizardOpenApiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open API Settings'**
  String get syncWizardOpenApiSettings;

  /// No description provided for @syncWizardSupabaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Supabase URL'**
  String get syncWizardSupabaseUrlLabel;

  /// No description provided for @syncWizardSupabaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://your-project.supabase.co'**
  String get syncWizardSupabaseUrlHint;

  /// No description provided for @syncWizardJoinExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Join an existing database'**
  String get syncWizardJoinExistingTitle;

  /// No description provided for @syncWizardScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get syncWizardScanQrCode;

  /// No description provided for @syncWizardAskOwnerQr.
  ///
  /// In en, this message translates to:
  /// **'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)'**
  String get syncWizardAskOwnerQr;

  /// No description provided for @syncWizardAskOwnerQrShort.
  ///
  /// In en, this message translates to:
  /// **'Ask the database owner to show their QR code'**
  String get syncWizardAskOwnerQrShort;

  /// No description provided for @syncWizardEnterManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get syncWizardEnterManuallyTitle;

  /// No description provided for @syncWizardOrEnterManually.
  ///
  /// In en, this message translates to:
  /// **'or enter manually'**
  String get syncWizardOrEnterManually;

  /// No description provided for @syncWizardUrlHelperText.
  ///
  /// In en, this message translates to:
  /// **'Whitespace and line breaks removed automatically'**
  String get syncWizardUrlHelperText;

  /// No description provided for @syncCredentialsPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Supabase project credentials. You can find them in your dashboard under Settings > API.'**
  String get syncCredentialsPrivateHint;

  /// No description provided for @syncCredentialsDatabaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Database URL'**
  String get syncCredentialsDatabaseUrlLabel;

  /// No description provided for @syncCredentialsAccessKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get syncCredentialsAccessKeyLabel;

  /// No description provided for @syncCredentialsAccessKeyHint.
  ///
  /// In en, this message translates to:
  /// **'eyJhbGciOiJIUzI1NiIs...'**
  String get syncCredentialsAccessKeyHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authPleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authPleaseEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authConnectAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Connect anonymously'**
  String get authConnectAnonymously;

  /// No description provided for @authCreateAccountAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Create account & connect'**
  String get authCreateAccountAndConnect;

  /// No description provided for @authSignInAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in & connect'**
  String get authSignInAndConnect;

  /// No description provided for @authAnonymousSegment.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get authAnonymousSegment;

  /// No description provided for @authEmailSegment.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailSegment;

  /// No description provided for @authAnonymousDescription.
  ///
  /// In en, this message translates to:
  /// **'Instant access, no email needed. Data tied to this device.'**
  String get authAnonymousDescription;

  /// No description provided for @authEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in from any device. Recover your data if your phone is lost.'**
  String get authEmailDescription;

  /// No description provided for @authSyncAcrossDevices.
  ///
  /// In en, this message translates to:
  /// **'Sync data automatically across all your devices.'**
  String get authSyncAcrossDevices;

  /// No description provided for @authNewHereCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create account'**
  String get authNewHereCreateAccount;

  /// No description provided for @ntfyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications (ntfy.sh)'**
  String get ntfyCardTitle;

  /// No description provided for @ntfyEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable ntfy.sh push'**
  String get ntfyEnableTitle;

  /// No description provided for @ntfyEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive price alerts via ntfy.sh'**
  String get ntfyEnableSubtitle;

  /// No description provided for @ntfyTopicUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic URL'**
  String get ntfyTopicUrlLabel;

  /// No description provided for @ntfyCopyTopicUrlTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy topic URL'**
  String get ntfyCopyTopicUrlTooltip;

  /// No description provided for @ntfySendTestButton.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get ntfySendTestButton;

  /// No description provided for @ntfyFdroidHint.
  ///
  /// In en, this message translates to:
  /// **'Install the ntfy app from F-Droid to receive push notifications on your device.'**
  String get ntfyFdroidHint;

  /// No description provided for @ntfyConnectFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Connect TankSync first to enable push notifications.'**
  String get ntfyConnectFirstHint;

  /// No description provided for @linkDeviceScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Device'**
  String get linkDeviceScreenTitle;

  /// No description provided for @linkDeviceThisDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get linkDeviceThisDeviceLabel;

  /// No description provided for @linkDeviceShareCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your other device:'**
  String get linkDeviceShareCodeHint;

  /// No description provided for @linkDeviceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get linkDeviceNotConnected;

  /// No description provided for @linkDeviceCopyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get linkDeviceCopyCodeTooltip;

  /// No description provided for @linkDeviceImportSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from another device'**
  String get linkDeviceImportSectionTitle;

  /// No description provided for @linkDeviceImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the device code from your other device to import its favorites, alerts, vehicles, and consumption log. Each device keeps its own profile and defaults.'**
  String get linkDeviceImportDescription;

  /// No description provided for @linkDeviceCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Device code'**
  String get linkDeviceCodeFieldLabel;

  /// No description provided for @linkDeviceCodeFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the UUID from other device'**
  String get linkDeviceCodeFieldHint;

  /// No description provided for @linkDeviceImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get linkDeviceImportButton;

  /// No description provided for @linkDeviceHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get linkDeviceHowItWorksTitle;

  /// No description provided for @linkDeviceHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'1. On Device A: copy the device code above\n2. On Device B: paste it in the \"Device code\" field\n3. Tap \"Import data\" to merge favorites, alerts, vehicles, and consumption logs\n4. Both devices will have all combined data\n\nEach device keeps its own anonymous identity and its own profile (preferred fuel, default vehicle, landing screen). Data is merged, not moved.'**
  String get linkDeviceHowItWorksBody;

  /// No description provided for @vehicleSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set active'**
  String get vehicleSetActive;

  /// No description provided for @swipeHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get swipeHide;

  /// No description provided for @evChargingSection.
  ///
  /// In en, this message translates to:
  /// **'EV Charging'**
  String get evChargingSection;

  /// No description provided for @fuelStationsSection.
  ///
  /// In en, this message translates to:
  /// **'Fuel Stations'**
  String get fuelStationsSection;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @noStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'No storage used'**
  String get noStorageUsed;

  /// No description provided for @aboutReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug / Suggest a feature'**
  String get aboutReportBug;

  /// No description provided for @aboutSupportProject.
  ///
  /// In en, this message translates to:
  /// **'Support this project'**
  String get aboutSupportProject;

  /// No description provided for @aboutSupportDescription.
  ///
  /// In en, this message translates to:
  /// **'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.'**
  String get aboutSupportDescription;

  /// No description provided for @luxembourgRegulatedPricesNotice.
  ///
  /// In en, this message translates to:
  /// **'Luxembourg fuel prices are government-regulated and uniform nationwide.'**
  String get luxembourgRegulatedPricesNotice;

  /// No description provided for @luxembourgFuelUnleaded95.
  ///
  /// In en, this message translates to:
  /// **'Unleaded 95'**
  String get luxembourgFuelUnleaded95;

  /// No description provided for @luxembourgFuelUnleaded98.
  ///
  /// In en, this message translates to:
  /// **'Unleaded 98'**
  String get luxembourgFuelUnleaded98;

  /// No description provided for @luxembourgFuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get luxembourgFuelDiesel;

  /// No description provided for @luxembourgFuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get luxembourgFuelLpg;

  /// No description provided for @luxembourgPricesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Luxembourg regulated prices are unavailable.'**
  String get luxembourgPricesUnavailable;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportIssueTitle;

  /// No description provided for @enterCorrection.
  ///
  /// In en, this message translates to:
  /// **'Please enter the correction'**
  String get enterCorrection;

  /// No description provided for @reportNoBackendAvailable.
  ///
  /// In en, this message translates to:
  /// **'The report could not be sent: no reporting service is configured for this country. Enable TankSync in Settings to send community reports.'**
  String get reportNoBackendAvailable;

  /// No description provided for @correctName.
  ///
  /// In en, this message translates to:
  /// **'Correct station name'**
  String get correctName;

  /// No description provided for @correctAddress.
  ///
  /// In en, this message translates to:
  /// **'Correct address'**
  String get correctAddress;

  /// No description provided for @wrongE85Price.
  ///
  /// In en, this message translates to:
  /// **'Wrong E85 price'**
  String get wrongE85Price;

  /// No description provided for @wrongE98Price.
  ///
  /// In en, this message translates to:
  /// **'Wrong Super 98 price'**
  String get wrongE98Price;

  /// No description provided for @wrongLpgPrice.
  ///
  /// In en, this message translates to:
  /// **'Wrong LPG price'**
  String get wrongLpgPrice;

  /// No description provided for @wrongStationName.
  ///
  /// In en, this message translates to:
  /// **'Wrong station name'**
  String get wrongStationName;

  /// No description provided for @wrongStationAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong address'**
  String get wrongStationAddress;

  /// No description provided for @independentStation.
  ///
  /// In en, this message translates to:
  /// **'Independent station'**
  String get independentStation;

  /// No description provided for @serviceRemindersSection.
  ///
  /// In en, this message translates to:
  /// **'Service reminders'**
  String get serviceRemindersSection;

  /// No description provided for @serviceRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet — pick a preset above.'**
  String get serviceRemindersEmpty;

  /// No description provided for @addServiceReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addServiceReminder;

  /// No description provided for @serviceReminderPresetOil.
  ///
  /// In en, this message translates to:
  /// **'Oil (15,000 km)'**
  String get serviceReminderPresetOil;

  /// No description provided for @serviceReminderPresetOilLabel.
  ///
  /// In en, this message translates to:
  /// **'Oil change'**
  String get serviceReminderPresetOilLabel;

  /// No description provided for @serviceReminderPresetTires.
  ///
  /// In en, this message translates to:
  /// **'Tires (20,000 km)'**
  String get serviceReminderPresetTires;

  /// No description provided for @serviceReminderPresetTiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get serviceReminderPresetTiresLabel;

  /// No description provided for @serviceReminderPresetInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection (30,000 km)'**
  String get serviceReminderPresetInspection;

  /// No description provided for @serviceReminderPresetInspectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get serviceReminderPresetInspectionLabel;

  /// No description provided for @serviceReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get serviceReminderLabel;

  /// No description provided for @serviceReminderInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval (km)'**
  String get serviceReminderInterval;

  /// No description provided for @serviceReminderLastService.
  ///
  /// In en, this message translates to:
  /// **'Last service'**
  String get serviceReminderLastService;

  /// No description provided for @serviceReminderMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get serviceReminderMarkDone;

  /// No description provided for @serviceReminderDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Service due'**
  String get serviceReminderDueTitle;

  /// No description provided for @serviceReminderDueBody.
  ///
  /// In en, this message translates to:
  /// **'{label} is due — {kmOver} km past the interval.'**
  String serviceReminderDueBody(String label, int kmOver);

  /// No description provided for @southKoreaApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Register at OPINET to get a free API key'**
  String get southKoreaApiKeyRequired;

  /// No description provided for @southKoreaApiProvider.
  ///
  /// In en, this message translates to:
  /// **'OPINET (KNOC)'**
  String get southKoreaApiProvider;

  /// No description provided for @chileApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Register at CNE to get a free API key'**
  String get chileApiKeyRequired;

  /// No description provided for @chileApiProvider.
  ///
  /// In en, this message translates to:
  /// **'CNE Bencina en Linea'**
  String get chileApiProvider;

  /// No description provided for @vinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this your car?'**
  String get vinConfirmTitle;

  /// No description provided for @vinConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{year} {make} {model} — {displacement}L, {cylinders}-cyl, {fuel}'**
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  );

  /// No description provided for @vinPartialInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Partial info (offline). You can edit below.'**
  String get vinPartialInfoNote;

  /// No description provided for @vinDecodeError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t decode this VIN'**
  String get vinDecodeError;

  /// No description provided for @vinInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid VIN format'**
  String get vinInvalidFormat;

  /// Banner shown (#797 phase 2) when the OBD2 Bluetooth link drops mid-recording. The trip is auto-paused on the device and the partial data is preserved. User can resume (if the link comes back) or end the recording entirely.
  ///
  /// In en, this message translates to:
  /// **'OBD2 connection lost — recording paused'**
  String get obd2PauseBannerTitle;

  /// Action on the OBD2 pause banner that resumes the recording once the Bluetooth link is back.
  ///
  /// In en, this message translates to:
  /// **'Resume recording'**
  String get obd2PauseBannerResume;

  /// Action on the OBD2 pause banner that stops the recording and saves what was captured before the drop.
  ///
  /// In en, this message translates to:
  /// **'End recording'**
  String get obd2PauseBannerEnd;

  /// Snackbar shown after #815 reconciles OBD2 integrated fuel against the pump receipt and learns a new volumetric-efficiency scalar for the vehicle.
  ///
  /// In en, this message translates to:
  /// **'Consumption calibration updated for {vehicleName} — accuracy improved by {percent}%'**
  String veCalibratedTitle(String vehicleName, String percent);

  /// Title of the confirm dialog shown before discarding the learned volumetric efficiency (#815).
  ///
  /// In en, this message translates to:
  /// **'Reset volumetric efficiency?'**
  String get veResetConfirmTitle;

  /// Body of the confirm dialog shown before discarding the learned volumetric efficiency (#815).
  ///
  /// In en, this message translates to:
  /// **'This will discard the learned volumetric efficiency (η_v) and restore the default value (0.85). Trip-level fuel-flow estimates will fall back to the manufacturer constant until the calibrator collects new samples from upcoming trips.'**
  String get veResetConfirmBody;

  /// Header of the radius-based watchlist section on the alerts screen (#578).
  ///
  /// In en, this message translates to:
  /// **'Radius alerts'**
  String get alertsRadiusSectionTitle;

  /// Tooltip/label of the button that opens the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Add radius alert'**
  String get alertsRadiusAdd;

  /// Empty state title shown when no radius alerts are configured (#578).
  ///
  /// In en, this message translates to:
  /// **'No radius alerts yet'**
  String get alertsRadiusEmptyTitle;

  /// Call-to-action button that opens the create sheet from the empty state (#578).
  ///
  /// In en, this message translates to:
  /// **'Create a radius alert'**
  String get alertsRadiusEmptyCta;

  /// Title of the bottom sheet used to create a new radius alert (#578).
  ///
  /// In en, this message translates to:
  /// **'Create radius alert'**
  String get alertsRadiusCreateTitle;

  /// Hint text for the label field in the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Label (e.g. Home diesel)'**
  String get alertsRadiusLabelHint;

  /// Fuel-type picker label in the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get alertsRadiusFuelType;

  /// Price-threshold field label in the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Threshold (€/L)'**
  String get alertsRadiusThreshold;

  /// Radius slider label in the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Radius (km)'**
  String get alertsRadiusKm;

  /// Button that sets the alert center to the user's current GPS position (#578).
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get alertsRadiusCenterGps;

  /// Fallback input for entering a postal code as the alert center when no map picker is available (#578).
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get alertsRadiusCenterPostalCode;

  /// Save button label in the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get alertsRadiusSave;

  /// Cancel button label in the radius-alert create sheet (#578).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get alertsRadiusCancel;

  /// Snackbar/confirm text shown when a radius alert is dismissed for deletion (#578).
  ///
  /// In en, this message translates to:
  /// **'Delete radius alert?'**
  String get alertsRadiusDeleteConfirm;

  /// Tooltip on the title-bar OBD2 status chip (#797 phase 3) shown only when the pinned adapter is currently connected.
  ///
  /// In en, this message translates to:
  /// **'OBD2 connected: {adapterName}'**
  String obd2ConnectedTooltip(String adapterName);

  /// Title of the price-drop velocity notification (#579). Fired when multiple nearby stations drop within the lookback window.
  ///
  /// In en, this message translates to:
  /// **'{fuelLabel} dropped at nearby stations'**
  String velocityAlertTitle(String fuelLabel);

  /// Body of the price-drop velocity notification (#579). Lists the number of affected stations and the largest observed drop in cents.
  ///
  /// In en, this message translates to:
  /// **'{stationCount} stations dropped by up to {maxDropCents}¢ in the last hour'**
  String velocityAlertBody(int stationCount, int maxDropCents);

  /// Title of the smoothDriver badge — five consecutive trips with driving-score >= 80 (#1041 phase 5).
  ///
  /// In en, this message translates to:
  /// **'Smooth streak'**
  String get achievementSmoothDriver;

  /// Tooltip for the smoothDriver badge (#1041 phase 5).
  ///
  /// In en, this message translates to:
  /// **'Drive 5 trips in a row with a smooth-driving score of 80 or higher.'**
  String get achievementSmoothDriverDesc;

  /// Title of the coldStartAware badge — whole month with cold-start excess <2% of total fuel (#1041 phase 5).
  ///
  /// In en, this message translates to:
  /// **'Cold-start aware'**
  String get achievementColdStartAware;

  /// Tooltip for the coldStartAware badge (#1041 phase 5).
  ///
  /// In en, this message translates to:
  /// **'Keep a whole month\'s cold-start fuel cost under 2 % of total fuel — combine short trips.'**
  String get achievementColdStartAwareDesc;

  /// Title of the highwayMaster badge — single 30km+ trip at consistent speed with driving-score >= 90 (#1041 phase 5).
  ///
  /// In en, this message translates to:
  /// **'Highway master'**
  String get achievementHighwayMaster;

  /// Tooltip for the highwayMaster badge (#1041 phase 5).
  ///
  /// In en, this message translates to:
  /// **'Complete a 30 km+ trip at consistent speed with a smooth-driving score of 90 or higher.'**
  String get achievementHighwayMasterDesc;

  /// Auth error pill — shown when the device has no network connectivity (DNS failure, dropped socket, AuthRetryableFetchException). Replaces the raw exception text leaked by #1186.
  ///
  /// In en, this message translates to:
  /// **'No network connection. Try again later.'**
  String get authErrorNoNetwork;

  /// Auth error pill — shown when Supabase rejects the email/password pair (#1186).
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Check your credentials.'**
  String get authErrorInvalidCredentials;

  /// Auth error pill — shown on sign-up when the email is already in use (#1186).
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get authErrorUserAlreadyExists;

  /// Auth error pill — shown when sign-in fails because the user has not yet clicked the confirmation link (#1186).
  ///
  /// In en, this message translates to:
  /// **'Please check your email and confirm your account first.'**
  String get authErrorEmailNotConfirmed;

  /// Auth error pill — generic fallback when no specific mapping matches the raw exception (#1186).
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get authErrorGeneric;

  /// Title of the per-vehicle auto-record configuration section on the edit-vehicle screen (#1004 phase 6).
  ///
  /// In en, this message translates to:
  /// **'Auto-record'**
  String get autoRecordSectionTitle;

  /// Label for the master ON/OFF switch that opts a vehicle into hands-free trip recording.
  ///
  /// In en, this message translates to:
  /// **'Auto-record trips'**
  String get autoRecordToggleLabel;

  /// Active-state banner shown when auto-record is enabled, an adapter is paired, and background-location consent is granted (#1310). Replaces the stale phase-status banner.
  ///
  /// In en, this message translates to:
  /// **'Auto-record will activate the next time you enter the car.'**
  String get autoRecordStatusActiveLabel;

  /// Warning banner shown when auto-record is enabled but no OBD2 adapter has been paired — the orchestrator gate cannot arm without a MAC (#1310).
  ///
  /// In en, this message translates to:
  /// **'Pair an OBD2 adapter to enable auto-record.'**
  String get autoRecordStatusNeedsPairingLabel;

  /// Warning banner shown when an OBD2 adapter is paired but background-location consent is missing — auto-record runs BT-only without GPS metadata (#1310).
  ///
  /// In en, this message translates to:
  /// **'Allow background location so auto-record keeps running with the screen off.'**
  String get autoRecordStatusNeedsBackgroundLocationLabel;

  /// CTA button on the 'needs pairing' banner that opens the OBD2 onboarding wizard so the user can pair an adapter (#1310).
  ///
  /// In en, this message translates to:
  /// **'Pair an adapter'**
  String get autoRecordStatusPairAdapterCta;

  /// Label for the slider that controls the movement-start threshold above which an auto-record trip begins.
  ///
  /// In en, this message translates to:
  /// **'Start speed (km/h)'**
  String get autoRecordSpeedThresholdLabel;

  /// Label for the slider that controls how long after a Bluetooth disconnect the auto-record path waits before saving the trip.
  ///
  /// In en, this message translates to:
  /// **'Save delay after disconnect (seconds)'**
  String get autoRecordSaveDelayLabel;

  /// Label for the read-only field showing the MAC address of the OBD2 adapter paired to this vehicle.
  ///
  /// In en, this message translates to:
  /// **'Paired adapter'**
  String get autoRecordPairedAdapterLabel;

  /// Empty-state text shown when no OBD2 adapter has been paired to this vehicle yet.
  ///
  /// In en, this message translates to:
  /// **'No adapter paired. Pair one via the OBD2 onboarding first.'**
  String get autoRecordPairedAdapterNone;

  /// Label for the read-only field showing whether the user has granted always-on location permission for auto-record.
  ///
  /// In en, this message translates to:
  /// **'Background location allowed'**
  String get autoRecordBackgroundLocationLabel;

  /// Button that prompts the OS for the always-on location permission required by auto-record's GPS-based metadata.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get autoRecordBackgroundLocationRequest;

  /// Title of the rationale dialog shown before the OS prompt for ACCESS_BACKGROUND_LOCATION (#1302).
  ///
  /// In en, this message translates to:
  /// **'Why \"Allow all the time\"?'**
  String get autoRecordBackgroundLocationRationaleTitle;

  /// Body copy of the rationale dialog explaining why the app needs ACCESS_BACKGROUND_LOCATION; shown before the OS prompt and on the permanently-denied path (#1302).
  ///
  /// In en, this message translates to:
  /// **'Auto-record streams GPS coordinates from the OBD-II foreground service while the screen is off so your trip route stays accurate. Android requires the \"Allow all the time\" option for that to keep working after the device locks.'**
  String get autoRecordBackgroundLocationRationaleBody;

  /// CTA on the rationale dialog that opens the OS app-settings page so the user can pick "Allow all the time" manually (#1302).
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get autoRecordBackgroundLocationOpenSettings;

  /// Snackbar shown when the user denied the foreground-location prompt; without it the background-location step cannot proceed (#1302).
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar;

  /// Snackbar shown when the permission request itself threw an exception. Replaces the previous silent debugPrint catch (#1302).
  ///
  /// In en, this message translates to:
  /// **'Could not request background location'**
  String get autoRecordBackgroundLocationRequestFailedSnackbar;

  /// Tooltip on the AppBar action that resets the auto-record unseen-trip badge to zero.
  ///
  /// In en, this message translates to:
  /// **'Clear counter'**
  String get autoRecordBadgeClearTooltip;

  /// AppBar IconButton tooltip on the consumption screen for the full XML-in-ZIP backup export (#1317).
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackupTooltip;

  /// SnackBar shown after a successful backup export when the share sheet is about to appear (#1317).
  ///
  /// In en, this message translates to:
  /// **'Backup ready — pick a destination'**
  String get exportBackupReady;

  /// SnackBar shown when the backup export pipeline throws (#1317).
  ///
  /// In en, this message translates to:
  /// **'Backup export failed — please try again'**
  String get exportBackupFailed;

  /// Label for the fuel fill-ups tab on the ConsumptionScreen (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get consumptionTabFuel;

  /// Label for the EV charging logs tab on the ConsumptionScreen (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get consumptionTabCharging;

  /// Empty-state title on the Charging tab when no sessions have been logged (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'No charging logs yet'**
  String get noChargingLogsTitle;

  /// Empty-state subtitle on the Charging tab (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Log your first charging session to start tracking EUR/100 km and kWh/100 km.'**
  String get noChargingLogsSubtitle;

  /// Floating-action-button label on the Charging tab for adding a new session (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Log charging'**
  String get addChargingLog;

  /// AppBar title for the Add-Charging-Log screen (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Log charging session'**
  String get addChargingLogTitle;

  /// Label for the kWh numeric input on the Add-Charging-Log form (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Energy (kWh)'**
  String get chargingKwh;

  /// Label for the cost numeric input on the Add-Charging-Log form (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get chargingCost;

  /// Label for the charge-time numeric input on the Add-Charging-Log form (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Charge time (min)'**
  String get chargingTimeMin;

  /// Label for the free-form station-name input on the Add-Charging-Log form (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Station (optional)'**
  String get chargingStationName;

  /// Derived EUR/100km readout on the Add-Charging-Log form (#582 phase 2). Shown when odometer + cost are both entered and a previous log exists.
  ///
  /// In en, this message translates to:
  /// **'{value} EUR / 100 km'**
  String chargingEurPer100km(String value);

  /// Derived kWh/100km readout on the Add-Charging-Log form (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'{value} kWh / 100 km'**
  String chargingKwhPer100km(String value);

  /// Helper text under the cost field when there is no prior charging log for the selected vehicle, so the EUR/100 km cannot be computed yet (#582 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Need a previous log to compare'**
  String get chargingDerivedHelper;

  /// Primary action button on the EV station detail screen that opens the Add-Charging-Log form pre-filled with this station (#582 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Log charging'**
  String get chargingLogButtonLabel;

  /// Section title above the monthly charging-cost bar chart on the Charging tab (#582 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Charging cost trend'**
  String get chargingCostTrendTitle;

  /// Section title above the monthly kWh/100 km line chart on the Charging tab (#582 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Efficiency (kWh/100 km)'**
  String get chargingEfficiencyTitle;

  /// Empty-state caption shown inside the charging charts when no data is available for the last 6 months (#582 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get chargingChartsEmpty;

  /// Axis label for the X axis (month) on the charging charts (#582 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get chargingChartsMonthAxis;

  /// GDPR consent toggle — short title for the opt-in to anonymously share station arrival/departure timestamps so the app can surface typical wait times (#1119). Used in both the first-launch consent screen and the settings page.
  ///
  /// In en, this message translates to:
  /// **'Community Wait Times'**
  String get gdprCommunityWaitTimeTitle;

  /// GDPR consent toggle — one-line subtitle shown in the settings page alongside the toggle (#1119). Kept terse; the first-launch consent screen uses gdprCommunityWaitTimeDescription for the longer explanation.
  ///
  /// In en, this message translates to:
  /// **'Anonymously share station wait times'**
  String get gdprCommunityWaitTimeShort;

  /// GDPR consent toggle — full description used on the first-launch consent screen (#1119). Mentions exactly what is uploaded (station ID + arrival/departure timestamps) and what is NOT uploaded (raw lat/lng) so the user can give informed consent.
  ///
  /// In en, this message translates to:
  /// **'Anonymously share when you arrive at and leave a fuel station so the app can show typical wait times. No location coordinates are uploaded — only the station ID.'**
  String get gdprCommunityWaitTimeDescription;

  /// Banner shown above the consumption stats card when one or more partial fill-ups have been logged after the most recent plein-complet (#1362). The fills are excluded from the L/100km average until the next plein-complet closes the window.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 partial fill pending plein complet — not in average} other{{count} partial fills pending plein complet — not in average}}'**
  String consumptionStatsOpenWindowBanner(int count);

  /// Hint shown when more than 5% of the totalled fuel volume comes from auto-generated correction fill-ups (#1362). Encourages the user to review the orange correction entries in the fill-up list.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of fuel from auto-corrections — review entries'**
  String consumptionStatsCorrectionShareHint(int percent);

  /// Inline label shown beneath the volume/cost line on a correction fill-up card (#1361). Indicates the entry was auto-generated by trip-vs-pump reconciliation and that tapping opens the edit sheet.
  ///
  /// In en, this message translates to:
  /// **'Auto-correction — tap to edit'**
  String get fillUpCorrectionLabel;

  /// Title of the bottom sheet that opens when the user taps a correction fill-up entry (#1361).
  ///
  /// In en, this message translates to:
  /// **'Edit auto-correction'**
  String get fillUpCorrectionEditTitle;

  /// Explanatory copy at the top of the correction fill-up edit sheet (#1361). Tells the user why this synthetic entry exists and that they can override the auto-computed values.
  ///
  /// In en, this message translates to:
  /// **'This entry was auto-generated to close the gap between recorded trips and pumped fuel. Adjust the values if you know the actual figures.'**
  String get fillUpCorrectionEditExplainer;

  /// Destructive button on the correction fill-up edit sheet that removes the synthetic entry from the fill-up list (#1361).
  ///
  /// In en, this message translates to:
  /// **'Delete correction'**
  String get fillUpCorrectionDelete;

  /// Label for the optional station-name field on the correction fill-up edit sheet (#1361). Synthetic entries have no station by default.
  ///
  /// In en, this message translates to:
  /// **'Station name (optional)'**
  String get fillUpCorrectionStation;

  /// No description provided for @greeceApiProvider.
  ///
  /// In en, this message translates to:
  /// **'Paratiritirio Timon (Greece)'**
  String get greeceApiProvider;

  /// No description provided for @greeceCommunityApiNotice.
  ///
  /// In en, this message translates to:
  /// **'Powered by the community-maintained fuelpricesgr API'**
  String get greeceCommunityApiNotice;

  /// No description provided for @romaniaApiProvider.
  ///
  /// In en, this message translates to:
  /// **'Monitorul Prețurilor (Romania)'**
  String get romaniaApiProvider;

  /// No description provided for @romaniaScrapingNotice.
  ///
  /// In en, this message translates to:
  /// **'Powered by pretcarburant.ro (Competition Council + ANPC)'**
  String get romaniaScrapingNotice;

  /// Banner shown when stations across the border are cheaper than local prices.
  ///
  /// In en, this message translates to:
  /// **'{country} stations {km} km away — €{price}/L cheaper'**
  String crossBorderCheaper(String country, String km, String price);

  /// Hint shown beneath the cross-border banner — tapping switches the active country and re-runs the search.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch country'**
  String get crossBorderTapToSwitch;

  /// Tooltip on the cross-border banner's dismiss icon.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get crossBorderDismissTooltip;

  /// Title of the driving-insights card on the Trip detail screen — surfaces the top-3 fuel-wasting behaviours from the analyzer (#1041 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Top wasteful behaviours'**
  String get insightCardTitle;

  /// Empty-state message inside the driving-insights card when the analyzer found no cost lines above the noise floor (#1041 phase 2).
  ///
  /// In en, this message translates to:
  /// **'No notable inefficiencies — keep it up!'**
  String get insightEmptyState;

  /// Cost-line copy for the high-RPM insight on the Trip detail screen (#1041 phase 2). Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Engine over 3000 RPM ({pctTime}% of trip): wasted {liters} L'**
  String insightHighRpm(String pctTime, String liters);

  /// Cost-line copy for the hard-acceleration insight on the Trip detail screen (#1041 phase 2). Count is the integer event count; liters is a pre-formatted string.
  ///
  /// In en, this message translates to:
  /// **'{count} hard accelerations: wasted {liters} L'**
  String insightHardAccel(String count, String liters);

  /// Cost-line copy for the idling insight on the Trip detail screen (#1041 phase 2). Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Idling ({pctTime}% of trip): wasted {liters} L'**
  String insightIdling(String pctTime, String liters);

  /// Secondary subtitle line under each insight ListTile showing the percent of the trip spent in this state (#1041 phase 2).
  ///
  /// In en, this message translates to:
  /// **'{pctTime}% of trip'**
  String insightSubtitlePctOfTrip(String pctTime);

  /// Trailing badge on each insight ListTile showing the litres wasted (#1041 phase 2). Liters is a pre-formatted one-decimal string.
  ///
  /// In en, this message translates to:
  /// **'+{liters} L'**
  String insightTrailingLitersWasted(String liters);

  /// Coaching line on the driving-insights card when secondsBelowOptimalGear > 60 (#1263 phase 3). Tells the driver they spent significant time in too-low a gear, raising fuel consumption. Placeholder is the integer minute count.
  ///
  /// In en, this message translates to:
  /// **'Labouring in low gear ({minutes} min)'**
  String insightLowGear(String minutes);

  /// Title of the composite driving-score card on the Trip detail screen — sits at the top of the Insights group above the cost-line card (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Driving score'**
  String get drivingScoreCardTitle;

  /// Suffix shown next to the big driving-score number on the Trip detail screen — clarifies the 0..100 scale (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get drivingScoreCardOutOf;

  /// Caption beneath the big driving-score number explaining what feeds the composite. Doubles as a placeholder for the future per-trip percentile sub-text (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Composite score from idling, hard accelerations, hard braking, and high-RPM time. A \'better than X% of past trips\' comparison will land in a follow-up release.'**
  String get drivingScoreCardSubtitle;

  /// TalkBack / VoiceOver label for the big driving-score number — bundles the value and the scale into a single accessible utterance (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Driving score {score} out of 100'**
  String drivingScoreCardSemanticsLabel(String score);

  /// Breakdown chip surfaced beneath the driving-score big number when the idling penalty was the largest contributor (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Idling'**
  String get drivingScorePenaltyIdling;

  /// Breakdown chip surfaced beneath the driving-score big number when the hard-acceleration penalty was a top contributor (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Hard accelerations'**
  String get drivingScorePenaltyHardAccel;

  /// Breakdown chip surfaced beneath the driving-score big number when the hard-braking penalty was a top contributor (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Hard braking'**
  String get drivingScorePenaltyHardBrake;

  /// Breakdown chip surfaced beneath the driving-score big number when the high-RPM penalty was a top contributor (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'High RPM'**
  String get drivingScorePenaltyHighRpm;

  /// Breakdown chip surfaced beneath the driving-score big number when the full-throttle penalty was a top contributor — currently unused while throttle is not persisted (#1041 phase 5a Card A).
  ///
  /// In en, this message translates to:
  /// **'Full throttle'**
  String get drivingScorePenaltyFullThrottle;

  /// Label for the eco-routing strategy chip on the route search controls (#1123). Picks routes that minimise fuel rather than time.
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get ecoRouteOption;

  /// Predicted savings preview shown when the eco-routing strategy is active on the route search controls (#1123). {liters} is the estimated litres saved compared to the fastest route, formatted with one decimal.
  ///
  /// In en, this message translates to:
  /// **'≈ {liters} L saved'**
  String ecoRouteSavings(String liters);

  /// Helper caption shown beneath the eco-routing chip explaining why the user might pick it (#1123). Keep concise; the leitmotiv 'Smarter pump. Smarter drive.' should remain recognisable.
  ///
  /// In en, this message translates to:
  /// **'Smarter drive — favours steady highway over zigzag shortcuts.'**
  String get ecoRouteHint;

  /// AppBar action tooltip for the share-favorites button on the Favorites screen (#1344).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get favoritesShareAction;

  /// Subject / preview text passed to the OS share sheet when the user shares the Favorites screen as an image (#1344). The {date} placeholder is replaced with a localised short date.
  ///
  /// In en, this message translates to:
  /// **'Tankstellen — favourites on {date}'**
  String favoritesShareSubject(String date);

  /// Snackbar shown when the favorites Share action fails to render or hand off the report PNG (#1344).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate share image'**
  String get favoritesShareError;

  /// Title of the one-time consent dialog before we file a public GitHub issue from a bad-scan report (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Send report to GitHub?'**
  String get feedbackConsentTitle;

  /// Body of the bad-scan-report consent dialog (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'This creates a public ticket on our GitHub repository with your photo and the OCR text. No personal data (location, account id) is sent. Continue?'**
  String get feedbackConsentBody;

  /// Primary action of the bad-scan-report consent dialog — opts the user in (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get feedbackConsentContinue;

  /// Negative action of the bad-scan-report consent dialog — persists the user's denial (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get feedbackConsentCancel;

  /// Tertiary action of the bad-scan-report consent dialog — does not persist anything; we re-ask on next attempt (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get feedbackConsentLater;

  /// Title of the foldable settings section that lets the user paste a GitHub PAT for the bad-scan reporter (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Bad-scan feedback (GitHub)'**
  String get feedbackTokenSectionTitle;

  /// Helper text explaining the PAT requirement on the bad-scan-feedback settings section (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'To automatically open a GitHub ticket from a failed scan, paste a GitHub PAT (`public_repo` scope on the tankstellen repository). Otherwise manual sharing remains available.'**
  String get feedbackTokenDescription;

  /// Status line in the bad-scan-feedback section when a PAT is stored (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Token configured'**
  String get feedbackTokenStatusSet;

  /// Status line in the bad-scan-feedback section when no PAT is stored (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'No token'**
  String get feedbackTokenStatusUnset;

  /// Button in the bad-scan-feedback section that opens the PAT-entry dialog (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get feedbackTokenSet;

  /// Button in the bad-scan-feedback section that wipes the stored PAT (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get feedbackTokenClear;

  /// Title of the dialog that prompts for a GitHub PAT (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'GitHub PAT'**
  String get feedbackTokenDialogTitle;

  /// Label of the obscured-text field that captures the GitHub PAT (#952 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Personal Access Token'**
  String get feedbackTokenFieldLabel;

  /// Snackbar shown on the Add-Fill-Up screen when the receipt scan returns no usable fields (#751).
  ///
  /// In en, this message translates to:
  /// **'No receipt data found — try again'**
  String get scanReceiptNoData;

  /// Snackbar shown after a successful receipt scan to prompt the user to verify the pre-filled values (#751).
  ///
  /// In en, this message translates to:
  /// **'Receipt scanned — verify values. Tap \"Report scan error\" below if anything is off.'**
  String get scanReceiptSuccess;

  /// Snackbar shown when the receipt scan throws (#751).
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String scanReceiptFailed(String error);

  /// Snackbar shown on the Add-Fill-Up screen when the pump-display scan returns no usable fields (#751).
  ///
  /// In en, this message translates to:
  /// **'Pump display not readable — try again'**
  String get scanPumpUnreadable;

  /// Snackbar shown after a successful pump-display scan (#751).
  ///
  /// In en, this message translates to:
  /// **'Pump display scanned — verify the values.'**
  String get scanPumpSuccess;

  /// Snackbar shown when the pump-display scan throws (#751).
  ///
  /// In en, this message translates to:
  /// **'Pump scan failed: {error}'**
  String scanPumpFailed(String error);

  /// Title of the bottom sheet that reports an incorrect receipt scan (#751).
  ///
  /// In en, this message translates to:
  /// **'Report a scan error'**
  String get badScanReportTitle;

  /// Receipt-specific title for the bad-scan report sheet (#953). Used when ScanKind == receipt.
  ///
  /// In en, this message translates to:
  /// **'Report a scan error — Receipt'**
  String get badScanReportTitleReceipt;

  /// Pump-display-specific title for the bad-scan report sheet (#953). Used when ScanKind == pumpDisplay.
  ///
  /// In en, this message translates to:
  /// **'Report a scan error — Pump display'**
  String get badScanReportTitlePumpDisplay;

  /// Title of the bottom sheet shown when a pump-display scan returns no usable data (#953).
  ///
  /// In en, this message translates to:
  /// **'Display unreadable'**
  String get pumpScanFailureTitle;

  /// Body text of the pump-scan failure sheet, prompting the user to choose between correcting manually, reporting, or removing the photo (#953).
  ///
  /// In en, this message translates to:
  /// **'The scan couldn\'t read the pump display. What would you like to do?'**
  String get pumpScanFailureBody;

  /// Action: close the failure sheet and leave the form untouched so the user types values (#953).
  ///
  /// In en, this message translates to:
  /// **'Correct manually'**
  String get pumpScanFailureCorrectManually;

  /// Action: open the bad-scan report flow so the unreadable photo is shipped to GitHub for triage (#953).
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get pumpScanFailureReport;

  /// Action: delete the captured photo and forget the scan (#953).
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get pumpScanFailureRemove;

  /// Subtitle under the bad-scan-report sheet title (#751).
  ///
  /// In en, this message translates to:
  /// **'We\'ll share the receipt photo and both sets of values so the next build can learn this layout.'**
  String get badScanReportHint;

  /// Button on the bad-scan-report sheet that triggers the system share intent (#751).
  ///
  /// In en, this message translates to:
  /// **'Share report + photo'**
  String get badScanReportShareAction;

  /// No description provided for @badScanReportFieldBrandLayout.
  ///
  /// In en, this message translates to:
  /// **'Brand layout'**
  String get badScanReportFieldBrandLayout;

  /// No description provided for @badScanReportFieldTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get badScanReportFieldTotal;

  /// No description provided for @badScanReportFieldPricePerLiter.
  ///
  /// In en, this message translates to:
  /// **'Price/L'**
  String get badScanReportFieldPricePerLiter;

  /// No description provided for @badScanReportFieldStation.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get badScanReportFieldStation;

  /// No description provided for @badScanReportFieldFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get badScanReportFieldFuel;

  /// No description provided for @badScanReportFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get badScanReportFieldDate;

  /// No description provided for @badScanReportHeaderField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get badScanReportHeaderField;

  /// No description provided for @badScanReportHeaderScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get badScanReportHeaderScanned;

  /// No description provided for @badScanReportHeaderYouTyped.
  ///
  /// In en, this message translates to:
  /// **'You typed'**
  String get badScanReportHeaderYouTyped;

  /// Primary action on the bad-scan-report sheet that files a GitHub issue (#952 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get badScanReportCreateTicket;

  /// Action shown after a GitHub issue is filed; opens the issue URL in the system browser (#952 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get badScanReportOpenInBrowser;

  /// Snackbar shown when the GitHub submission fails and we fall back to the system share sheet (#952 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Submission failed — manual share'**
  String get badScanReportFallbackToShare;

  /// Card title grouping date, fuel and quantity inputs on the Add-Fill-up form (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'What you filled'**
  String get fillUpSectionWhatTitle;

  /// Sub-title for the 'What you filled' card (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Fuel, amount, price'**
  String get fillUpSectionWhatSubtitle;

  /// Card title grouping station, odometer and notes on the Add-Fill-up form (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Where you were'**
  String get fillUpSectionWhereTitle;

  /// Sub-title for the 'Where you were' card (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Station, odometer, notes'**
  String get fillUpSectionWhereSubtitle;

  /// Chip label that opens the import bottom sheet with receipt / pump / OBD-II options (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Import from…'**
  String get fillUpImportFromLabel;

  /// Bottom-sheet title for the import-from chooser (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Import fill-up data'**
  String get fillUpImportSheetTitle;

  /// Import option: OCR-scan a paper receipt (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get fillUpImportReceiptLabel;

  /// Subtitle for the receipt-scan import option (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Scan a paper receipt with the camera'**
  String get fillUpImportReceiptDescription;

  /// Import option: OCR-scan the fuel-pump LCD (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Pump display'**
  String get fillUpImportPumpLabel;

  /// Subtitle for the pump-display import option (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Read Betrag / Preis from the pump LCD'**
  String get fillUpImportPumpDescription;

  /// Import option: pull the odometer reading via OBD-II Bluetooth (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'OBD-II adapter'**
  String get fillUpImportObdLabel;

  /// Subtitle for the OBD-II import option (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Read odometer from the OBD-II port over Bluetooth'**
  String get fillUpImportObdDescription;

  /// Read-only derived value shown below the cost field when liters + cost are both entered (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Price per liter'**
  String get fillUpPricePerLiterLabel;

  /// Tiny chip label shown next to the big vehicle title on the edit screen header (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get vehicleHeaderPlateLabel;

  /// Placeholder shown in the vehicle header when no name has been typed yet (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'New vehicle'**
  String get vehicleHeaderUntitled;

  /// Card title grouping name + VIN on the edit-vehicle form (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get vehicleSectionIdentityTitle;

  /// Sub-title for the identity card (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Name & VIN'**
  String get vehicleSectionIdentitySubtitle;

  /// Card title grouping vehicle type (combustion/hybrid/EV) and the type-specific inputs (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get vehicleSectionDrivetrainTitle;

  /// Sub-title for the drivetrain card (#751 phase 2).
  ///
  /// In en, this message translates to:
  /// **'How this vehicle moves'**
  String get vehicleSectionDrivetrainSubtitle;

  /// Label above the rule/fuzzy segmented button on the vehicle edit screen (#894).
  ///
  /// In en, this message translates to:
  /// **'Calibration mode'**
  String get calibrationModeLabel;

  /// Rule-based calibration option (#894) — the default winner-take-all classifier from #779.
  ///
  /// In en, this message translates to:
  /// **'Rule-based'**
  String get calibrationModeRule;

  /// Fuzzy calibration option (#894) — each sample contributes to all situations weighted by membership.
  ///
  /// In en, this message translates to:
  /// **'Fuzzy'**
  String get calibrationModeFuzzy;

  /// No description provided for @calibrationModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rule-based assigns each driving sample to exactly one situation. Fuzzy spreads it across all of them by how well each fits — smoother around 60 km/h or changing gradients, but slower to fill all buckets.'**
  String get calibrationModeTooltip;

  /// Title of the master gamification opt-out switch on the profile / settings screen (#1194).
  ///
  /// In en, this message translates to:
  /// **'Show achievements & scores'**
  String get profileGamificationToggleTitle;

  /// Subtitle explaining what the gamification opt-out toggle hides (#1194).
  ///
  /// In en, this message translates to:
  /// **'When off, badges, scores and trophy icons are hidden across the app.'**
  String get profileGamificationToggleSubtitle;

  /// Section header on the Settings screen grouping wheel-lens (driving-behaviour) settings (#1122).
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get hapticEcoCoachSectionTitle;

  /// Title of the haptic-eco-coach toggle on the Settings screen (#1122).
  ///
  /// In en, this message translates to:
  /// **'Real-time eco coaching'**
  String get hapticEcoCoachSettingTitle;

  /// Subtitle/explanation of the haptic-eco-coach toggle on the Settings screen (#1122). Describes both the haptic and visual surfaces in user-facing terms (#1273).
  ///
  /// In en, this message translates to:
  /// **'Gentle haptic + on-screen tip when you floor it during cruise'**
  String get hapticEcoCoachSettingSubtitle;

  /// SnackBar copy shown on the trip-recording screen when the eco-coach heuristic fires (#1273). Co-located with the haptic; same toggle gates both surfaces.
  ///
  /// In en, this message translates to:
  /// **'Easy on the throttle — coasting saves more'**
  String get hapticEcoCoachSnackBarMessage;

  /// Title of the loyalty settings sub-screen where the user manages fuel-club cards (#1120).
  ///
  /// In en, this message translates to:
  /// **'Fuel club cards'**
  String get loyaltySettingsTitle;

  /// Banner subtitle on the loyalty settings sub-screen explaining what cards do (#1120).
  ///
  /// In en, this message translates to:
  /// **'Apply your loyalty discount to displayed prices'**
  String get loyaltySettingsSubtitle;

  /// Settings menu tile title that routes to the loyalty settings screen (#1120).
  ///
  /// In en, this message translates to:
  /// **'Fuel club cards'**
  String get loyaltyMenuTitle;

  /// Settings menu tile subtitle on the loyalty settings entry (#1120).
  ///
  /// In en, this message translates to:
  /// **'Apply per-litre discounts from Total, Aral, Shell, …'**
  String get loyaltyMenuSubtitle;

  /// Floating-action-button label for adding a new loyalty card (#1120).
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get loyaltyAddCard;

  /// Title shown at the top of the add-loyalty-card bottom sheet (#1120).
  ///
  /// In en, this message translates to:
  /// **'Add fuel club card'**
  String get loyaltyAddCardSheetTitle;

  /// Label for the loyalty brand picker on the add-card sheet (#1120).
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get loyaltyBrandLabel;

  /// Label for the optional free-form label input on the add-card sheet (#1120).
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get loyaltyCardLabelLabel;

  /// Label for the per-litre discount numeric input on the add-card sheet (#1120).
  ///
  /// In en, this message translates to:
  /// **'Discount (per litre)'**
  String get loyaltyDiscountLabel;

  /// Validation error shown when the per-litre discount is missing, zero, or negative (#1120).
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number'**
  String get loyaltyDiscountInvalid;

  /// Title of the confirmation dialog shown before deleting a loyalty card (#1120).
  ///
  /// In en, this message translates to:
  /// **'Delete card?'**
  String get loyaltyDeleteConfirmTitle;

  /// Body of the confirmation dialog shown before deleting a loyalty card (#1120).
  ///
  /// In en, this message translates to:
  /// **'This card will stop applying its discount.'**
  String get loyaltyDeleteConfirmBody;

  /// Empty-state title shown on the loyalty settings screen when no card is registered (#1120).
  ///
  /// In en, this message translates to:
  /// **'No fuel club cards yet'**
  String get loyaltyEmptyTitle;

  /// Empty-state body explaining what loyalty cards do (#1120).
  ///
  /// In en, this message translates to:
  /// **'Add a card to apply your per-litre discount to matching stations automatically.'**
  String get loyaltyEmptyBody;

  /// Prefix character (minus sign) used on the discounted-price badge shown on station cards (#1120).
  ///
  /// In en, this message translates to:
  /// **'−'**
  String get loyaltyBadgePrefix;

  /// Title of the predictive-maintenance card on the Trips tab when the idle-RPM creep heuristic fires (#1124).
  ///
  /// In en, this message translates to:
  /// **'Idle RPM creep detected'**
  String get maintenanceSignalIdleRpmCreepTitle;

  /// Body copy of the predictive-maintenance card when the idle-RPM creep heuristic fires (#1124). {percent} is the observed delta as a whole-number percent (e.g. '9'); {tripCount} is the number of trips analysed.
  ///
  /// In en, this message translates to:
  /// **'Idle RPM has crept up by {percent}% over your last {tripCount} trips. Possible early sign of a clogged air filter or sensor drift.'**
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount);

  /// Title of the predictive-maintenance card when the MAF-deviation heuristic fires — proxied via cruise fuel-rate drop (#1124).
  ///
  /// In en, this message translates to:
  /// **'Possible intake restriction'**
  String get maintenanceSignalMafDeviationTitle;

  /// Body copy of the predictive-maintenance card when the MAF-deviation heuristic fires (#1124). {percent} is the observed drop as a whole-number percent; {tripCount} is the number of trips analysed.
  ///
  /// In en, this message translates to:
  /// **'Cruise fuel rate has dropped by {percent}% over your last {tripCount} trips. Possible sign of a clogged air filter or restricted intake — worth a check-up.'**
  String maintenanceSignalMafDeviationBody(String percent, int tripCount);

  /// Label on the 'Dismiss' button of the predictive-maintenance card — silences the card for 24 hours (#1124).
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get maintenanceActionDismiss;

  /// Label on the 'Snooze 30 days' button of the predictive-maintenance card — silences the card for the standard 30-day snooze window (#1124).
  ///
  /// In en, this message translates to:
  /// **'Snooze 30 days'**
  String get maintenanceActionSnooze;

  /// Title of the monthly-insights card on the Trajets tab landing screen — aggregates all trips into a current-vs-previous-month comparison (#1041 phase 4).
  ///
  /// In en, this message translates to:
  /// **'This month vs last month'**
  String get consumptionMonthlyInsightsTitle;

  /// Row label on the monthly-insights card for trip count (#1041 phase 4).
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get consumptionMonthlyTripsLabel;

  /// Row label on the monthly-insights card for total drive time across the month (#1041 phase 4).
  ///
  /// In en, this message translates to:
  /// **'Drive time'**
  String get consumptionMonthlyDriveTimeLabel;

  /// Row label on the monthly-insights card for total distance across the month (#1041 phase 4).
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get consumptionMonthlyDistanceLabel;

  /// Row label on the monthly-insights card for average L/100 km across the month (#1041 phase 4). Only rendered when both months recorded fuel-rate samples.
  ///
  /// In en, this message translates to:
  /// **'Avg consumption'**
  String get consumptionMonthlyAvgConsumptionLabel;

  /// Caption shown on the monthly-insights card when one or both months has fewer than 3 trips. The card still shows the current-month numbers but skips the previous-month column and the delta arrows (#1041 phase 4).
  ///
  /// In en, this message translates to:
  /// **'Need at least 3 trips per month for comparison'**
  String get consumptionMonthlyComparisonNotReliable;

  /// Snackbar shown after the OBD2 picker falls back from a silent pinned-MAC connect to the manual sheet (#1188). The placeholder is the display name of the previously paired adapter so the user knows which one was unreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach \'{adapterName}\' — pick another adapter'**
  String obd2PickerPinnedFallback(String adapterName);

  /// Title of the optional onboarding step (#816) that offers to connect an OBD2 adapter, read the VIN, and auto-fill the vehicle profile.
  ///
  /// In en, this message translates to:
  /// **'Connect your OBD2 adapter'**
  String get onboardingObd2StepTitle;

  /// Body copy for the OBD2 onboarding step (#816) explaining what the user needs to do.
  ///
  /// In en, this message translates to:
  /// **'Plug your OBD2 adapter into the car\'s port and turn the ignition on. We\'ll read the VIN and fill in engine details for you.'**
  String get onboardingObd2StepBody;

  /// Label of the primary button on the OBD2 onboarding step (#816) that opens the adapter picker.
  ///
  /// In en, this message translates to:
  /// **'Connect adapter'**
  String get onboardingObd2ConnectButton;

  /// Label of the skip button on the OBD2 onboarding step (#816) — users without an adapter can skip without connecting.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get onboardingObd2SkipButton;

  /// Spinner label shown while the app reads the VIN from the connected OBD2 adapter (#816).
  ///
  /// In en, this message translates to:
  /// **'Reading VIN…'**
  String get onboardingObd2ReadingVin;

  /// Banner shown on the next manual vehicle step when the OBD2 adapter connected but the VIN could not be read (#816).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read VIN — enter manually'**
  String get onboardingObd2VinReadFailed;

  /// No description provided for @onboardingObd2ConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the adapter. You can retry or skip.'**
  String get onboardingObd2ConnectFailed;

  /// Label of the per-alert frequency dropdown (#1012 phase 1) — chooses how often the background runner re-evaluates this radius alert.
  ///
  /// In en, this message translates to:
  /// **'Check frequency'**
  String get alertsRadiusFrequencyLabel;

  /// Per-alert frequency option: evaluate at most once every 24 h (#1012 phase 1).
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get alertsRadiusFrequencyDaily;

  /// Per-alert frequency option: evaluate at most once every 12 h (#1012 phase 1).
  ///
  /// In en, this message translates to:
  /// **'Twice a day'**
  String get alertsRadiusFrequencyTwiceDaily;

  /// Per-alert frequency option: evaluate at most once every 8 h (#1012 phase 1).
  ///
  /// In en, this message translates to:
  /// **'Three times a day'**
  String get alertsRadiusFrequencyThriceDaily;

  /// Per-alert frequency option: evaluate at most once every 6 h (#1012 phase 1).
  ///
  /// In en, this message translates to:
  /// **'Four times a day'**
  String get alertsRadiusFrequencyFourTimesDaily;

  /// Button on the radius-alert create sheet that opens the full-screen map-picker for the alert center (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get radiusAlertPickOnMap;

  /// AppBar title of the full-screen map-picker shown when choosing the center of a radius alert (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Pick alert center'**
  String get radiusAlertMapPickerTitle;

  /// AppBar action that confirms the currently pinned location and returns it to the create sheet (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get radiusAlertMapPickerConfirm;

  /// AppBar action that dismisses the map-picker without returning a location (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get radiusAlertMapPickerCancel;

  /// Overlay hint on the map-picker explaining the center-crosshair interaction (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Drag the map to position the alert center'**
  String get radiusAlertMapPickerHint;

  /// Label shown in the create sheet after a location has been picked on the map, distinguishing it from a GPS or postal-code center (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get radiusAlertCenterFromMap;

  /// Background notification title when a station in the radius drops to the alert threshold (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'{fuelLabel} near {label}'**
  String radiusAlertNotificationTitle(String fuelLabel, String label);

  /// Background notification body with the observed price and the user's threshold (#578 phase 3).
  ///
  /// In en, this message translates to:
  /// **'A station is at {price} € (target: {threshold} €)'**
  String radiusAlertNotificationBody(String price, String threshold);

  /// Trailing unit suffix on a fuel-pump price in the unified RefuelOptionCard (#1116 phase 3b). Renders below the numeric price (e.g. "1,799" + "/L" → "1,799 /L").
  ///
  /// In en, this message translates to:
  /// **'/L'**
  String get refuelUnitPerLiter;

  /// Trailing unit suffix on an EV charging price in the unified RefuelOptionCard (#1116 phase 3b).
  ///
  /// In en, this message translates to:
  /// **'/kWh'**
  String get refuelUnitPerKwh;

  /// Trailing unit suffix when an EV network bills a flat per-session price instead of per-kWh in the unified RefuelOptionCard (#1116 phase 3b).
  ///
  /// In en, this message translates to:
  /// **'/session'**
  String get refuelUnitPerSession;

  /// Title of the consumption-by-speed card on the Carbon dashboard Charts tab — bins per-second OBD2 samples by speed band so the user can see what motorway speed is costing them per 100 km (#1192).
  ///
  /// In en, this message translates to:
  /// **'Consumption by speed'**
  String get speedConsumptionCardTitle;

  /// Label of the 0-10 km/h speed band on the consumption-by-speed card — stop-and-go and traffic-jam time. Has a time-share figure but no L/100 km average (denominator approaches zero) (#1192).
  ///
  /// In en, this message translates to:
  /// **'Idle / jam'**
  String get speedBandIdleJam;

  /// Label of the 10-50 km/h speed band on the consumption-by-speed card — city driving (#1192).
  ///
  /// In en, this message translates to:
  /// **'Urban (10–50)'**
  String get speedBandUrban;

  /// Label of the 50-80 km/h speed band on the consumption-by-speed card — boulevards and mixed roads (#1192).
  ///
  /// In en, this message translates to:
  /// **'Suburban (50–80)'**
  String get speedBandSuburban;

  /// Label of the 80-100 km/h speed band on the consumption-by-speed card — country roads and secondary highways (#1192).
  ///
  /// In en, this message translates to:
  /// **'Rural (80–100)'**
  String get speedBandRural;

  /// Label of the 100-115 km/h speed band on the consumption-by-speed card — eco-cruise sweet spot on most modern engines (#1192).
  ///
  /// In en, this message translates to:
  /// **'Eco-cruise (100–115)'**
  String get speedBandMotorwaySlow;

  /// Label of the 115-130 km/h speed band on the consumption-by-speed card — standard motorway / French highway speed limit (#1192).
  ///
  /// In en, this message translates to:
  /// **'Motorway (115–130)'**
  String get speedBandMotorway;

  /// Label of the 130+ km/h speed band on the consumption-by-speed card — above the French limit; German Autobahn fast lane (#1192).
  ///
  /// In en, this message translates to:
  /// **'Motorway fast (130+)'**
  String get speedBandMotorwayFast;

  /// Empty-state copy on the consumption-by-speed card when the user has logged less than 30 min of OBD2 telemetry — explains what's needed to populate the chart (#1192).
  ///
  /// In en, this message translates to:
  /// **'Record 30+ minutes of trips with the OBD2 adapter to unlock the speed/consumption analysis.'**
  String get speedConsumptionInsufficientData;

  /// Per-bar sub-label on the consumption-by-speed card — share of total driving time spent in this band (#1192).
  ///
  /// In en, this message translates to:
  /// **'{percent} % of driving'**
  String speedConsumptionTimeShare(int percent);

  /// Placeholder shown on a speed-band bar when the bin's sample count is under the statistical floor — averaging a thin sliver of seconds isn't meaningful (#1192).
  ///
  /// In en, this message translates to:
  /// **'Need more data'**
  String get speedConsumptionNeedMoreData;

  /// Accessibility label announced by TalkBack/VoiceOver while the animated splash screen is visible. Not rendered visually; keep it concise and speakable.
  ///
  /// In en, this message translates to:
  /// **'Loading Tankstellen'**
  String get splashLoadingLabel;

  /// Title of the tank-level card on the Fuel tab — shows the current estimated litres in the tank above the consumption stats card (#1195).
  ///
  /// In en, this message translates to:
  /// **'Tank level'**
  String get tankLevelTitle;

  /// Big-number rendering of the current tank level on the Fuel tab — value is pre-formatted with one decimal (e.g. '32.4 L') (#1195).
  ///
  /// In en, this message translates to:
  /// **'{litres} L'**
  String tankLevelLitersFormat(String litres);

  /// Sub-text under the tank-level big number — distance the user can still drive at the vehicle's average L/100 km (#1195).
  ///
  /// In en, this message translates to:
  /// **'≈ {kilometres} km of range'**
  String tankLevelRangeFormat(String kilometres);

  /// Caption beneath the tank-level card — when the last fill-up was logged and how many trips have been recorded since (#1195).
  ///
  /// In en, this message translates to:
  /// **'Last fill-up: {date} · {count} trip(s) since'**
  String tankLevelLastFillUpFormat(String date, String count);

  /// Method label appended to the tank-level caption when every trip since the last fill-up carried a measured OBD2 fuel-rate value (#1195).
  ///
  /// In en, this message translates to:
  /// **'OBD2 measured'**
  String get tankLevelMethodObd2;

  /// Method label appended to the tank-level caption when no OBD2 fuel measurement was available and consumption was estimated from distance × avg L/100 km (#1195).
  ///
  /// In en, this message translates to:
  /// **'distance-based estimate'**
  String get tankLevelMethodDistanceFallback;

  /// Method label appended to the tank-level caption when some trips used OBD2 and some used the distance-based fallback (#1195).
  ///
  /// In en, this message translates to:
  /// **'mixed measurement'**
  String get tankLevelMethodMixed;

  /// Empty-state message inside the tank-level card when the active vehicle has no fill-ups logged yet (#1195).
  ///
  /// In en, this message translates to:
  /// **'Log a fill-up to see your tank level'**
  String get tankLevelEmptyNoFillUp;

  /// Title of the bottom sheet shown when the user taps the tank-level card — lists the trips folded into the level calculation (#1195).
  ///
  /// In en, this message translates to:
  /// **'Trips since last fill-up'**
  String get tankLevelDetailSheetTitle;

  /// Label of the Full-tank toggle on the Add fill-up screen — defaults on, captures whether the fill-up topped the tank up to capacity (#1195).
  ///
  /// In en, this message translates to:
  /// **'Full tank'**
  String get addFillUpIsFullTankLabel;

  /// Subtitle of the Full-tank toggle on the Add fill-up screen — explains the partial-fill alternative so users know when to flip the switch off (#1360).
  ///
  /// In en, this message translates to:
  /// **'Tank filled to the brim — uncheck if this was a partial fill'**
  String get addFillUpIsFullTankSubtitle;

  /// Title of the Theme card on the Settings screen (#897). The card matches the Privacy + Storage card pattern and navigates to a dedicated theme picker screen.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeCardTitle;

  /// Subtitle on the Theme card when the active theme mode is System (follow device setting) (#897).
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeCardSubtitleSystem;

  /// Subtitle on the Theme card when the active theme mode is Light (#897).
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeCardSubtitleLight;

  /// Subtitle on the Theme card when the active theme mode is Dark (#897).
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeCardSubtitleDark;

  /// AppBar title of the dedicated Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettingsScreenTitle;

  /// Radio option label for the System theme mode on the Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSettingsSystemLabel;

  /// Radio option label for the Light theme mode on the Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeSettingsLightLabel;

  /// Radio option label for the Dark theme mode on the Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeSettingsDarkLabel;

  /// Description text under the System option on the Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Match the current device appearance.'**
  String get themeSettingsSystemDescription;

  /// Description text under the Light option on the Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Bright backgrounds — best for daytime use.'**
  String get themeSettingsLightDescription;

  /// Description text under the Dark option on the Theme settings screen (#897).
  ///
  /// In en, this message translates to:
  /// **'Dark backgrounds — easier on the eyes at night and saves battery on OLED screens.'**
  String get themeSettingsDarkDescription;

  /// Title of the throttle / RPM histogram card on the Trip detail screen — surfaces the share of time the driver spent at each throttle quartile and RPM band (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'How you used the engine'**
  String get throttleRpmHistogramTitle;

  /// Section label above the throttle-quartile bar group on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Throttle position'**
  String get throttleRpmHistogramThrottleSection;

  /// Section label above the RPM-band bar group on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Engine RPM'**
  String get throttleRpmHistogramRpmSection;

  /// Bottom-quartile throttle label (closed throttle / coasting) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Coast (0–25%)'**
  String get throttleRpmHistogramThrottleCoast;

  /// Second-quartile throttle label (light cruise) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Light (25–50%)'**
  String get throttleRpmHistogramThrottleLight;

  /// Third-quartile throttle label (firm pedal) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Firm (50–75%)'**
  String get throttleRpmHistogramThrottleFirm;

  /// Top-quartile throttle label (wide-open / kick-down) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Wide-open (75–100%)'**
  String get throttleRpmHistogramThrottleWide;

  /// Idle RPM band label (≤900 RPM) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Idle (≤900)'**
  String get throttleRpmHistogramRpmIdle;

  /// Cruise RPM band label (901–2000 RPM) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Cruise (901–2000)'**
  String get throttleRpmHistogramRpmCruise;

  /// Spirited RPM band label (2001–3000 RPM) on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'Spirited (2001–3000)'**
  String get throttleRpmHistogramRpmSpirited;

  /// Hard RPM band label (>3000 RPM) on the throttle/RPM histogram card (#1041 phase 3a). Cutoff aligns with the 'Engine over 3000 RPM' driving-insight on the same screen.
  ///
  /// In en, this message translates to:
  /// **'Hard (>3000)'**
  String get throttleRpmHistogramRpmHard;

  /// Empty-state caption inside the throttle/RPM histogram card when neither axis has any time-share to show — typically a legacy trip recorded before the throttle PID was added to the polling rotation (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'No throttle or RPM samples in this trip.'**
  String get throttleRpmHistogramEmpty;

  /// Trailing time-share label on each histogram bar — whole-number percent (e.g. '12%') on the throttle/RPM histogram card (#1041 phase 3a).
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String throttleRpmHistogramBarShare(String pct);

  /// Label for the Trips tab on the ConsumptionScreen (#889). Sits between Fuel and Charging.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trajetsTabLabel;

  /// Primary CTA on the Trips tab that kicks off a new trip recording (#889).
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get trajetsStartRecordingButton;

  /// Primary CTA on the Trips tab when a trip is already being recorded in the background; tapping it brings focus back to the recording screen (#1237).
  ///
  /// In en, this message translates to:
  /// **'Resume recording'**
  String get trajetsResumeRecordingButton;

  /// Status label shown on the Trips tab while the pinned OBD2 adapter is being reached over Bluetooth, before the recording screen opens. Replaces the silent disabled-button wait.
  ///
  /// In en, this message translates to:
  /// **'Connecting to OBD2 adapter…'**
  String get tripStartProgressConnectingAdapter;

  /// Status label shown on the Trips tab while the trip recorder is reading the odometer / VIN and warming up the polling loop, before the recording screen opens.
  ///
  /// In en, this message translates to:
  /// **'Reading vehicle data…'**
  String get tripStartProgressReadingVehicleData;

  /// Status label shown on the Trips tab in the final moment before pushing to the live recording screen.
  ///
  /// In en, this message translates to:
  /// **'Starting recording…'**
  String get tripStartProgressStartingRecording;

  /// Empty-state title on the Trips tab when no trips have been recorded (#889).
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get trajetsEmptyStateTitle;

  /// Empty-state body text on the Trips tab inviting the user to start recording (#889).
  ///
  /// In en, this message translates to:
  /// **'Tap Start recording to begin logging your drives.'**
  String get trajetsEmptyStateBody;

  /// Distance chip on a trip history row (#889).
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String trajetsRowDistance(String km);

  /// Duration chip on a trip history row (#889).
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String trajetsRowDuration(String minutes);

  /// Average consumption chip on a trip history row (#889). Unit is L/100 km for combustion trips and kWh/100 km for EV trips.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String trajetsRowAvgConsumption(String value, String unit);

  /// Title of the summary card at the top of the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get trajetDetailSummaryTitle;

  /// Label for the trip date row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get trajetDetailFieldDate;

  /// Label for the vehicle-name row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get trajetDetailFieldVehicle;

  /// Label for the OBD2-adapter identity row in the Trip detail summary card (#1312). Shown immediately under the Vehicle row when the trip carries any adapter MAC, name, or firmware so device-test bug reports can name the suspect device. Hidden when none of the three fields were captured.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter'**
  String get trajetDetailFieldAdapter;

  /// Label for the distance row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get trajetDetailFieldDistance;

  /// Label for the duration row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trajetDetailFieldDuration;

  /// Label for the average consumption row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Avg consumption'**
  String get trajetDetailFieldAvgConsumption;

  /// Label for the total fuel litres row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Fuel used'**
  String get trajetDetailFieldFuelUsed;

  /// Label for the estimated fuel cost row in the Trip detail summary card. Shown only when a recent fill-up's price-per-litre is available so we can multiply by fuel-litres-consumed (#1209).
  ///
  /// In en, this message translates to:
  /// **'Fuel cost'**
  String get trajetDetailFieldFuelCost;

  /// Label for the average speed row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get trajetDetailFieldAvgSpeed;

  /// Label for the max speed row in the Trip detail summary card (#890).
  ///
  /// In en, this message translates to:
  /// **'Max speed'**
  String get trajetDetailFieldMaxSpeed;

  /// Placeholder shown in the Trip detail summary card when a value is unknown (no samples, missing timestamp, etc.) (#890).
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get trajetDetailFieldValueUnknown;

  /// Section title above the speed-over-time chart on the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'Speed (km/h)'**
  String get trajetDetailChartSpeed;

  /// Section title above the fuel-rate-over-time chart on the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'Fuel rate (L/h)'**
  String get trajetDetailChartFuelRate;

  /// Section title above the RPM-over-time chart on the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'RPM'**
  String get trajetDetailChartRpm;

  /// Section title above the engine-load-over-time chart on the Trip detail screen (#1262 phase 3). Hidden when no sample carries an engineLoadPercent value (cars without OBD2 PID 0x04).
  ///
  /// In en, this message translates to:
  /// **'Engine load (%)'**
  String get trajetDetailChartEngineLoad;

  /// Compact chip label rendered on the trip-history row when the trip's coldStartSurcharge flag is true (#1262 phase 3). Tells the user the engine never reached operating temperature, which raised fuel consumption.
  ///
  /// In en, this message translates to:
  /// **'Cold start'**
  String get trajetsRowColdStartChip;

  /// Tooltip shown when the user long-presses the cold-start chip on a trip-history row (#1262 phase 3). Explains the surcharge in plain language.
  ///
  /// In en, this message translates to:
  /// **'Engine didn\'t reach operating temperature during this trip — fuel consumption was higher than usual.'**
  String get trajetsRowColdStartTooltip;

  /// Empty-state caption shown inside a Trip detail chart when no matching samples were recorded (#890).
  ///
  /// In en, this message translates to:
  /// **'No samples recorded'**
  String get trajetDetailChartEmpty;

  /// AppBar action tooltip for the share-trip button on the Trip detail screen (#890, #1189).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get trajetDetailShareAction;

  /// Subject / preview text passed to the OS share sheet when the user shares a trip detail report as an image (#1189). The {date} placeholder is replaced with a localised short date.
  ///
  /// In en, this message translates to:
  /// **'Tankstellen — trip on {date}'**
  String trajetDetailShareSubject(String date);

  /// Snackbar shown when the trip-detail Share action fails to render or hand off the report PNG (#1189).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate share image'**
  String get trajetDetailShareError;

  /// AppBar action tooltip for the delete-trip button on the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get trajetDetailDeleteAction;

  /// Title of the confirmation dialog before deleting a trip on the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'Delete this trip?'**
  String get trajetDetailDeleteConfirmTitle;

  /// Body of the confirmation dialog before deleting a trip on the Trip detail screen (#890).
  ///
  /// In en, this message translates to:
  /// **'This trip will be permanently removed from your history.'**
  String get trajetDetailDeleteConfirmBody;

  /// Cancel button label on the delete-trip confirmation dialog (#890).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trajetDetailDeleteConfirmCancel;

  /// Confirm button label on the delete-trip confirmation dialog (#890).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get trajetDetailDeleteConfirmConfirm;

  /// OBD2 pause banner copy (#1330 phase 3) when the adapter is connected but every high-priority PID parse returned null for ~10 s. Distinct from the 'connection lost' message — the link is fine, but the ECU isn't answering. Suggests trying a different adapter or checking the vehicle's diagnostic protocol.
  ///
  /// In en, this message translates to:
  /// **'OBD2 adapter connected but not returning data. Try a different adapter or check the vehicle\'s diagnostic protocol.'**
  String get tripRecordingObd2NotResponding;

  /// Title of the trip-length consumption card on the Carbon dashboard Charts tab — splits trips into short/medium/long buckets so the user can see cold-start fuel waste vs. cruising efficiency (#1191).
  ///
  /// In en, this message translates to:
  /// **'Consumption by trip length'**
  String get tripLengthCardTitle;

  /// Label of the short-trip tile on the trip-length breakdown card — trips under 5 km, where cold-engine warmup dominates (#1191).
  ///
  /// In en, this message translates to:
  /// **'Short (<5 km)'**
  String get tripLengthBucketShort;

  /// Label of the medium-trip tile on the trip-length breakdown card — trips between 5 and 25 km, mostly urban / mixed driving (#1191).
  ///
  /// In en, this message translates to:
  /// **'Medium (5–25 km)'**
  String get tripLengthBucketMedium;

  /// Label of the long-trip tile on the trip-length breakdown card — trips over 25 km, stable-temperature cruising (#1191).
  ///
  /// In en, this message translates to:
  /// **'Long (>25 km)'**
  String get tripLengthBucketLong;

  /// Placeholder shown on a trip-length breakdown tile when the bucket has fewer than 5 trips — statistically meaningless to show an average that thin (#1191).
  ///
  /// In en, this message translates to:
  /// **'Need more data'**
  String get tripLengthBucketNeedMoreData;

  /// Trip-count subtitle on each trip-length breakdown tile (#1191).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no trips} one{1 trip} other{{count} trips}}'**
  String tripLengthBucketTripCount(int count);

  /// Tooltip on the pin toggle in the trip-recording AppBar (#891). Warns the user that enabling pin keeps the screen awake at a battery cost.
  ///
  /// In en, this message translates to:
  /// **'Pinning keeps the screen on — uses more battery'**
  String get tripRecordingPinTooltip;

  /// Accessibility label when the pin toggle is currently ON. Tapping will unpin (disable wake lock + restore system UI).
  ///
  /// In en, this message translates to:
  /// **'Unpin recording form'**
  String get tripRecordingPinSemanticOn;

  /// Accessibility label when the pin toggle is currently OFF. Tapping will pin (enable wake lock + immersive mode).
  ///
  /// In en, this message translates to:
  /// **'Pin recording form'**
  String get tripRecordingPinSemanticOff;

  /// Tooltip on the help (?) icon adjacent to the pin button (#1273). Tapping opens a bottom sheet explaining what pin does.
  ///
  /// In en, this message translates to:
  /// **'What does pin do?'**
  String get tripRecordingPinHelpTooltip;

  /// Title of the bottom sheet explaining the pin button (#1273).
  ///
  /// In en, this message translates to:
  /// **'About pin'**
  String get tripRecordingPinHelpTitle;

  /// Body text in the bottom sheet explaining the pin button (#1273).
  ///
  /// In en, this message translates to:
  /// **'Pin keeps the screen on and hides system bars so the form stays readable on a dashboard mount. Tap again to release. Auto-releases when the trip stops.'**
  String get tripRecordingPinHelpBody;

  /// One-time tooltip shown the first time the user backs out of the recording screen while a trip is still recording (#1273). Tells them they can tap the persistent banner to return. Persisted dismissal — never fires twice.
  ///
  /// In en, this message translates to:
  /// **'Recording continues in the background. Tap the red banner at the top of any screen to return.'**
  String get tripRecordingResumeHintMessage;

  /// Snackbar shown when the user taps the trip-recording banner on a screen whose context is above the GoRouter ancestor (#1322). Falls back from a navigation push to a hint pointing the user at the consumption tab.
  ///
  /// In en, this message translates to:
  /// **'Open the active trip from the Conso tab'**
  String get tripBannerOpenFromConsumptionTab;

  /// Filter chip label that narrows the unified search list to fuel pumps only (#1116 phase 3c).
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get unifiedFilterFuel;

  /// Filter chip label that narrows the unified search list to EV chargers only (#1116 phase 3c).
  ///
  /// In en, this message translates to:
  /// **'EV'**
  String get unifiedFilterEv;

  /// Filter chip label that shows fuel pumps and EV chargers together in the unified search list (default selection, #1116 phase 3c).
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get unifiedFilterBoth;

  /// Empty-state placeholder shown in the unified search list when the active filter (Fuel / EV / Both) leaves zero options (#1116 phase 3c).
  ///
  /// In en, this message translates to:
  /// **'No results match this filter'**
  String get unifiedNoResultsForFilter;

  /// No description provided for @vinLabel.
  ///
  /// In en, this message translates to:
  /// **'VIN (optional)'**
  String get vinLabel;

  /// No description provided for @vinDecodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decode VIN'**
  String get vinDecodeTooltip;

  /// No description provided for @vinConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, auto-fill'**
  String get vinConfirmAction;

  /// No description provided for @vinModifyAction.
  ///
  /// In en, this message translates to:
  /// **'Modify manually'**
  String get vinModifyAction;

  /// Action on the vehicle edit screen that discards the learned volumetric-efficiency calibration (#815).
  ///
  /// In en, this message translates to:
  /// **'Reset volumetric efficiency'**
  String get veResetAction;

  /// Button label on the vehicle edit screen that triggers an OBD2 Mode 09 PID 02 read of the VIN from the paired adapter (#1162).
  ///
  /// In en, this message translates to:
  /// **'Read VIN from car'**
  String get vehicleReadVinFromCarButton;

  /// Tooltip for the read-VIN-from-car button on the vehicle edit screen (#1162).
  ///
  /// In en, this message translates to:
  /// **'Read VIN from the paired OBD2 adapter'**
  String get vehicleReadVinFromCarTooltip;

  /// Snackbar shown when the OBD2 adapter does not support Mode 09 PID 02 (#1162).
  ///
  /// In en, this message translates to:
  /// **'VIN not available (Mode 09 PID 02 unsupported on pre-2005 vehicles)'**
  String get vehicleReadVinFailedUnsupportedSnackbar;

  /// Snackbar shown when reading the VIN failed for a non-unsupported reason (timeout, malformed, IO) (#1162).
  ///
  /// In en, this message translates to:
  /// **'VIN read failed — please enter manually'**
  String get vehicleReadVinFailedGenericSnackbar;

  /// Helper text shown under the disabled "Read VIN from car" button on the vehicle edit screen when no OBD2 adapter is paired yet (#1328). Tells the user how to enable the auto-read flow.
  ///
  /// In en, this message translates to:
  /// **'Pair an OBD2 adapter first to read VIN automatically'**
  String get vehicleReadVinNoAdapterHint;

  /// Tooltip + Semantics label for the info icon next to the VIN field on EditVehicleScreen (#895).
  ///
  /// In en, this message translates to:
  /// **'What is a VIN?'**
  String get vinInfoTooltip;

  /// Heading for the 'What VIN is' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'What is a VIN?'**
  String get vinInfoSectionWhatTitle;

  /// Body of the 'What VIN is' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'The Vehicle Identification Number is a 17-character code unique to your car. It\'s stamped on the chassis and printed on your vehicle registration document.'**
  String get vinInfoSectionWhatBody;

  /// Heading for the 'Why we ask' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Why we ask'**
  String get vinInfoSectionWhyTitle;

  /// Body of the 'Why we ask' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Decoding the VIN auto-fills engine displacement, cylinder count, model year, primary fuel type, and gross weight — saving you from looking up technical specs manually. The OBD2 fuel-rate calculation uses these values to give you accurate consumption numbers.'**
  String get vinInfoSectionWhyBody;

  /// Heading for the 'Privacy' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get vinInfoSectionPrivacyTitle;

  /// Body of the 'Privacy' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Your VIN is stored only locally in the app\'s encrypted storage — it\'s never uploaded to Tankstellen servers. The NHTSA vPIC database is queried with the VIN but returns only anonymous technical specs; NHTSA does not link the VIN to any personal data. Without network, an offline lookup returns manufacturer and country only.'**
  String get vinInfoSectionPrivacyBody;

  /// Heading for the 'Where to find it' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Where to find it'**
  String get vinInfoSectionWhereTitle;

  /// Body of the 'Where to find it' section of the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Look through the windshield at the lower-left corner on the driver\'s side, check the driver-side door-frame sticker when the door is open, or read it off your vehicle registration document (card / Carte Grise).'**
  String get vinInfoSectionWhereBody;

  /// Dismiss button label on the VIN info sheet (#895).
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get vinInfoDismiss;

  /// One-line privacy reassurance shown near the top of the VIN confirm dialog (#895).
  ///
  /// In en, this message translates to:
  /// **'We looked up your VIN on NHTSA\'s free vehicle database — nothing sent to Tankstellen servers.'**
  String get vinConfirmPrivacyNote;

  /// Label for the default home-widget content variant — shows just the current pump price (#1121).
  ///
  /// In en, this message translates to:
  /// **'Current price only'**
  String get widgetVariantDefault;

  /// Label for the predictive home-widget content variant — adds a best-time-to-fill nudge under each row (#1121).
  ///
  /// In en, this message translates to:
  /// **'Predictive: best time to fill'**
  String get widgetVariantPredictive;

  /// One-word prefix shown before the current price on the predictive widget line, e.g. 'now €1.84/L' (#1121).
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get widgetPredictiveNowPrefix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bg',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'hr',
    'hu',
    'it',
    'lt',
    'lv',
    'nb',
    'nl',
    'pl',
    'pt',
    'ro',
    'sk',
    'sl',
    'sv',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'it':
      return AppLocalizationsIt();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'nb':
      return AppLocalizationsNb();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
