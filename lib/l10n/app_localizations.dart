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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en', 'XA'),
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
  /// **'Sparkilo'**
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

  /// No description provided for @fabOpenCriteria.
  ///
  /// In en, this message translates to:
  /// **'Open search'**
  String get fabOpenCriteria;

  /// No description provided for @fabOpenResults.
  ///
  /// In en, this message translates to:
  /// **'Open results'**
  String get fabOpenResults;

  /// No description provided for @fabRunSearch.
  ///
  /// In en, this message translates to:
  /// **'Run search'**
  String get fabRunSearch;

  /// No description provided for @fabRefineCriteria.
  ///
  /// In en, this message translates to:
  /// **'Refine search'**
  String get fabRefineCriteria;

  /// No description provided for @routeSearchPartialBanner.
  ///
  /// In en, this message translates to:
  /// **'Searching for more stations…'**
  String get routeSearchPartialBanner;

  /// No description provided for @routeSearchingChip.
  ///
  /// In en, this message translates to:
  /// **'Searching the route…'**
  String get routeSearchingChip;

  /// No description provided for @routeSegmentSummaryBadge.
  ///
  /// In en, this message translates to:
  /// **'Every {km} km'**
  String routeSegmentSummaryBadge(String km);

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
  /// **'Sparkilo'**
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

  /// No description provided for @cacheTtlGroupNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get cacheTtlGroupNetwork;

  /// No description provided for @cacheTtlGroupData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get cacheTtlGroupData;

  /// No description provided for @cacheTtlGroupGeocoding.
  ///
  /// In en, this message translates to:
  /// **'Geocoding'**
  String get cacheTtlGroupGeocoding;

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

  /// No description provided for @reportAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'You already reported this issue.'**
  String get reportAlreadySent;

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

  /// Demo-mode banner content shown for API-key countries with no key configured. Jargon-free per #1696 — names neither 'API key' nor any technical term.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — showing sample prices.'**
  String get demoModeBanner;

  /// Action button on the demo-mode banner — opens Settings where live prices can be set up. Jargon-free wording (#1696).
  ///
  /// In en, this message translates to:
  /// **'Get live prices'**
  String get demoModeBannerAction;

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

  /// No description provided for @routeModeBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Route mode — distances are along the corridor'**
  String get routeModeBannerLabel;

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

  /// SnackBar confirming the active profile changed after tapping Activate in the profile list.
  ///
  /// In en, this message translates to:
  /// **'Switched to {profile}'**
  String profileSwitchedTo(String profile);

  /// SnackBar confirming a new profile was created from the profile list.
  ///
  /// In en, this message translates to:
  /// **'Profile {name} created'**
  String profileCreatedNamed(String name);

  /// Blocks selecting a country in the profile editor when another profile already uses it (one profile per country).
  ///
  /// In en, this message translates to:
  /// **'A profile for {country} already exists — edit it instead.'**
  String profileCountryTaken(String country);

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

  /// Access-cost badge on an EV station: charging is free of charge (no payment, no membership). Derived from the OpenChargeMap UsageType signal (#2618).
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get evPriceFree;

  /// Access-cost badge on an EV station: a tariff is paid on site (pay-as-you-go). Derived from the OpenChargeMap UsageType signal (#2618).
  ///
  /// In en, this message translates to:
  /// **'Pay at location'**
  String get evPricePayAtLocation;

  /// Access-cost badge on an EV station: a network membership / RFID card is required to charge. Derived from the OpenChargeMap UsageType signal (#2618).
  ///
  /// In en, this message translates to:
  /// **'Membership required'**
  String get evPriceMembership;

  /// Label preceding the operator-declared, unverified indicative price text on an EV station (never a confirmed comparison price) (#2618).
  ///
  /// In en, this message translates to:
  /// **'Indicative price'**
  String get evPriceIndicative;

  /// Honest-UX disclaimer shown under the raw operator-declared EV price text: the figure is indicative only and must be checked on site (#2618).
  ///
  /// In en, this message translates to:
  /// **'Indicative price declared by the operator — verify on site'**
  String get evPriceDeclaredByOperator;

  /// Data attribution shown only on French EV stations enriched from the IRVE open dataset (Etalab / data.gouv.fr / ODRÉ) (#2618). Brand/source names are proper nouns.
  ///
  /// In en, this message translates to:
  /// **'Pricing: Base nationale des IRVE — Licence Ouverte / data.gouv.fr / ODRÉ'**
  String get evPriceFranceAttribution;

  /// Best-effort pricing caption shown on non-IRVE EV stations whose usage cost came from OpenChargeMap's community-sourced (and sparse) UsageCost field (#2616). Mutually exclusive with the France IRVE attribution. OpenChargeMap is a proper noun within the localized sentence.
  ///
  /// In en, this message translates to:
  /// **'Best-effort pricing from OpenChargeMap — sparse and may be incomplete.'**
  String get evPriceBestEffortOcm;

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

  /// No description provided for @routePlanningSection.
  ///
  /// In en, this message translates to:
  /// **'Route planning'**
  String get routePlanningSection;

  /// No description provided for @routeMinSaving.
  ///
  /// In en, this message translates to:
  /// **'Minimum saving'**
  String get routeMinSaving;

  /// No description provided for @routeMinSavingOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get routeMinSavingOff;

  /// No description provided for @routeMinSavingOffCaption.
  ///
  /// In en, this message translates to:
  /// **'Showing every station found along the route'**
  String get routeMinSavingOffCaption;

  /// No description provided for @routeMinSavingCaption.
  ///
  /// In en, this message translates to:
  /// **'Only stations within {amount} of the route\'s cheapest'**
  String routeMinSavingCaption(String amount);

  /// No description provided for @routeDetourBudget.
  ///
  /// In en, this message translates to:
  /// **'Maximum detour'**
  String get routeDetourBudget;

  /// No description provided for @routeDetourBudgetCaption.
  ///
  /// In en, this message translates to:
  /// **'Surface stations up to {km} km off your direct route'**
  String routeDetourBudgetCaption(int km);

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

  /// No description provided for @calculatorDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance ({unit})'**
  String calculatorDistanceLabel(String unit);

  /// No description provided for @calculatorConsumptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumption ({unit})'**
  String calculatorConsumptionLabel(String unit);

  /// No description provided for @calculatorPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel price ({unit})'**
  String calculatorPriceLabel(String unit);

  /// No description provided for @calculatorUseMine.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get calculatorUseMine;

  /// No description provided for @calculatorApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get calculatorApplied;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetails;

  /// No description provided for @calculatorRoundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round trip'**
  String get calculatorRoundTrip;

  /// No description provided for @roundTripTotal.
  ///
  /// In en, this message translates to:
  /// **'Round trip'**
  String get roundTripTotal;

  /// No description provided for @costPerDistance.
  ///
  /// In en, this message translates to:
  /// **'Cost per km'**
  String get costPerDistance;

  /// No description provided for @costPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Cost per month'**
  String get costPerMonth;

  /// No description provided for @calculatorEstimateMonthly.
  ///
  /// In en, this message translates to:
  /// **'Estimate monthly cost'**
  String get calculatorEstimateMonthly;

  /// No description provided for @calculatorTripsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Trips per month'**
  String get calculatorTripsPerMonth;

  /// No description provided for @calculatorTripsPerMonthHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 20'**
  String get calculatorTripsPerMonthHint;

  /// No description provided for @calculatorReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get calculatorReset;

  /// No description provided for @calculatorResultPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Fill in distance, consumption and price to see your trip cost'**
  String get calculatorResultPlaceholder;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price History'**
  String get priceHistory;

  /// No description provided for @ignoredStationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get ignoredStationsLabel;

  /// No description provided for @ratingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratingsLabel;

  /// No description provided for @favoritesDataCache.
  ///
  /// In en, this message translates to:
  /// **'Favorites data'**
  String get favoritesDataCache;

  /// No description provided for @citySearchCache.
  ///
  /// In en, this message translates to:
  /// **'City search'**
  String get citySearchCache;

  /// No description provided for @dataDeletionNotAvailableCommunity.
  ///
  /// In en, this message translates to:
  /// **'Data deletion is not available in community mode. Disconnect first, or use a private database.'**
  String get dataDeletionNotAvailableCommunity;

  /// No description provided for @priceHistoryStationsTracked.
  ///
  /// In en, this message translates to:
  /// **'{count} stations tracked'**
  String priceHistoryStationsTracked(int count);

  /// No description provided for @alertsConfiguredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} configured'**
  String alertsConfiguredCount(int count);

  /// No description provided for @ignoredStationsHidden.
  ///
  /// In en, this message translates to:
  /// **'{count} stations hidden'**
  String ignoredStationsHidden(int count);

  /// No description provided for @ratingsStationsRated.
  ///
  /// In en, this message translates to:
  /// **'{count} stations rated'**
  String ratingsStationsRated(int count);

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

  /// No description provided for @forgetAllSyncedTripsButton.
  ///
  /// In en, this message translates to:
  /// **'Forget all synced trips'**
  String get forgetAllSyncedTripsButton;

  /// No description provided for @forgetAllSyncedTripsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget all synced trips?'**
  String get forgetAllSyncedTripsConfirmTitle;

  /// No description provided for @forgetAllSyncedTripsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every trip summary and detail blob will be removed from the server. Your local trip history on this device won\'t be affected.\n\nThis action cannot be undone.'**
  String get forgetAllSyncedTripsConfirmBody;

  /// No description provided for @forgetAllSyncedTripsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Forget all'**
  String get forgetAllSyncedTripsConfirmAction;

  /// No description provided for @forgetAllSyncedTripsSuccess.
  ///
  /// In en, this message translates to:
  /// **'All synced trips removed from server'**
  String get forgetAllSyncedTripsSuccess;

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

  /// No description provided for @syncedTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get syncedTrips;

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
  /// **'Sync favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.'**
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

  /// No description provided for @brandLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'{brand} logo'**
  String brandLogoLabel(String brand);

  /// No description provided for @ratingStarLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rate 1 star} other{Rate {count} stars}}'**
  String ratingStarLabel(int count);

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
  /// **'When sync is enabled, favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips are also stored on the TankSync server.'**
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

  /// Snackbar confirming an export was written to the device's public Downloads folder (#2014). Replaces the earlier savedToFile string, which leaked a filesystem path that is meaningless to users (and on Android Q+ becomes a content:// URI).
  ///
  /// In en, this message translates to:
  /// **'Saved to your Downloads folder'**
  String get savedToDownloadsFolder;

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

  /// Button on the Privacy Dashboard that writes the buffered error traces to the device's Downloads folder (and shares / copies as a secondary path). Supersedes privacyCopyErrorLog (#2145). count = number of traces buffered.
  ///
  /// In en, this message translates to:
  /// **'Save error log ({count})'**
  String privacySaveErrorLog(int count);

  /// No description provided for @privacyClearErrorLog.
  ///
  /// In en, this message translates to:
  /// **'Clear error log'**
  String get privacyClearErrorLog;

  /// No description provided for @privacyErrorLogCleared.
  ///
  /// In en, this message translates to:
  /// **'Error log cleared'**
  String get privacyErrorLogCleared;

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

  /// Title of the voice-announcement price-threshold slider in driving settings: only stations priced at or below this per-litre figure are announced.
  ///
  /// In en, this message translates to:
  /// **'Maximum price'**
  String get voiceAnnouncementPriceLimit;

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
  /// **'Your cars — fuel type, engine and tank size for accurate consumption estimates'**
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

  /// TextButton label that reveals the per-driving-situation calibration rows on the vehicle-edit baseline section (#2514, was English-only inline).
  ///
  /// In en, this message translates to:
  /// **'Show per-situation breakdown'**
  String get vehicleBaselineShowDetails;

  /// TextButton label that collapses the per-driving-situation calibration rows back to the single aggregate bar (#2514).
  ///
  /// In en, this message translates to:
  /// **'Hide per-situation breakdown'**
  String get vehicleBaselineHideDetails;

  /// Warning chip on the baseline-calibration section naming the driving situations that have never accumulated a sample (e.g. Stop & go, Climbing / loaded), so the user understands calibration is incomplete even when the aggregate bar looks high (#2514).
  ///
  /// In en, this message translates to:
  /// **'Not detected yet: {situations}. These driving situations still read 0 samples, so the baseline is incomplete.'**
  String vehicleBaselineMissingWarning(String situations);

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

  /// No description provided for @situationColdStart.
  ///
  /// In en, this message translates to:
  /// **'Cold start'**
  String get situationColdStart;

  /// No description provided for @situationSustainedLoad.
  ///
  /// In en, this message translates to:
  /// **'Sustained load / towing'**
  String get situationSustainedLoad;

  /// No description provided for @situationPartialDecel.
  ///
  /// In en, this message translates to:
  /// **'Coasting'**
  String get situationPartialDecel;

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

  /// No description provided for @wizardProfileChoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use the app. You can change this later in Settings.'**
  String get wizardProfileChoiceHint;

  /// No description provided for @wizardProfileChoiceFooter.
  ///
  /// In en, this message translates to:
  /// **'You can change your choice any time from Settings → Use mode.'**
  String get wizardProfileChoiceFooter;

  /// No description provided for @wizardProfileBasicName.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get wizardProfileBasicName;

  /// No description provided for @wizardProfileBasicDescription.
  ///
  /// In en, this message translates to:
  /// **'Cheapest fuel and EV charging prices nearby. Favorites and price alerts.'**
  String get wizardProfileBasicDescription;

  /// No description provided for @wizardProfileMediumName.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get wizardProfileMediumName;

  /// No description provided for @wizardProfileMediumDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything in Basic, plus track your fuel fill-ups and EV charging by hand.'**
  String get wizardProfileMediumDescription;

  /// No description provided for @wizardProfileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get wizardProfileFullName;

  /// No description provided for @wizardProfileFullDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything in Medium, plus automatic OBD2 trip recording, driving scores, and loyalty cards.'**
  String get wizardProfileFullDescription;

  /// No description provided for @wizardProfileCustomName.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get wizardProfileCustomName;

  /// No description provided for @wizardProfileCustomDescription.
  ///
  /// In en, this message translates to:
  /// **'Your own combination of features. Tweak each toggle below.'**
  String get wizardProfileCustomDescription;

  /// No description provided for @useModeSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Right-size the app to how you actually use it. Picking a preset enables the matching set of features.'**
  String get useModeSectionHint;

  /// No description provided for @useModeCustomSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your feature mix doesn\'t match any preset. Pick one above to overwrite, or keep customising individual features in the section below.'**
  String get useModeCustomSettingsDescription;

  /// No description provided for @useModeSwitchedSnack.
  ///
  /// In en, this message translates to:
  /// **'Use mode set to {profile}.'**
  String useModeSwitchedSnack(String profile);

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

  /// No description provided for @vehiclePowerLabel.
  ///
  /// In en, this message translates to:
  /// **'Engine power (kW)'**
  String get vehiclePowerLabel;

  /// No description provided for @vehiclePowerHelper.
  ///
  /// In en, this message translates to:
  /// **'≈ {ps} PS'**
  String vehiclePowerHelper(String ps);

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

  /// No description provided for @evStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly available'**
  String get evStatusPartial;

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

  /// Settings group header (#2521) over the API Key + Location entries — the first-run configuration the app needs to find prices.
  ///
  /// In en, this message translates to:
  /// **'Setup & data sources'**
  String get sectionSetupDataSources;

  /// Settings group header (#2521) over Feature management + Consumption — the toggles that decide which surfaces appear and how they're used.
  ///
  /// In en, this message translates to:
  /// **'Features & usage'**
  String get sectionFeaturesUsage;

  /// Settings group header (#2521) over the TankSync cloud-sync entry.
  ///
  /// In en, this message translates to:
  /// **'Account & sync'**
  String get sectionAccountSync;

  /// Settings group header (#2521) over the Theme chooser + Home-screen widget help entries.
  ///
  /// In en, this message translates to:
  /// **'Appearance & widgets'**
  String get sectionAppearanceWidgets;

  /// Settings group header (#2521) over Privacy consent + Privacy Dashboard + Storage & cache — one data-control concern.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get sectionPrivacyData;

  /// Settings group header (#2521) over the bad-scan PAT entry + Developer tools — power-user controls hidden by default.
  ///
  /// In en, this message translates to:
  /// **'Advanced & developer'**
  String get sectionAdvancedDeveloper;

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

  /// No description provided for @tooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// No description provided for @tooltipClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search input'**
  String get tooltipClearSearch;

  /// Label above the headline instant-L/100km figure in the MinimalDriveSummary card on the trip-recording screen (#2026). Replaces the five-card 'Distance/Speed/Fuel/Avg/Elapsed' wall as the primary live-drive surface.
  ///
  /// In en, this message translates to:
  /// **'Instant consumption'**
  String get minimalDriveInstantConsumption;

  /// No description provided for @coachingShiftUp.
  ///
  /// In en, this message translates to:
  /// **'Shift up'**
  String get coachingShiftUp;

  /// No description provided for @coachingShiftDown.
  ///
  /// In en, this message translates to:
  /// **'Shift down'**
  String get coachingShiftDown;

  /// No description provided for @coachingEasePedal.
  ///
  /// In en, this message translates to:
  /// **'Ease off'**
  String get coachingEasePedal;

  /// Spoken driving-coach cue (#2663) when a harsh acceleration event is detected during recording. Full sentence — distinct from the glanceable tile label coachingEasePedal.
  ///
  /// In en, this message translates to:
  /// **'Easy on the accelerator'**
  String get coachingVoiceHardAcceleration;

  /// Spoken driving-coach cue (#2663) when a harsh braking event is detected during recording.
  ///
  /// In en, this message translates to:
  /// **'Try to brake more gently'**
  String get coachingVoiceHarshBraking;

  /// Spoken driving-coach cue (#2663) when the engine is revving high in cruise — full spoken phrasing of the coachingShiftUp tile.
  ///
  /// In en, this message translates to:
  /// **'Shift up a gear to save fuel'**
  String get coachingVoiceShiftUp;

  /// Spoken driving-coach cue (#2663) when the engine is lugging at low RPM under load — full spoken phrasing of the coachingShiftDown tile.
  ///
  /// In en, this message translates to:
  /// **'Shift down, the engine is labouring'**
  String get coachingVoiceShiftDown;

  /// Spoken driving-coach cue (#2663) when the throttle is wide open during a heavy-consumption cruise — full spoken phrasing of the coachingEasePedal tile.
  ///
  /// In en, this message translates to:
  /// **'Ease off the pedal to cut your fuel use'**
  String get coachingVoiceEasePedal;

  /// Spoken driving-coach cue (#2663) when cruising downhill with no recent braking — full spoken phrasing of the coachingGpsLiftOff tile.
  ///
  /// In en, this message translates to:
  /// **'Lift off the accelerator and coast'**
  String get coachingVoiceLiftOff;

  /// Spoken driving-coach cue (#2663) after a braking event — full spoken phrasing of the coachingGpsAnticipateBrake tile.
  ///
  /// In en, this message translates to:
  /// **'Look further ahead and lift off earlier'**
  String get coachingVoiceAnticipateBrake;

  /// Spoken driving-coach cue (#2663) after a sharp acceleration on a GPS-only trip — full spoken phrasing of the coachingGpsSmoothAccel tile.
  ///
  /// In en, this message translates to:
  /// **'Accelerate more smoothly'**
  String get coachingVoiceSmoothAccel;

  /// Spoken driving-coach cue (#3504) when the IMU confirms a sustained sharp corner (lateral load + yaw) during recording.
  ///
  /// In en, this message translates to:
  /// **'Take corners a little gentler'**
  String get coachingVoiceSharpCorner;

  /// Strong-severity variant of coachingVoiceHarshBraking (#3504): spoken instead of the normal cue when the braking magnitude is well past the harsh threshold (>=1.5x).
  ///
  /// In en, this message translates to:
  /// **'That was a very hard stop — leave more distance'**
  String get coachingVoiceHarshBrakingStrong;

  /// Strong-severity variant of coachingVoiceHardAcceleration (#3504), spoken when the acceleration magnitude is well past the harsh threshold (>=1.5x).
  ///
  /// In en, this message translates to:
  /// **'Very hard acceleration — that burns real fuel'**
  String get coachingVoiceHardAccelerationStrong;

  /// Strong-severity variant of coachingVoiceSharpCorner (#3504), spoken when the lateral load is well past the corner threshold (>=1.5x).
  ///
  /// In en, this message translates to:
  /// **'Very sharp corner — slow in, gentle out'**
  String get coachingVoiceSharpCornerStrong;

  /// Optional spoken end-of-trip summary (#3504), spoken once when a recording finishes saving, behind the existing voice-coaching toggle. distanceKm is pre-formatted (e.g. '20.1'); consumption is a pre-formatted localized phrase (e.g. '7.1 litres per 100 kilometres'); harshCount is the summed harsh accel+brake count.
  ///
  /// In en, this message translates to:
  /// **'Trip saved: {distanceKm} kilometres, {consumption}. {harshCount, plural, =0{Nice and smooth — no harsh events.} =1{One harsh event.} other{{harshCount} harsh events.}}'**
  String coachingVoiceTripSummary(
    String distanceKm,
    String consumption,
    int harshCount,
  );

  /// TTS-friendly consumption phrase used inside coachingVoiceTripSummary (#3504) — spelled out so the speech engine does not have to read 'L/100km'. value is the pre-formatted number.
  ///
  /// In en, this message translates to:
  /// **'{value} litres per 100 kilometres'**
  String coachingVoiceConsumptionPhrase(String value);

  /// Title of the toggle (#2663) in the coaching settings section that turns spoken driving cues (hard acceleration, harsh braking, shift hints) on or off. On by default.
  ///
  /// In en, this message translates to:
  /// **'Spoken driving coaching'**
  String get voiceCoachingSettingTitle;

  /// Subtitle of the spoken-driving-coaching toggle (#2663) describing what the cues cover.
  ///
  /// In en, this message translates to:
  /// **'Hear spoken tips while you drive — hard acceleration, harsh braking and gear hints'**
  String get voiceCoachingSettingSubtitle;

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
  /// **'Set a price threshold for a station. You\'ll be notified when prices drop below it. Prices are checked periodically in the background — best effort, not in real time.'**
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

  /// No description provided for @iosAutoRecordOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay out of the app — but don\'t quit it.'**
  String get iosAutoRecordOnboardingTitle;

  /// No description provided for @iosAutoRecordOnboardingBullet1Title.
  ///
  /// In en, this message translates to:
  /// **'Open Sparkilo once after each reboot.'**
  String get iosAutoRecordOnboardingBullet1Title;

  /// No description provided for @iosAutoRecordOnboardingBullet1Body.
  ///
  /// In en, this message translates to:
  /// **'Apple wakes Sparkilo only after you\'ve opened it at least once since the phone restarted. After that, your trips record automatically.'**
  String get iosAutoRecordOnboardingBullet1Body;

  /// No description provided for @iosAutoRecordOnboardingBullet2Title.
  ///
  /// In en, this message translates to:
  /// **'Don\'t swipe Sparkilo away in the app switcher.'**
  String get iosAutoRecordOnboardingBullet2Title;

  /// No description provided for @iosAutoRecordOnboardingBullet2Body.
  ///
  /// In en, this message translates to:
  /// **'\"Force-quit\" tells iOS to stop relaunching the app. Your trips will stop recording until you open Sparkilo again.'**
  String get iosAutoRecordOnboardingBullet2Body;

  /// No description provided for @iosAutoRecordOnboardingBullet3Title.
  ///
  /// In en, this message translates to:
  /// **'When iOS asks for \"Always\" location, please say yes.'**
  String get iosAutoRecordOnboardingBullet3Title;

  /// No description provided for @iosAutoRecordOnboardingBullet3Body.
  ///
  /// In en, this message translates to:
  /// **'The fallback that records your trip when the OBD2 adapter is slow needs background location. We never share it.'**
  String get iosAutoRecordOnboardingBullet3Body;

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
  /// **'Your app works fully without cloud sync. TankSync lets you sync favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips across devices using Supabase (free tier available).'**
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

  /// No description provided for @syncSchemaOutdated.
  ///
  /// In en, this message translates to:
  /// **'Your TankSync schema is outdated — re-run the setup SQL below to enable the latest synced features.'**
  String get syncSchemaOutdated;

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
  /// **'Sparkilo Community'**
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

  /// No description provided for @serviceReminderDueNowBody.
  ///
  /// In en, this message translates to:
  /// **'{label} is due now.'**
  String serviceReminderDueNowBody(String label);

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

  /// Lightweight banner shown (#2565) when the OBD2 link drops mid-trip but GPS is still alive. Recording continues automatically from GPS, so there are no Resume/End actions — the app keeps capturing the trip while it tries to re-attach the dongle.
  ///
  /// In en, this message translates to:
  /// **'Recording with GPS — OBD2 reconnecting'**
  String get obd2GpsDegradedBannerTitle;

  /// Calmer variant of obd2GpsDegradedBannerTitle shown (#2767) once the reconnect scanner has exhausted its active-scan attempts and switched to a low-power passive wait for the adapter to power back up. The trip is still recording on GPS and the app still re-arms an active scan periodically, so the wording is reassuring ("waiting for") rather than urgent ("reconnecting").
  ///
  /// In en, this message translates to:
  /// **'Recording with GPS — waiting for the OBD2 adapter'**
  String get obd2GpsDegradedPassiveWaitingBanner;

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

  /// Header of the per-station price-alert section on the alerts screen, symmetric with the radius/zone section (#2819).
  ///
  /// In en, this message translates to:
  /// **'Station alerts'**
  String get alertsStationSectionTitle;

  /// Tooltip of the add button on the Station alerts section header; tapping it explains that station alerts are created from a station's detail page (#2819).
  ///
  /// In en, this message translates to:
  /// **'Add a station alert'**
  String get alertsStationAdd;

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

  /// Past-tense snackbar shown after a radius alert is deleted, paired with an Undo action that re-inserts it (#2494).
  ///
  /// In en, this message translates to:
  /// **'Radius alert \"{name}\" deleted'**
  String radiusAlertDeleted(String name);

  /// Tooltip on the title-bar OBD2 status chip (#797 phase 3) shown only when the pinned adapter is currently connected.
  ///
  /// In en, this message translates to:
  /// **'OBD2 connected: {adapterName}'**
  String obd2ConnectedTooltip(String adapterName);

  /// Tooltip on the title-bar OBD2 chip when no adapter is paired yet — tapping opens the adapter picker so pairing has a discoverable entry point (#1695).
  ///
  /// In en, this message translates to:
  /// **'Pair an OBD2 adapter'**
  String get obd2PairChipTooltip;

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

  /// Success snackbar confirming a fill-up was saved, shown after the Add fill-up screen pops back to the consumption list (#1692).
  ///
  /// In en, this message translates to:
  /// **'Fill-up saved'**
  String get fillUpSavedSnackbar;

  /// Title of the navigation entry on the favorites Alerts tab that opens the radius-alerts + statistics screen (#1701).
  ///
  /// In en, this message translates to:
  /// **'Radius alerts & statistics'**
  String get radiusAlertsEntryTitle;

  /// Subtitle of the radius-alerts navigation entry on the favorites Alerts tab — explains what radius alerts do (#1701).
  ///
  /// In en, this message translates to:
  /// **'Get notified when prices drop near you'**
  String get radiusAlertsEntrySubtitle;

  /// AppBar title of the go_router 404 / error screen shown when a route cannot be matched (#1690).
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// Body of the 404 / page-not-found screen, naming the unmatched route location (#1690).
  ///
  /// In en, this message translates to:
  /// **'\"{location}\" not found.'**
  String notFoundBody(String location);

  /// Button on the 404 screen that returns the user to the home route (#1690).
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get notFoundHomeButton;

  /// SnackBar shown when a profile change removes the Consumption tab at runtime and the bottom-nav selection jumps to Search — explains why the tab vanished (#1690).
  ///
  /// In en, this message translates to:
  /// **'The Consumption tab was hidden by your profile settings.'**
  String get consumptionTabHiddenNotice;

  /// One-time first-run SnackBar hint that the bottom-nav tabs respond to a horizontal swipe gesture (#1690).
  ///
  /// In en, this message translates to:
  /// **'Tip: swipe left or right to switch between tabs.'**
  String get swipeBetweenTabsHint;

  /// Title of the confirm dialog shown when the user leaves a form (fill-up, vehicle edit) with unsaved changes (#1693).
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// Body of the unsaved-changes confirm dialog (#1693).
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leaving now will discard them.'**
  String get discardChangesBody;

  /// Confirm action on the unsaved-changes dialog — leaves the form and discards the edits (#1693).
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChangesConfirm;

  /// Dismiss action on the unsaved-changes dialog — stays on the form (#1693).
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardChangesKeepEditing;

  /// Subtitle under the 'TankSync' settings section header — explains what the (brand-named) feature does so it isn't an unexplained label (#1696).
  ///
  /// In en, this message translates to:
  /// **'Cloud sync across your devices'**
  String get tankSyncSectionSubtitle;

  /// Error-state text shown when the inline map fails to load (#1661).
  ///
  /// In en, this message translates to:
  /// **'Map unavailable'**
  String get mapUnavailable;

  /// Hint text in the save-route name field — an example route (#1661).
  ///
  /// In en, this message translates to:
  /// **'e.g. Paris → Lyon'**
  String get routeNameHintExample;

  /// Label above the current fuel price in the price-stats card (#1662).
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get priceStatsCurrent;

  /// Field label in the fuel-prices API-key dialog; 'Tankerkoenig' is a brand (#1660).
  ///
  /// In en, this message translates to:
  /// **'Tankerkoenig API Key'**
  String get tankerkoenigApiKeyLabel;

  /// Field label in the EV-charging API-key dialog; 'OpenChargeMap' is a brand (#1660).
  ///
  /// In en, this message translates to:
  /// **'OpenChargeMap API Key'**
  String get openChargeMapApiKeyLabel;

  /// Tappable hint row in the profile location section (#1660).
  ///
  /// In en, this message translates to:
  /// **'Tap to update GPS position'**
  String get tapToUpdateGpsPosition;

  /// Generic 'Name' field label in the profile rename dialog (#1660).
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// User-facing OBD2 connection error: Bluetooth permission was denied (#1663).
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is required to connect to an OBD2 adapter.'**
  String get obd2ErrorPermissionDenied;

  /// User-facing OBD2 connection error: the Bluetooth radio is off (#1663).
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth and try again.'**
  String get obd2ErrorBluetoothOff;

  /// User-facing OBD2 connection error: scan found no adapter (#1663).
  ///
  /// In en, this message translates to:
  /// **'No OBD2 adapter found nearby. Make sure it is plugged in and powered on.'**
  String get obd2ErrorScanTimeout;

  /// User-facing OBD2 connection error: the adapter itself never answered the init sequence (#1663). Distinct from obd2ErrorEngineOff, where the adapter answered but the engine was off (#3009).
  ///
  /// In en, this message translates to:
  /// **'The OBD2 adapter did not respond. Check the connection and try again.'**
  String get obd2ErrorAdapterUnresponsive;

  /// User-facing OBD2 condition (#3009): the adapter connected and initialised fine, but the vehicle bus was silent (engine off / ECU asleep) so no live data could be read. Does NOT blame the adapter.
  ///
  /// In en, this message translates to:
  /// **'No data from the vehicle — start the engine and try again.'**
  String get obd2ErrorEngineOff;

  /// User-facing OBD2 connection error: the adapter's init string was unrecognised (#1663).
  ///
  /// In en, this message translates to:
  /// **'The OBD2 adapter sent an unrecognized response. It may be incompatible — try a different adapter.'**
  String get obd2ErrorProtocolInitFailed;

  /// User-facing OBD2 connection error: the transport dropped mid-session (#1663).
  ///
  /// In en, this message translates to:
  /// **'The OBD2 adapter disconnected. Reconnect and try again.'**
  String get obd2ErrorDisconnected;

  /// User-facing OBD2 connection error (#3181): BLE pairing was required but did not complete — the OBDLink CX family pairs on the first connection and only accepts new pairings in the first ~5 minutes after power-on, so the actionable fix is to power-cycle the adapter and retry promptly.
  ///
  /// In en, this message translates to:
  /// **'The adapter needs Bluetooth pairing. Unplug the adapter, plug it back in, then retry within 5 minutes.'**
  String get obd2ErrorPairingRequired;

  /// Onboarding API-key step — CTA to skip key entry and use demo data (#1691).
  ///
  /// In en, this message translates to:
  /// **'Explore with demo data'**
  String get onboardingExploreDemoData;

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

  /// Title of the background price-alert push notification: station name and fuel grade (#2306). Resolved in the main isolate at task-registration time and read back by the WorkManager isolate via Hive settings.
  ///
  /// In en, this message translates to:
  /// **'{station} - {fuelType}'**
  String priceAlertNotificationTitle(String station, String fuelType);

  /// Body of the background price-alert push notification: current price and the user's target, both with the local currency symbol (#2306).
  ///
  /// In en, this message translates to:
  /// **'{price} {currency} (target: {target} {currency})'**
  String priceAlertNotificationBody(
    String price,
    String currency,
    String target,
  );

  /// Title of the background velocity-drop notification fired when a fuel grade drops at several nearby stations at once (#2306, #579).
  ///
  /// In en, this message translates to:
  /// **'{fuelLabel} dropped at nearby stations'**
  String velocityAlertNotificationTitle(String fuelLabel);

  /// Body of the background velocity-drop notification: how many nearby stations dropped and by how much in the last hour (#2306, #579).
  ///
  /// In en, this message translates to:
  /// **'{count} stations dropped by up to {cents}¢ in the last hour'**
  String velocityAlertNotificationBody(String count, String cents);

  /// Title of the background grouped radius-alert notification: the user's alert label, how many stations are at or below the threshold, and the threshold price (#2306, #1012). Supersedes the single-station radiusAlertNotificationTitle for the grouped-fire path.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count} stations ≤ {threshold} {currency}'**
  String radiusAlertGroupedTitle(
    String label,
    String count,
    String threshold,
    String currency,
  );

  /// Trailing line in the background grouped radius-alert notification body when more matching stations exist than fit in the notification (#2306, #1012).
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String radiusAlertGroupedMore(String count);

  /// Footer line on the alerts screen showing when the background alert scan last completed (#3147), so the alert SLA is field-verifiable. {when} is a locale-formatted date + time.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {when}'**
  String alertsLastChecked(String when);

  /// Footer line on the alerts screen when no background alert scan has ever completed (#3147).
  ///
  /// In en, this message translates to:
  /// **'Prices haven\'t been checked in the background yet'**
  String get alertsLastCheckedNever;

  /// iOS-only honest disclosure on the alerts screen (#3169): background alert delivery on iPhone is OS-budgeted and best-effort — never promise Android-grade delivery. Mentions that opening the app always triggers a fresh check.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, alert checks are best effort: iOS decides when the app may check prices in the background, so an alert can arrive late or occasionally not at all. Opening the app always runs a fresh check.'**
  String get alertsIosBestEffortNote;

  /// Label of the target-price field in the create-alert dialog, parameterised with the station country's currency symbol now that background alerts fire for every country (#2865).
  ///
  /// In en, this message translates to:
  /// **'Target price ({currency})'**
  String alertTargetPriceWithCurrency(String currency);

  /// Label of the price-per-litre threshold field in the radius-alert create sheet, parameterised with the alert centre's country currency symbol (#2865).
  ///
  /// In en, this message translates to:
  /// **'Threshold ({currency}/L)'**
  String alertThresholdWithCurrency(String currency);

  /// Section title in the profile edit sheet for the in-trip Fuel Station Radar settings (#2067 / Epic #2065 / #2661).
  ///
  /// In en, this message translates to:
  /// **'Fuel Station Radar'**
  String get approachOverlaySection;

  /// Slider label for the Fuel Station Radar radius (km).
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get approachRadiusLabel;

  /// Caption under the approach-radius slider.
  ///
  /// In en, this message translates to:
  /// **'Radar leads with the price when within {km} km of a fuel station'**
  String approachRadiusCaption(String km);

  /// Title above the nearest/cheapest-in-radius choice chips.
  ///
  /// In en, this message translates to:
  /// **'Show price for'**
  String get approachPriceModeLabel;

  /// Choice chip — overlay shows the price at the single nearest station the driver crossed the radius of.
  ///
  /// In en, this message translates to:
  /// **'Nearest station'**
  String get approachPriceModeNearest;

  /// Choice chip — overlay shows the price at the cheapest station currently within the radius.
  ///
  /// In en, this message translates to:
  /// **'Cheapest in radius'**
  String get approachPriceModeCheapestInRadius;

  /// Slider label for the minimum poll interval (seconds) used by the approach detector.
  ///
  /// In en, this message translates to:
  /// **'Min refresh'**
  String get approachMinPollLabel;

  /// Caption under the min-poll slider.
  ///
  /// In en, this message translates to:
  /// **'Floor on how often the overlay refreshes the nearest station (faster at speed, never tighter than {seconds} s)'**
  String approachMinPollCaption(int seconds);

  /// Button on the trip-recording screen that pushes a synthetic ApproachInRadius into the PiP for 30 s so the user can verify the price layout without driving (#2163).
  ///
  /// In en, this message translates to:
  /// **'Test Fuel Station Radar'**
  String get approachTestSimulateButton;

  /// Button that aborts the in-app Fuel Station Radar simulation (#2163).
  ///
  /// In en, this message translates to:
  /// **'Stop test'**
  String get approachTestStopButton;

  /// Caption shown under the test button while a simulated approach is running (#2163).
  ///
  /// In en, this message translates to:
  /// **'Test active — radar shows the price for {station}'**
  String approachTestActiveCaption(String station);

  /// Caption shown when the test button is disabled because no favorite station is available as a target (#2163).
  ///
  /// In en, this message translates to:
  /// **'Add a favorite station to test the Fuel Station Radar'**
  String get approachTestUnavailable;

  /// PiP overlay caption (#2084) showing how far the driver is from the in-radius target station, in metres.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String approachStationDistance(String meters);

  /// Fuel Station Radar caption (#2661) showing how far the driver is from the radar station while still approaching, in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String fuelStationRadarDistanceKm(String km);

  /// Accessibility label for the battery-style proximity fill bar (#2661): how close the driver is to the radar station, as a percentage (100% at the station, 0% at the radar radius edge).
  ///
  /// In en, this message translates to:
  /// **'Proximity {percent}%'**
  String fuelStationRadarProximity(int percent);

  /// Tooltip + accessibility label on the floating Picture-in-Picture tile body (#2964): tapping the little window brings the full Sparkilo app back to the foreground / full screen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open the full app'**
  String get pipTapToRestore;

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

  /// Auth card heading shown to an anonymous user — framing the primary action as attaching an email to their CURRENT account (keeping their data) rather than creating a separate new account (#3079).
  ///
  /// In en, this message translates to:
  /// **'Link an email'**
  String get authLinkEmailTitle;

  /// Auth card body for an anonymous user — reassures that linking an email upgrades the current anonymous identity in place, so existing favorites/trips are preserved and become reachable on other devices (#3079).
  ///
  /// In en, this message translates to:
  /// **'Link an email so your data syncs across devices. Your current favorites and trips stay on this account.'**
  String get authLinkEmailSubtitle;

  /// Status text for a connected anonymous (guest) user, prompting them to attach an email for cross-device sync (#3079).
  ///
  /// In en, this message translates to:
  /// **'You\'re using a guest account ({idPrefix}…). Link an email so your favorites and trips sync to your other devices.'**
  String authGuestLinkPrompt(String idPrefix);

  /// Shown after an anonymous account is upgraded to email when the server requires email confirmation: the email change is pending the confirmation link, but the user's UUID and data are already safe (#3079).
  ///
  /// In en, this message translates to:
  /// **'Almost there — check your email and click the link to finish linking it. Your data is already saved on this account.'**
  String get authConfirmationPending;

  /// Scope-explicit label for the background-location consent badge on the auto-record card (#1439). Replaces the ambiguous pre-#1439 label that read as a profile-wide grant; clarifies that the consent is consumed exclusively by the auto-record service.
  ///
  /// In en, this message translates to:
  /// **'Background location — for auto-record only'**
  String get autoRecordConsentBadgeLabel;

  /// Title of the explanation dialog opened by the help icon next to the auto-record consent badge (#1439).
  ///
  /// In en, this message translates to:
  /// **'About this permission'**
  String get autoRecordConsentExplanationTitle;

  /// Body copy of the explanation dialog clarifying that the background-location grant is scoped to auto-record and does not affect search or map features (#1439).
  ///
  /// In en, this message translates to:
  /// **'Auto-record needs background location to detect when you start driving while the app is closed. This grant is used only by auto-record — station search and map centering use a separate foreground location grant.'**
  String get autoRecordConsentExplanationBody;

  /// Dismiss button for the auto-record consent explanation dialog (#1439).
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get autoRecordConsentExplanationCloseButton;

  /// Tooltip on the help icon next to the auto-record consent badge (#1439); accessibility hint that tells the user the icon opens an explanation dialog.
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get autoRecordConsentExplanationTooltip;

  /// Accessibility hint and visual subline on the auto-record consent badge indicating that tapping it opens the OS app-info screen so the user can revoke the grant (#1439).
  ///
  /// In en, this message translates to:
  /// **'Tap to manage in system settings'**
  String get autoRecordConsentRevokeAction;

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

  /// Passive informational link rendered on the auto-record card when no adapter is paired (#1400). Replaces the duplicate orange-tinted 'Pair an adapter' CTA that lived in the auto-record card before #1400; tapping the link scrolls to the canonical 'OBD2 adapter' card below and pulses its border.
  ///
  /// In en, this message translates to:
  /// **'Pair an adapter in the section below to enable auto-recording'**
  String get autoRecordPairAdapterLinkText;

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

  /// Label in the indeterminate progress dialog shown while the full backup zips and writes to Downloads (#2815).
  ///
  /// In en, this message translates to:
  /// **'Exporting your backup…'**
  String get backupExportProgress;

  /// Success SnackBar after a backup export, naming the file the user will find in the Downloads folder / the restore picker (#2815).
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads as {fileName}'**
  String exportBackupSavedAs(String fileName);

  /// AppBar IconButton tooltip on the consumption screen for the full-backup RESTORE flow (#2571).
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackupTooltip;

  /// Title of the merge-vs-replace confirmation dialog shown after a backup .zip is picked (#2571).
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackupDialogTitle;

  /// Body of the restore confirmation dialog explaining the difference between Merge and Replace, with a data-loss warning on Replace (#2571).
  ///
  /// In en, this message translates to:
  /// **'Merge adds and updates records from the backup and keeps everything already on this device. Replace deletes all current data first, then restores only the backup — this cannot be undone.'**
  String get restoreBackupDialogBody;

  /// Primary (safe) action button in the restore dialog: add/update by id, keep existing data (#2571).
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get restoreBackupMergeAction;

  /// Destructive action button in the restore dialog: wipe all current data then restore only the backup (#2571).
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get restoreBackupReplaceAction;

  /// Success SnackBar after a restore completes with at least one record (#2571).
  ///
  /// In en, this message translates to:
  /// **'Backup restored — {count} records imported'**
  String restoreBackupSuccess(int count);

  /// Success SnackBar when the restored backup parsed correctly but held zero records (#2571).
  ///
  /// In en, this message translates to:
  /// **'Backup restored — it contained no records'**
  String get restoreBackupEmpty;

  /// Error SnackBar when the chosen file is not a readable backup zip, is malformed XML, or has an unsupported schema version (#2571).
  ///
  /// In en, this message translates to:
  /// **'Restore failed — this file is not a valid Tankstellen backup'**
  String get restoreBackupCorrupt;

  /// Generic error SnackBar when the restore flow throws an unexpected error or the file could not be read (#2571).
  ///
  /// In en, this message translates to:
  /// **'Restore failed — the file could not be read'**
  String get restoreBackupFailed;

  /// Label in the indeterminate progress dialog shown while a backup zip decodes, parses, and writes its records (#2815).
  ///
  /// In en, this message translates to:
  /// **'Restoring your backup…'**
  String get backupImportProgress;

  /// Success SnackBar after a MERGE restore, breaking down what was added/updated per category (#2815).
  ///
  /// In en, this message translates to:
  /// **'Merged {vehicles} vehicles, {fillUps} fill-ups, {trips} trips, {chargingLogs} charging logs'**
  String restoreBackupMergedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  );

  /// Success SnackBar after a REPLACE-all restore, breaking down what now exists per category (#2815).
  ///
  /// In en, this message translates to:
  /// **'Replaced all data with {vehicles} vehicles, {fillUps} fill-ups, {trips} trips, {chargingLogs} charging logs'**
  String restoreBackupReplacedSummary(
    int vehicles,
    int fillUps,
    int trips,
    int chargingLogs,
  );

  /// Diagnostic-overlay chip shown while the broken-MAP belief is in the 0.4–0.7 confidence band — the app is still gathering observations and not yet ready to warn the user (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor verifying…'**
  String get brokenMapChipVerifying;

  /// Small chip displayed alongside the live fuel-rate metric while the broken-MAP belief sits in the 0.7–0.9 confidence band — the rate continues to be shown but the user is told it may be unreliable (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP readings suspicious'**
  String get brokenMapChipDisclaimer;

  /// Snackbar fired once per session per vehicle when the broken-MAP belief crosses 0.7. Tells the user the live fuel-rate numbers are likely undercounting heavily and suggests trying a different OBD2 adapter (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor reads incorrectly — fuel readings may be 50–80% too low. Try a different adapter.'**
  String get brokenMapSnackbarUnreliable;

  /// Persistent MaterialBanner shown at the top of the trip-recording screen when the broken-MAP belief is at or above 0.9 — the live fuel-rate display is hard-disabled and the app falls back to per-fill L/100km from receipts (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor unreliable. Showing fill-up averages instead of live fuel rate.'**
  String get brokenMapBannerHardDisable;

  /// Diagnostic-overlay row shown in the OBD2 breadcrumb panel when the broken-MAP belief sits below 0.4 — the sensor has been observed and looks healthy (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor: verified ({confidence})'**
  String brokenMapOverlayVerified(String confidence);

  /// Diagnostic-overlay row shown in the OBD2 breadcrumb panel when the broken-MAP belief sits in 0.4–0.7 — the app is still building confidence (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor: verifying ({confidence})'**
  String brokenMapOverlayUnverified(String confidence);

  /// Diagnostic-overlay row shown in the OBD2 breadcrumb panel when the broken-MAP belief sits at or above 0.7 — strong evidence the MAP sensor is broken (#1423 phase 5).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor: suspicious ({confidence})'**
  String brokenMapOverlaySuspicious(String confidence);

  /// Diagnostic-overlay row showing the Bayesian posterior point estimate and the half-width of the 95% credible interval for the broken-MAP belief (#1424 deliverable G).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor: {posterior}% ± {margin}%'**
  String brokenMapOverlayPosterior(String posterior, String margin);

  /// Diagnostic-overlay row variant when the auto-clear gate has fired (#1424 deliverable D) — appends a (verified) badge to the posterior + credible-interval row. Shown only when isVerifiedClean is true (50+ observations, mean<0.1, upper-CI<0.3).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor: {posterior}% ± {margin}% (verified)'**
  String brokenMapOverlayPosteriorVerified(String posterior, String margin);

  /// Title of the broken-MAP diagnostics card on the vehicle settings screen — surfaces the belief + the adapter blocklist (#1622).
  ///
  /// In en, this message translates to:
  /// **'MAP sensor diagnostics'**
  String get brokenMapDiagnosticsCardTitle;

  /// Line on the broken-MAP diagnostics card showing the active vehicle's Bayesian posterior point estimate and the half-width of the 95% credible interval (#1622).
  ///
  /// In en, this message translates to:
  /// **'Broken-MAP confidence: {posterior}% ± {margin}%'**
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin);

  /// Line on the broken-MAP diagnostics card showing how many observations have been folded into the belief (#1622).
  ///
  /// In en, this message translates to:
  /// **'{count} observations recorded'**
  String brokenMapDiagnosticsObservationCount(int count);

  /// Badge on the broken-MAP diagnostics card shown when the belief has reached the verified-clean terminal state (#1622).
  ///
  /// In en, this message translates to:
  /// **'Verified clean'**
  String get brokenMapDiagnosticsVerifiedBadge;

  /// Placeholder on the broken-MAP diagnostics card when the active vehicle has no broken-MAP observations recorded yet (#1622).
  ///
  /// In en, this message translates to:
  /// **'This vehicle\'s MAP sensor hasn\'t been observed yet.'**
  String get brokenMapDiagnosticsBeliefNone;

  /// Sub-heading on the broken-MAP diagnostics card above the list of OBD2 adapters flagged as having a broken MAP sensor (#1622).
  ///
  /// In en, this message translates to:
  /// **'Blocklisted adapters'**
  String get brokenMapDiagnosticsBlocklistHeading;

  /// Empty-state line on the broken-MAP diagnostics card when no OBD2 adapter is on the broken-MAP blocklist (#1622).
  ///
  /// In en, this message translates to:
  /// **'No adapters are blocklisted.'**
  String get brokenMapDiagnosticsBlocklistEmpty;

  /// A single blocklisted-adapter row on the broken-MAP diagnostics card: the adapter's ELM firmware id and its recorded broken-confidence (#1622).
  ///
  /// In en, this message translates to:
  /// **'{adapter} — flagged {percent}% broken'**
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent);

  /// Button on a blocklisted-adapter row that removes the adapter from the broken-MAP blocklist — the manual escape hatch for a healthy adapter that was mis-flagged (#1622).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get brokenMapDiagnosticsClearButton;

  /// Title of the diesel rev prompt shown during a broken-MAP probe — asks the user to blip the throttle so the detector reads the MAP delta off a confirmed rev instead of a blind fixed delay (#1621).
  ///
  /// In en, this message translates to:
  /// **'Rev the engine'**
  String get brokenMapRevPromptTitle;

  /// Body text of the diesel rev prompt — instructs the user to give a short throttle blip during the broken-MAP detection window (#1621).
  ///
  /// In en, this message translates to:
  /// **'Briefly blip the throttle so the app can check the MAP sensor responds.'**
  String get brokenMapRevPromptBody;

  /// Confirmation button on the diesel rev prompt — the user taps it once they have blipped the throttle so the probe takes the rev MAP read (#1621).
  ///
  /// In en, this message translates to:
  /// **'Done — I revved'**
  String get brokenMapRevPromptConfirm;

  /// ExpansionTile title for the user-overridable calibration constants section on the edit-vehicle screen (#1397).
  ///
  /// In en, this message translates to:
  /// **'Advanced calibration'**
  String get calibrationAdvancedTitle;

  /// TextFormField label for the manual displacement override in cubic centimetres.
  ///
  /// In en, this message translates to:
  /// **'Engine displacement (cc)'**
  String get calibrationDisplacementLabel;

  /// TextFormField label for the manual volumetric efficiency override (0.50–1.00).
  ///
  /// In en, this message translates to:
  /// **'Volumetric efficiency (η_v)'**
  String get calibrationVolumetricEfficiencyLabel;

  /// TextFormField label for the manual AFR override in kg/kg (~14.7 petrol / ~14.5 diesel).
  ///
  /// In en, this message translates to:
  /// **'Air-to-fuel ratio (AFR)'**
  String get calibrationAfrLabel;

  /// TextFormField label for the manual fuel density override in g/L (~740 petrol / ~832 diesel).
  ///
  /// In en, this message translates to:
  /// **'Fuel density (g/L)'**
  String get calibrationFuelDensityLabel;

  /// Helper text shown beneath a calibration field when its current value comes from a VIN decode.
  ///
  /// In en, this message translates to:
  /// **'(detected from VIN)'**
  String get calibrationSourceDetected;

  /// Helper text shown when the current value comes from the reference-vehicle catalog row.
  ///
  /// In en, this message translates to:
  /// **'(catalog: {makeModel})'**
  String calibrationSourceCatalog(String makeModel);

  /// Helper text shown when the current value is the generic estimator fallback constant.
  ///
  /// In en, this message translates to:
  /// **'(default)'**
  String get calibrationSourceDefault;

  /// Helper text shown when the current value is a user-entered override.
  ///
  /// In en, this message translates to:
  /// **'(manual)'**
  String get calibrationSourceManual;

  /// Tooltip / a11y label for the per-field reset IconButton that nulls a manual override.
  ///
  /// In en, this message translates to:
  /// **'Reset to detected value'**
  String get calibrationResetToDetected;

  /// Live readout when the learner has accepted at least 3 plein-complet samples.
  ///
  /// In en, this message translates to:
  /// **'η_v: {eta} (calibrated, {samples} samples)'**
  String calibrationLearnerStatusCalibrated(String eta, int samples);

  /// Live readout while the learner is bootstrapping (1-2 samples).
  ///
  /// In en, this message translates to:
  /// **'η_v: {eta} (learning, {samples} samples)'**
  String calibrationLearnerStatusLearning(String eta, int samples);

  /// Live readout before the first plein-complet has been logged.
  ///
  /// In en, this message translates to:
  /// **'η_v: 0.85 (default — no plein-complet yet)'**
  String get calibrationLearnerStatusNoSamples;

  /// #2112 — compact engineer-detail pill that rides alongside the confidence-tier badge on the Fuel tab. Replaces the longer 'learning' / 'calibrated' parenthetical labels — the maturity colour is carried by the confidence tier next to it.
  ///
  /// In en, this message translates to:
  /// **'η_v: {eta} · {samples} samples'**
  String calibrationLearnerEtaCompact(String eta, int samples);

  /// OutlinedButton label that resets η_v back to 0.85 and clears the sample counter.
  ///
  /// In en, this message translates to:
  /// **'Reset learner'**
  String get calibrationResetLearner;

  /// Engine-tech basis label for η_v (#1422 phase 2). Shown inside the catalog origin tag when the reference vehicle is an Atkinson-cycle hybrid (Toyota Hybrid, Mazda Skyactiv-X).
  ///
  /// In en, this message translates to:
  /// **'Atkinson cycle'**
  String get calibrationBasisAtkinson;

  /// Engine-tech basis label for η_v. VNT = variable-geometry turbocharger; DI = direct injection. Common on modern diesels (Renault/Dacia dCi, etc.).
  ///
  /// In en, this message translates to:
  /// **'VNT diesel + DI'**
  String get calibrationBasisVnt;

  /// Engine-tech basis label for η_v. Petrol / diesel turbo with direct injection (VW TSI, Audi TFSI, BlueHDi, etc.).
  ///
  /// In en, this message translates to:
  /// **'Turbocharged + DI'**
  String get calibrationBasisTurboDi;

  /// Engine-tech basis label for η_v. Turbocharged with port injection (older turbo petrol).
  ///
  /// In en, this message translates to:
  /// **'Turbocharged'**
  String get calibrationBasisTurbo;

  /// Engine-tech basis label for η_v. Naturally aspirated petrol with direct injection (some Toyota / Mazda petrol).
  ///
  /// In en, this message translates to:
  /// **'Naturally aspirated + DI'**
  String get calibrationBasisNaDi;

  /// Helper text shown beneath the η_v field when value comes from the catalog AND the engine-tech basis is known (#1422 phase 2). Replaces the plain `calibrationSourceCatalog` for this field only.
  ///
  /// In en, this message translates to:
  /// **'(catalog: {makeModel} — {basis} default)'**
  String calibrationSourceCatalogWithBasis(String makeModel, String basis);

  /// Replaces the editable volumetric-efficiency field + its learner readout on the Advanced calibration card when the vehicle reports fuel rate directly via PID 5E / MAF, making the η_v calibration irrelevant (#2837).
  ///
  /// In en, this message translates to:
  /// **'This vehicle reports its fuel rate directly (PID 5E), so volumetric-efficiency calibration is not used — your consumption is measured, not modelled.'**
  String get calibrationDirectFuelRateNote;

  /// One-time snackbar (#1396) shown when a diesel-marked vehicle profile resolves to a non-diesel reference catalog row. The placeholder is the make + model, e.g. 'Dacia Duster'.
  ///
  /// In en, this message translates to:
  /// **'Your {makeModel} is marked as diesel but matches a petrol catalog entry. Tap to update.'**
  String catalogReresolveSnackbarMessage(String makeModel);

  /// Action button on the #1396 catalog re-resolve snackbar — taps push the vehicle edit screen so the user can re-pick their catalog row.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get catalogReresolveSnackbarAction;

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

  /// No description provided for @consoFeatureGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get consoFeatureGroupTitle;

  /// No description provided for @consoFeatureGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your consumption — manual fill-ups, or automatic OBD2 trip recording.'**
  String get consoFeatureGroupDescription;

  /// No description provided for @consoModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get consoModeOff;

  /// No description provided for @consoModeFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get consoModeFuel;

  /// No description provided for @consoModeFuelAndTrips.
  ///
  /// In en, this message translates to:
  /// **'Fuel + Trips'**
  String get consoModeFuelAndTrips;

  /// No description provided for @consoModeOffDescription.
  ///
  /// In en, this message translates to:
  /// **'No Conso tab and no Conso settings section.'**
  String get consoModeOffDescription;

  /// No description provided for @consoModeFuelDescription.
  ///
  /// In en, this message translates to:
  /// **'Manual fill-ups only. Useful without an OBD2 adapter.'**
  String get consoModeFuelDescription;

  /// No description provided for @consoModeFuelAndTripsDescription.
  ///
  /// In en, this message translates to:
  /// **'Adds automatic OBD2 trip recording. Requires a paired adapter.'**
  String get consoModeFuelAndTripsDescription;

  /// No description provided for @consoGroupVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get consoGroupVehicles;

  /// No description provided for @consoGroupCoaching.
  ///
  /// In en, this message translates to:
  /// **'Coaching while driving'**
  String get consoGroupCoaching;

  /// No description provided for @consoGroupRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards & savings'**
  String get consoGroupRewards;

  /// No description provided for @consoGroupTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get consoGroupTroubleshooting;

  /// #2262 — plain-language accuracy indicator on the consumption stats card, replacing the back-to-front A/B/C confidence letters. `level` is one of the localized High/Medium/Low words; `band` is the language-neutral expected-error mask (e.g. ±3-7%).
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {level} · {band}'**
  String consumptionAccuracyLabel(String level, String band);

  /// #2262 — accuracy word for the fully-calibrated tier (fill-ups + OBD2 trips). Highest trust.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get consumptionAccuracyHigh;

  /// #2262 — accuracy word for the fill-ups-anchored-but-no-OBD2-trip tier.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get consumptionAccuracyMedium;

  /// #2262 — accuracy word for the GPS-only, no-fill-ups tier. Lowest trust.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get consumptionAccuracyLow;

  /// #2262 — tooltip for the High accuracy indicator. No improvement action needed.
  ///
  /// In en, this message translates to:
  /// **'Full calibration: fill-ups plus OBD2-recorded trips. The L/100 km figure tracks reality to within a few percent.'**
  String get consumptionAccuracyTooltipHigh;

  /// #2262 — tooltip for the Medium accuracy indicator. Tells the user to record an OBD2 trip to improve.
  ///
  /// In en, this message translates to:
  /// **'Fill-ups have anchored the consumption model, but no OBD2 trip has fed the loop yet. Record one with OBD2 connected to reach High accuracy.'**
  String get consumptionAccuracyTooltipMedium;

  /// #2262 — tooltip for the Low accuracy indicator. Tells the user to add full fill-ups to improve.
  ///
  /// In en, this message translates to:
  /// **'GPS-only — no fill-ups have anchored the consumption model yet. Add a couple of full fill-ups to improve the accuracy.'**
  String get consumptionAccuracyTooltipLow;

  /// Tooltip on the consumption app-bar overflow (kebab) menu button that holds the secondary actions — export/restore backup, the gated carbon dashboard and Settings (#2756).
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActionsTooltip;

  /// Overflow-menu item label on the consumption app bar that runs the full XML-in-ZIP backup export (#2756).
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackupMenuLabel;

  /// Overflow-menu item label on the consumption app bar that opens the backup-restore flow — pick a .zip, confirm merge/replace, import (#2756).
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackupMenuLabel;

  /// Overflow-menu item label on the consumption app bar that opens the carbon dashboard. Only shown when Feature.carbonDashboard is enabled (#2756).
  ///
  /// In en, this message translates to:
  /// **'Carbon dashboard'**
  String get carbonDashboardMenuLabel;

  /// Overflow-menu item label on the consumption app bar that opens the app-global Settings screen. Sits below a divider, separated from the consumption-specific items above (#2756).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsMenuLabel;

  /// App-bar title of the full consumption-statistics detail page opened from the Fuel tab's summary card (#2698).
  ///
  /// In en, this message translates to:
  /// **'Consumption statistics'**
  String get consumptionStatsPageTitle;

  /// Section title of the month-over-month comparison card on the consumption-statistics page (#2698).
  ///
  /// In en, this message translates to:
  /// **'This month vs last month'**
  String get consumptionStatsComparisonTitle;

  /// Section title above the per-metric monthly evolution bar charts on the consumption-statistics page (#2698).
  ///
  /// In en, this message translates to:
  /// **'Evolution over time'**
  String get consumptionStatsTrendsTitle;

  /// Caption shown on the consumption-statistics comparison card when fewer than two calendar months of fill-up data exist, so no previous-month column can be shown (#2698).
  ///
  /// In en, this message translates to:
  /// **'Log fill-ups across at least two months to compare.'**
  String get consumptionStatsNeedTwoMonths;

  /// Label for the average price-per-litre metric (current month spend divided by litres) on the consumption-statistics page (#2698).
  ///
  /// In en, this message translates to:
  /// **'Avg price/L'**
  String get consumptionStatsPricePerLiter;

  /// Percentage change of a metric versus the previous month, shown next to the absolute delta on the comparison card (#2698). The sign is included in the value.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String consumptionStatsDeltaPercent(String pct);

  /// Title of the monthly litres evolution bar chart on the consumption-statistics page (#2698).
  ///
  /// In en, this message translates to:
  /// **'Litres per month'**
  String get consumptionStatsChartLiters;

  /// Title of the monthly spend evolution bar chart on the consumption-statistics page (#2698).
  ///
  /// In en, this message translates to:
  /// **'Spend per month'**
  String get consumptionStatsChartSpend;

  /// Title of the monthly average price-per-litre evolution bar chart on the consumption-statistics page (#2698).
  ///
  /// In en, this message translates to:
  /// **'Price per litre'**
  String get consumptionStatsChartPricePerLiter;

  /// Title of the monthly average L/100km evolution bar chart on the consumption-statistics page; months without a closed plein-to-plein window are skipped (#2698).
  ///
  /// In en, this message translates to:
  /// **'L/100km per month'**
  String get consumptionStatsChartConsumption;

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

  /// Transparent line on the consumption stats card showing how many correction litres were added across closed windows, kept separate from the headline Total L which reflects only real pumped fuel (#2446).
  ///
  /// In en, this message translates to:
  /// **'Corrections: +{liters} L'**
  String statCorrectionLiters(String liters);

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
  /// **'Powered by monitorulpreturilor.info (Competition Council + ANPC)'**
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

  /// Accessibility label and tooltip for the tappable country-service header on the search screen, which opens the active country's upstream fuel-price data source in the browser (#2373). Relocates the open-data attribution from the old bottom footer into the link, so the provider name and licence stay available to screen-reader and long-press users (CC BY / Licence Ouverte / OGL / IODL all mandate visible attribution). {source} and {license} are data — proper-noun provider + licence names rendered verbatim from the country's FuelServicePolicy.
  ///
  /// In en, this message translates to:
  /// **'Open the {source} data source ({license}) in your browser'**
  String dataSourceLinkSemantic(String source, String license);

  /// Map-tile attribution shown on every OpenStreetMap-tiled map (the flutter_map RichAttributionWidget on the station/driving/trip/radius-picker maps and the about screen's data-source list). OSM's tile-usage policy mandates the visible '© OpenStreetMap contributors' credit. Only the surrounding structural wording ('© … contributors') is translatable; {brand} is the proper-noun 'OpenStreetMap', passed verbatim from the call site (kept literal there under an i18n-ignore brand exemption) so it can never be mistranslated. Keep the leading © and the {brand} token in every translation (#2402).
  ///
  /// In en, this message translates to:
  /// **'© {brand} contributors'**
  String mapAttributionOsm(String brand);

  /// Title of the Settings section / screen hosting dev-only diagnostics, shown only when Developer / Debug mode is on (#2248).
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get developerToolsSectionTitle;

  /// Label for the Developer-tools action that exports the recorded network-vs-cache data-access trace (cache-hit ratio + per-provider request intervals) as JSON to Downloads (#2824).
  ///
  /// In en, this message translates to:
  /// **'Export data-access trace'**
  String get dataAccessTracerExport;

  /// Confirmation snackbar after the data-access trace JSON was written to the Downloads folder (#2824).
  ///
  /// In en, this message translates to:
  /// **'Data-access trace saved to Downloads.'**
  String get dataAccessTracerExportSuccess;

  /// Snackbar shown when writing the data-access trace JSON to Downloads failed (#2824).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the data-access trace.'**
  String get dataAccessTracerExportFailure;

  /// Snackbar shown when the data-access tracer export is tapped but nothing has been recorded yet (tracer off or no queries made) (#2824).
  ///
  /// In en, this message translates to:
  /// **'No data-access events recorded yet — search or open stations first, then export.'**
  String get dataAccessTracerEmpty;

  /// One-line subtitle under the Developer tools section explaining it is gated on Developer / Debug mode (#2248).
  ///
  /// In en, this message translates to:
  /// **'Diagnostics and tools for debugging — only visible in Developer / Debug mode.'**
  String get developerToolsSubtitle;

  /// Subtitle on the Settings menu tile that opens the Developer tools screen (#2248).
  ///
  /// In en, this message translates to:
  /// **'Error log, test alerts, diagnostics'**
  String get developerToolsMenuSubtitle;

  /// Group header above the error-log export / clear actions in the Developer tools screen (#2248).
  ///
  /// In en, this message translates to:
  /// **'Error log'**
  String get developerToolsErrorLogGroupTitle;

  /// Label for the action that exports the buffered error log. {count} is the number of buffered traces (#2248).
  ///
  /// In en, this message translates to:
  /// **'Save error log ({count})'**
  String developerToolsExportErrorLog(int count);

  /// Tooltip / label for the action that clears the buffered error log in the Developer tools screen (#2248).
  ///
  /// In en, this message translates to:
  /// **'Clear error log'**
  String get developerToolsClearErrorLog;

  /// Label for the action that opens a raw, in-app viewer of the buffered error traces (#2248).
  ///
  /// In en, this message translates to:
  /// **'View error log'**
  String get developerToolsViewErrorLog;

  /// Empty-state text shown in the raw error-log viewer when no traces are buffered (#2248).
  ///
  /// In en, this message translates to:
  /// **'No error traces recorded.'**
  String get developerToolsErrorLogEmpty;

  /// Group header above the test-notification / test-alert actions in the Developer tools screen (#2248).
  ///
  /// In en, this message translates to:
  /// **'Alerts & notifications'**
  String get developerToolsAlertsGroupTitle;

  /// Label for the action that posts a test notification through NotificationService to verify the permission, channel and delivery (#2248).
  ///
  /// In en, this message translates to:
  /// **'Fire test notification'**
  String get developerToolsFireTestNotification;

  /// Title of the test notification fired by the Developer tools 'Fire test notification' action (#2248).
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get developerToolsTestNotificationTitle;

  /// Body of the test notification fired by the Developer tools 'Fire test notification' action (#2248).
  ///
  /// In en, this message translates to:
  /// **'If you can read this, notifications are working.'**
  String get developerToolsTestNotificationBody;

  /// Confirmation snackbar after the test notification is posted (#2248).
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get developerToolsTestNotificationSent;

  /// Snackbar shown when the OS notification permission is denied so the test notification cannot be delivered (#2248).
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked — enable them in system settings, then retry.'**
  String get developerToolsTestNotificationBlocked;

  /// Label for the action that runs the radius-alert evaluation pipeline end-to-end against a synthetic in-range match (#2248).
  ///
  /// In en, this message translates to:
  /// **'Run test alert pipeline'**
  String get developerToolsRunTestAlert;

  /// Confirmation snackbar after the synthetic test-alert pipeline run, with the number of notifications it produced (#2248).
  ///
  /// In en, this message translates to:
  /// **'Test alert fired — pipeline delivered {count} notification(s).'**
  String developerToolsTestAlertFired(int count);

  /// Notification title produced by the synthetic test-alert pipeline run (#2248).
  ///
  /// In en, this message translates to:
  /// **'Test price alert'**
  String get developerToolsTestAlertTitle;

  /// Notification body produced by the test-alert pipeline run, naming the real station the synthetic alert fired against (#2248, #2408).
  ///
  /// In en, this message translates to:
  /// **'Synthetic match: {station} is below your target.'**
  String developerToolsTestAlertBody(String station);

  /// Snackbar shown when the test-alert action is tapped but there is no station in the current search results to fire against, so the notification would deep-link to a non-resolving station (#2408).
  ///
  /// In en, this message translates to:
  /// **'Search for stations first, then run the test alert so the notification can open a real station.'**
  String get developerToolsTestAlertNoStation;

  /// Group header above the feature-flag dump / clear-caches / copy-diagnostics actions in the Developer tools screen (#2248).
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get developerToolsDiagnosticsGroupTitle;

  /// Label for the action that opens a dump of every Feature flag and its current enabled/disabled state (#2248).
  ///
  /// In en, this message translates to:
  /// **'Feature flag inspector'**
  String get developerToolsFeatureFlagDump;

  /// Trailing label shown next to an enabled feature flag in the feature-flag inspector (#2248).
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get developerToolsFlagOn;

  /// Trailing label shown next to a disabled feature flag in the feature-flag inspector (#2248).
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get developerToolsFlagOff;

  /// Label for the action that clears the station / price-history cache without deleting user data (#2248).
  ///
  /// In en, this message translates to:
  /// **'Clear caches'**
  String get developerToolsClearCaches;

  /// Confirmation snackbar after the clear-caches action completes (#2248).
  ///
  /// In en, this message translates to:
  /// **'Caches cleared.'**
  String get developerToolsCachesCleared;

  /// Label for the action that copies a build / device / flag diagnostics blob to the clipboard (#2248).
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get developerToolsCopyDiagnostics;

  /// Confirmation snackbar after the copy-diagnostics action copies the blob to the clipboard (#2248).
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied to clipboard.'**
  String get developerToolsDiagnosticsCopied;

  /// Group header above the read-only app version / channel build-info rows in the Developer tools screen (#2248).
  ///
  /// In en, this message translates to:
  /// **'Build info'**
  String get developerToolsBuildInfoGroupTitle;

  /// Row label for the running app version in the Developer tools build-info group (#2248).
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get developerToolsBuildVersion;

  /// Row label for the active build channel in the Developer tools build-info group (#2248).
  ///
  /// In en, this message translates to:
  /// **'Build channel'**
  String get developerToolsBuildChannel;

  /// Section header for the startup-initialization trace panel in Developer tools (#3383).
  ///
  /// In en, this message translates to:
  /// **'Startup initialization trace'**
  String get startupTraceSectionTitle;

  /// Button that exports the startup-initialization trace as a JSON file to Downloads (#3383).
  ///
  /// In en, this message translates to:
  /// **'Export startup trace'**
  String get startupTraceExportButton;

  /// Shown in the startup-trace panel when no startup milestones were captured this session (#3383).
  ///
  /// In en, this message translates to:
  /// **'No startup trace recorded yet.'**
  String get startupTraceEmpty;

  /// Total cold-start duration line above the startup-trace waterfall (#3383).
  ///
  /// In en, this message translates to:
  /// **'Total: {ms} ms'**
  String startupTraceTotalMs(int ms);

  /// A single phase's duration in milliseconds in the startup-trace waterfall (#3383).
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String startupTraceMs(int ms);

  /// Confirmation snackbar after the startup trace is exported to Downloads (#3383).
  ///
  /// In en, this message translates to:
  /// **'Startup trace saved to Downloads.'**
  String get startupTraceExportSuccess;

  /// Error snackbar when the startup-trace export to Downloads fails (#3383).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the startup trace.'**
  String get startupTraceExportFailure;

  /// Distance-provenance badge label (#3253) on the trip detail's Distance row — the km figure came from the car's own odometer PID delta (ground truth, #800).
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get distanceSourceOdometer;

  /// Tooltip for the 'Odometer' distance-provenance badge (#3253): explains the km is a real odometer delta, not an estimate.
  ///
  /// In en, this message translates to:
  /// **'Distance read from the car\'s odometer — a measured ground truth.'**
  String get distanceSourceOdometerTooltip;

  /// Distance-provenance badge label (#3253) — the km figure is the haversine-summed GPS track (#1979): true road distance, gated against jitter/teleports.
  ///
  /// In en, this message translates to:
  /// **'GPS track'**
  String get distanceSourceGps;

  /// Tooltip for the 'GPS track' distance-provenance badge (#3253).
  ///
  /// In en, this message translates to:
  /// **'Distance summed from the recorded GPS track — true road distance.'**
  String get distanceSourceGpsTooltip;

  /// Distance-provenance badge label (#3253) — the km figure was integrated from the OBD2 speed sensor (the 'virtual odometer', #800). The speed sensor over-reads, so this is an estimate, like the ~ fuel figures.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get distanceSourceEstimated;

  /// Tooltip for the 'Estimated' distance-provenance badge (#3253): explains the virtual-odometer estimate and its over-read bias.
  ///
  /// In en, this message translates to:
  /// **'Distance integrated from the speed sensor — an estimate; the sensor typically over-reads slightly.'**
  String get distanceSourceEstimatedTooltip;

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

  /// How-to-improve advice for the idling lesson in the post-trip lessons registry (#2251). Embedded in the GPX recording export; the trip-detail card keeps its existing percent-of-trip caption.
  ///
  /// In en, this message translates to:
  /// **'Turn the engine off at long stops instead of letting it idle.'**
  String get lessonAdviceIdling;

  /// How-to-improve advice for the high-RPM lesson in the post-trip lessons registry (#2251). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Shift up earlier to keep the engine out of the high-RPM band.'**
  String get lessonAdviceHighRpm;

  /// How-to-improve advice for the hard-acceleration lesson in the post-trip lessons registry (#2251). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Ease onto the throttle — smooth acceleration uses less fuel.'**
  String get lessonAdviceHardAccel;

  /// How-to-improve advice for the low-gear lesson in the post-trip lessons registry (#2251). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Shift up sooner so the engine settles into a lower, more efficient gear.'**
  String get lessonAdviceLowGear;

  /// Post-trip lesson headline for the high-speed-band penalty (#2287) — time spent above ~110 km/h where aerodynamic drag dominates consumption. Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Sustained high speed ({pctTime}% of trip): wasted {liters} L'**
  String insightHighSpeedBand(String pctTime, String liters);

  /// High-speed-band lesson headline (#2287) for trips with no fuel-consumption figure (GPS-only / no fuel-rate PID) — same coaching without the wasted-litres clause.
  ///
  /// In en, this message translates to:
  /// **'Sustained high speed ({pctTime}% of trip)'**
  String insightHighSpeedBandNoFuel(String pctTime);

  /// How-to-improve advice for the high-speed-band lesson (#2287). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Ease off above 110 km/h — drag rises sharply, so a small speed cut saves a lot of fuel.'**
  String get lessonAdviceHighSpeedBand;

  /// Positive-reinforcement post-trip lesson headline (#2287) shown when a real trip had no harsh acceleration or braking events.
  ///
  /// In en, this message translates to:
  /// **'Smooth driving — nicely done!'**
  String get lessonSmoothDrivingTitle;

  /// Encouragement line for the smooth-driving praise lesson (#2287). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'No harsh acceleration or braking this trip — steady inputs like these keep consumption low.'**
  String get lessonAdviceSmoothDriving;

  /// Cost-line copy for the full-throttle insight on the Trip detail screen (#2461) — time spent at pedal/throttle >= 90 %. Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Full throttle ({pctTime}% of trip): wasted {liters} L'**
  String insightFullThrottle(String pctTime, String liters);

  /// How-to-improve advice for the full-throttle lesson (#2461). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Ease onto the pedal — a gentler 70 % of the throttle gets you up to speed on far less fuel.'**
  String get lessonAdviceFullThrottle;

  /// Cost-line copy for the lambda-enrichment insight on the Trip detail screen (#2461) — time the ECU commanded a mixture richer than stoichiometric (lambda < 1), dumping extra fuel under heavy load. Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Rich mixture under load ({pctTime}% of trip): wasted {liters} L'**
  String insightLambdaEnrichment(String pctTime, String liters);

  /// How-to-improve advice for the lambda-enrichment lesson (#2461). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Heavy, sustained load makes the engine run rich — short-shift and back off on long climbs to keep the mixture lean.'**
  String get lessonAdviceLambdaEnrichment;

  /// Cost-line copy for the climbing-fuel insight on the Trip detail screen (#2693 C6) — extra fuel burned over a flat-road counterfactual while on a confident uphill grade. Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Climbing at {gradePercent}% grade ({pctTime}% of trip): wasted {liters} L'**
  String insightClimbingCost(
    String gradePercent,
    String pctTime,
    String liters,
  );

  /// How-to-improve advice for the climbing-fuel lesson (#2693 C6). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Carry momentum into a hill and feed the throttle smoothly — surging on a climb burns extra fuel.'**
  String get lessonAdviceClimbingCost;

  /// Cost-line copy for the stop-and-go restart insight on the Trip detail screen (#2694 C8) — extra fuel from accelerating a fully-stopped car back up to speed. Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'{count} stop-and-go restarts: wasted {liters} L'**
  String insightRestartCost(String count, String liters);

  /// How-to-improve advice for the stop-and-go restart lesson (#2694 C8). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Anticipate traffic and coast toward stops so you roll rather than restart — pulling away from a dead stop is the thirstiest part of stop-and-go.'**
  String get lessonAdviceRestartCost;

  /// Combustion-health HEURISTIC headline (#2931), borderline lean case. Deliberately tentative ('looks a little lean', 'compensate') — a coarse health signal from sustained positive fuel trim, NOT a diagnosis of a fault. Placeholder is the pre-formatted mean total-trim percent.
  ///
  /// In en, this message translates to:
  /// **'Mixture looks a little lean — the engine added fuel ({pctTrim}% trim) to compensate'**
  String lessonCombustionHealthLeanBorderline(String pctTrim);

  /// Combustion-health HEURISTIC headline (#2931), marked lean case (large sustained positive trim). Still tentative ('looks', 'possible inefficiency') — never claims a definite fault. Placeholder is the pre-formatted mean total-trim percent.
  ///
  /// In en, this message translates to:
  /// **'Mixture looks lean — the engine sustained a large {pctTrim}% fuel addition, a possible inefficiency'**
  String lessonCombustionHealthLeanMarked(String pctTrim);

  /// Combustion-health HEURISTIC headline (#2931), borderline rich case. Deliberately tentative — a coarse health signal from sustained negative fuel trim, NOT a diagnosis. Placeholder is the pre-formatted mean total-trim percent (magnitude).
  ///
  /// In en, this message translates to:
  /// **'Mixture looks a little rich — the engine pulled fuel ({pctTrim}% trim) to compensate'**
  String lessonCombustionHealthRichBorderline(String pctTrim);

  /// Combustion-health HEURISTIC headline (#2931), marked rich case (large sustained negative trim). Still tentative ('looks', 'possible inefficiency') — never claims a definite fault. Placeholder is the pre-formatted mean total-trim percent (magnitude).
  ///
  /// In en, this message translates to:
  /// **'Mixture looks rich — the engine sustained a large {pctTrim}% fuel cut, a possible inefficiency'**
  String lessonCombustionHealthRichMarked(String pctTrim);

  /// Combustion-health HEURISTIC headline (#2931), commanded-enrichment case — the ECU commanded a rich mixture (lambda < 1) for a large share of the warm engine window. Tentative ('possible wasted fuel'). Placeholder is the pre-formatted percent of the warm drive spent enriched.
  ///
  /// In en, this message translates to:
  /// **'Engine ran rich under load ({pctShare}% of the warm drive) — possible wasted fuel'**
  String lessonCombustionHealthEnrichment(String pctShare);

  /// Subtitle under every combustion-health lesson (#2931) making it explicit that the line is a coarse heuristic from fuel trims / commanded lambda, NOT a per-cylinder diagnosis or a diagnostic certainty.
  ///
  /// In en, this message translates to:
  /// **'Heuristic health signal, not a diagnosis'**
  String get lessonCombustionHealthSubtitle;

  /// How-to-improve advice for the lean combustion-health heuristic (#2931). Frames it as a heads-up to confirm with a proper scan, never as a definite fault. Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'A sustained lean-correcting trim can mean an intake-air leak, a weak fuel supply, or an ageing sensor. If consumption or running quality worsens, a workshop scan can confirm.'**
  String get lessonAdviceCombustionHealthLean;

  /// How-to-improve advice for the rich combustion-health heuristic (#2931). Frames it as a heads-up to confirm with a proper scan, never as a definite fault. Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'A sustained rich-correcting trim can mean a leaking injector, high fuel pressure, or an over-reading sensor. If consumption or running quality worsens, a workshop scan can confirm.'**
  String get lessonAdviceCombustionHealthRich;

  /// How-to-improve advice for the commanded-enrichment combustion-health heuristic (#2931). Points at the driving that triggers enrichment. Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Running rich under heavy load burns extra fuel. Short-shift and ease off on long pulls so the engine can stay near a stoichiometric mixture.'**
  String get lessonAdviceCombustionHealthEnrichment;

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

  /// Breakdown chip surfaced beneath the driving-score big number when the full-throttle penalty was a top contributor. Since #2460 throttle/pedal is persisted, so this penalty now fires.
  ///
  /// In en, this message translates to:
  /// **'Full throttle'**
  String get drivingScorePenaltyFullThrottle;

  /// Headline classification band shown above the driving-score number when the score is 85-100 (#2460).
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get drivingScoreClassVeryGood;

  /// Headline classification band shown above the driving-score number when the score is 70-84 (#2460).
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get drivingScoreClassGood;

  /// Headline classification band shown above the driving-score number when the score is 50-69 (#2460).
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get drivingScoreClassAverage;

  /// Headline classification band shown above the driving-score number when the score is below 50 (#2460).
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get drivingScoreClassBad;

  /// Breakdown chip beneath the driving-score number when labouring below the optimal gear (lugging) was a top contributor (#2460).
  ///
  /// In en, this message translates to:
  /// **'Lugging'**
  String get drivingScorePenaltyLugging;

  /// Breakdown chip beneath the driving-score number when jerky / uneven speed and pedal inputs (low smoothness) were a top contributor (#2460).
  ///
  /// In en, this message translates to:
  /// **'Jerky driving'**
  String get drivingScorePenaltySmoothness;

  /// Breakdown chip beneath the driving-score number when sustained high speed (drag-dominated, above 110 km/h) was a top contributor (#2460).
  ///
  /// In en, this message translates to:
  /// **'High speed'**
  String get drivingScorePenaltyHighSpeed;

  /// Breakdown chip beneath the driving-score number when stabbing the accelerator pedal (high pedal velocity) was a top contributor (#2460).
  ///
  /// In en, this message translates to:
  /// **'Aggressive pedal'**
  String get drivingScorePenaltyPedalVelocity;

  /// Breakdown chip beneath the driving-score number when the engine ran a rich mixture (lambda < 1) under load, dumping extra fuel, as a top contributor (#2460).
  ///
  /// In en, this message translates to:
  /// **'Rich mixture'**
  String get drivingScorePenaltyLambda;

  /// Title of the GPS-only efficiency KPI card on the Trip detail screen (#2695 C9) — shown for trips recorded without an engine signal.
  ///
  /// In en, this message translates to:
  /// **'GPS efficiency'**
  String get gpsKpiCardTitle;

  /// Label for the Relative Positive Acceleration KPI on the GPS efficiency card (#2695 C9) — a speed-only eco-driving aggressiveness index.
  ///
  /// In en, this message translates to:
  /// **'Positive acceleration (RPA)'**
  String get gpsKpiRpa;

  /// Label for the Positive Kinetic Energy KPI on the GPS efficiency card (#2695 C9) — distance-normalised positive kinetic-energy changes.
  ///
  /// In en, this message translates to:
  /// **'Kinetic energy demand (PKE)'**
  String get gpsKpiPke;

  /// Label for the mean positive v·a KPI on the GPS efficiency card (#2695 C9) — average power-proxy while accelerating.
  ///
  /// In en, this message translates to:
  /// **'Acceleration intensity (VAPOS)'**
  String get gpsKpiVapos;

  /// Label for the coasting-share KPI on the GPS efficiency card (#2695 C9) — fraction of moving time spent coasting, an eco-positive signal.
  ///
  /// In en, this message translates to:
  /// **'Coasting share'**
  String get gpsKpiCoast;

  /// Label for the climb-energy-per-km KPI on the GPS efficiency card (#2695 C9) — metres climbed per kilometre, a potential-energy work proxy.
  ///
  /// In en, this message translates to:
  /// **'Climb energy'**
  String get gpsKpiClimbEnergy;

  /// Trip-detail line comparing this trip's average consumption to the driver's synced efficient baseline (#2696 C10). The placeholder is a pre-formatted signed percentage (e.g. '+8%' worse, '-5%' better). Hidden when there is no learned baseline yet.
  ///
  /// In en, this message translates to:
  /// **'{pct} vs your efficient baseline'**
  String drivingScoreBaselineDelta(String pct);

  /// Title of the developer-only card on the trip-detail screen that exports the trip's driving-analysis trace for threshold calibration (#2804, Epic #2789). Only visible in Developer / Debug mode.
  ///
  /// In en, this message translates to:
  /// **'Driving-analysis trace (dev)'**
  String get drivingTraceCardTitle;

  /// One-line explanation under the driving-analysis trace card title clarifying it is a gated developer calibration tool (#2804).
  ///
  /// In en, this message translates to:
  /// **'Export this trip\'s GPS KPIs, score and lessons as JSON, write how the drive actually felt in the comment field, and share it back so the driving-style thresholds can be calibrated against real trips.'**
  String get drivingTraceCardBody;

  /// Button that exports the trip's driving-analysis trace as JSON to Downloads and opens the share sheet on the trip-detail screen (#2804).
  ///
  /// In en, this message translates to:
  /// **'Export analysis trace'**
  String get drivingTraceExportAction;

  /// Snackbar confirming the driving-analysis trace JSON was saved to the Downloads folder and the share sheet was opened (#2804).
  ///
  /// In en, this message translates to:
  /// **'Analysis trace saved to Downloads — add your verdict in the comment field and share it back.'**
  String get drivingTraceExported;

  /// Snackbar shown when exporting the driving-analysis trace JSON failed (#2804).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the analysis trace.'**
  String get drivingTraceExportFailed;

  /// Label of the trip-running-average row on the live minimal drive summary card (#3431). Sits under the true instantaneous headline so 'instant' and 'average' are never conflated.
  ///
  /// In en, this message translates to:
  /// **'Trip average'**
  String get minimalDriveTripAverage;

  /// Post-trip lesson headline (#3432) for steady-speed cruising at high RPM where an earlier upshift was available. Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'High-RPM cruising ({pctTime}% of trip): shifting up earlier could save {liters} L'**
  String insightUpshiftCruise(String pctTime, String liters);

  /// How-to-improve advice for the high-RPM-cruise upshift lesson (#3432). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Shift up earlier when cruising — the same speed at lower RPM burns noticeably less fuel.'**
  String get lessonAdviceUpshiftCruise;

  /// Positive post-trip lesson headline (#3432) recognising deceleration-fuel-cut coasting (measured fuel rate near zero while moving). Placeholders are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'Fuel-cut coasting ({pctTime}% of trip): saved about {liters} L'**
  String insightCoastingFuelCut(String pctTime, String liters);

  /// Praise/advice line for the fuel-cut coasting lesson (#3432). Embedded in the GPX recording export.
  ///
  /// In en, this message translates to:
  /// **'Nicely anticipated — lifting off early lets the engine cut fuel completely while coasting.'**
  String get lessonAdviceCoastingFuelCut;

  /// Trailing badge for a POSITIVE lesson / breakdown row showing litres saved (#3432) — the minus-sign counterpart of insightTrailingLitersWasted. Liters is a pre-formatted one-decimal string.
  ///
  /// In en, this message translates to:
  /// **'−{liters} L'**
  String insightTrailingLitersSaved(String liters);

  /// Title of the per-event fuel-cost breakdown card on the Trip detail screen (#3432).
  ///
  /// In en, this message translates to:
  /// **'Where your fuel went'**
  String get fuelBreakdownTitle;

  /// Breakdown row label (#3432): litres burned while stationary with the engine running (idle events > 30 s).
  ///
  /// In en, this message translates to:
  /// **'Idling'**
  String get fuelBreakdownIdle;

  /// Breakdown row label (#3432): excess litres attributed to pedal-spike acceleration events.
  ///
  /// In en, this message translates to:
  /// **'Hard accelerations'**
  String get fuelBreakdownHarshAccel;

  /// Breakdown row label (#3432): estimated litres an earlier upshift would have saved during steady high-RPM cruising.
  ///
  /// In en, this message translates to:
  /// **'High-RPM cruising'**
  String get fuelBreakdownHighRpmCruise;

  /// Positive breakdown row label (#3432): litres saved by deceleration fuel cut while coasting.
  ///
  /// In en, this message translates to:
  /// **'Saved by coasting'**
  String get fuelBreakdownCoastingSaved;

  /// Neutral breakdown row label (#3432): the remainder of the trip's fuel not attributed to any waste event class.
  ///
  /// In en, this message translates to:
  /// **'Normal driving'**
  String get fuelBreakdownEfficient;

  /// Plain litres badge for the neutral breakdown remainder row (#3432). Liters is a pre-formatted one-decimal string.
  ///
  /// In en, this message translates to:
  /// **'{liters} L'**
  String fuelBreakdownLiters(String liters);

  /// Live in-trip nudge SnackBar (#3432) after 30+ seconds stationary with the engine running. Rate-limited to at most one nudge per minute, three per trip.
  ///
  /// In en, this message translates to:
  /// **'Idling for a while — switching the engine off saves fuel'**
  String get ecoNudgeIdle;

  /// Live in-trip nudge SnackBar (#3432) after a sustained full-pedal spike. Rate-limited to at most one nudge per minute, three per trip.
  ///
  /// In en, this message translates to:
  /// **'Strong acceleration — a gentler pedal saves fuel'**
  String get ecoNudgeHarshAccel;

  /// Live in-trip nudge SnackBar (#3432) after sustained high-RPM steady-speed cruising. Rate-limited to at most one nudge per minute, three per trip.
  ///
  /// In en, this message translates to:
  /// **'High revs at cruise — shifting up earlier saves fuel'**
  String get ecoNudgeHighRpm;

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

  /// Trip-detail note (#3499, epic #3498) shown on a gpsPlusObd2 trip whose samples carried ZERO engine PIDs: the adapter session never delivered engine data (drop at start, silent ECU, no supported PIDs), so the fuel chart/figures silently fell back to the GPS-physics estimate. This makes that fallback honest instead of unexplained.
  ///
  /// In en, this message translates to:
  /// **'No engine data arrived from the OBD2 adapter on this trip — fuel figures are GPS-based estimates.'**
  String get obd2CoverageNoneNote;

  /// Trip-detail note (#3499) for the adapter-dropped-mid-trip signature: engine PIDs flowed, then ended well before the trip did. percent is the position (0-100) of the last engine-bearing sample.
  ///
  /// In en, this message translates to:
  /// **'Engine data stopped {percent}% into the trip (connection dropped) — fuel figures after that point are GPS-based estimates.'**
  String obd2CoverageDroppedNote(int percent);

  /// Trip-detail note (#3499) for patchy engine coverage with no clean cut-off (flaky link / slow PID round-trips). percent is the share (0-100) of samples that carried an engine PID.
  ///
  /// In en, this message translates to:
  /// **'Engine data covered only {percent}% of this trip — gaps use GPS-based estimates.'**
  String obd2CoveragePartialNote(int percent);

  /// AppBar action tooltip for the share-favorites button on the Favorites screen (#1344).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get favoritesShareAction;

  /// Subject / preview text passed to the OS share sheet when the user shares the Favorites screen as an image (#1344). The {date} placeholder is replaced with a localised short date.
  ///
  /// In en, this message translates to:
  /// **'Sparkilo — favourites on {date}'**
  String favoritesShareSubject(String date);

  /// Snackbar shown when the favorites Share action fails to render or hand off the report PNG (#1344).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate share image'**
  String get favoritesShareError;

  /// Title of the foldable settings section that lets the user toggle each top-level app feature on or off (#1373 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Feature management'**
  String get featureManagementSectionTitle;

  /// One-line subtitle shown at the top of the Feature management section explaining the dependency-aware behaviour.
  ///
  /// In en, this message translates to:
  /// **'Turn individual features on or off. Some features depend on others — switches are disabled until prerequisites are met.'**
  String get featureManagementSectionSubtitle;

  /// Display name for the OBD2 trip recording feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'OBD2 trip recording'**
  String get featureLabel_obd2TripRecording;

  /// One-line description for the OBD2 trip recording feature.
  ///
  /// In en, this message translates to:
  /// **'Capture trips automatically over OBD2.'**
  String get featureDescription_obd2TripRecording;

  /// Display name for the gamification feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get featureLabel_gamification;

  /// One-line description for the gamification feature.
  ///
  /// In en, this message translates to:
  /// **'Driving scores and earned badges.'**
  String get featureDescription_gamification;

  /// Display name for the haptic eco-coach feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Haptic eco-coach'**
  String get featureLabel_hapticEcoCoach;

  /// One-line description for the haptic eco-coach feature.
  ///
  /// In en, this message translates to:
  /// **'Real-time haptic feedback during a trip.'**
  String get featureDescription_hapticEcoCoach;

  /// Display name for the TankSync (cross-device sync) feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'TankSync'**
  String get featureLabel_tankSync;

  /// One-line description for the TankSync feature.
  ///
  /// In en, this message translates to:
  /// **'Cross-device sync via Supabase.'**
  String get featureDescription_tankSync;

  /// Display name for the consumption analytics feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Consumption analytics'**
  String get featureLabel_consumptionAnalytics;

  /// One-line description for the consumption analytics feature.
  ///
  /// In en, this message translates to:
  /// **'Fill-up and trip analysis tab.'**
  String get featureDescription_consumptionAnalytics;

  /// Display name for the driving-baseline sync feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Baseline sync'**
  String get featureLabel_baselineSync;

  /// One-line description for the baseline sync feature.
  ///
  /// In en, this message translates to:
  /// **'Sync driving baselines via TankSync.'**
  String get featureDescription_baselineSync;

  /// Display name for the unified fuel + EV search results feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Unified search results'**
  String get featureLabel_unifiedSearchResults;

  /// One-line description for the unified search results feature.
  ///
  /// In en, this message translates to:
  /// **'Single result list combining fuel and EV stations.'**
  String get featureDescription_unifiedSearchResults;

  /// Display name for the price alerts feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get featureLabel_priceAlerts;

  /// One-line description for the price alerts feature.
  ///
  /// In en, this message translates to:
  /// **'Threshold-based price-drop notifications.'**
  String get featureDescription_priceAlerts;

  /// Display name for the price history feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get featureLabel_priceHistory;

  /// One-line description for the price history feature.
  ///
  /// In en, this message translates to:
  /// **'30-day price charts on station details.'**
  String get featureDescription_priceHistory;

  /// Display name for the route planning feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Route planning'**
  String get featureLabel_routePlanning;

  /// One-line description for the route planning feature.
  ///
  /// In en, this message translates to:
  /// **'Cheapest stop along your route.'**
  String get featureDescription_routePlanning;

  /// Display name for the EV charging feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'EV charging'**
  String get featureLabel_evCharging;

  /// One-line description for the EV charging feature.
  ///
  /// In en, this message translates to:
  /// **'Charging stations via OpenChargeMap.'**
  String get featureDescription_evCharging;

  /// Display name for the hypermiling glide-coach feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'Glide-coach'**
  String get featureLabel_glideCoach;

  /// One-line description for the glide-coach feature.
  ///
  /// In en, this message translates to:
  /// **'Hypermiling guidance using OSM traffic signals.'**
  String get featureDescription_glideCoach;

  /// Display name for the GPS trip path feature in the Feature management list.
  ///
  /// In en, this message translates to:
  /// **'GPS trip path'**
  String get featureLabel_gpsTripPath;

  /// One-line description for the GPS trip path feature.
  ///
  /// In en, this message translates to:
  /// **'Persist GPS path samples alongside each trip.'**
  String get featureDescription_gpsTripPath;

  /// Display name for the master auto-record feature gate (#1373 phase 3d). The per-vehicle auto-record toggle is independent; this central switch is the master gate consulted first.
  ///
  /// In en, this message translates to:
  /// **'Auto-record'**
  String get featureLabel_autoRecord;

  /// One-line description for the master auto-record feature gate.
  ///
  /// In en, this message translates to:
  /// **'Automatically start a trip when the OBD2 adapter connects to a moving vehicle.'**
  String get featureDescription_autoRecord;

  /// Display name for the show-fuel-stations feature gate (#1373 phase 3c). Migrated from the legacy UserProfile.showFuel bool.
  ///
  /// In en, this message translates to:
  /// **'Show fuel stations'**
  String get featureLabel_showFuel;

  /// One-line description for the show-fuel-stations feature gate.
  ///
  /// In en, this message translates to:
  /// **'Display petrol/diesel station results in search and on the map.'**
  String get featureDescription_showFuel;

  /// Display name for the show-EV-charging-stations feature gate (#1373 phase 3c). Migrated from the legacy UserProfile.showElectric bool.
  ///
  /// In en, this message translates to:
  /// **'Show charging stations'**
  String get featureLabel_showElectric;

  /// One-line description for the show-EV-charging-stations feature gate.
  ///
  /// In en, this message translates to:
  /// **'Display EV charging stations in search and on the map.'**
  String get featureDescription_showElectric;

  /// Display name for the consumption-tab visibility feature gate (#1373 phase 3c). Migrated from the legacy UserProfile.showConsumptionTab bool.
  ///
  /// In en, this message translates to:
  /// **'Consumption tab'**
  String get featureLabel_showConsumptionTab;

  /// One-line description for the consumption-tab visibility feature gate.
  ///
  /// In en, this message translates to:
  /// **'Show the consumption analytics tab in the bottom navigation.'**
  String get featureDescription_showConsumptionTab;

  /// Tooltip shown on the disabled gamification toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_gamification;

  /// Tooltip shown on the disabled haptic eco-coach toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_hapticEcoCoach;

  /// Tooltip shown on the disabled consumption analytics toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_consumptionAnalytics;

  /// Tooltip shown on the disabled baseline sync toggle when its prerequisite (TankSync) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable TankSync first'**
  String get featureBlockedEnable_baselineSync;

  /// Tooltip shown on the disabled glide-coach toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_glideCoach;

  /// Tooltip shown on the disabled GPS trip path toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_gpsTripPath;

  /// Tooltip shown on the disabled master auto-record toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_autoRecord;

  /// Tooltip shown on the disabled show-fuel-stations toggle. The feature has no prerequisites today so this string is a defensive fallback for the dependency-graph helpers.
  ///
  /// In en, this message translates to:
  /// **'Prerequisites not met'**
  String get featureBlockedEnable_showFuel;

  /// Tooltip shown on the disabled show-EV-charging-stations toggle. The feature has no prerequisites today so this string is a defensive fallback for the dependency-graph helpers.
  ///
  /// In en, this message translates to:
  /// **'Prerequisites not met'**
  String get featureBlockedEnable_showElectric;

  /// Tooltip shown on the disabled consumption-tab toggle when its prerequisite (OBD2 trip recording) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_showConsumptionTab;

  /// Settings toggle label for the on-device price-prediction guidance (#1543).
  ///
  /// In en, this message translates to:
  /// **'Best time to fill up'**
  String get featureLabel_tflitePricePrediction;

  /// Settings toggle description for the on-device price-prediction guidance (#1543). Emphasises that the heuristic runs locally and no data leaves the device.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance on when to fill up, computed from your local price history — nothing leaves the device.'**
  String get featureDescription_tflitePricePrediction;

  /// Tooltip shown on the disabled TFLite-prediction toggle when its prerequisite (priceHistory) is off.
  ///
  /// In en, this message translates to:
  /// **'Enable price history first'**
  String get featureBlockedEnable_tflitePricePrediction;

  /// Settings toggle label for the fuel-cost Calculator feature (#1613).
  ///
  /// In en, this message translates to:
  /// **'Fuel calculator'**
  String get featureLabel_fuelCalculator;

  /// Settings toggle description for the fuel-cost Calculator feature (#1613).
  ///
  /// In en, this message translates to:
  /// **'Reachable fuel-cost calculator from the search results.'**
  String get featureDescription_fuelCalculator;

  /// Settings toggle label for the Carbon dashboard feature (#1613).
  ///
  /// In en, this message translates to:
  /// **'Carbon dashboard'**
  String get featureLabel_carbonDashboard;

  /// Settings toggle description for the Carbon dashboard feature (#1613).
  ///
  /// In en, this message translates to:
  /// **'CO2 footprint dashboard reachable from the Consumption tab.'**
  String get featureDescription_carbonDashboard;

  /// Settings toggle label for the experimental OEM-PID exact-fuel-level feature (#1615).
  ///
  /// In en, this message translates to:
  /// **'Experimental OEM PIDs'**
  String get featureLabel_experimentalOemPids;

  /// Settings toggle description for the experimental OEM-PID exact-fuel-level feature (#1615).
  ///
  /// In en, this message translates to:
  /// **'Read exact tank litres via manufacturer-specific PIDs on supported adapters.'**
  String get featureDescription_experimentalOemPids;

  /// Shown when the user taps the experimental OEM-PID toggle while its OBD2-trip-recording prerequisite is off (#1615).
  ///
  /// In en, this message translates to:
  /// **'Enable OBD2 trip recording first'**
  String get featureBlockedEnable_experimentalOemPids;

  /// Settings toggle label for the scan-payment-QR station-detail action (#1638).
  ///
  /// In en, this message translates to:
  /// **'Scan payment QR'**
  String get featureLabel_paymentQrScan;

  /// Settings toggle description for the scan-payment-QR station-detail action (#1638).
  ///
  /// In en, this message translates to:
  /// **'Scan-to-pay QR reader on the station detail screen.'**
  String get featureDescription_paymentQrScan;

  /// Settings toggle label for the community price-report station-detail action (#1638).
  ///
  /// In en, this message translates to:
  /// **'Community price reports'**
  String get featureLabel_communityPriceReports;

  /// Settings toggle description for the community price-report station-detail action (#1638).
  ///
  /// In en, this message translates to:
  /// **'Report a station price from the station detail screen.'**
  String get featureDescription_communityPriceReports;

  /// Settings toggle label for the OBD2-optional flag (#2024). When the toggle is on (default), the trip recorder still requires an OBD2 adapter; when off, GPS-only trajets become possible.
  ///
  /// In en, this message translates to:
  /// **'Require OBD2 for trip recording'**
  String get featureLabel_obd2Optional;

  /// Settings toggle description for the OBD2-optional flag (#2024). Explains the trade-off between gpsPlusObd2 (default) and gpsOnly trip recording.
  ///
  /// In en, this message translates to:
  /// **'When off, the app records GPS-only trajets without needing an OBD2 adapter. Coaching is reduced — no instant L/100 km, fewer engine-derived signals.'**
  String get featureDescription_obd2Optional;

  /// Settings toggle label for the Add-fill-up receipt-OCR import button (#2110). Default-on.
  ///
  /// In en, this message translates to:
  /// **'Receipt OCR'**
  String get featureLabel_addFillUpOcrReceipt;

  /// Settings toggle description for the Add-fill-up receipt-OCR button (#2110).
  ///
  /// In en, this message translates to:
  /// **'Scan a printed receipt on the Add fill-up screen to pre-fill date, litres, total, and station.'**
  String get featureDescription_addFillUpOcrReceipt;

  /// Settings toggle label for the Add-fill-up pump-display-OCR import button (#2110). Default-off — recognizer unreliable.
  ///
  /// In en, this message translates to:
  /// **'Pump display OCR (experimental)'**
  String get featureLabel_addFillUpOcrPump;

  /// Settings toggle description for the Add-fill-up pump-display-OCR button (#2110). Sets expectation that the recognizer is experimental.
  ///
  /// In en, this message translates to:
  /// **'Scan a fuel pump display to pre-fill the form. Recognition is unreliable today — opt in only if you want to test.'**
  String get featureDescription_addFillUpOcrPump;

  /// Settings toggle label for the bad-scan-feedback PAT panel (#2116-6). Default-off — most users never paste a token.
  ///
  /// In en, this message translates to:
  /// **'Developer feedback (GitHub PAT)'**
  String get featureLabel_developerPatToken;

  /// Settings toggle description for the bad-scan-feedback PAT panel (#2116-6).
  ///
  /// In en, this message translates to:
  /// **'Enable the bad-scan feedback panel that auto-files GitHub issues with a Personal Access Token. Power-user / contributor feature.'**
  String get featureDescription_developerPatToken;

  /// Settings toggle label for Developer / Debug mode (#2248). Default-off — gates the Developer tools section with dev-only diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Developer / Debug mode'**
  String get featureLabel_debugMode;

  /// Settings toggle description for Developer / Debug mode (#2248).
  ///
  /// In en, this message translates to:
  /// **'Surface a Developer tools section in Settings with diagnostics: error-log export, test notifications, a test-alert pipeline run, a feature-flag dump, clear caches, and copy diagnostics.'**
  String get featureDescription_debugMode;

  /// Settings toggle label for the in-trip Fuel Station Radar / approach overlay (#2382 / #2661 rename). Default-on for the Medium and Full use-modes. The enum value + persistence key remain approachOverlay.
  ///
  /// In en, this message translates to:
  /// **'Fuel Station Radar'**
  String get featureLabel_approachOverlay;

  /// Settings toggle description for the in-trip Fuel Station Radar (#2382 / #2661).
  ///
  /// In en, this message translates to:
  /// **'Turn the floating trip tile into a live Fuel Station Radar — as you near a fuel station it flips to the fuel type\'s colour and shows the price.'**
  String get featureDescription_approachOverlay;

  /// Settings toggle label for spoken voice announcements of nearby cheap fuel while driving (#2569). Default-off.
  ///
  /// In en, this message translates to:
  /// **'Voice announcements'**
  String get featureLabel_voiceAnnouncements;

  /// Settings toggle description for spoken voice announcements while driving (#2569).
  ///
  /// In en, this message translates to:
  /// **'Speak nearby cheap fuel stations aloud as you drive, so you can keep your eyes on the road.'**
  String get featureDescription_voiceAnnouncements;

  /// Tooltip shown on the disabled voice-announcements toggle when its prerequisite (approachOverlay, surfaced as Fuel Station Radar) is off (#2569 / #2681).
  ///
  /// In en, this message translates to:
  /// **'Enable the Fuel Station Radar first'**
  String get featureBlockedEnable_voiceAnnouncements;

  /// Section header title for the Finding & map category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Finding & map'**
  String get featureGroupTitle_finding;

  /// Section header subtitle for the Finding & map category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Where to fuel up or charge — search, map, routing.'**
  String get featureGroupDescription_finding;

  /// Section header title for the Prices & alerts category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Prices & alerts'**
  String get featureGroupTitle_prices;

  /// Section header subtitle for the Prices & alerts category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Price drops, history, and reporting.'**
  String get featureGroupDescription_prices;

  /// Section header title for the Fuel Station Radar category in Feature management (#2681 / #2661).
  ///
  /// In en, this message translates to:
  /// **'Fuel Station Radar'**
  String get featureGroupTitle_radar;

  /// Section header subtitle for the Fuel Station Radar category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Live price nudges as you drive.'**
  String get featureGroupDescription_radar;

  /// Section header title for the Sync & backup category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Sync & backup'**
  String get featureGroupTitle_sync;

  /// Section header subtitle for the Sync & backup category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Keep your data across devices.'**
  String get featureGroupDescription_sync;

  /// Section header title for the Input & scanning category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Input & scanning'**
  String get featureGroupTitle_input;

  /// Section header subtitle for the Input & scanning category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Helpers for logging fill-ups.'**
  String get featureGroupDescription_input;

  /// Section header title for the Developer & experimental category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Developer & experimental'**
  String get featureGroupTitle_developer;

  /// Section header subtitle for the Developer & experimental category in Feature management (#2681).
  ///
  /// In en, this message translates to:
  /// **'Power-user and contributor tools.'**
  String get featureGroupDescription_developer;

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

  /// Hint shown under the fuel picker on the Add-Fill-up form for a multi-fuel-capable vehicle, reminding the user to log the exact fuel they pumped so the per-fuel cost-per-km comparison stays accurate (#2886).
  ///
  /// In en, this message translates to:
  /// **'This vehicle can use different fuels — log the one you actually pumped'**
  String get fillUpMultiFuelHint;

  /// Title of the on-device 'best time to fill up' guidance card on the price-history screen (#1543).
  ///
  /// In en, this message translates to:
  /// **'Best time to fill up'**
  String get fillUpGuidanceTitle;

  /// Guidance shown when the current price sits in the cheapest band of the trailing window (#1543).
  ///
  /// In en, this message translates to:
  /// **'The current price is among the cheapest of the last {days} days — a good time to fill up.'**
  String fillUpGuidanceGoodTimeNow(int days);

  /// Guidance shown when the current price is high but a reliably cheaper day/time window exists (#1543).
  ///
  /// In en, this message translates to:
  /// **'Prices are near their {days}-day high. They are usually cheaper {window} — consider waiting.'**
  String fillUpGuidanceWaitCheaper(int days, String window);

  /// Guidance shown when the short-term price trend is clearly rising (#1543).
  ///
  /// In en, this message translates to:
  /// **'Prices are trending up — consider filling up soon.'**
  String get fillUpGuidanceFillSoon;

  /// Neutral guidance shown when no strong cheap/dear/trend signal is present (#1543).
  ///
  /// In en, this message translates to:
  /// **'Today\'s price is around the {days}-day average.'**
  String fillUpGuidanceNeutral(int days);

  /// Optional line appended when a meaningful per-litre saving between cheap and dear windows is detected (#1543).
  ///
  /// In en, this message translates to:
  /// **'Could save about {amount}/L by timing your fill-up.'**
  String fillUpGuidanceSaving(String amount);

  /// Confidence footnote showing how many local price readings the guidance is based on (#1543).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Based on 1 price reading} other{Based on {count} price readings}}'**
  String fillUpGuidanceSampleNote(int count);

  /// Composed cheap-window phrase combining a weekday and a time-of-day part, e.g. 'Tuesday mornings' (#1543).
  ///
  /// In en, this message translates to:
  /// **'{day} {part}'**
  String fillUpGuidanceWindowDayAndPart(String day, String part);

  /// Cheap-window phrase when only a weekday signal is available, e.g. 'on Tuesdays' (#1543).
  ///
  /// In en, this message translates to:
  /// **'on {day}'**
  String fillUpGuidanceWindowDayOnly(String day);

  /// Cheap-window phrase when only a time-of-day signal is available, e.g. 'in the mornings' (#1543).
  ///
  /// In en, this message translates to:
  /// **'in the {part}'**
  String fillUpGuidanceWindowPartOnly(String part);

  /// Fallback cheap-window phrase when neither a weekday nor a time-of-day signal cleared the sample-size guard (#1543).
  ///
  /// In en, this message translates to:
  /// **'at other times'**
  String get fillUpGuidanceWindowGeneric;

  /// Plural weekday name used inside the cheap-window phrase (Monday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Mondays'**
  String get fillUpGuidanceWeekday1;

  /// Plural weekday name used inside the cheap-window phrase (Tuesday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Tuesdays'**
  String get fillUpGuidanceWeekday2;

  /// Plural weekday name used inside the cheap-window phrase (Wednesday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Wednesdays'**
  String get fillUpGuidanceWeekday3;

  /// Plural weekday name used inside the cheap-window phrase (Thursday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Thursdays'**
  String get fillUpGuidanceWeekday4;

  /// Plural weekday name used inside the cheap-window phrase (Friday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Fridays'**
  String get fillUpGuidanceWeekday5;

  /// Plural weekday name used inside the cheap-window phrase (Saturday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Saturdays'**
  String get fillUpGuidanceWeekday6;

  /// Plural weekday name used inside the cheap-window phrase (Sunday) (#1543).
  ///
  /// In en, this message translates to:
  /// **'Sundays'**
  String get fillUpGuidanceWeekday7;

  /// Time-of-day part name (06:00-08:59) used inside the cheap-window phrase (#1543).
  ///
  /// In en, this message translates to:
  /// **'early mornings'**
  String get fillUpGuidancePartEarlyMorning;

  /// Time-of-day part name (09:00-11:59) used inside the cheap-window phrase (#1543).
  ///
  /// In en, this message translates to:
  /// **'mornings'**
  String get fillUpGuidancePartMorning;

  /// Time-of-day part name (12:00-17:59) used inside the cheap-window phrase (#1543).
  ///
  /// In en, this message translates to:
  /// **'afternoons'**
  String get fillUpGuidancePartAfternoon;

  /// Time-of-day part name (18:00-23:59) used inside the cheap-window phrase (#1543).
  ///
  /// In en, this message translates to:
  /// **'evenings'**
  String get fillUpGuidancePartEvening;

  /// Time-of-day part name (00:00-05:59) used inside the cheap-window phrase (#1543).
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get fillUpGuidancePartNight;

  /// Label of the third import button on the Add-Fill-Up form that opens a dialog to paste a digital fuel-receipt's text (no camera, no cloud) and pre-fill the form from it (#2687).
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get fillUpImportPasteLabel;

  /// Title of the dialog where the user pastes a fuel-receipt's text (e-mail body, SMS confirmation, or PDF text) to pre-fill the fill-up (#2687).
  ///
  /// In en, this message translates to:
  /// **'Paste receipt text'**
  String get pasteReceiptDialogTitle;

  /// Helper text in the paste-receipt dialog explaining what to paste and that parsing happens on-device (#2687).
  ///
  /// In en, this message translates to:
  /// **'Paste the text of a fuel receipt — e-mail, SMS, or a shared PDF. The litres, price per litre, fuel grade, total and station are read on-device and used to pre-fill the form. Nothing is sent to a server.'**
  String get pasteReceiptDialogHint;

  /// hintText of the multiline text field in the paste-receipt dialog (#2687).
  ///
  /// In en, this message translates to:
  /// **'Receipt text'**
  String get pasteReceiptFieldHint;

  /// Confirm button in the paste-receipt dialog that runs the parser and pre-fills the form; the user still reviews and saves manually (#2687).
  ///
  /// In en, this message translates to:
  /// **'Pre-fill'**
  String get pasteReceiptParseAction;

  /// Snackbar shown when the pasted text yields no usable fuel fields (#2687).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read any fuel data from that text — check it\'s a fuel receipt and try again.'**
  String get pasteReceiptNoData;

  /// Chip label rendered on a fill-up card when both fuelLevelBeforeL and fuelLevelAfterL were captured by the OBD2 adapter, signalling the pumped litres match the car's own tank-level sensor delta (#1401 phase 7b).
  ///
  /// In en, this message translates to:
  /// **'Verified by adapter'**
  String get fillUpReconciliationVerifiedBadgeLabel;

  /// Title of the confirmation dialog shown on save when the user-entered litres differ from the adapter-derived tank delta by more than 5 percent (#1401 phase 7b).
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match adapter reading'**
  String get fillUpReconciliationVarianceDialogTitle;

  /// Body of the variance confirmation dialog. Shows both numeric values pre-formatted by the caller so the dialog stays locale-agnostic (#1401 phase 7b).
  ///
  /// In en, this message translates to:
  /// **'Your entry: {userL} L. Adapter says: {adapterL} L (delta from before/after fuel-level capture). Use adapter value?'**
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL);

  /// Button on the variance dialog that closes the prompt and proceeds to save the fill-up with the user-entered litres value (#1401 phase 7b).
  ///
  /// In en, this message translates to:
  /// **'Keep my entry'**
  String get fillUpReconciliationVarianceDialogKeepMine;

  /// Button on the variance dialog that closes the prompt and replaces the user-entered litres with the adapter-derived tank delta before saving (#1401 phase 7b).
  ///
  /// In en, this message translates to:
  /// **'Use adapter value'**
  String get fillUpReconciliationVarianceDialogUseAdapter;

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

  /// Snackbar shown when the pump-display capture is rejected for excessive glare and the user is asked to re-angle (#2275).
  ///
  /// In en, this message translates to:
  /// **'Too much glare on the display — try again at a slight angle so the numbers aren\'t washed out.'**
  String get scanPumpGlare;

  /// Snackbar shown when the pump-display scan read values that failed the country validation gate (the numbers don't reconcile or are out of range), so the app declines to auto-fill a plausible-but-wrong pair (#2828).
  ///
  /// In en, this message translates to:
  /// **'The scanned values don\'t add up — please enter them manually.'**
  String get scanPumpInconsistent;

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

  /// Hint shown over the in-app camera reticle for the pump-display capture (#1868).
  ///
  /// In en, this message translates to:
  /// **'Line up the three pump-display numbers inside the frame'**
  String get pumpCameraHint;

  /// Label of the shutter button on the pump-display camera screen (#1868).
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get pumpCameraCapture;

  /// Shown when the camera permission is denied on the pump-display capture screen (#1868).
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan the pump display. Enable it in your device settings.'**
  String get pumpCameraPermissionDenied;

  /// Shown when the in-app camera fails to initialise on the pump-display capture screen (#1868).
  ///
  /// In en, this message translates to:
  /// **'The camera couldn\'t start. Try again or enter the values by hand.'**
  String get pumpCameraError;

  /// Tooltip on the orientation-toggle button when the overlay is currently vertical (#2276).
  ///
  /// In en, this message translates to:
  /// **'Switch to horizontal layout'**
  String get pumpCameraOrientationHorizontal;

  /// Tooltip on the orientation-toggle button when the overlay is currently horizontal (#2276).
  ///
  /// In en, this message translates to:
  /// **'Switch to vertical layout'**
  String get pumpCameraOrientationVertical;

  /// Live amber feedback bar shown when the framed region is over-exposed by glare (#2276).
  ///
  /// In en, this message translates to:
  /// **'Too much glare — tilt slightly to avoid reflections'**
  String get pumpCameraGlareWarning;

  /// Default hint shown in the live feedback bar on the guided alignment overlay (#2276).
  ///
  /// In en, this message translates to:
  /// **'Line up the display inside the frame, then capture'**
  String get pumpCameraAlignHint;

  /// Highest-priority feedback shown over the camera while the phone is held portrait; the shutter is disabled until the user rotates to landscape so the wide pump display fills the frame with large, upright digits (#2477).
  ///
  /// In en, this message translates to:
  /// **'Turn your phone sideways — the pump display is wide, so the numbers come out larger and upright'**
  String get pumpCameraRotateToLandscape;

  /// Title of the confirmation dialog shown on save when a fill-up has data-quality warnings (wrong fuel for the engine, or an odometer below the previous reading) before persisting (#2836).
  ///
  /// In en, this message translates to:
  /// **'Check this fill-up'**
  String get fillUpWarningDialogTitle;

  /// Warning line shown when the chosen fuel belongs to a different engine family than the vehicle's configured fuel, e.g. petrol on a diesel car (#2836). Both fuel names are pre-localised by the caller.
  ///
  /// In en, this message translates to:
  /// **'You picked {chosenFuel}, but this vehicle runs on {vehicleFuel}.'**
  String fillUpWarningFuelMismatch(String chosenFuel, String vehicleFuel);

  /// Warning line shown when the entered odometer is lower than the most recent prior fill-up's odometer for the same vehicle (#2836). Both numbers are pre-formatted by the caller.
  ///
  /// In en, this message translates to:
  /// **'Odometer {entered} km is below the previous fill-up\'s {previous} km — distance can\'t go backwards.'**
  String fillUpWarningOdometerBelowPrevious(String entered, String previous);

  /// Button on the fill-up warning dialog that dismisses it without saving so the user can correct the flagged field (#2836).
  ///
  /// In en, this message translates to:
  /// **'Go back and fix'**
  String get fillUpWarningGoBack;

  /// Button on the fill-up warning dialog that proceeds to save the fill-up despite the warnings (#2836).
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get fillUpWarningSaveAnyway;

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

  /// Card title grouping the avoid-highways, show-fuel and show-EV toggles on the edit-profile form (#2551).
  ///
  /// In en, this message translates to:
  /// **'Display & stations'**
  String get profileSectionDisplayStations;

  /// Card title grouping the country and language selectors on the edit-profile form (#2551).
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get profileSectionRegion;

  /// Title of the per-fuel-type efficiency comparison card on the consumption-statistics page, comparing real cost-per-km across the fuels a multi-fuel vehicle has used (#2887, Epic #2881).
  ///
  /// In en, this message translates to:
  /// **'Cost per kilometre by fuel'**
  String get fuelEfficiencyCardTitle;

  /// Subtitle of the per-fuel efficiency card explaining it ranks fuel compositions (pure grades and blends) by real driving cost per kilometre, not pump price per litre (#2887, ADR 0015).
  ///
  /// In en, this message translates to:
  /// **'Which fuel mix is actually cheapest to drive on'**
  String get fuelEfficiencyCardSubtitle;

  /// Winner chip at the top of the per-fuel efficiency card, crowning the fuel composition (a pure grade or a blend) with the lowest verified cost per kilometre (#2887, ADR 0015). The {fuel} placeholder is a language-neutral grade code or A/B mix mask.
  ///
  /// In en, this message translates to:
  /// **'Cheapest per km: {fuel} ({costPerKm})'**
  String fuelEfficiencyWinnerChip(String fuel, String costPerKm);

  /// Row badge on the per-fuel efficiency card marking a composition bucket that is a single pure fuel grade (>= 85% one fuel) rather than a blend (#2928, ADR 0015).
  ///
  /// In en, this message translates to:
  /// **'Pure'**
  String get fuelEfficiencyPureBadge;

  /// Row badge on the per-fuel efficiency card marking a composition bucket that is a blend of two fuels rather than a single pure grade (#2928, ADR 0015).
  ///
  /// In en, this message translates to:
  /// **'Blend'**
  String get fuelEfficiencyMixBadge;

  /// Secondary line on a blend row of the per-fuel efficiency card, naming the dominant (largest-share) fuel of the blend (#2928, ADR 0015).
  ///
  /// In en, this message translates to:
  /// **'Mostly {fuel}'**
  String fuelEfficiencyMixDominant(String fuel);

  /// Column header for the litres-per-100km metric in the per-fuel efficiency card (#2887).
  ///
  /// In en, this message translates to:
  /// **'L/100km'**
  String get fuelEfficiencyColL100km;

  /// Column header for the cost-per-kilometre metric in the per-fuel efficiency card (#2887).
  ///
  /// In en, this message translates to:
  /// **'Cost/km'**
  String get fuelEfficiencyColCostPerKm;

  /// Column header for the total-spent metric in the per-fuel efficiency card (#2887).
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get fuelEfficiencyColTotalSpent;

  /// Number of fill-ups logged for a fuel, shown on its row in the per-fuel efficiency card (#2887).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 fill} other{{count} fills}}'**
  String fuelEfficiencyFillCount(int count);

  /// Transparency footnote on the per-fuel efficiency card, disclosing how many tanks contained more than one fuel and were each attributed whole to their dominant fuel (#2887, ADR 0014).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mixed tank counted toward its main fuel} other{{count} mixed tanks counted toward their main fuel}}'**
  String fuelEfficiencyMixedFootnote(int count);

  /// Footnote shown on the per-fuel efficiency card when no winner can be crowned yet because at least one composition bucket has fewer than two closed plein-to-plein intervals (#2887, ADR 0015 verdict gate).
  ///
  /// In en, this message translates to:
  /// **'Log at least two full tanks per composition to crown the cheapest.'**
  String get fuelEfficiencyInsufficientData;

  /// Transparency footnote on the per-fuel efficiency card explaining the pure-vs-blend bucketing rule used to compare fuel compositions (#2928, ADR 0015).
  ///
  /// In en, this message translates to:
  /// **'Tanks are grouped by composition: a tank is pure when one fuel is at least 85% of it, otherwise a blend.'**
  String get fuelEfficiencyCompositionFootnote;

  /// Localized display name for the E5 (Super, up to 5% ethanol) petrol grade, used on the per-fuel efficiency card (#2887).
  ///
  /// In en, this message translates to:
  /// **'Super E5'**
  String get fuelNameE5;

  /// Localized display name for the E10 (up to 10% ethanol) petrol grade (#2887).
  ///
  /// In en, this message translates to:
  /// **'Super E10'**
  String get fuelNameE10;

  /// Localized display name for the 98-octane petrol grade (#2887).
  ///
  /// In en, this message translates to:
  /// **'Super 98'**
  String get fuelNameE98;

  /// Localized display name for diesel fuel (#2887).
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelNameDiesel;

  /// Localized display name for premium diesel (#2887).
  ///
  /// In en, this message translates to:
  /// **'Diesel Premium'**
  String get fuelNameDieselPremium;

  /// Localized display name for the E85 flex-fuel (up to 85% bioethanol) grade (#2887).
  ///
  /// In en, this message translates to:
  /// **'E85 Bioethanol'**
  String get fuelNameE85;

  /// Localized display name for liquefied petroleum gas (autogas) (#2887).
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelNameLpg;

  /// Localized display name for compressed natural gas (#2887).
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get fuelNameCng;

  /// Localized display name for hydrogen fuel (#2887).
  ///
  /// In en, this message translates to:
  /// **'Hydrogen'**
  String get fuelNameHydrogen;

  /// Localized display name for electric charging (#2887).
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelNameElectric;

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

  /// GPS-only coaching tile (#2058): the driver is cruising downhill with no recent brake event; lifting off would let the car coast more efficiently.
  ///
  /// In en, this message translates to:
  /// **'Lift off'**
  String get coachingGpsLiftOff;

  /// GPS-only coaching tile (#2058): a brake event was detected in the rolling window; reading the road further ahead would let the lift-off start earlier.
  ///
  /// In en, this message translates to:
  /// **'Anticipate'**
  String get coachingGpsAnticipateBrake;

  /// GPS-only coaching tile (#2058): an acceleration event was detected in the rolling window; a gentler ramp uses less fuel.
  ///
  /// In en, this message translates to:
  /// **'Smooth accel'**
  String get coachingGpsSmoothAccel;

  /// One-line GPS coverage verdict on the trip-detail GPS diagnostics card (#3465): the share of the trip's time span the recorded GPS track actually covers, the single longest hole in the track, and its attributed cause. gap is a pre-formatted duration ('3m 42s'); cause is one of the localized gpsCoverageAttr* labels.
  ///
  /// In en, this message translates to:
  /// **'Track covers {pct}% — longest gap {gap} ({cause})'**
  String gpsCoverageSummary(int pct, String gap, String cause);

  /// Variant of the GPS coverage verdict line (#3465) for a hole-free track: no gap exceeded twice the expected fix interval, so there is no longest-gap/cause pair to show.
  ///
  /// In en, this message translates to:
  /// **'Track covers {pct}% — no gaps detected'**
  String gpsCoverageSummaryNoGaps(int pct);

  /// Gap-cause label (#3465): the gap fell inside a stretch where the app was backgrounded on a build without the recording foreground service, so the OS throttled or paused the GPS stream — the dominant field cause of incomplete traces.
  ///
  /// In en, this message translates to:
  /// **'app in background'**
  String get gpsCoverageAttrBackgroundThrottle;

  /// Gap-cause label (#3465): the OS queued GPS fixes and delivered them late in one burst right after the gap, so the receiver was alive but delivery was deferred.
  ///
  /// In en, this message translates to:
  /// **'OS fix batching'**
  String get gpsCoverageAttrOsBatching;

  /// Gap-cause label (#3465): the app's own accuracy/teleport/decimation gates rejected the fixes in this stretch (too noisy to trust for road distance), so the hole is deliberate filtering, not lost signal.
  ///
  /// In en, this message translates to:
  /// **'fixes filtered'**
  String get gpsCoverageAttrGateRejected;

  /// Gap-cause label (#3465): the app was foregrounded and nothing else explains the gap — GPS reception itself dropped (tunnel, parking garage, urban canyon).
  ///
  /// In en, this message translates to:
  /// **'signal loss'**
  String get gpsCoverageAttrSignalLoss;

  /// Gap-cause label (#3465): no verdict was possible — typically an older trip recorded before lifecycle marks were persisted.
  ///
  /// In en, this message translates to:
  /// **'unknown cause'**
  String get gpsCoverageAttrUnknown;

  /// Short actionable hint under the coverage line (#3465) when the longest gap was caused by OS background throttling on a no-foreground-service build.
  ///
  /// In en, this message translates to:
  /// **'The app was in the background without a foreground service, so the system throttled GPS. Keep the screen on while recording, or enable background recording when available.'**
  String get gpsCoverageHintBackgroundThrottle;

  /// Short hint under the coverage line (#3465) when the longest gap was caused by the OS batching fix delivery.
  ///
  /// In en, this message translates to:
  /// **'The system delivered position fixes late in batches; the track filled in afterwards, so little data was actually lost.'**
  String get gpsCoverageHintOsBatching;

  /// Short hint under the coverage line (#3465) when the longest gap was caused by the app's own GPS quality gates rejecting fixes.
  ///
  /// In en, this message translates to:
  /// **'Noisy position fixes in this stretch were filtered out to keep the distance figure honest.'**
  String get gpsCoverageHintGateRejected;

  /// Short hint under the coverage line (#3465) when the longest gap was caused by genuine GPS signal loss while the app was foregrounded.
  ///
  /// In en, this message translates to:
  /// **'GPS reception dropped — this usually means a tunnel, parking garage or dense urban canyon.'**
  String get gpsCoverageHintSignalLoss;

  /// Short hint under the coverage line (#3465) when the longest gap could not be attributed (typically a trip recorded before lifecycle marks existed).
  ///
  /// In en, this message translates to:
  /// **'This trip carries no app-lifecycle information for the gap, so the cause can\'t be determined.'**
  String get gpsCoverageHintUnknown;

  /// Gap attribution label: GPS gap coinciding with an OBD2 reconnect episode (#3465)
  ///
  /// In en, this message translates to:
  /// **'OBD2 reconnection interference'**
  String get gpsCoverageAttrLinkRecovery;

  /// Hint for the linkRecovery gap attribution (#3465)
  ///
  /// In en, this message translates to:
  /// **'The gap coincides with an OBD2 reconnection episode — the adapter link was recovering while GPS ingest stalled. Fixing the adapter connection also fixes the track.'**
  String get gpsCoverageHintLinkRecovery;

  /// Title of the read-only GPS sample diagnostics card on the Trip detail screen — surfaces the cadence + lifecycle-state info captured by #1458 phase 2 so the user can verify that the OS did not throttle the GPS stream during phone-sleep, ahead of deciding whether phase 3 (foreground service) is needed.
  ///
  /// In en, this message translates to:
  /// **'GPS sampling diagnostics'**
  String get gpsDiagnosticsTitle;

  /// Collapsed-header summary line of the GPS diagnostics card (#1458 phase 2.5). At-a-glance triple: total sample count, total trip time span, and the number of GPS gaps detected (intervals at least 3x the median). count and span are pre-formatted strings.
  ///
  /// In en, this message translates to:
  /// **'{count} samples · {span} · {gaps, plural, =0{no gaps} =1{1 gap} other{{gaps} gaps}}'**
  String gpsDiagnosticsHeader(String count, String span, int gaps);

  /// Expanded-body line on the GPS diagnostics card (#1458 phase 2.5) showing the median sample-to-sample interval (rounded to 100ms). A healthy ~1000ms median says the OS is not throttling; a 5000ms+ median means the GPS stream paused during sleep.
  ///
  /// In en, this message translates to:
  /// **'Median interval: {ms} ms'**
  String gpsDiagnosticsCadence(int ms);

  /// Subtle one-line explanation at the bottom of the GPS diagnostics card (#1458 phase 2.5) reminding the user why this card exists — they probably opened the trip detail to look at consumption, not GPS plumbing.
  ///
  /// In en, this message translates to:
  /// **'Captured during recording to verify GPS cadence under phone-sleep.'**
  String get gpsDiagnosticsExplain;

  /// Expanded-body line on the GPS diagnostics card (#1458 phase 2.5 / #2765) reporting the single largest interval observed between two GPS fixes, in whole seconds — the worst-case throttling moment of the trip.
  ///
  /// In en, this message translates to:
  /// **'Largest gap: {seconds} s'**
  String gpsDiagnosticsLargestGap(int seconds);

  /// Localized label for the 'resumed' app-lifecycle state in the GPS diagnostics lifecycle breakdown (#2765). The app was in the foreground and interactive when these GPS fixes were captured.
  ///
  /// In en, this message translates to:
  /// **'Resumed'**
  String get gpsLifecycleResumed;

  /// Localized label for the 'paused' app-lifecycle state in the GPS diagnostics lifecycle breakdown (#2765). The app was backgrounded (Android) when these GPS fixes were captured.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get gpsLifecyclePaused;

  /// Localized label for the 'inactive' app-lifecycle state in the GPS diagnostics lifecycle breakdown (#2765). The app was transitioning / not receiving input (e.g. iOS app switcher) when these GPS fixes were captured.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get gpsLifecycleInactive;

  /// Per-KPI verdict badge on the GPS-efficiency card (#2795): gentle, energy-light driving for this metric (RPA / PKE / VAPOS / coasting). Shown in the positive colour.
  ///
  /// In en, this message translates to:
  /// **'Efficient'**
  String get gpsKpiVerdictGood;

  /// Per-KPI verdict badge on the GPS-efficiency card (#2795): typical mixed driving for this metric — neither notably efficient nor wasteful.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get gpsKpiVerdictModerate;

  /// Per-KPI verdict badge on the GPS-efficiency card (#2795): energy-heavy driving for this metric (hard acceleration, or — for coasting — very little coasting). Shown in the warning colour.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get gpsKpiVerdictAggressive;

  /// One-line interpretation under the GPS-efficiency KPIs (#2795) when the metrics overall read efficient: praise mirroring the driving-score verdict line.
  ///
  /// In en, this message translates to:
  /// **'Smooth, energy-light driving — this is what efficient looks like.'**
  String get gpsKpiInterpretationGood;

  /// One-line interpretation under the GPS-efficiency KPIs (#2795) when the metrics overall read moderate: neutral guidance toward gentler acceleration.
  ///
  /// In en, this message translates to:
  /// **'Fairly typical driving — a little smoother on the throttle would save more.'**
  String get gpsKpiInterpretationModerate;

  /// One-line interpretation under the GPS-efficiency KPIs (#2795) when the metrics overall read aggressive: actionable guidance to accelerate gentler and coast more.
  ///
  /// In en, this message translates to:
  /// **'Energy-heavy driving — easing off the accelerator and coasting more would cut fuel use.'**
  String get gpsKpiInterpretationAggressive;

  /// Maturity tier label (#2082) — GPS calibration matrix has had fewer than 3 fill-up reconciliations OR residual variance > 1.5. Estimates are provisional.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get gpsMatrixMaturityCold;

  /// Maturity tier label (#2082) — GPS matrix has 3–7 reconciliations with variance ≤ 1.5. Usable but still settling.
  ///
  /// In en, this message translates to:
  /// **'Warming'**
  String get gpsMatrixMaturityWarming;

  /// Maturity tier label (#2082) — GPS matrix has 8+ reconciliations with variance ≤ 0.5. Estimates trustworthy within ~2 %.
  ///
  /// In en, this message translates to:
  /// **'Converged'**
  String get gpsMatrixMaturityConverged;

  /// Tooltip explaining the cold tier.
  ///
  /// In en, this message translates to:
  /// **'GPS matrix is still warming up ({count} fill-up refinements so far). Estimates are provisional.'**
  String gpsMatrixMaturityColdTooltip(int count);

  /// Tooltip explaining the warming tier.
  ///
  /// In en, this message translates to:
  /// **'GPS matrix is converging ({count} fill-ups). Estimates are usable but may drift a few %.'**
  String gpsMatrixMaturityWarmingTooltip(int count);

  /// Tooltip explaining the converged tier.
  ///
  /// In en, this message translates to:
  /// **'GPS matrix has converged ({count} fill-ups). Estimates are within ~2 % of real-world burn.'**
  String gpsMatrixMaturityConvergedTooltip(int count);

  /// Info tooltip on the recording-screen Average-consumption card (#2391) explaining that the leading '~' marks a GPS-modelled estimate (not a measured fuel-sensor reading) and that accuracy improves with calibration maturity.
  ///
  /// In en, this message translates to:
  /// **'GPS estimate (~) — no fuel sensor on this trip. The figure is modelled from speed and your vehicle\'s calibration; accuracy improves as the matrix matures.'**
  String get tripAvgGpsEstimateTooltip;

  /// Title of the GPS-only trip-detail panel (#2796) that replaces the engine throttle/RPM card on dongle-less trips, showing the speed-band and movement-phase split derived from the GPS track.
  ///
  /// In en, this message translates to:
  /// **'How you used the road'**
  String get gpsRoadUseCardTitle;

  /// Section header on the road-use panel (#2796) above the speed-band bars (stopped / town / cruise / fast).
  ///
  /// In en, this message translates to:
  /// **'Where you spent your time'**
  String get gpsRoadUseSpeedSection;

  /// Speed-band bar label on the road-use panel (#2796): time spent stationary or crawling below 5 km/h. The 5 km/h edge matches the GPS feature integration.
  ///
  /// In en, this message translates to:
  /// **'Stopped (<5 km/h)'**
  String get gpsRoadUseSpeedIdle;

  /// Speed-band bar label on the road-use panel (#2796): urban / start-stop driving between 5 and 50 km/h.
  ///
  /// In en, this message translates to:
  /// **'Town (5–50 km/h)'**
  String get gpsRoadUseSpeedLow;

  /// Speed-band bar label on the road-use panel (#2796): extra-urban cruising between 50 and 110 km/h.
  ///
  /// In en, this message translates to:
  /// **'Cruise (50–110 km/h)'**
  String get gpsRoadUseSpeedCruise;

  /// Speed-band bar label on the road-use panel (#2796): highway driving at or above 110 km/h, the fuel-cost band.
  ///
  /// In en, this message translates to:
  /// **'Fast (≥110 km/h)'**
  String get gpsRoadUseSpeedHigh;

  /// Section header on the road-use panel (#2796) above the movement-phase bars (accelerating / holding speed / coasting).
  ///
  /// In en, this message translates to:
  /// **'How you moved'**
  String get gpsRoadUsePhaseSection;

  /// Movement-phase bar label on the road-use panel (#2796): share of moving time spent speeding up (putting energy in).
  ///
  /// In en, this message translates to:
  /// **'Accelerating'**
  String get gpsRoadUsePhaseAccel;

  /// Movement-phase bar label on the road-use panel (#2796): share of moving time spent at a roughly constant speed.
  ///
  /// In en, this message translates to:
  /// **'Holding speed'**
  String get gpsRoadUsePhaseSteady;

  /// Movement-phase bar label on the road-use panel (#2796): share of moving time spent coasting (foot off, gentle deceleration), the eco-positive phase.
  ///
  /// In en, this message translates to:
  /// **'Coasting'**
  String get gpsRoadUsePhaseCoast;

  /// Trailing percent share for a road-use bar (#2796), e.g. "42%". Language-neutral percent mask.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String gpsRoadUseShare(String pct);

  /// Positive coaching line on the road-use panel (#2796), shown in green when the coasting share is high (≥ ~25%): praises the driver for coasting / engine-braking instead of accelerating then braking.
  ///
  /// In en, this message translates to:
  /// **'Lots of coasting — letting the car roll instead of braking saves fuel. Nice.'**
  String get gpsRoadUseCoastPraise;

  /// Footnote on the road-use panel (#2796) clarifying the shares come from the GPS speed/position track (no OBD2 dongle needed).
  ///
  /// In en, this message translates to:
  /// **'From your GPS track'**
  String get gpsRoadUseSource;

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

  /// No description provided for @semanticsNavigateTo.
  ///
  /// In en, this message translates to:
  /// **'Navigate to {name}'**
  String semanticsNavigateTo(String name);

  /// No description provided for @semanticsRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from favorites'**
  String semanticsRemoveFromFavorites(String name);

  /// No description provided for @showOnMapSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Show stations on map'**
  String get showOnMapSemanticLabel;

  /// No description provided for @searchResultsSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResultsSemanticLabel;

  /// No description provided for @searchCriteriaSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Search criteria summary. Tap to edit.'**
  String get searchCriteriaSemanticLabel;

  /// No description provided for @noFavoritesSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Tap the star on a station to save it as a favorite.'**
  String get noFavoritesSemanticLabel;

  /// No description provided for @stationStatusSemantic.
  ///
  /// In en, this message translates to:
  /// **'{open, select, true{Station is open} false{Station is closed} other{Station is closed}}'**
  String stationStatusSemantic(String open);

  /// No description provided for @countryChipSemantic.
  ///
  /// In en, this message translates to:
  /// **'{selected, select, true{Country {name}, selected} false{Country {name}} other{Country {name}}}'**
  String countryChipSemantic(String name, String selected);

  /// No description provided for @languageChipSemantic.
  ///
  /// In en, this message translates to:
  /// **'{selected, select, true{Language {name}, selected} false{Language {name}} other{Language {name}}}'**
  String languageChipSemantic(String name, String selected);

  /// No description provided for @sortBySemantic.
  ///
  /// In en, this message translates to:
  /// **'{selected, select, true{Sort by {option}, selected} false{Sort by {option}} other{Sort by {option}}}'**
  String sortBySemantic(String option, String selected);

  /// No description provided for @fuelTypeSemantic.
  ///
  /// In en, this message translates to:
  /// **'{selected, select, true{Fuel type {type}, selected} false{Fuel type {type}} other{Fuel type {type}}}'**
  String fuelTypeSemantic(String type, String selected);

  /// No description provided for @evChargingStationSemantic.
  ///
  /// In en, this message translates to:
  /// **'EV charging station {name}, {power} kW'**
  String evChargingStationSemantic(String name, int power);

  /// No description provided for @shieldIllustrationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Privacy shield with fuel drop'**
  String get shieldIllustrationSemantic;

  /// No description provided for @globeIllustrationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Globe with fuel station markers'**
  String get globeIllustrationSemantic;

  /// No description provided for @fuelPumpIllustrationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Fuel pump with price ticker'**
  String get fuelPumpIllustrationSemantic;

  /// No description provided for @countryInfoSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, data source: {provider}, {keyRequirement}, fuel types: {fuelTypes}'**
  String countryInfoSemantic(
    String name,
    String provider,
    String keyRequirement,
    String fuelTypes,
  );

  /// No description provided for @countryInfoApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key required'**
  String get countryInfoApiKeyRequired;

  /// No description provided for @countryInfoNoKeyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Free, no key needed'**
  String get countryInfoNoKeyNeeded;

  /// No description provided for @countryInfoDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data: {provider}'**
  String countryInfoDataSource(String provider);

  /// No description provided for @countryInfoFuelTypes.
  ///
  /// In en, this message translates to:
  /// **'Fuel types: {fuelTypes}'**
  String countryInfoFuelTypes(String fuelTypes);

  /// No description provided for @countryInfoDemoSource.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get countryInfoDemoSource;

  /// No description provided for @anonKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Anon Key'**
  String get anonKeyLabel;

  /// No description provided for @anonKeyHideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide key'**
  String get anonKeyHideTooltip;

  /// No description provided for @anonKeyShowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show key to verify'**
  String get anonKeyShowTooltip;

  /// No description provided for @anonKeyTooLong.
  ///
  /// In en, this message translates to:
  /// **'Key is too long ({length} chars) — check for extra text'**
  String anonKeyTooLong(int length);

  /// No description provided for @anonKeyLooksCorrect.
  ///
  /// In en, this message translates to:
  /// **'Key looks correct ({length} chars)'**
  String anonKeyLooksCorrect(int length);

  /// No description provided for @anonKeyShouldBeJwt.
  ///
  /// In en, this message translates to:
  /// **'Key should be a JWT (header.payload.signature)'**
  String get anonKeyShouldBeJwt;

  /// No description provided for @anonKeyMayBeTruncated.
  ///
  /// In en, this message translates to:
  /// **'Key may be truncated ({length} of ~208 expected chars)'**
  String anonKeyMayBeTruncated(int length);

  /// No description provided for @anonKeyExceedsMax.
  ///
  /// In en, this message translates to:
  /// **'Key exceeds maximum length'**
  String get anonKeyExceedsMax;

  /// No description provided for @qrShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your database'**
  String get qrShareTitle;

  /// No description provided for @qrShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Others can scan this QR code to connect'**
  String get qrShareSubtitle;

  /// No description provided for @qrShareCopyAsText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get qrShareCopyAsText;

  /// No description provided for @authInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Why create an account?'**
  String get authInfoTitle;

  /// No description provided for @authInfoBenefit1.
  ///
  /// In en, this message translates to:
  /// **'• Sync favorites, ratings, alerts, ignored stations, saved routes, vehicles, fuel logs and trips across devices'**
  String get authInfoBenefit1;

  /// No description provided for @authInfoBenefit2.
  ///
  /// In en, this message translates to:
  /// **'• Prepare a route on your phone, use it in your car'**
  String get authInfoBenefit2;

  /// No description provided for @authInfoBenefit3.
  ///
  /// In en, this message translates to:
  /// **'• No data is shared with third parties'**
  String get authInfoBenefit3;

  /// No description provided for @authInfoBenefit4.
  ///
  /// In en, this message translates to:
  /// **'• You can delete your account at any time'**
  String get authInfoBenefit4;

  /// No description provided for @privacyLocalDataEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing stored yet. Add a favorite or set a price alert to see entries here.'**
  String get privacyLocalDataEmpty;

  /// No description provided for @privacyHideEmptyRows.
  ///
  /// In en, this message translates to:
  /// **'Hide empty rows'**
  String get privacyHideEmptyRows;

  /// No description provided for @privacyShowEmptyRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show {count} empty row} other{Show {count} empty rows}}'**
  String privacyShowEmptyRows(int count);

  /// No description provided for @apiKeySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'API key setup (optional)'**
  String get apiKeySetupTitle;

  /// No description provided for @apiKeySetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Register for a free API key, or skip to explore the app with demo data.'**
  String get apiKeySetupDescription;

  /// No description provided for @apiKeyRegistrationButton.
  ///
  /// In en, this message translates to:
  /// **'{provider} Registration'**
  String apiKeyRegistrationButton(String provider);

  /// No description provided for @apiKeyTerms.
  ///
  /// In en, this message translates to:
  /// **'By entering an API key you accept the terms of {provider}. Data redistribution is prohibited.'**
  String apiKeyTerms(String provider);

  /// No description provided for @calculatorDistanceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 150'**
  String get calculatorDistanceHint;

  /// No description provided for @calculatorConsumptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 7.0'**
  String get calculatorConsumptionHint;

  /// No description provided for @calculatorPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1.899'**
  String get calculatorPriceHint;

  /// No description provided for @routeStrategyLabel.
  ///
  /// In en, this message translates to:
  /// **'Strategy:'**
  String get routeStrategyLabel;

  /// No description provided for @routeStrategyUniform.
  ///
  /// In en, this message translates to:
  /// **'Uniform'**
  String get routeStrategyUniform;

  /// No description provided for @routeStrategyBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get routeStrategyBalanced;

  /// No description provided for @glideCoachBetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Glide-coach beta (experimental)'**
  String get glideCoachBetaTitle;

  /// No description provided for @glideCoachBetaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtle haptic when slowing down ahead of a red light. Off by default — distraction risk.'**
  String get glideCoachBetaSubtitle;

  /// No description provided for @consentSyncTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync trip recordings'**
  String get consentSyncTripsTitle;

  /// No description provided for @consentSyncTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Back up OBD2 + GPS trips to TankSync. Cross-device, opt-in.'**
  String get consentSyncTripsSubtitle;

  /// No description provided for @consentSyncTripsDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Enable Cloud Sync above to back up trips.'**
  String get consentSyncTripsDisabledHint;

  /// No description provided for @consentSyncTripsAnonymousHint.
  ///
  /// In en, this message translates to:
  /// **'Trips back up under this device\'s anonymous account. Sign in with an email to reach them from other devices.'**
  String get consentSyncTripsAnonymousHint;

  /// No description provided for @consentHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get consentHideDetails;

  /// No description provided for @consentShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get consentShowDetails;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// No description provided for @invalidLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get invalidLinkTitle;

  /// No description provided for @invalidLinkBody.
  ///
  /// In en, this message translates to:
  /// **'The link \"{path}\" is not valid.'**
  String invalidLinkBody(String path);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Title of the trip-detail card (#2792) that surfaces the phone-IMU-detected hard-acceleration / hard-braking / sharp-cornering episode counts on a GPS-only (dongle-less) trip.
  ///
  /// In en, this message translates to:
  /// **'Acceleration & braking'**
  String get accelBrakeCardTitle;

  /// Row label on the acceleration & braking card (#2792): count (and per-km) of confirmed hard-acceleration episodes detected by the phone's accelerometer.
  ///
  /// In en, this message translates to:
  /// **'Hard accelerations'**
  String get accelBrakeHardAccel;

  /// Row label on the acceleration & braking card (#2792): count (and per-km) of confirmed hard-braking episodes.
  ///
  /// In en, this message translates to:
  /// **'Hard braking'**
  String get accelBrakeHardBrake;

  /// Row label on the acceleration & braking card (#2792): count (and per-km) of sharp-cornering episodes (high lateral acceleration + yaw).
  ///
  /// In en, this message translates to:
  /// **'Sharp corners'**
  String get accelBrakeSharpCorner;

  /// Footnote on the acceleration & braking card (#2792) clarifying the counts come from the phone's inertial sensors (no OBD2 dongle needed).
  ///
  /// In en, this message translates to:
  /// **'From the phone\'s motion sensors'**
  String get accelBrakeSource;

  /// Trip-detail lesson headline (#2793) for hard braking detected by the phone IMU on a GPS-only trip. Placeholder is the integer episode count.
  ///
  /// In en, this message translates to:
  /// **'{count} hard braking events'**
  String lessonHardBrake(String count);

  /// Advice sub-line under the hard-braking lesson (#2793).
  ///
  /// In en, this message translates to:
  /// **'Anticipate stops and ease off the accelerator earlier — hard braking throws away the fuel you just spent getting up to speed.'**
  String get lessonAdviceHardBrake;

  /// Trip-detail lesson headline (#2793) for sharp cornering detected by the phone IMU. Placeholder is the integer episode count.
  ///
  /// In en, this message translates to:
  /// **'{count} sharp corners'**
  String lessonSharpCornering(String count);

  /// Advice sub-line under the sharp-cornering lesson (#2793).
  ///
  /// In en, this message translates to:
  /// **'Slow before the bend, not in it — hard cornering scrubs off speed you then have to rebuild.'**
  String get lessonAdviceSharpCornering;

  /// Title of the GDPR location-consent dialog (#2306). Replaces the legacy _ConsentTexts map that only covered 10 of 23 locales for the title.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get locationConsentTitle;

  /// Bold lead sentence of the GDPR location-consent dialog explaining why location is requested (#2306).
  ///
  /// In en, this message translates to:
  /// **'This app would like to use your location to find fuel stations near you.'**
  String get locationConsentSubtitle;

  /// Heading above the three transparency bullets in the GDPR location-consent dialog (#2306).
  ///
  /// In en, this message translates to:
  /// **'What happens with your location data:'**
  String get locationConsentWhatHappens;

  /// First transparency bullet in the GDPR location-consent dialog: coordinates leave the device only to query the fuel-price API (#2306).
  ///
  /// In en, this message translates to:
  /// **'Your coordinates are sent to the fuel price API to find nearby stations.'**
  String get locationConsentBulletApi;

  /// Second transparency bullet in the GDPR location-consent dialog: there is no backend that stores the user's location (#2306).
  ///
  /// In en, this message translates to:
  /// **'Your location is not stored on any server — there is no server.'**
  String get locationConsentBulletNoServer;

  /// Third transparency bullet in the GDPR location-consent dialog: location is never used for ads, analytics or tracking (#2306).
  ///
  /// In en, this message translates to:
  /// **'Location data is not used for advertising, analytics, or tracking.'**
  String get locationConsentBulletNoTracking;

  /// Notice in the GDPR location-consent dialog explaining how to revoke the grant and the postal-code alternative (#2306).
  ///
  /// In en, this message translates to:
  /// **'You can revoke location access anytime in system settings. Alternatively, search by postal code.'**
  String get locationConsentRevoke;

  /// Legal-basis footnote of the GDPR location-consent dialog. 'GDPR' is the established English/EU abbreviation; the article reference is the legal citation (#2306).
  ///
  /// In en, this message translates to:
  /// **'Legal basis: Art. 6(1)(a) GDPR (Consent)'**
  String get locationConsentLegalBasis;

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

  /// Row label on the monthly-insights card for total metres climbed across the month (#2697 P3) — now trustworthy that altitude is guarded + persisted. Rendered only when at least one trip carried altitude samples.
  ///
  /// In en, this message translates to:
  /// **'Climbed'**
  String get consumptionMonthlyClimbLabel;

  /// Title of the card on the vehicle settings screen that surfaces the connected OBD2 adapter's runtime capability tier (#1401 phase 6).
  ///
  /// In en, this message translates to:
  /// **'Adapter capabilities'**
  String get obd2CapabilitySectionTitle;

  /// Tier label for adapters that only support the OBD-II standard mode 01-09 PIDs — cheap clones / ELM327 v1.x (#1401 phase 6).
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get obd2CapabilityStandardOnly;

  /// Tier label for adapters that can read manufacturer-specific PIDs via header switching — genuine ELM327 v2.2+ (#1401 phase 6).
  ///
  /// In en, this message translates to:
  /// **'OEM PIDs'**
  String get obd2CapabilityOemPids;

  /// Tier label for adapters that support listen-mode CAN bus access — STN-chip family, OBDLink MX+/LX/CX/EX (#1401 phase 6).
  ///
  /// In en, this message translates to:
  /// **'Full CAN'**
  String get obd2CapabilityFullCan;

  /// Informational one-liner shown only when the connected adapter is on the standardOnly tier (#1401 phase 6). Points users at the OBDLink STN-chip family without an affiliate link or purchase button.
  ///
  /// In en, this message translates to:
  /// **'For exact litres-in-tank on Peugeot/Citroën, the app supports OBDLink MX+/LX/CX (STN chip).'**
  String get obd2CapabilityUpgradeHintStandard;

  /// Snackbar shown when the user has flipped the in-app OBD2 fuel-rate diagnostic overlay ON via the hidden 5-tap gesture on the trip-recording screen title (#1395).
  ///
  /// In en, this message translates to:
  /// **'OBD2 diagnostic overlay enabled'**
  String get obd2DebugOverlayEnabledSnack;

  /// Snackbar shown when the user has flipped the in-app OBD2 fuel-rate diagnostic overlay OFF via the hidden 5-tap gesture (#1395).
  ///
  /// In en, this message translates to:
  /// **'OBD2 diagnostic overlay disabled'**
  String get obd2DebugOverlayDisabledSnack;

  /// Button on the in-app OBD2 fuel-rate diagnostic overlay that empties the recorded breadcrumb list (#1395).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get obd2DebugOverlayClearButton;

  /// Button on the in-app OBD2 fuel-rate diagnostic overlay that hides the overlay by disabling the persisted flag (#1395).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get obd2DebugOverlayCloseButton;

  /// Title shown at the top of the in-app OBD2 fuel-rate diagnostic overlay panel (#1395).
  ///
  /// In en, this message translates to:
  /// **'OBD2 breadcrumbs'**
  String get obd2DebugOverlayTitle;

  /// Label and tooltip for the button on the in-app OBD2 diagnostic overlay that exports the OBD2 connect/drop/reconnect trace as plain text to the OS share sheet, so a developer can analyse a failed recording session (#1920).
  ///
  /// In en, this message translates to:
  /// **'Share diagnostic log'**
  String get obd2DiagnosticShareLabel;

  /// Title of the opt-in checkbox in the Trips (OBD2) settings sub-section that turns on detailed OBD2 session recording (#1925).
  ///
  /// In en, this message translates to:
  /// **'OBD2 debug logging'**
  String get obd2DebugLoggingTitle;

  /// Helper text under the OBD2 debug-logging checkbox, explaining what gets recorded and that the feature is off unless opted into (#1925).
  ///
  /// In en, this message translates to:
  /// **'Record each OBD2 session — connection, handshake, data gaps and reconnects — to an exportable XML log. Off by default.'**
  String get obd2DebugLoggingSubtitle;

  /// Label and tooltip for the button on the in-app OBD2 diagnostic overlay that exports the most recent OBD2 debug session as an XML file to the OS share sheet (#1925).
  ///
  /// In en, this message translates to:
  /// **'Share OBD2 session log'**
  String get obd2DebugSessionShareLabel;

  /// Title of the read-only OBD2 communication-health diagnostics card on the Trip detail screen + the dev-tools screen (#2470/#2471, Epic #2463). The OBD2 analogue of the GPS sampling diagnostics card. Only visible in Developer / Debug mode.
  ///
  /// In en, this message translates to:
  /// **'OBD2 communication health'**
  String get obd2DiagnosticsTitle;

  /// Collapsed-header summary line of the OBD2 diagnostics card (#2470). At-a-glance triple: overall session completeness percentage, active-duty-cycle percentage, and the number of detected mid-session link drops. percent and duty are pre-formatted integers.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete · {duty}% duty · {drops, plural, =0{no drops} =1{1 drop} other{{drops} drops}}'**
  String obd2DiagnosticsHeader(String percent, String duty, int drops);

  /// Section header above the adapter-identity rows (redacted MAC, ELM firmware version, protocol digit, MTU, warm/cold start, capability tier) on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get obd2DiagnosticsAdapterSection;

  /// Section header above the connection-lifecycle rows (attempts, successes, drops, silent/visible reconnects, time-to-connect percentiles) on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Connection lifecycle'**
  String get obd2DiagnosticsConnectionSection;

  /// Section header above the per-PID outcome table (polled/ok/no-data/timeout/error counts + p50/p95 round-trip latency + effective-vs-target Hz) on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Per-PID outcomes'**
  String get obd2DiagnosticsPidSection;

  /// Section header above the per-reconnect-attempt + session-state-transition telemetry rows (attempt count, successes, failure-reason tally, typed disconnects, GPS-fallback marker) on the OBD2 diagnostics card (#2905, Epic #2904).
  ///
  /// In en, this message translates to:
  /// **'Reconnect telemetry'**
  String get obd2DiagnosticsReconnectSection;

  /// Reconnect-telemetry summary line on the OBD2 diagnostics card (#2905). attempts is the per-attempt-timeline row count; successes the attempts that re-established a link; transitions the session-state-transition marker count; disconnects the Obd2DisconnectedException (typed drop) count.
  ///
  /// In en, this message translates to:
  /// **'{attempts} reconnect attempts · {successes} ok · {transitions} transitions · {disconnects} typed drops'**
  String obd2DiagnosticsReconnectAttemptsLine(
    int attempts,
    int successes,
    int transitions,
    int disconnects,
  );

  /// One failed-reconnect-attempt reason-tally row on the OBD2 diagnostics card (#2905). reason is the low-cardinality failure tag (rfcomm-open-fail / gatt-133 / device-not-connected / timeout / other), count how many attempts failed for that reason this session.
  ///
  /// In en, this message translates to:
  /// **'{reason}: {count}'**
  String obd2DiagnosticsReconnectReasonLine(String reason, int count);

  /// Marker line on the OBD2 diagnostics card (#2905) shown when GPS-only fallback recording was activated during the session — the OBD2 link dropped but GPS kept the trip recording.
  ///
  /// In en, this message translates to:
  /// **'GPS-only fallback activated this session.'**
  String get obd2DiagnosticsFallbackLine;

  /// Section header above the scheduler-health rows (achieved tick-rate, back-pressure skips, governor demotions, starvation) on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Scheduler health'**
  String get obd2DiagnosticsSchedulerSection;

  /// Section header above the completeness rollup rows (overall % + per-tier %) on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Completeness'**
  String get obd2DiagnosticsCompletenessSection;

  /// Section header above the discovered-supported tri-state counts (supported / unsupported / unknown) on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Discovered-supported PIDs'**
  String get obd2DiagnosticsSupportSection;

  /// Section header above the per-tick fuel-resolution-tier distribution + downgrade-suspicion rollup on the OBD2 diagnostics card (#2470).
  ///
  /// In en, this message translates to:
  /// **'Fuel-tier rollup'**
  String get obd2DiagnosticsFuelSection;

  /// Adapter-identity line on the OBD2 diagnostics card (#2470). mac is the redacted MAC, firmware the ELM banner version, protocol the auto-detected OBD protocol digit, mtu the negotiated BLE ATT MTU. All pre-formatted strings (an em-dash placeholder is supplied for any unknown field).
  ///
  /// In en, this message translates to:
  /// **'{mac} · {firmware} · protocol {protocol} · MTU {mtu}'**
  String obd2DiagnosticsAdapterIdentity(
    String mac,
    String firmware,
    String protocol,
    String mtu,
  );

  /// Connection-lifecycle summary line on the OBD2 diagnostics card (#2470). attempts/successes/drops are counts; p50/p95 are pre-formatted time-to-connect latency strings (em-dash when unknown).
  ///
  /// In en, this message translates to:
  /// **'{attempts} attempts · {successes} ok · {drops} drops · time-to-connect p50 {p50} / p95 {p95}'**
  String obd2DiagnosticsConnectionLine(
    int attempts,
    int successes,
    int drops,
    String p50,
    String p95,
  );

  /// Reconnect-breakdown line on the OBD2 diagnostics card (#2470): silent reconnects recovered the link without the user seeing a disconnect; visible reconnects surfaced a disconnect first.
  ///
  /// In en, this message translates to:
  /// **'Reconnects: {silent} silent · {visible} visible'**
  String obd2DiagnosticsReconnectLine(int silent, int visible);

  /// Scheduler-health summary line on the OBD2 diagnostics card (#2470). tickRate is the pre-formatted achieved tick-rate in Hz; skips and demotions are counts.
  ///
  /// In en, this message translates to:
  /// **'{tickRate} Hz tick · {skips} back-pressure skips · {demotions} demotions'**
  String obd2DiagnosticsSchedulerLine(
    String tickRate,
    int skips,
    int demotions,
  );

  /// Warning line shown on the OBD2 diagnostics card (#2470) when the scheduler reported starvation: the dynamics tier dropped below its protected reads-per-second floor on a slow link.
  ///
  /// In en, this message translates to:
  /// **'Dynamics tier starved — RPM / speed fell below the governor floor.'**
  String get obd2DiagnosticsStarved;

  /// Overall-completeness line on the OBD2 diagnostics card (#2470). percent is overall session completeness, duty the active-duty-cycle, both pre-formatted integers.
  ///
  /// In en, this message translates to:
  /// **'Overall {percent}% · active duty {duty}%'**
  String obd2DiagnosticsCompletenessLine(String percent, String duty);

  /// Per-tier completeness row on the OBD2 diagnostics card (#2470). tier is the cadence-tier name (dynamics / mixture / slowCorrection / thermalContext), percent the pre-formatted per-tier completeness integer.
  ///
  /// In en, this message translates to:
  /// **'{tier}: {percent}%'**
  String obd2DiagnosticsTierLine(String tier, String percent);

  /// Discovered-supported tri-state counts line on the OBD2 diagnostics card (#2470). supported/unsupported are PIDs the resolver confirmed; unknown is every command when the supported-PID probe never ran (probe-less clone / blind session).
  ///
  /// In en, this message translates to:
  /// **'{supported} supported · {unsupported} unsupported · {unknown} unknown'**
  String obd2DiagnosticsSupportLine(
    int supported,
    int unsupported,
    int unknown,
  );

  /// Fuel-downgrade rollup line on the OBD2 diagnostics card (#2470): how many fuel-rate samples tripped a sanity flag (suspicious-low / 5E-vs-MAF divergent) out of the total seen this session.
  ///
  /// In en, this message translates to:
  /// **'Suspicious {suspicious} of {total} samples'**
  String obd2DiagnosticsFuelLine(int suspicious, int total);

  /// One per-PID row on the OBD2 diagnostics card (#2470). pid is the poll command (e.g. 010C); polled/ok/noData/timeout/error are the 5-way outcome counts; p50/p95 the round-trip latency percentiles; effectiveHz/targetHz the achieved-vs-target refresh rate (pre-formatted strings). ND = no-data, TO = timeout.
  ///
  /// In en, this message translates to:
  /// **'{pid}: {polled} polled · {ok} ok · {noData} ND · {timeout} TO · {error} err · p50 {p50} / p95 {p95} ms · {effectiveHz}/{targetHz} Hz'**
  String obd2DiagnosticsPidRow(
    String pid,
    int polled,
    int ok,
    int noData,
    int timeout,
    int error,
    int p50,
    int p95,
    String effectiveHz,
    String targetHz,
  );

  /// Section header above the ELM327 dongle initialization-handshake transcript (the timed ATZ/ATE0/… command→response lines) on the OBD2 diagnostics card (#2511, Epic #2463).
  ///
  /// In en, this message translates to:
  /// **'Dongle init transcript'**
  String get obd2DiagnosticsInitSection;

  /// Summary header above the init-transcript lines on the OBD2 diagnostics card (#2511). protocol is the auto-detected OBD protocol digit; start is the localised warm/cold word; firmware is the ELM banner version; tier is the firmware capability-tier name; pids is the count of discovered-supported PIDs. All pre-formatted (an em-dash is supplied for any unknown field).
  ///
  /// In en, this message translates to:
  /// **'Protocol {protocol} · {start} · firmware {firmware} · {tier} · {pids} PIDs'**
  String obd2DiagnosticsInitHeader(
    String protocol,
    String start,
    String firmware,
    String tier,
    int pids,
  );

  /// One init-handshake transcript line on the OBD2 diagnostics card (#2511): the AT/OBD command sent, an arrow, the redacted reply, and the round-trip latency in milliseconds. cmd and response are raw adapter data (AT commands / hex replies) shown verbatim.
  ///
  /// In en, this message translates to:
  /// **'{cmd} → {response} ({latency} ms)'**
  String obd2DiagnosticsInitLine(String cmd, String response, int latency);

  /// Word for a warm (already-initialised, fast-path) adapter start in the init-transcript header on the OBD2 diagnostics card (#2511).
  ///
  /// In en, this message translates to:
  /// **'warm'**
  String get obd2DiagnosticsInitWarm;

  /// Word for a cold (full-handshake) adapter start in the init-transcript header on the OBD2 diagnostics card (#2511).
  ///
  /// In en, this message translates to:
  /// **'cold'**
  String get obd2DiagnosticsInitCold;

  /// Label for the action on the dev-tools OBD2 communication-health screen (#2511) that copies only the dongle-init handshake (adapter identity + init transcript + supported PIDs) to the clipboard as JSON, without the full per-PID/session payload.
  ///
  /// In en, this message translates to:
  /// **'Copy init transcript only'**
  String get obd2HealthCopyInitTranscript;

  /// Empty-state line on the OBD2 diagnostics card / screen (#2470/#2471) shown when Developer mode is off or no diagnostics session has been captured yet.
  ///
  /// In en, this message translates to:
  /// **'No OBD2 session recorded yet — connect an adapter and record a trip with Developer mode on.'**
  String get obd2DiagnosticsEmpty;

  /// Subtle one-line explanation at the bottom of the OBD2 diagnostics card (#2470) reminding the developer why the card exists and that it is gated on Developer mode.
  ///
  /// In en, this message translates to:
  /// **'Captured while recording to debug the dongle↔app communication — only collected in Developer mode.'**
  String get obd2DiagnosticsExplain;

  /// AppBar title of the dev-tools 'OBD2 Communication Health' screen (#2471), gated on Developer / Debug mode.
  ///
  /// In en, this message translates to:
  /// **'OBD2 communication health'**
  String get obd2HealthScreenTitle;

  /// Label of the Developer-tools menu row that opens the OBD2 communication-health screen (#2471).
  ///
  /// In en, this message translates to:
  /// **'OBD2 communication health'**
  String get obd2HealthNavLabel;

  /// Section header above the live (in-progress) OBD2 session diagnostics on the OBD2 communication-health screen (#2471).
  ///
  /// In en, this message translates to:
  /// **'Live session'**
  String get obd2HealthLiveSection;

  /// Section header above the capped ring of finished OBD2 session diagnostics on the OBD2 communication-health screen (#2471).
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get obd2HealthHistorySection;

  /// Label for the action that copies the OBD2 session diagnostics (per-PID table + counters) to the clipboard as JSON, on the OBD2 communication-health screen (#2471).
  ///
  /// In en, this message translates to:
  /// **'Copy as JSON'**
  String get obd2HealthCopyJson;

  /// Confirmation snackbar after the OBD2 communication-health screen copies the session diagnostics JSON to the clipboard (#2471).
  ///
  /// In en, this message translates to:
  /// **'OBD2 diagnostics copied to clipboard.'**
  String get obd2HealthCopied;

  /// Label for the action that saves the OBD2 session diagnostics (per-PID table + counters) as a JSON file to the device's Downloads folder, on the OBD2 communication-health screen (#2938).
  ///
  /// In en, this message translates to:
  /// **'Download as JSON'**
  String get obd2HealthDownloadJson;

  /// Label for the action on the OBD2 communication-health screen (#2938) that saves only the dongle-init handshake (adapter identity + init transcript + supported PIDs) as a JSON file to the Downloads folder, without the full per-PID/session payload.
  ///
  /// In en, this message translates to:
  /// **'Download init transcript only'**
  String get obd2HealthDownloadInitTranscript;

  /// Error snackbar shown when the OBD2 communication-health screen fails to write the diagnostics JSON file to the Downloads folder (#2938).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the diagnostics file'**
  String get obd2HealthDownloadError;

  /// Label of the dropdown above the Run-adapter-test button (#2938) that lets the user choose which paired OBD2 adapter the self-test should connect to.
  ///
  /// In en, this message translates to:
  /// **'Adapter to test'**
  String get obd2TestAdapterLabel;

  /// Last option in the adapter-to-test dropdown (#2938): instead of connecting to a paired adapter by MAC, fall back to the blind Bluetooth scan (the original self-test behaviour).
  ///
  /// In en, this message translates to:
  /// **'Scan for adapter'**
  String get obd2TestAdapterScanOption;

  /// First step label in the OBD2 adapter self-test progress list when the run connects directly to a chosen adapter by MAC instead of scanning (#2938). adapter is the chosen adapter's display name.
  ///
  /// In en, this message translates to:
  /// **'Connect to {adapter}'**
  String obd2TestStepConnectTo(String adapter);

  /// Section header above the on-demand OBD2 adapter self-test on the dev-tools communication-health screen (#2645).
  ///
  /// In en, this message translates to:
  /// **'Run adapter test'**
  String get obd2TestRunTitle;

  /// Label for the button that starts the on-demand OBD2 adapter self-test (scan, connect, info, PIDs, reconnect) on the communication-health screen (#2645).
  ///
  /// In en, this message translates to:
  /// **'Run adapter test'**
  String get obd2TestRunButton;

  /// Pass banner shown when every step of the OBD2 adapter self-test succeeded (#2645).
  ///
  /// In en, this message translates to:
  /// **'Adapter test passed'**
  String get obd2TestRunPassed;

  /// Fail banner shown when one or more steps of the OBD2 adapter self-test did not succeed (#2645).
  ///
  /// In en, this message translates to:
  /// **'Adapter test failed'**
  String get obd2TestRunFailed;

  /// Non-alarming amber banner shown when the OBD2 adapter self-test passed every adapter-capability step but the live-data steps were ECU-silent because the engine is off (#3009). The adapter is fine; only the engine is off.
  ///
  /// In en, this message translates to:
  /// **'Adapter OK — engine off; start the engine to read live data'**
  String get obd2TestRunEngineOff;

  /// Summary line under the OBD2 adapter self-test pass/fail banner: passed-step count, total steps, and total elapsed milliseconds (#2645).
  ///
  /// In en, this message translates to:
  /// **'{passed} of {total} steps OK · {elapsed} ms'**
  String obd2TestRunSummary(int passed, int total, int elapsed);

  /// Notice shown when the user tries to run the OBD2 adapter self-test while a trip recording owns the single-link adapter (#2645).
  ///
  /// In en, this message translates to:
  /// **'Stop the active recording before running the adapter test.'**
  String get obd2TestRunCannotWhileRecording;

  /// Step label in the OBD2 adapter self-test progress list: discover the Bluetooth adapter (#2645).
  ///
  /// In en, this message translates to:
  /// **'Scan for adapter'**
  String get obd2TestStepScan;

  /// Step label in the OBD2 adapter self-test progress list: open the link and run the ELM327 init handshake (#2645).
  ///
  /// In en, this message translates to:
  /// **'Connect & init'**
  String get obd2TestStepConnect;

  /// Step label in the OBD2 adapter self-test progress list: read the adapter description and battery voltage (#2645).
  ///
  /// In en, this message translates to:
  /// **'Adapter info'**
  String get obd2TestStepInfo;

  /// Step label in the OBD2 adapter self-test progress list: request the supported-PID bitmask (0100) (#2645).
  ///
  /// In en, this message translates to:
  /// **'Supported PIDs'**
  String get obd2TestStepSupportedPids;

  /// Step label in the OBD2 adapter self-test progress list: sample-read RPM, speed and coolant (#2645).
  ///
  /// In en, this message translates to:
  /// **'Sample reads'**
  String get obd2TestStepSampleReads;

  /// Step label in the OBD2 adapter self-test progress list: deliberately disconnect and reconnect, timing the recovery (#2645).
  ///
  /// In en, this message translates to:
  /// **'Reconnect test'**
  String get obd2TestStepReconnect;

  /// Step label in the OBD2 adapter self-test progress list: clean teardown of the link (#2645).
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get obd2TestStepDisconnect;

  /// Accessible status / icon label for a passed step in the OBD2 adapter self-test progress list (#2645).
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get obd2TestStatusOk;

  /// Accessible status / icon label for a step that timed out in the OBD2 adapter self-test progress list (#2645).
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get obd2TestStatusTimeout;

  /// Accessible status / icon label for a step whose adapter reply was garbage / unrecognised in the OBD2 adapter self-test progress list (#2645).
  ///
  /// In en, this message translates to:
  /// **'Unreadable reply'**
  String get obd2TestStatusGarbage;

  /// Accessible status / icon label for a step where the ECU answered NO DATA / nothing in the OBD2 adapter self-test progress list (#2645).
  ///
  /// In en, this message translates to:
  /// **'No response'**
  String get obd2TestStatusNoResponse;

  /// Accessible status / icon label for a failed (or skipped after abort) step in the OBD2 adapter self-test progress list (#2645).
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get obd2TestStatusFail;

  /// Transport tag shown next to a paired adapter in the self-test adapter picker when its name matched a Bluetooth Classic (SPP) profile (#2969).
  ///
  /// In en, this message translates to:
  /// **'Classic (SPP)'**
  String get obd2TestAdapterTransportClassic;

  /// Transport tag shown next to a paired adapter in the self-test adapter picker when its name matched a Bluetooth LE profile (#2969).
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE'**
  String get obd2TestAdapterTransportBle;

  /// Transport tag shown next to a paired adapter in the self-test adapter picker when its stored name matched no known profile, so the run defaults to Bluetooth LE (#2969).
  ///
  /// In en, this message translates to:
  /// **'unknown — defaulting to BLE'**
  String get obd2TestAdapterTransportUnknown;

  /// Section header on the OBD2 health screen for the list of recent connect attempts (each captured even when it FAILED before a session could begin) (#2969).
  ///
  /// In en, this message translates to:
  /// **'Recent connect attempts'**
  String get obd2HealthConnectAttemptsSection;

  /// Placeholder on the OBD2 health screen when no connect attempt has been traced yet (#2969).
  ///
  /// In en, this message translates to:
  /// **'No connect attempts recorded yet.'**
  String get obd2HealthConnectAttemptsEmpty;

  /// Button to download one connect-attempt trace as JSON to the Downloads folder (#2969).
  ///
  /// In en, this message translates to:
  /// **'Download connect trace'**
  String get obd2HealthDownloadConnectTrace;

  /// Button to download every recent connect-attempt trace as one JSON file to the Downloads folder (#2969).
  ///
  /// In en, this message translates to:
  /// **'Download all connect traces'**
  String get obd2HealthDownloadAllConnectTraces;

  /// Label for the origin (self-test / live reconnect / first connect) of a connect attempt on the OBD2 health screen (#2969).
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get obd2HealthConnectOrigin;

  /// Label for the requested vs resolved transport of a connect attempt on the OBD2 health screen (#2969).
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get obd2HealthConnectTransport;

  /// Label for the terminal outcome of a connect attempt on the OBD2 health screen (#2969).
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get obd2HealthConnectOutcome;

  /// Label for the list of devices seen during the scan phase of a connect attempt on the OBD2 health screen (#2969).
  ///
  /// In en, this message translates to:
  /// **'Scanned devices'**
  String get obd2HealthConnectScanList;

  /// Label for the per-step timeline of a connect attempt on the OBD2 health screen (#2969).
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get obd2HealthConnectSteps;

  /// Headline fallback on a connect-attempt trace card when the adapter's human name could not be resolved (an anonymous BLE advertiser) and only the redacted MAC is known (#3014).
  ///
  /// In en, this message translates to:
  /// **'Unknown adapter'**
  String get obd2HealthConnectUnknownAdapter;

  /// Snackbar shown after the OBD2 picker falls back from a silent pinned-MAC connect to the manual sheet (#1188). The placeholder is the display name of the previously paired adapter so the user knows which one was unreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach \'{adapterName}\' — pick another adapter'**
  String obd2PickerPinnedFallback(String adapterName);

  /// Section header in the OBD2 adapter picker (#3103) above Bluetooth devices the catalog did not recognize as a known adapter but which the user can still try to connect to.
  ///
  /// In en, this message translates to:
  /// **'Other Bluetooth devices'**
  String get obd2PickerOtherDevices;

  /// Subtitle on an unrecognized device row in the OBD2 adapter picker (#3103). The device is named but not a known adapter; tapping attempts a connection anyway.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized — tap to try'**
  String get obd2PickerTapToTry;

  /// Explanatory note shown in the OBD2 adapter picker on iOS (#3103). iPhone cannot discover Bluetooth-Classic/SPP adapters (Apple MFi restriction), so this tells the user why a Classic-only adapter does not appear and that it must be used on Android instead.
  ///
  /// In en, this message translates to:
  /// **'iPhone works with Bluetooth-LE adapters only. A Classic-only adapter (e.g. vLinker BM, Konnwei KW902) must be used on Android.'**
  String get obd2PickerBleOnlyNotice;

  /// Hint shown under the connecting spinner while a FIRST-connect OBD2 adapter is waiting for the user to confirm the OS Bluetooth pairing dialog (#3181). Secure-BLE adapters like the OBDLink CX initiate pairing on the first connection; without this hint the spinner looks hung while the dialog waits.
  ///
  /// In en, this message translates to:
  /// **'Confirm the pairing request on your phone'**
  String get obd2PairingConfirmHint;

  /// Shown while the trip-independent auto-reconnect controller is actively trying to re-establish a dropped OBD2 adapter link (Epic #3013 phase 3, #3019). Bounded backoff loop in flight.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to your OBD2 adapter…'**
  String get obd2ReconnectInProgress;

  /// Shown while auto-reconnect is trying to re-establish a named OBD2 adapter link (Epic #3013 phase 3). adapter is the friendly device name, e.g. 'vLinker FS'.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to {adapter}…'**
  String obd2ReconnectInProgressNamed(String adapter);

  /// Title of the terminal auto-reconnect-failure surface, shown after the bounded reconnect attempts were exhausted (Epic #3013 phase 3, #3019). The auto-loop has stopped; the user can tap to retry.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reconnect to your adapter'**
  String get obd2ReconnectFailedTitle;

  /// Body text of the terminal auto-reconnect-failure surface (Epic #3013 phase 3). Explains the auto-reconnect gave up after bounded attempts and how to recover.
  ///
  /// In en, this message translates to:
  /// **'The OBD2 connection was lost and automatic reconnection didn’t succeed. Check the adapter is powered and in range, then tap retry.'**
  String get obd2ReconnectFailedBody;

  /// Tooltip of the X button on the terminal reconnect-failed strip (#3505). Dismisses the strip for the current drop episode only — a fresh drop re-arms it.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get obd2ReconnectDismiss;

  /// Title of the Android foreground-service notification shown while the hands-free auto-record watch is armed (#3505 — replaces the hard-coded English string in AutoRecordForegroundService.kt). Handed to the native side at arm time.
  ///
  /// In en, this message translates to:
  /// **'Trip auto-record'**
  String get autoRecordNotificationTitle;

  /// Body of the Android auto-record foreground-service notification (#3505). Handed to the native side at arm time.
  ///
  /// In en, this message translates to:
  /// **'Watching for your OBD2 adapter'**
  String get autoRecordNotificationText;

  /// Label of the button that restarts the bounded auto-reconnect loop after it gave up (Epic #3013 phase 3, #3019). The user-actionable 'tap to retry' affordance the Epic requires.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get obd2ReconnectRetry;

  /// One-time actionable recovery hint shown when the Classic OBD2 adapter is wedged (#3422, epic #3415): repeated reconnects ended in exhausted RFCOMM ladders and the in-app recovery rungs did not clear it. Tells the user the two physical recoveries (ignition cycle / replug) and the Bluetooth toggle.
  ///
  /// In en, this message translates to:
  /// **'Your OBD2 adapter stopped responding. Switch the ignition off and on or replug the adapter — or toggle Bluetooth off and on.'**
  String get obd2WedgeHintBody;

  /// Label of the button on the wedged-adapter recovery hint (#3422) that deep-links to the system Bluetooth settings screen so the user can toggle Bluetooth off and on.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth settings'**
  String get obd2WedgeHintOpenBtSettings;

  /// Title of the gated developer OCR tester screen that runs the pump / receipt OCR pipeline on a chosen image and shows the full reasoning trace (#2518, Epic #2516). Only visible in Developer / Debug mode.
  ///
  /// In en, this message translates to:
  /// **'OCR tester'**
  String get ocrTesterTitle;

  /// Label of the Developer-tools button that opens the OCR tester screen (#2518).
  ///
  /// In en, this message translates to:
  /// **'OCR tester'**
  String get ocrTesterNavLabel;

  /// One-line explanation under the OCR tester title clarifying it is a gated developer tool (#2518).
  ///
  /// In en, this message translates to:
  /// **'Run the pump / receipt OCR pipeline on a chosen photo and inspect every step — only available in Developer mode.'**
  String get ocrTesterExplain;

  /// Segmented-button label for the pump-display OCR mode on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Pump'**
  String get ocrTesterModePump;

  /// Segmented-button label for the paper-receipt OCR mode on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get ocrTesterModeReceipt;

  /// Button that opens the camera to capture a fresh image to run through the OCR pipeline (#2518).
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get ocrTesterCapture;

  /// Button that picks an existing image from the gallery to re-run a fixture through the OCR pipeline (#2518).
  ///
  /// In en, this message translates to:
  /// **'Pick image'**
  String get ocrTesterPickImage;

  /// Button that runs the chosen OCR pipeline on the selected image (#2518).
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get ocrTesterRun;

  /// Label of the optional country dropdown that threads the locale profile into the OCR pipeline on the tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get ocrTesterCountry;

  /// Dropdown entry on the OCR tester for running with no country locale profile, i.e. the default EUR behaviour (#2518).
  ///
  /// In en, this message translates to:
  /// **'Default (no profile)'**
  String get ocrTesterCountryNone;

  /// Empty-state hint shown on the OCR tester before any image has been selected (#2518).
  ///
  /// In en, this message translates to:
  /// **'Pick or capture an image, then Run.'**
  String get ocrTesterNoImage;

  /// Progress label shown while the OCR pipeline runs on the selected image in the tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Running OCR…'**
  String get ocrTesterRunning;

  /// Shown on the OCR tester when the pipeline returned no result (e.g. the user cancelled the camera or OCR read nothing) (#2518).
  ///
  /// In en, this message translates to:
  /// **'OCR produced no readable result.'**
  String get ocrTesterNoResult;

  /// Section header above the ML Kit block overlay (the image with classified boxes) on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Block overlay'**
  String get ocrTesterOverlaySection;

  /// Section header above the per-stage steps panel on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Pipeline steps'**
  String get ocrTesterStepsSection;

  /// Legend chip for blocks classified as printed labels (blue) on the OCR tester block overlay (#2518).
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get ocrTesterLegendLabel;

  /// Legend chip for blocks classified as numeric values (green) on the OCR tester block overlay (#2518).
  ///
  /// In en, this message translates to:
  /// **'Numeric'**
  String get ocrTesterLegendNumeric;

  /// Legend chip for blocks classified as noise (grey) on the OCR tester block overlay (#2518).
  ///
  /// In en, this message translates to:
  /// **'Noise'**
  String get ocrTesterLegendNoise;

  /// Legend chip for a field the cross-check derived rather than read (dashed amber) on the OCR tester block overlay (#2518).
  ///
  /// In en, this message translates to:
  /// **'Derived'**
  String get ocrTesterLegendDerived;

  /// Steps-panel stage name for the glare-fraction preprocessing reject decision on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Capture / glare'**
  String get ocrTesterStageGlare;

  /// Steps-panel stage name for ML Kit text recognition (flat text + block geometry) on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'ML Kit'**
  String get ocrTesterStageMlkit;

  /// Steps-panel stage name for per-block label / numeric / noise classification on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Classify'**
  String get ocrTesterStageClassify;

  /// Steps-panel stage name for split-label assembly on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Assemble'**
  String get ocrTesterStageAssemble;

  /// Steps-panel stage name for label-to-numeric anchoring on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get ocrTesterStageAnchor;

  /// Steps-panel stage name for the magnitude fallback for unbound fields on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Fallback'**
  String get ocrTesterStageFallback;

  /// Steps-panel stage name for the total / volume / unit-price cross-check derivation on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Cross-check'**
  String get ocrTesterStageCrossCheck;

  /// Steps-panel stage name for the per-component confidence scoring on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get ocrTesterStageConfidence;

  /// Steps-panel stage name for the per-country validation gate on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get ocrTesterStageGate;

  /// Steps-panel stage name for receipt brand detection on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get ocrTesterStageBrand;

  /// Steps-panel stage name for receipt per-station override dispatch on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Overrides'**
  String get ocrTesterStageOverrides;

  /// Steps-panel stage name for receipt cross-field reconcile on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get ocrTesterStageReconcile;

  /// Steps-panel stage name for the final read on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get ocrTesterStageResult;

  /// Chip flagging a value that was read directly off the display / receipt on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'READ'**
  String get ocrTesterChipRead;

  /// Chip flagging a value the cross-check computed rather than read, on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'DERIVED'**
  String get ocrTesterChipDerived;

  /// Steps-panel label shown when the validation gate accepted the read on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get ocrTesterGateAccepted;

  /// Steps-panel label shown when the validation gate rejected the read on the OCR tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get ocrTesterGateRejected;

  /// Banner shown in the steps panel when the magnitude-fallback stage bound a field, prompting the developer to double-check it (#2518).
  ///
  /// In en, this message translates to:
  /// **'A field was recovered via magnitude fallback — verify it.'**
  String get ocrTesterFallbackBanner;

  /// Placeholder shown inside a steps-panel tile for a stage the pipeline never reached (#2518).
  ///
  /// In en, this message translates to:
  /// **'Stage did not run.'**
  String get ocrTesterStageNoData;

  /// Button that copies the full OCR trace package as JSON to the clipboard on the tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Copy as JSON'**
  String get ocrTesterCopyJson;

  /// Button that exports the OCR trace (image + JSON) to the Downloads folder / share sheet on the tester (#2518).
  ///
  /// In en, this message translates to:
  /// **'Export package'**
  String get ocrTesterExportPackage;

  /// Snackbar confirming the OCR trace JSON was copied to the clipboard (#2518).
  ///
  /// In en, this message translates to:
  /// **'OCR trace copied to clipboard.'**
  String get ocrTesterCopied;

  /// Snackbar confirming the OCR trace package (image + JSON) was saved to Downloads (#2518).
  ///
  /// In en, this message translates to:
  /// **'OCR package saved to your Downloads folder.'**
  String get ocrTesterExported;

  /// Button that saves the current OCR trace as a regression fixture — the source image plus a .ocrpkg.json with expected values — into the device Downloads folder, ready to commit and run through the fixture-promotion generator (#2519).
  ///
  /// In en, this message translates to:
  /// **'Save as fixture'**
  String get ocrTesterSaveFixture;

  /// Snackbar confirming the OCR regression fixture (source image + .ocrpkg.json) was saved to Downloads, with a hint on the next step (#2519).
  ///
  /// In en, this message translates to:
  /// **'Fixture saved to your Downloads folder. Move it under test/fixtures and run tool/promote_ocr_fixture.dart.'**
  String get ocrTesterFixtureSaved;

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

  /// Error shown when the user taps the onboarding wizard's Next button on the first step without choosing a use mode (#1691).
  ///
  /// In en, this message translates to:
  /// **'Pick a use mode to continue.'**
  String get onboardingPickUseMode;

  /// Informational note on the iOS variant of the OBD2 onboarding step (App Review 5.1.1(iv), #3535): no in-wizard connect flow on iOS, the adapter is paired later from the vehicle screen.
  ///
  /// In en, this message translates to:
  /// **'You can pair a Bluetooth OBD2 adapter anytime later from the vehicle screen to record trips and read engine data.'**
  String get onboardingObd2LaterNote;

  /// Opening-hours status line — station is currently open (#2709).
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openNow;

  /// Opening-hours status line — station is currently closed (#2709).
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get openNowClosed;

  /// Opening-hours status line — the schedule could not be resolved (#2709).
  ///
  /// In en, this message translates to:
  /// **'Hours unknown'**
  String get openHoursUnknown;

  /// Opening-hours status detail — when an open station next closes (#2709).
  ///
  /// In en, this message translates to:
  /// **'Closes {time}'**
  String closesAt(String time);

  /// Opening-hours status detail — when a closed station next opens on a future day (#2709).
  ///
  /// In en, this message translates to:
  /// **'Opens {day} {time}'**
  String opensAt(String day, String time);

  /// Opening-hours status detail — when a closed station next opens later the same day (#2709).
  ///
  /// In en, this message translates to:
  /// **'Opens {time}'**
  String opensToday(String time);

  /// Opening-hours row shown when the station is open every day around the clock (#2709).
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get open24Hours;

  /// Compact badge shown next to the status for an around-the-clock station (#2709).
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get badge24h;

  /// Opening-hours indicator shown alongside the staffed schedule when an unattended pump is open round-the-clock (FR Automate : 24/24, #2742).
  ///
  /// In en, this message translates to:
  /// **'24/7 automate'**
  String get openingHoursAutomate24h;

  /// Full weekday name — Monday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMon;

  /// Full weekday name — Tuesday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTue;

  /// Full weekday name — Wednesday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWed;

  /// Full weekday name — Thursday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThu;

  /// Full weekday name — Friday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFri;

  /// Full weekday name — Saturday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySat;

  /// Full weekday name — Sunday (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySun;

  /// Abbreviated weekday name — Monday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayShortMon;

  /// Abbreviated weekday name — Tuesday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayShortTue;

  /// Abbreviated weekday name — Wednesday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayShortWed;

  /// Abbreviated weekday name — Thursday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayShortThu;

  /// Abbreviated weekday name — Friday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayShortFri;

  /// Abbreviated weekday name — Saturday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get dayShortSat;

  /// Abbreviated weekday name — Sunday (collapsed opening-hours range, #2709).
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dayShortSun;

  /// Collapsed weekday span, e.g. "Mon – Fri" (opening-hours table, #2709).
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String dayRange(String from, String to);

  /// Opening-hours table row label for the public-holiday schedule (#2709).
  ///
  /// In en, this message translates to:
  /// **'Public holidays'**
  String get publicHolidays;

  /// Opening-hours table value shown for a day the station is closed (#2709).
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLabel;

  /// Muted message when no opening-hours data was provided for a station (#2709).
  ///
  /// In en, this message translates to:
  /// **'Opening hours not available'**
  String get openingHoursNotAvailable;

  /// Expand affordance under the collapsed opening-hours week — reveals the full per-day table (#2709).
  ///
  /// In en, this message translates to:
  /// **'Show all hours'**
  String get showAllHours;

  /// Collapse affordance shown when the full opening-hours table is expanded (#2709).
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLessHours;

  /// Tri-state open badge/status when the data source publishes no open/closed signal (#3198). Shown instead of Open/Closed on cards and the detail status row.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get openStateUnknown;

  /// Screen-reader label for the tri-state station open state (#3198). 'true'/'false' are the known states; any other value (the stringified null) means the source gave no signal.
  ///
  /// In en, this message translates to:
  /// **'{open, select, true{Station is open} false{Station is closed} other{Open state unknown}}'**
  String stationOpenStateSemantic(String open);

  /// #2393 — unit caption under the big GPS-estimated consumption figure on the PiP tile (the GPS-only branch added by #2390). Marks the value as an estimate ('est.') so it reads distinctly from the OBD2-measured 'L/100 km' caption — the leading '~' on the figure carries the same meaning visually. Short, fits a narrow PiP window.
  ///
  /// In en, this message translates to:
  /// **'est. L/100 km'**
  String get tripRecordingPipEstConsumptionCaption;

  /// #2393 — long-press tooltip / accessibility label on the GPS-estimated consumption value shown on the trip-recording PiP tile and banner strip (#2390). Explains that the leading '~' means the figure is a GPS physics estimate, not a measured OBD2 value, and gives the expected accuracy band. Never shown on OBD2-measured trips.
  ///
  /// In en, this message translates to:
  /// **'Estimated value (~) — no fuel sensor on this trip, so the L/100 km figure is modelled from GPS speed and your vehicle\'s calibration. It is approximate (typically ±10–30 %, tightening as the calibration matures), not a measured reading.'**
  String get tripRecordingEstimatedInfo;

  /// PiP overlay caption (#2094) shown under the big elapsed-time figure when the trip has just started and no distance / fuel data is available yet. Lowercase, unitless — pairs visually with 'L/100 km' / 'km' on the other branches.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get tripRecordingPipElapsedCaption;

  /// Title of the bottom sheet explaining the pin button on the fuel-station radar (search) screen (#2785). Opened by long-pressing the pin in the AppBar.
  ///
  /// In en, this message translates to:
  /// **'About pin'**
  String get radarPinHelpTitle;

  /// Body text in the radar pin-help bottom sheet (#2785). Explains what pinning does and that it releases when the radar stops.
  ///
  /// In en, this message translates to:
  /// **'Pin keeps the screen on and hides system bars so the closest-station readout stays readable on a dashboard mount. Tap again to release. Auto-releases when the radar stops.'**
  String get radarPinHelpBody;

  /// Title of the opt-in switch in the radar pin-help bottom sheet (#2785). When on, the search screen pins itself (screen stays on, system bars hidden) automatically the moment the fuel-station radar starts, instead of the user tapping the pin each time. On by default.
  ///
  /// In en, this message translates to:
  /// **'Always pin when the radar starts'**
  String get radarAutoPinTitle;

  /// Subtitle under the always-pin opt-in switch in the radar pin-help bottom sheet (#2785). Explains the trade-off: convenience vs battery cost.
  ///
  /// In en, this message translates to:
  /// **'Pin the radar automatically every time instead of tapping each time. Uses more battery.'**
  String get radarAutoPinSubtitle;

  /// Tooltip / accessibility label for the button that switches the Fuel Station Radar results from the distance-sorted list to the PPI radar-scope view (#3342) — a green radar face with a rotating sweep and a blip per station.
  ///
  /// In en, this message translates to:
  /// **'Radar view'**
  String get radarScopeShowScope;

  /// Tooltip / accessibility label for the button that switches the Fuel Station Radar results back from the radar-scope view to the distance-sorted list (#3342).
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get radarScopeShowList;

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

  /// Title of the guided reconciliation workflow dialog raised after a full-tank fill-up when recorded trips don't account for all the pumped fuel (#2442).
  ///
  /// In en, this message translates to:
  /// **'Reconcile your fuel'**
  String get reconcileWorkflowTitle;

  /// Step 1 headline of the reconciliation workflow, stating the size of the gap between pumped and recorded fuel (#2442).
  ///
  /// In en, this message translates to:
  /// **'We found a {gap} L gap'**
  String reconcileWorkflowExplainHeadline(String gap);

  /// Step 1 body of the reconciliation workflow, comparing pumped litres to recorded-trip litres and stating the difference (#2442). All numbers are pre-formatted by the caller in the active locale.
  ///
  /// In en, this message translates to:
  /// **'You pumped {pumped} L, but your recorded trips only account for {consumed} L. That leaves {gap} L unexplained.'**
  String reconcileWorkflowExplainBody(
    String pumped,
    String consumed,
    String gap,
  );

  /// Step 1 likely-causes copy in the reconciliation workflow (#2442).
  ///
  /// In en, this message translates to:
  /// **'This usually means a drive wasn\'t recorded (the adapter was unplugged or the app was closed), or a fill-up is missing or mistyped.'**
  String get reconcileWorkflowExplainCauses;

  /// Step 1 consequence copy in the reconciliation workflow, explaining what happens if the gap is left unresolved (#2442).
  ///
  /// In en, this message translates to:
  /// **'Until this is resolved, your fuel total and your trips total won\'t match.'**
  String get reconcileWorkflowExplainConsequence;

  /// Step 2 headline of the reconciliation workflow, introducing the attribution questions (#2442).
  ///
  /// In en, this message translates to:
  /// **'Help us attribute the gap'**
  String get reconcileWorkflowAttributeQuestion;

  /// Step 2 first attribution question in the reconciliation workflow — whether the fill-ups are complete/correct (#2442).
  ///
  /// In en, this message translates to:
  /// **'Are all your fill-ups for this tank complete and correct?'**
  String get reconcileWorkflowFillUpsCompleteQuestion;

  /// Step 2 second attribution question in the reconciliation workflow — whether all drives were recorded (#2442).
  ///
  /// In en, this message translates to:
  /// **'Are all your drives recorded?'**
  String get reconcileWorkflowDrivesRecordedQuestion;

  /// Affirmative answer chip for the reconciliation workflow attribution questions (#2442).
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get reconcileWorkflowAnswerYes;

  /// Negative answer chip for the reconciliation workflow attribution questions (#2442).
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get reconcileWorkflowAnswerNo;

  /// Hint shown in the reconciliation workflow when the attribution routes to Path A (correct the fill-ups) (#2442/#2443).
  ///
  /// In en, this message translates to:
  /// **'A fill-up is missing or wrong — we\'ll add a correction so your fill-ups add up.'**
  String get reconcileWorkflowPathAHint;

  /// Hint shown in the reconciliation workflow when the attribution routes to Path B (add a virtual trajet) (#2442/#2444).
  ///
  /// In en, this message translates to:
  /// **'Your fill-ups are right and a drive went unrecorded — we\'ll add a virtual trip for the missing distance.'**
  String get reconcileWorkflowPathBHint;

  /// Field label for the editable correction litres in the reconciliation workflow Path A (#2443).
  ///
  /// In en, this message translates to:
  /// **'Correction litres'**
  String get reconcileWorkflowCorrectionLitersLabel;

  /// Field label for the editable unrecorded-drive distance in the reconciliation workflow Path B (#2444).
  ///
  /// In en, this message translates to:
  /// **'How far was the unrecorded drive? (km)'**
  String get reconcileWorkflowVirtualDistanceLabel;

  /// Button in the reconciliation workflow that defers the decision, creating nothing and keeping the gap (#2442/#2445).
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get reconcileWorkflowDecideLater;

  /// Button in the reconciliation workflow that returns to the previous step (#2442).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get reconcileWorkflowBack;

  /// Button in the reconciliation workflow that advances to the next step (#2442).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reconcileWorkflowNext;

  /// Button in the reconciliation workflow that applies the chosen resolution (#2442).
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reconcileWorkflowApply;

  /// Inline label on a synthetic reconciliation trajet row in the Trajets list, indicating it was added by the reconciliation workflow and that tapping opens the edit sheet (#2444).
  ///
  /// In en, this message translates to:
  /// **'Virtual trip — tap to edit'**
  String get reconcileVirtualTrajetLabel;

  /// Title of the bottom sheet that opens when the user taps a virtual reconciliation trajet (#2444).
  ///
  /// In en, this message translates to:
  /// **'Edit virtual trip'**
  String get reconcileVirtualTrajetEditTitle;

  /// Explanatory copy at the top of the virtual trajet edit sheet (#2444).
  ///
  /// In en, this message translates to:
  /// **'This trip was added to account for fuel you used while driving without recording. Adjust the distance or fuel, or delete it.'**
  String get reconcileVirtualTrajetEditExplainer;

  /// Destructive button on the virtual trajet edit sheet that removes the synthetic trip (#2444).
  ///
  /// In en, this message translates to:
  /// **'Delete virtual trip'**
  String get reconcileVirtualTrajetDelete;

  /// Tappable banner on the consumption stats card when a reconciliation gap was deferred ('Decide later') and is still unresolved. Tapping re-opens the guided workflow for that gap (#2445). Replaces the old accusatory auto-correction-share hint. The litres figure is pre-formatted by the caller in the active locale.
  ///
  /// In en, this message translates to:
  /// **'Unresolved fuel/trip gap of {gap} L — tap to resolve'**
  String reconcileResolveGapBanner(String gap);

  /// Accessibility label for the tappable 'Resolve gap' banner on the consumption stats card (#2445).
  ///
  /// In en, this message translates to:
  /// **'Resolve unresolved fuel and trip gap'**
  String get reconcileResolveGapSemanticLabel;

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

  /// Shown briefly while an inbound shared receipt image is being OCR'd on the Add fill-up screen (#2735).
  ///
  /// In en, this message translates to:
  /// **'Importing shared receipt…'**
  String get shareReceiptImporting;

  /// Snackbar shown when the user shares an unsupported file (e.g. a PDF) into the app. Image receipts work today; PDF rasterisation arrives in #2737 (#2735).
  ///
  /// In en, this message translates to:
  /// **'That file type can\'t be imported yet — share a photo of the receipt instead.'**
  String get shareReceiptUnsupportedFormat;

  /// Snackbar shown when reading / OCR'ing an inbound shared receipt image failed (#2735).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the shared receipt — try sharing it again or add the fill-up manually.'**
  String get shareReceiptFailed;

  /// Settings toggle label for the inbound OS share-intent receipt importer (#2735). Default-off — opt-in.
  ///
  /// In en, this message translates to:
  /// **'Share receipt to import'**
  String get featureLabel_addFillUpShareIntentReceipt;

  /// Settings toggle description for the inbound OS share-intent receipt importer (#2735).
  ///
  /// In en, this message translates to:
  /// **'Share a receipt photo from another app to pre-fill a fill-up — date, litres, total, and station are read on-device.'**
  String get featureDescription_addFillUpShareIntentReceipt;

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
  /// **'Loading Sparkilo'**
  String get splashLoadingLabel;

  /// Title of the cold-start recovery screen shown when a Hive box is corrupted beyond repair and the app cannot open its local data store (#2294).
  ///
  /// In en, this message translates to:
  /// **'Storage problem'**
  String get storageRecoveryTitle;

  /// Body text of the storage-corruption recovery screen explaining that the local Hive data store could not be opened (#2294).
  ///
  /// In en, this message translates to:
  /// **'Sparkilo couldn\'t open its local data store. The storage file appears to be damaged.'**
  String get storageRecoveryMessage;

  /// Guidance text on the storage-corruption recovery screen telling the user how to recover — clear app storage or reinstall (#2294).
  ///
  /// In en, this message translates to:
  /// **'To recover, clear the app\'s storage in your device settings, or reinstall the app. Your favourites and history are stored on this device only, so they cannot be restored automatically.'**
  String get storageRecoveryGuidance;

  /// Title of the QR-join adoption step — the second device adopts the first device's email account (#3080).
  ///
  /// In en, this message translates to:
  /// **'Join {email}\'s account'**
  String syncAdoptTitle(String email);

  /// Explanatory subtitle of the QR-join adoption step (#3080).
  ///
  /// In en, this message translates to:
  /// **'Sign in with this account\'s password to share its data across both devices.'**
  String get syncAdoptSubtitle;

  /// Label of the password field on the QR-join adoption step (#3080).
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get syncAdoptPasswordLabel;

  /// Primary button that signs the second device into the first device's account (#3080).
  ///
  /// In en, this message translates to:
  /// **'Join account'**
  String get syncAdoptJoinButton;

  /// Link that leaves the QR-join adoption step and returns to the normal account-setup flow (#3080).
  ///
  /// In en, this message translates to:
  /// **'Use a different account instead'**
  String get syncAdoptUseDifferentAccount;

  /// Tile title in the TankSync settings section that opens the per-category server-side data deletion flow (#3453).
  ///
  /// In en, this message translates to:
  /// **'Delete synced data'**
  String get syncDeleteDataTitle;

  /// Subtitle under the delete-synced-data tile (#3453).
  ///
  /// In en, this message translates to:
  /// **'Remove your trips, vehicles or fill-ups from the sync database'**
  String get syncDeleteDataSubtitle;

  /// Title of the category-picker dialog for the synced-data deletion (#3453).
  ///
  /// In en, this message translates to:
  /// **'Delete which synced data?'**
  String get syncDeleteDataPickTitle;

  /// Category option: delete synced trips (#3453).
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get syncDeleteDataCategoryTrips;

  /// Category option: delete synced vehicles (#3453).
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get syncDeleteDataCategoryVehicles;

  /// Category option: delete synced fill-ups (#3453).
  ///
  /// In en, this message translates to:
  /// **'Fill-ups'**
  String get syncDeleteDataCategoryFillUps;

  /// Category option: delete ALL synced data (the identity itself stays usable) (#3453).
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get syncDeleteDataCategoryEverything;

  /// Confirmation dialog title before the server-side deletion; {category} is the localized category label the user picked (#3453).
  ///
  /// In en, this message translates to:
  /// **'Delete {category} from the sync database?'**
  String syncDeleteDataConfirmTitle(String category);

  /// Confirmation dialog body. Documents the server-side-only decision: local data on this device stays; other devices drop their copies via tombstones (#3453).
  ///
  /// In en, this message translates to:
  /// **'This removes the selected data from your sync database and it will not re-sync from your other devices. Data stored locally on this device is kept.'**
  String get syncDeleteDataConfirmBody;

  /// Destructive confirm button of the synced-data deletion dialog (#3453).
  ///
  /// In en, this message translates to:
  /// **'Delete from server'**
  String get syncDeleteDataConfirmAction;

  /// Snackbar shown when the server-side deletion completed (#3453).
  ///
  /// In en, this message translates to:
  /// **'Synced data deleted'**
  String get syncDeleteDataDone;

  /// Snackbar shown when the server-side deletion failed or the user is not connected (#3453).
  ///
  /// In en, this message translates to:
  /// **'Deleting synced data failed — please try again'**
  String get syncDeleteDataFailed;

  /// Warning tile title in the TankSync settings section when a stored sync identity has no active session anymore (#3449).
  ///
  /// In en, this message translates to:
  /// **'Cloud sync needs re-linking'**
  String get syncRelinkTitle;

  /// Explanatory body under the relink warning tile (#3449).
  ///
  /// In en, this message translates to:
  /// **'This device\'s saved sync identity is signed out. Sign in with your email to re-link your synced data, or start fresh with a new identity.'**
  String get syncRelinkBody;

  /// Primary button that opens the email auth screen to restore the stored sync identity (#3449).
  ///
  /// In en, this message translates to:
  /// **'Sign in to re-link'**
  String get syncRelinkSignInAction;

  /// Secondary button that knowingly abandons the old sync identity and creates a new anonymous one (#3449).
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get syncRelinkStartFreshAction;

  /// Confirmation dialog title before abandoning the old sync identity (#3449).
  ///
  /// In en, this message translates to:
  /// **'Start fresh?'**
  String get syncRelinkStartFreshTitle;

  /// Confirmation dialog body explaining the consequence of abandoning the old sync identity (#3449).
  ///
  /// In en, this message translates to:
  /// **'A new anonymous identity will be created for this device. Data synced under the old identity stays on the server but will no longer be reachable from here unless you sign in with its email account.'**
  String get syncRelinkStartFreshBody;

  /// Destructive confirm button of the start-fresh dialog (#3449).
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get syncRelinkStartFreshConfirm;

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

  /// Radio option label for the green Eco theme on the Theme settings screen (#1712).
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get themeSettingsEcoLabel;

  /// Description text under the Eco option on the Theme settings screen (#1712).
  ///
  /// In en, this message translates to:
  /// **'The app\'s signature green look — bright and easy to read, with softly green-tinted backgrounds.'**
  String get themeSettingsEcoDescription;

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

  /// Status label on the inline save-progress card shown on the trip-recording screen after the user taps Stop, while the trip summary is being finalised — odometer refresh / summary build (#2548). The stop-side bookend to the start-progress labels. Indeterminate, never a percentage.
  ///
  /// In en, this message translates to:
  /// **'Finalizing summary…'**
  String get tripSaveProgressFinalizingSummary;

  /// Status label on the inline save-progress card shown on the trip-recording screen after the user taps Stop, while the finished trip is being written to the local history log (#2548). Indeterminate, never a percentage.
  ///
  /// In en, this message translates to:
  /// **'Saving to history…'**
  String get tripSaveProgressSavingToHistory;

  /// Status label on the inline save-progress card shown on the trip-recording screen after the user taps Stop, while the saved trip is handed to the cloud sync upload (#2548). Worded 'in background' on purpose: the upload is fire-and-forget (unawaited), so this beat never blocks the resolve to the summary, and it is only shown when cloud sync is enabled. Indeterminate, never a percentage.
  ///
  /// In en, this message translates to:
  /// **'Syncing in background…'**
  String get tripSaveProgressSyncingToCloud;

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

  /// Section title above the throttle/pedal-position-over-time chart on the Trip detail screen (#2461). Plots accelerator-pedal % (PID 0x49-0x4B) when present, else throttle % (PID 0x11). Hidden when no sample carries either value.
  ///
  /// In en, this message translates to:
  /// **'Throttle / pedal (%)'**
  String get trajetDetailChartThrottle;

  /// Section title above the coolant-temperature-over-time chart on the Trip detail screen (#2461). Hidden when no sample carries a coolantTempC value (cars without OBD2 PID 0x05).
  ///
  /// In en, this message translates to:
  /// **'Coolant (°C)'**
  String get trajetDetailChartCoolant;

  /// Trip-detail chart section title (#3502): the altitude profile is plotted RELATIVE to the trip start, because raw GPS altitude is the WGS84 ellipsoid height on Android (no geoid correction) and routinely reads below sea level near a coast. 'from start' tells the user the 0 line is where they departed.
  ///
  /// In en, this message translates to:
  /// **'Altitude (m, from start)'**
  String get trajetDetailChartAltitudeRelative;

  /// Section title above the GPS-altitude-over-time chart on the Trip detail screen (#2461). Hidden when no sample carries an altitude value (GPS path off / no fix).
  ///
  /// In en, this message translates to:
  /// **'Altitude (m)'**
  String get trajetDetailChartAltitude;

  /// Section title above the commanded-lambda-over-time chart on the Trip detail screen (#2461). Lambda is the commanded equivalence ratio (PID 0x44); values below 1 mean an enriched mixture. The Greek letter lambda is a universal automotive symbol — kept untranslated. Hidden when no sample carries a lambda value.
  ///
  /// In en, this message translates to:
  /// **'Commanded λ'**
  String get trajetDetailChartLambda;

  /// Header of the collapsible section that groups all per-trip telemetry charts on the Trip detail screen (#1895). Collapsed by default — the trip summary and insight cards stay visible above it.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get trajetDetailChartsSection;

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

  /// Badge overlaid on the Trip detail fuel-rate chart when the car's adapter supported no fuel PID, so the plotted series is the GPS-physics estimate rather than a measurement (#2431). Rendered with a leading '~' (~ estimated) so the user reads it as an estimate, never as measured data. Keep it short — it sits in a small chip in the chart corner.
  ///
  /// In en, this message translates to:
  /// **'estimated'**
  String get trajetDetailChartEstimatedBadge;

  /// AppBar action tooltip for the share-trip button on the Trip detail screen (#890, #1189).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get trajetDetailShareAction;

  /// Menu option on the Trip detail share button (#2032). Selecting it rasterises the report into a PNG and hands it to the OS share sheet — the legacy behaviour before the GPX option was added.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get trajetDetailShareImageOption;

  /// Menu option on the Trip detail share button (#2032). Selecting it serialises every persisted GPS sample as a GPX 1.1 file and hands it to the OS share sheet so the user can open the route in Google Earth / Strava / etc.
  ///
  /// In en, this message translates to:
  /// **'Share GPS track (GPX)'**
  String get trajetDetailShareGpxOption;

  /// Subtitle shown under the GPX share menu option when the trip has no GPS samples (e.g. recorded with the gpsTripPath feature flag off). Also reused as the snackbar message if the GPX share action is invoked anyway.
  ///
  /// In en, this message translates to:
  /// **'No GPS samples in this trip'**
  String get trajetDetailShareGpxEmpty;

  /// Subject / preview text passed to the OS share sheet when the user shares a trip detail report as an image (#1189). The {date} placeholder is replaced with a localised short date.
  ///
  /// In en, this message translates to:
  /// **'Sparkilo — trip on {date}'**
  String trajetDetailShareSubject(String date);

  /// Snackbar shown when the trip-detail Share action fails to render or hand off the report PNG (#1189).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate share image'**
  String get trajetDetailShareError;

  /// Menu option on the Trip detail share button (#2652). Selecting it serialises the trip's full OBD2 + GPS sample stream as a CSV file and saves it to the device's Downloads folder for spreadsheet / pandas analysis.
  ///
  /// In en, this message translates to:
  /// **'Download telemetry (CSV)'**
  String get trajetDetailDownloadCsvOption;

  /// Menu option on the Trip detail share button (#2652). Selecting it saves the trip in its persisted, re-importable JSON form to the device's Downloads folder for power users / backup.
  ///
  /// In en, this message translates to:
  /// **'Download telemetry (JSON)'**
  String get trajetDetailDownloadJsonOption;

  /// Snackbar shown when a trip-detail telemetry download (CSV / JSON) fails to write to the Downloads folder (#2652).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file'**
  String get trajetDetailDownloadError;

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

  /// Action button on the Trajets tab (#2030) that opens a new screen overlaying every visible trajet's GPS polyline on a single flutter_map view, with an aggregate GPX export.
  ///
  /// In en, this message translates to:
  /// **'View all on map'**
  String get trajetsViewAllOnMap;

  /// AppBar title of the TrajetsMapScreen (#2030).
  ///
  /// In en, this message translates to:
  /// **'Trajets on map'**
  String get trajetsMapTitle;

  /// AppBar action tooltip on the TrajetsMapScreen (#2030) that exports the visible trajets as a multi-track GPX file via the OS share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share GPX'**
  String get trajetsMapShareGpx;

  /// Empty-state caption on the TrajetsMapScreen (#2030) when every selected trip's samples lack lat/lon — e.g. legacy trips recorded before #1374 or trips whose Feature.gpsTripPath flag was off.
  ///
  /// In en, this message translates to:
  /// **'None of the selected trajets carry GPS samples.'**
  String get trajetsMapEmpty;

  /// Snackbar shown on the TrajetsMapScreen (#2030) when handing the aggregate GPX off to the OS share sheet throws.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the GPX file'**
  String get trajetsMapShareError;

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

  /// Title of the trip-detail card that shows the GPS-recorded route as a polyline on a map (#1374 phase 2).
  ///
  /// In en, this message translates to:
  /// **'Trip path'**
  String get tripPathCardTitle;

  /// Sub-line beneath the trip-path card title clarifying that the polyline comes from the GPS samples captured during the trip.
  ///
  /// In en, this message translates to:
  /// **'GPS-recorded route'**
  String get tripPathCardSubtitle;

  /// Header label above the trip-path heatmap legend (#1374 phase 3) — names the metric the colour coding represents.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get tripPathLegendTitle;

  /// Legend entry for the green heatmap bucket on the trip-path card (#1374 phase 3): segments where computed L/100 km is below 6.
  ///
  /// In en, this message translates to:
  /// **'Efficient (< 6 L/100km)'**
  String get tripPathLegendEfficient;

  /// Legend entry for the orange heatmap bucket on the trip-path card (#1374 phase 3): segments where computed L/100 km is between 6 and 10.
  ///
  /// In en, this message translates to:
  /// **'Borderline (6–10 L/100km)'**
  String get tripPathLegendBorderline;

  /// Legend entry for the red heatmap bucket on the trip-path card (#1374 phase 3): segments where computed L/100 km is at least 10.
  ///
  /// In en, this message translates to:
  /// **'Wasteful (≥ 10 L/100km)'**
  String get tripPathLegendWasteful;

  /// Title of the Fuel Station Radar card at the top of the active trip-recording screen (#2380 / #2661).
  ///
  /// In en, this message translates to:
  /// **'Fuel Station Radar'**
  String get tripRadarClosestStation;

  /// Placeholder shown on the trip-recording radar card while the nearest-station lookup is in flight (#2380).
  ///
  /// In en, this message translates to:
  /// **'Scanning for nearby stations'**
  String get tripRadarScanning;

  /// Placeholder shown on the trip-recording radar card when no fuel station is within range of the live GPS fix (#2380).
  ///
  /// In en, this message translates to:
  /// **'No station nearby'**
  String get tripRadarNoStationNearby;

  /// Swipe-left hint / screen-reader action on the Fuel Station Radar card: page to the next-nearer station in the distance-ranked list (#2661).
  ///
  /// In en, this message translates to:
  /// **'Nearer station'**
  String get fuelStationRadarNearer;

  /// Swipe-right hint / screen-reader action on the Fuel Station Radar card: page to the next-farther station in the distance-ranked list (#2661).
  ///
  /// In en, this message translates to:
  /// **'Farther station'**
  String get fuelStationRadarFarther;

  /// Label on the extended floating-action button (styled like the trip 'Start recording' pill) that launches a cache-first Fuel Station Radar scan around the user and shows the nearby stations in the search-results list (#2682).
  ///
  /// In en, this message translates to:
  /// **'Start fuel station radar'**
  String get fuelStationRadarStart;

  /// Label on the extended floating-action button when the Fuel Station Radar is active: tapping it ends the radar session and hands the results list back to the regular search. Replaces the ambiguous shared 'stop' key (FR 'Étape') that read as a route-waypoint label, not a radar-off affordance (#2744).
  ///
  /// In en, this message translates to:
  /// **'Stop radar'**
  String get stopRadar;

  /// Label of the grey summary-bar chip shown above the results list while the on-search Fuel Station Radar owns the results, replacing the radius chip to signal the list is a radar scan rather than a regular search (#2676).
  ///
  /// In en, this message translates to:
  /// **'Fuel Station Radar result'**
  String get fuelStationRadarResultBadge;

  /// Status shown while the on-search Fuel Station Radar acquires the first GPS fix and has no last-known position to scan around yet (#3267).
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get radarAcquiringLocation;

  /// Status banner shown above the on-search Fuel Station Radar results while a fresh GPS fix is still resolving — the list is painted from the last-known position and refreshes once the live fix lands (#3267).
  ///
  /// In en, this message translates to:
  /// **'Updating your location…'**
  String get radarUpdatingLocation;

  /// Label on the Fuel Station Radar launch button while a scan is initialising — the GPS fix is being acquired and/or the first station list is loading — so the user sees the radar is working rather than a button that silently flipped to 'Stop' (#3290).
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get radarSearching;

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

  /// One-shot SnackBar shown the moment the user lands on the trip-recording screen with the pin toggle OFF (#1458 phase 2). Warns that without pinning, Android may suspend or throttle GPS while the screen sleeps and the captured path will show gaps.
  ///
  /// In en, this message translates to:
  /// **'Pin the screen to keep GPS active during the trip — Android may throttle GPS during sleep.'**
  String get tripRecordingUnpinnedWarning;

  /// Tooltip on the minimise (Picture-in-Picture) icon button on the trip-recording screen (#1884). Tapping shrinks the app into a small floating tile that keeps showing live consumption over other apps. Android-only.
  ///
  /// In en, this message translates to:
  /// **'Minimise to a floating tile'**
  String get tripRecordingMinimiseTooltip;

  /// Title of the opt-in switch in the pin-help bottom sheet on the trip-recording screen (#2274). When on, the form pins itself (screen stays on, system bars hidden) automatically at the start of every recording instead of the user tapping the pin each drive. Off by default.
  ///
  /// In en, this message translates to:
  /// **'Always pin when recording starts'**
  String get tripRecordingAutoPinTitle;

  /// Subtitle under the always-pin opt-in switch in the pin-help bottom sheet (#2274). Explains the trade-off: convenience vs battery cost.
  ///
  /// In en, this message translates to:
  /// **'Pin the form automatically every drive instead of tapping each time. Uses more battery.'**
  String get tripRecordingAutoPinSubtitle;

  /// AppBar title shown on the trip-recording screen while the BLE adapter connect + odometer prime run, before the first live sample lands (#2274 start-now-connect-later). The screen is pushed immediately in this transient connecting state.
  ///
  /// In en, this message translates to:
  /// **'Starting recording…'**
  String get tripRecordingConnectingTitle;

  /// AppBar title shown on the trip-recording screen after the user taps Stop, while the trip is finalised, written to history, and (when enabled) handed to the cloud upload, before the screen flips to the summary (#2548). The stop-side bookend to tripRecordingConnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving trip…'**
  String get tripRecordingSavingTitle;

  /// SnackBar shown after the user stops a recording that covered no distance and captured no usable signal — a genuine false-start / stationary stop (#2509). Tells the user nothing was saved because the car never moved. Never shown when the trip was actually saved.
  ///
  /// In en, this message translates to:
  /// **'Recording discarded — no movement detected'**
  String get tripRecordingDiscardedNoMovement;

  /// Title of the Android GPS foreground-service notification shown while a trip is recording (#2766). Reassures the user that location tracking is intentional and tied to the active recording, so the persistent notification reads as expected rather than alarming.
  ///
  /// In en, this message translates to:
  /// **'Recording your trip'**
  String get tripRecordingGpsNotificationTitle;

  /// Body text of the Android GPS foreground-service notification shown while a trip is recording (#2766). Explains why location is tracked: to compute the route, fuel consumption and driving stats for this trip.
  ///
  /// In en, this message translates to:
  /// **'Tracking your route for fuel & driving stats'**
  String get tripRecordingGpsNotificationText;

  /// Menu option / tooltip on the trip-detail Share menu (#2240) that opens the cross-account sharing sheet — distinct from the existing 'Share image' / 'Share GPX' options which export to the OS share sheet. This shares the trip with a DIFFERENT TankSync account.
  ///
  /// In en, this message translates to:
  /// **'Share with another account'**
  String get tripShareAction;

  /// Title of the cross-account trip-sharing bottom sheet (#2240).
  ///
  /// In en, this message translates to:
  /// **'Share this trip'**
  String get tripShareSheetTitle;

  /// Subtitle under the cross-account trip-sharing sheet title explaining that sharing grants read-only access (#2240).
  ///
  /// In en, this message translates to:
  /// **'Give another TankSync account read-only access to this recorded trip.'**
  String get tripShareSheetSubtitle;

  /// Label for the email text field in the cross-account trip-sharing sheet where the user types the recipient's TankSync account email (#2240).
  ///
  /// In en, this message translates to:
  /// **'Recipient email'**
  String get tripShareEmailLabel;

  /// Hint text inside the recipient-email field of the trip-sharing sheet (#2240). A neutral placeholder address.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get tripShareEmailHint;

  /// Button that submits the recipient email to create a direct account-to-account trip share (#2240).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tripShareSendButton;

  /// Button in the trip-sharing sheet that mints an unguessable share link the user can send to anyone; the recipient claims it to gain read access (#2240).
  ///
  /// In en, this message translates to:
  /// **'Create share link'**
  String get tripShareCreateLinkButton;

  /// Snackbar shown after a trip share link is generated and handed to the OS share sheet (#2240).
  ///
  /// In en, this message translates to:
  /// **'Share link copied — paste it to the recipient.'**
  String get tripShareLinkCreated;

  /// Snackbar confirming a direct account-to-account trip share succeeded (#2240).
  ///
  /// In en, this message translates to:
  /// **'Trip shared.'**
  String get tripShareSuccess;

  /// Snackbar shown when the recipient email entered in the trip-sharing sheet does not match any TankSync account (#2240).
  ///
  /// In en, this message translates to:
  /// **'No TankSync account uses that email.'**
  String get tripShareRecipientNotFound;

  /// Snackbar shown when creating a trip share fails for a non-specific reason (network / server) (#2240).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share this trip. Try again.'**
  String get tripShareError;

  /// Section header above the list of accounts / links this trip is already shared with, in the trip-sharing sheet (#2240).
  ///
  /// In en, this message translates to:
  /// **'Shared with'**
  String get tripShareExistingTitle;

  /// Empty-state caption under the 'Shared with' header when the trip has no active shares yet (#2240).
  ///
  /// In en, this message translates to:
  /// **'Not shared with anyone yet.'**
  String get tripShareExistingEmpty;

  /// Label for a direct account-to-account share row in the 'Shared with' list when the recipient's email isn't surfaced to the owner for privacy (#2240).
  ///
  /// In en, this message translates to:
  /// **'An account'**
  String get tripShareDirectRecipient;

  /// Label for a link-share row in the 'Shared with' list that no recipient has claimed yet (#2240).
  ///
  /// In en, this message translates to:
  /// **'Share link (unclaimed)'**
  String get tripShareLinkRecipient;

  /// Tooltip on the revoke (delete) button next to a share row in the 'Shared with' list (#2240).
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get tripShareRevokeTooltip;

  /// Snackbar confirming a trip share was revoked (#2240).
  ///
  /// In en, this message translates to:
  /// **'Share revoked.'**
  String get tripShareRevoked;

  /// Section header on the Trajets tab above the list of trips other accounts have shared with the current user (#2240).
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get trajetsSharedSectionTitle;

  /// Small badge on a trip row indicating the trip was shared with the user by another account and is read-only (#2240).
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get trajetsSharedBadge;

  /// Title of the 3-tap post-trip verdict prompt on the trip detail (#3501, epic #3498). The driver's subjective answer calibrates the driving-analysis thresholds (RPA/PKE/VAPOS bands, harsh-event gates) against how trips actually felt.
  ///
  /// In en, this message translates to:
  /// **'How did this trip feel?'**
  String get tripVerdictPromptTitle;

  /// Verdict chip (#3501): the trip felt calm/relaxed — no notable hard accelerations, braking or cornering.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get tripVerdictSmooth;

  /// Verdict chip (#3501): an ordinary trip — some brisk moments, nothing aggressive.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get tripVerdictModerate;

  /// Verdict chip (#3501): the trip had hard accelerations / late braking / sharp cornering.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get tripVerdictAggressive;

  /// Dismiss affordance (tooltip of the X button) on the verdict prompt (#3501). Dismissing is persisted per trip so the prompt never nags twice for the same trip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get tripVerdictDismiss;

  /// Confirmation line shown in place of the verdict prompt right after the driver answers (#3501).
  ///
  /// In en, this message translates to:
  /// **'Thanks — this helps calibrate your driving analysis.'**
  String get tripVerdictThanks;

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

  /// Error snackbar shown when a search request fails. Replaces a raw exception toString() that previously leaked stack-like text to the user (#1692).
  ///
  /// In en, this message translates to:
  /// **'Search failed — please try again'**
  String get searchFailedSnackbar;

  /// Station count shown in the route-results summary line (e.g. '29 stations'). Pluralised so '1 station' reads naturally (#2622).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 station} other{{count} stations}}'**
  String routeStationCount(int count);

  /// Wraps a station's pre-formatted last-updated timestamp so the value reads as a freshness indicator rather than a bare code (#2622). {time} is the upstream-provided, already-localized time string.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String stationUpdatedLabel(String time);

  /// Tooltip / accessibility label on the '+N' amenity overflow pill, listing the hidden amenities by localized name (#2622). {names} is a comma-joined list.
  ///
  /// In en, this message translates to:
  /// **'Also: {names}'**
  String amenityMoreTooltip(String names);

  /// Tooltip / accessibility label on the station-card favourite star when the station is NOT yet a favourite (#2622).
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteAdd;

  /// Tooltip / accessibility label on the station-card favourite star when the station IS already a favourite (#2622).
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favoriteRemove;

  /// Tooltip on the price headline when a loyalty discount applies, surfacing the un-discounted raw price for power users (#2622). {price} is an already-formatted price string.
  ///
  /// In en, this message translates to:
  /// **'Raw: {price}'**
  String loyaltyRawPriceTooltip(String price);

  /// Multi-country data-source attribution shown above a cross-border route result, joining each crossed country's provider credit (#2622). {sources} is the pre-joined ' · '-separated list, e.g. 'France — Prix-Carburants · Spain — Geoportal Gasolineras'.
  ///
  /// In en, this message translates to:
  /// **'{sources}'**
  String routeDataSourceMulti(String sources);

  /// Station-card title fallback for a forecourt that carries no brand AND no station name (#2926). The street stays as the address subtitle; this label replaces showing the bare street as a duplicate title.
  ///
  /// In en, this message translates to:
  /// **'Unbranded station'**
  String get stationUnbrandedTitle;

  /// Title of the dismissible banner shown on the search screen when the user's GPS-detected country has no fuel-price provider (#3361). Explains the lack of nearby prices is a coverage gap, not a bug.
  ///
  /// In en, this message translates to:
  /// **'Not available in your region yet'**
  String get unsupportedRegionTitle;

  /// Body of the unsupported-region banner (#3361). Tells the user fuel-price data isn't available for their detected country and that they can manually choose a supported country.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have fuel prices for your country yet, so results may be empty or from another country. You can still pick a supported country in the search settings.'**
  String get unsupportedRegionBody;

  /// Dismiss button on the unsupported-region banner (#3361).
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get unsupportedRegionDismiss;

  /// Title of the dismissible banner shown when the user's detected country IS supported but they haven't configured it (#3361), so the app is showing another country's prices.
  ///
  /// In en, this message translates to:
  /// **'Set your country'**
  String get configureCountryTitle;

  /// Body of the configure-country banner (#3361). Tells the user their country is supported but unconfigured, and to set it in the search settings.
  ///
  /// In en, this message translates to:
  /// **'Your country is supported, but it isn\'t set up yet — so prices may be from another country. Choose your country in the search settings to see local prices.'**
  String get configureCountryBody;

  /// Switch label on the vehicle edit screen (combustion section) shown only for E10/E85 flex-fuel vehicles. Declares this car may be filled with more than one fuel type, enabling the per-fuel cost-per-km comparison (#2885).
  ///
  /// In en, this message translates to:
  /// **'I may fill up with different fuel types'**
  String get vehicleMultiFuelCapableLabel;

  /// Helper subtitle under the multi-fuel-capable switch on the vehicle edit screen, explaining the per-fuel efficiency comparison it unlocks (#2885).
  ///
  /// In en, this message translates to:
  /// **'Tracks which fuel is cheapest per kilometre'**
  String get vehicleMultiFuelCapableHelper;

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

  /// Button on the new-vehicle edit screen that opens the reference catalog picker (#1372 phase 3) so users can pre-fill make/model/year/displacement/volumetricEfficiency from a curated list.
  ///
  /// In en, this message translates to:
  /// **'Pick from catalog'**
  String get pickerButtonLabel;

  /// Hint text shown in the search field of the reference vehicle picker bottom sheet (#1372 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Search make or model'**
  String get pickerSearchHint;

  /// Helper subtitle next to the picker button explaining the catalog size (#1372 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Pre-fill from 50+ supported vehicles'**
  String get pickerHelpText;

  /// Empty-state shown in the picker sheet when the search query matches no catalog entries (#1372 phase 3).
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get pickerEmptyResults;

  /// Cancel button in the reference vehicle picker bottom sheet (#1372 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pickerCancel;

  /// Loading-state label shown in the reference vehicle picker bottom sheet while the catalog asset is decoding (#1372 phase 3).
  ///
  /// In en, this message translates to:
  /// **'Loading catalog…'**
  String get pickerLoading;

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
  /// **'Your VIN is stored only locally in the app\'s encrypted storage — it\'s never uploaded to Sparkilo servers. The NHTSA vPIC database is queried with the VIN but returns only anonymous technical specs; NHTSA does not link the VIN to any personal data. Without network, an offline lookup returns manufacturer and country only.'**
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
  /// **'We looked up your VIN on NHTSA\'s free vehicle database — nothing sent to Sparkilo servers.'**
  String get vinConfirmPrivacyNote;

  /// GDPR consent toggle — short title for the opt-in to send the 17-character VIN to NHTSA's free public vPIC service to look up additional vehicle details (#1399). Used in both the first-launch consent screen and the settings page.
  ///
  /// In en, this message translates to:
  /// **'VIN online decode'**
  String get gdprVinOnlineDecodeTitle;

  /// GDPR consent toggle — one-line subtitle shown in the settings page alongside the toggle (#1399). Kept terse; the first-launch consent screen uses gdprVinOnlineDecodeDescription for the longer explanation.
  ///
  /// In en, this message translates to:
  /// **'Decode the VIN via NHTSA\'s free public service'**
  String get gdprVinOnlineDecodeShort;

  /// GDPR consent toggle — full description used on the first-launch consent screen (#1399). Mentions exactly what is sent (the VIN) and what is NOT sent (anything else) so the user can give informed consent.
  ///
  /// In en, this message translates to:
  /// **'When you pair an adapter, your vehicle\'s VIN is read locally to identify the car. Enabling this sends the 17-char VIN to NHTSA\'s free vPIC service to look up additional details (model, engine displacement, fuel type). The VIN is the only data sent — no other information leaves your device.'**
  String get gdprVinOnlineDecodeDescription;

  /// Short badge shown next to a vehicle profile field (make, model, year, etc.) whose value matches the VIN-decoded value, to signal the field was auto-populated rather than typed by the user (#1399).
  ///
  /// In en, this message translates to:
  /// **'(detected)'**
  String get vehicleDetectedFromVinBadge;

  /// Snackbar shown when the VIN-decoded values differ from values the user has already entered, offering to apply the detected values without silently overwriting (#1399).
  ///
  /// In en, this message translates to:
  /// **'Detected from VIN: {summary}. Apply?'**
  String vehicleDetectedFromVinSnackbar(String summary);

  /// Snackbar action button label — confirm applying the VIN-decoded values to the vehicle profile (#1399).
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get vehicleDetectedFromVinApply;

  /// Spoken text-to-speech announcement for a nearby cheap fuel station while in driving/approach mode (#2762). Resolved for the app's SELECTED locale (not the widget tree) and spoken by FlutterTtsAnnouncementService. name is the station brand or name; distanceKm is pre-formatted to one decimal place; fuelType is the fuel grade; euros/cents are the whole-euro and two-digit cents halves of the price. Keep this idiomatic for a driver hearing it aloud.
  ///
  /// In en, this message translates to:
  /// **'{name}, {distanceKm} kilometers ahead, {fuelType} {euros} euros {cents}'**
  String voiceStationAnnouncement(
    String name,
    String distanceKm,
    String fuelType,
    String euros,
    String cents,
  );

  /// Title of the home-screen widget help section in Settings (#1806).
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget'**
  String get widgetHelpSectionTitle;

  /// Intro line of the home-screen widget help section in Settings (#1806).
  ///
  /// In en, this message translates to:
  /// **'Add the SparKilo widget to your home screen to see fuel and charging prices at a glance.'**
  String get widgetHelpIntro;

  /// Help line explaining how to add the home-screen widget (#1806).
  ///
  /// In en, this message translates to:
  /// **'Add it from your launcher\'s widget picker — long-press an empty area of the home screen, choose Widgets, and find SparKilo.'**
  String get widgetHelpAdd;

  /// Help line explaining the home-screen widget's tap and refresh behaviour (#1806).
  ///
  /// In en, this message translates to:
  /// **'Tap a station in the widget to open it in the app. Tap the refresh icon to update prices.'**
  String get widgetHelpTap;

  /// Help line explaining how to reconfigure the Android home-screen widget (#1806). Shown only on fresh installs without an active profile; otherwise the in-app defaults editor (#2106) renders instead.
  ///
  /// In en, this message translates to:
  /// **'On Android, long-press the widget and choose Reconfigure to change the profile, colour, and content.'**
  String get widgetHelpConfigure;

  /// #2106 — italicised hint above the in-Settings widget-defaults editor explaining the live-override semantics.
  ///
  /// In en, this message translates to:
  /// **'Choices below apply to every installed widget on the next refresh.'**
  String get widgetDefaultsApplyToAllHint;

  /// #2106 — label above the widget colour-scheme dropdown in Settings.
  ///
  /// In en, this message translates to:
  /// **'Colour scheme'**
  String get widgetDefaultsColorLabel;

  /// #2106 — label above the widget content-variant SegmentedButton in Settings.
  ///
  /// In en, this message translates to:
  /// **'Content variant'**
  String get widgetDefaultsVariantLabel;

  /// #2106 — widget colour-scheme option that follows the OS dark/light mode.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get widgetColorSchemeSystem;

  /// #2106 — widget colour-scheme option (light background).
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get widgetColorSchemeLight;

  /// #2106 — widget colour-scheme option (dark background).
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get widgetColorSchemeDark;

  /// #2106 — widget colour-scheme option (blue accent).
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get widgetColorSchemeBlue;

  /// #2106 — widget colour-scheme option (green accent).
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get widgetColorSchemeGreen;

  /// #2106 — widget colour-scheme option (orange accent).
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get widgetColorSchemeOrange;

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
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return AppLocalizationsEnXa();
        }
        break;
      }
  }

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
