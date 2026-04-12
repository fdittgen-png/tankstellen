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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
    Locale('sv')
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
  String voiceAnnouncementCheapFuel(String station, String distance, String fuelType, String price);

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

  /// No description provided for @carbonTabCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get carbonTabCharts;

  /// No description provided for @carbonTabAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get carbonTabAchievements;

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

  /// No description provided for @milestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestonesTitle;

  /// No description provided for @milestoneFirstFillUp.
  ///
  /// In en, this message translates to:
  /// **'First fill-up logged'**
  String get milestoneFirstFillUp;

  /// No description provided for @milestoneTenFillUps.
  ///
  /// In en, this message translates to:
  /// **'10 fill-ups tracked'**
  String get milestoneTenFillUps;

  /// No description provided for @milestoneFiftyFillUps.
  ///
  /// In en, this message translates to:
  /// **'50 fill-ups tracked'**
  String get milestoneFiftyFillUps;

  /// No description provided for @milestoneHundredLiters.
  ///
  /// In en, this message translates to:
  /// **'100 L tracked'**
  String get milestoneHundredLiters;

  /// No description provided for @milestoneThousandLiters.
  ///
  /// In en, this message translates to:
  /// **'1000 L tracked'**
  String get milestoneThousandLiters;

  /// No description provided for @milestoneHundredKgCo2.
  ///
  /// In en, this message translates to:
  /// **'100 kg CO2 tracked'**
  String get milestoneHundredKgCo2;

  /// No description provided for @milestoneOneTonneCo2.
  ///
  /// In en, this message translates to:
  /// **'1 tonne CO2 tracked'**
  String get milestoneOneTonneCo2;

  /// No description provided for @milestoneThousandKm.
  ///
  /// In en, this message translates to:
  /// **'1000 km driven'**
  String get milestoneThousandKm;

  /// No description provided for @milestoneTenThousandKm.
  ///
  /// In en, this message translates to:
  /// **'10,000 km driven'**
  String get milestoneTenThousandKm;

  /// No description provided for @fuelVsEvTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel vs EV'**
  String get fuelVsEvTitle;

  /// No description provided for @fuelVsEvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CO2 comparison for the same distance driven'**
  String get fuelVsEvSubtitle;

  /// No description provided for @fuelVsEvYourFuel.
  ///
  /// In en, this message translates to:
  /// **'Your fuel'**
  String get fuelVsEvYourFuel;

  /// No description provided for @fuelVsEvEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent EV'**
  String get fuelVsEvEquivalent;

  /// No description provided for @fuelVsEvDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get fuelVsEvDistance;

  /// No description provided for @fuelVsEvDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get fuelVsEvDifference;

  /// No description provided for @shareProgress.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareProgress;

  /// No description provided for @shareCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get shareCopied;

  /// No description provided for @shareCo2Message.
  ///
  /// In en, this message translates to:
  /// **'I tracked {kg} kg CO2 with Tankstellen.'**
  String shareCo2Message(String kg);

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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bg', 'cs', 'da', 'de', 'el', 'en', 'es', 'et', 'fi', 'fr', 'hr', 'hu', 'it', 'lt', 'lv', 'nb', 'nl', 'pl', 'pt', 'ro', 'sk', 'sl', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg': return AppLocalizationsBg();
    case 'cs': return AppLocalizationsCs();
    case 'da': return AppLocalizationsDa();
    case 'de': return AppLocalizationsDe();
    case 'el': return AppLocalizationsEl();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'et': return AppLocalizationsEt();
    case 'fi': return AppLocalizationsFi();
    case 'fr': return AppLocalizationsFr();
    case 'hr': return AppLocalizationsHr();
    case 'hu': return AppLocalizationsHu();
    case 'it': return AppLocalizationsIt();
    case 'lt': return AppLocalizationsLt();
    case 'lv': return AppLocalizationsLv();
    case 'nb': return AppLocalizationsNb();
    case 'nl': return AppLocalizationsNl();
    case 'pl': return AppLocalizationsPl();
    case 'pt': return AppLocalizationsPt();
    case 'ro': return AppLocalizationsRo();
    case 'sk': return AppLocalizationsSk();
    case 'sl': return AppLocalizationsSl();
    case 'sv': return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
