// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Tankstellen';

  @override
  String get search => 'Suche';

  @override
  String get favorites => 'Favoriten';

  @override
  String get map => 'Karte';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get gpsLocation => 'GPS-Standort';

  @override
  String get zipCode => 'Postleitzahl';

  @override
  String get zipCodeHint => 'z.B. 10115';

  @override
  String get fuelType => 'Kraftstoff';

  @override
  String get searchRadius => 'Umkreis';

  @override
  String get searchNearby => 'Tankstellen in der Nähe';

  @override
  String get searchButton => 'Suchen';

  @override
  String get searchCriteriaTitle => 'Suchkriterien';

  @override
  String get searchCriteriaOpen => 'Suchen';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Im Umkreis von $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tippen, um die Suche zu starten';

  @override
  String get noResults => 'Keine Tankstellen gefunden.';

  @override
  String get startSearch => 'Suche starten, um Tankstellen zu finden.';

  @override
  String get open => 'Geöffnet';

  @override
  String get closed => 'Geschlossen';

  @override
  String distance(String distance) {
    return '$distance entfernt';
  }

  @override
  String get price => 'Preis';

  @override
  String get prices => 'Preise';

  @override
  String get address => 'Adresse';

  @override
  String get openingHours => 'Öffnungszeiten';

  @override
  String get open24h => '24 Stunden geöffnet';

  @override
  String get navigate => 'Navigation starten';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get apiKeySetup => 'API-Schlüssel einrichten';

  @override
  String get apiKeyDescription =>
      'Registrieren Sie sich einmalig für einen kostenlosen API-Schlüssel.';

  @override
  String get apiKeyLabel => 'API-Schlüssel';

  @override
  String get register => 'Registrierung';

  @override
  String get continueButton => 'Weiter';

  @override
  String get welcome => 'Tankstellen';

  @override
  String get welcomeSubtitle =>
      'Finden Sie die günstigsten Kraftstoffpreise in Ihrer Nähe.';

  @override
  String get profileName => 'Profilname';

  @override
  String get preferredFuel => 'Bevorzugter Kraftstoff';

  @override
  String get defaultRadius => 'Standard-Umkreis';

  @override
  String get landingScreen => 'Startbildschirm';

  @override
  String get homeZip => 'Heim-PLZ';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get countryChangeTitle => 'Land wechseln?';

  @override
  String countryChangeBody(String country) {
    return 'Der Wechsel nach $country ändert:';
  }

  @override
  String get countryChangeCurrency => 'Währung';

  @override
  String get countryChangeDistance => 'Entfernung';

  @override
  String get countryChangeVolume => 'Volumen';

  @override
  String get countryChangePricePerUnit => 'Preisformat';

  @override
  String get countryChangeNote =>
      'Vorhandene Favoriten und Tankungen werden nicht umgerechnet; nur neue Einträge verwenden die neuen Einheiten.';

  @override
  String get countryChangeConfirm => 'Wechseln';

  @override
  String get delete => 'Löschen';

  @override
  String get activate => 'Aktivieren';

  @override
  String get configured => 'Konfiguriert';

  @override
  String get notConfigured => 'Nicht konfiguriert';

  @override
  String get about => 'Info';

  @override
  String get openSource => 'Open Source (MIT Lizenz)';

  @override
  String get sourceCode => 'Quellcode auf GitHub';

  @override
  String get noFavorites => 'Noch keine Favoriten';

  @override
  String get noFavoritesHint =>
      'Tippen Sie auf den Stern bei einer Tankstelle, um sie als Favorit zu speichern.';

  @override
  String get language => 'Sprache';

  @override
  String get country => 'Land';

  @override
  String get demoMode => 'Demo-Modus — Beispieldaten werden angezeigt.';

  @override
  String get setupLiveData => 'Für Live-Daten einrichten';

  @override
  String get freeNoKey => 'Kostenlos — kein Schlüssel nötig';

  @override
  String get apiKeyRequired => 'API-Schlüssel erforderlich';

  @override
  String get skipWithoutKey => 'Ohne Schlüssel fortfahren';

  @override
  String get dataTransparency => 'Datentransparenz';

  @override
  String get storageAndCache => 'Speicher & Cache';

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get errorLog => 'Fehlerprotokoll';

  @override
  String stationsFound(int count) {
    return '$count Tankstellen gefunden';
  }

  @override
  String get whatIsShared => 'Was wird geteilt — und mit wem?';

  @override
  String get gpsCoordinates => 'GPS-Koordinaten';

  @override
  String get gpsReason =>
      'Wird bei jeder Standort-Suche gesendet, um Tankstellen in der Nähe zu finden.';

  @override
  String get postalCodeData => 'Postleitzahl';

  @override
  String get postalReason => 'Wird bei PLZ-Suche in Koordinaten umgewandelt.';

  @override
  String get mapViewport => 'Kartenausschnitt';

  @override
  String get mapReason =>
      'Beim Öffnen der Karte werden Kartenkacheln geladen. Keine persönlichen Daten werden übertragen.';

  @override
  String get apiKeyData => 'API-Schlüssel';

  @override
  String get apiKeyReason =>
      'Ihr persönlicher Schlüssel wird bei jeder API-Anfrage mitgesendet.';

  @override
  String get notShared => 'Wird NICHT geteilt:';

  @override
  String get searchHistory => 'Suchverlauf';

  @override
  String get favoritesData => 'Favoritenanlage';

  @override
  String get profileNames => 'Profilnamen';

  @override
  String get homeZipData => 'Heim-PLZ';

  @override
  String get usageData => 'App-Nutzungsdaten';

  @override
  String get privacyBanner =>
      'Diese App hat keinen eigenen Server. Alle Daten bleiben auf Ihrem Gerät. Keine Analyse, kein Tracking, keine Werbung.';

  @override
  String get storageUsage => 'Speichernutzung auf diesem Gerät';

  @override
  String get settingsLabel => 'Einstellungen';

  @override
  String get profilesStored => 'Profile gespeichert';

  @override
  String get stationsMarked => 'Tankstellen gemerkt';

  @override
  String get cachedResponses => 'zwischengespeicherte Antworten';

  @override
  String get total => 'Gesamt';

  @override
  String get cacheManagement => 'Cache-Verwaltung';

  @override
  String get cacheDescription =>
      'Der Cache speichert API-Antworten für schnellere Ladezeiten und Offline-Zugriff.';

  @override
  String get stationSearch => 'Tankstellen-Suche';

  @override
  String get stationDetails => 'Stationsdetails';

  @override
  String get priceQuery => 'Preisabfrage';

  @override
  String get zipGeocoding => 'PLZ-Geocodierung';

  @override
  String minutes(int n) {
    return '$n Minuten';
  }

  @override
  String hours(int n) {
    return '$n Stunden';
  }

  @override
  String get clearCacheTitle => 'Cache leeren?';

  @override
  String get clearCacheBody =>
      'Zwischengespeicherte Suchergebnisse und Preise werden gelöscht. Profile, Favoriten und Einstellungen bleiben erhalten.';

  @override
  String get clearCacheButton => 'Cache leeren';

  @override
  String get deleteAllTitle => 'Alle Daten löschen?';

  @override
  String get deleteAllBody =>
      'Dies löscht unwiderruflich alle Profile, Favoriten, den API-Schlüssel, alle Einstellungen und den gesamten Cache.';

  @override
  String get deleteAllButton => 'Alles löschen';

  @override
  String get entries => 'Einträge';

  @override
  String get cacheEmpty => 'Cache ist leer';

  @override
  String get noStorage => 'Kein Speicher belegt';

  @override
  String get apiKeyNote =>
      'Kostenlose Registrierung. Daten von den Markttransparenzstellen.';

  @override
  String get apiKeyFormatError =>
      'Ungültiges Format — UUID erwartet (8-4-4-4-12)';

  @override
  String get supportProject => 'Dieses Projekt unterstützen';

  @override
  String get supportDescription =>
      'Diese App ist kostenlos, Open Source und ohne Werbung. Wenn Sie sie nützlich finden, unterstützen Sie den Entwickler.';

  @override
  String get reportBug => 'Fehler melden / Funktion vorschlagen';

  @override
  String get reportThisIssue => 'Dieses Problem melden';

  @override
  String get reportConsentTitle => 'Auf GitHub melden?';

  @override
  String get reportConsentBody =>
      'Dies öffnet ein öffentliches GitHub-Issue mit den unten gezeigten Fehlerdetails. Keine GPS-Koordinaten, API-Schlüssel oder persönlichen Daten werden übermittelt.';

  @override
  String get reportConsentConfirm => 'GitHub öffnen';

  @override
  String get reportConsentCancel => 'Abbrechen';

  @override
  String get configProfileSection => 'Profil';

  @override
  String get configActiveProfile => 'Aktives Profil';

  @override
  String get configPreferredFuel => 'Bevorzugter Kraftstoff';

  @override
  String get configCountry => 'Land';

  @override
  String get configRouteSegment => 'Streckenabschnitt';

  @override
  String get configApiKeysSection => 'API-Schlüssel';

  @override
  String get configTankerkoenigKey => 'Tankerkönig API-Schlüssel';

  @override
  String get configApiKeyConfigured => 'Konfiguriert';

  @override
  String get configApiKeyNotSet => 'Nicht gesetzt (Demo-Modus)';

  @override
  String get configApiKeyCommunity => 'Standard-Community-Schlüssel';

  @override
  String get searchLocationPlaceholder => 'Adresse, Postleitzahl oder Stadt';

  @override
  String get configEvKey => 'Ladesäulen API-Schlüssel';

  @override
  String get configEvKeyCustom => 'Eigener Schlüssel';

  @override
  String get configEvKeyShared => 'Standard (geteilt)';

  @override
  String get configCloudSyncSection => 'Cloud-Sync';

  @override
  String get configTankSyncConnected => 'Verbunden';

  @override
  String get configTankSyncDisabled => 'Deaktiviert';

  @override
  String get configAuthMode => 'Anmeldeverfahren';

  @override
  String get configAuthEmail => 'E-Mail (dauerhaft)';

  @override
  String get configAuthAnonymous => 'Anonym (nur dieses Gerät)';

  @override
  String get configDatabase => 'Datenbank';

  @override
  String get configPrivacySummary => 'Datenschutz-Zusammenfassung';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favoriten, Preisalarme und ignorierte Tankstellen werden in Ihre private Datenbank synchronisiert\n• GPS-Position und API-Schlüssel verlassen Ihr Gerät nie\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Alle Daten werden nur lokal auf diesem Gerät gespeichert\n• Es werden keine Daten an einen Server gesendet\n• API-Schlüssel sind im sicheren Gerätespeicher verschlüsselt';

  @override
  String get configAuthNoteEmail =>
      'E-Mail-Konto ermöglicht gerätübergreifenden Zugriff';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymes Konto — Daten an dieses Gerät gebunden';

  @override
  String get configNone => 'Keine';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get fuels => 'Kraftstoffe';

  @override
  String get services => 'Services';

  @override
  String get zone => 'Zone';

  @override
  String get highway => 'Autobahn';

  @override
  String get localStation => 'Ortsnahe Tankstelle';

  @override
  String get lastUpdate => 'Letzte Aktualisierung';

  @override
  String get automate24h => '24h/24 — Automat';

  @override
  String get refreshPrices => 'Preise aktualisieren';

  @override
  String get station => 'Tankstelle';

  @override
  String get locationDenied =>
      'Standortfreigabe abgelehnt. Sie können per PLZ suchen.';

  @override
  String get demoModeBanner =>
      'Demo-Modus. API-Schlüssel in den Einstellungen eingeben.';

  @override
  String get sortDistance => 'Entfernung';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Bewertung';

  @override
  String get sortPriceDistance => 'Preis/km';

  @override
  String get cheap => 'günstig';

  @override
  String get expensive => 'teuer';

  @override
  String stationsOnMap(int count) {
    return '$count Tankstellen';
  }

  @override
  String get loadingFavorites =>
      'Favoriten werden geladen...\nSuchen Sie zuerst Tankstellen, um Daten zu speichern.';

  @override
  String get reportPrice => 'Preis melden';

  @override
  String get whatsWrong => 'Was stimmt nicht?';

  @override
  String get correctPrice => 'Korrekter Preis (z.B. 1,459)';

  @override
  String get sendReport => 'Meldung senden';

  @override
  String get reportSent => 'Meldung gesendet. Vielen Dank!';

  @override
  String get enterValidPrice => 'Bitte korrekten Preis eingeben';

  @override
  String get cacheCleared => 'Cache wurde geleert.';

  @override
  String get yourPosition => 'Ihre Position';

  @override
  String get positionUnknown => 'Position unbekannt';

  @override
  String get distancesFromCenter => 'Entfernungen vom Suchzentrum';

  @override
  String get autoUpdatePosition => 'Position automatisch aktualisieren';

  @override
  String get autoUpdateDescription =>
      'GPS-Position vor jeder Suche aktualisieren';

  @override
  String get location => 'Standort';

  @override
  String get switchProfileTitle => 'Land gewechselt';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Sie sind jetzt in $country. Zum Profil \"$profile\" wechseln?';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Gewechselt zu Profil \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Kein Profil für dieses Land';

  @override
  String noProfileForCountry(String country) {
    return 'Sie befinden sich in $country, aber es ist kein Profil dafür konfiguriert. Erstellen Sie eins in den Einstellungen.';
  }

  @override
  String get autoSwitchProfile => 'Profil automatisch wechseln';

  @override
  String get autoSwitchDescription =>
      'Profil beim Grenzübertritt automatisch wechseln';

  @override
  String get switchProfile => 'Wechseln';

  @override
  String get dismiss => 'Schließen';

  @override
  String get profileCountry => 'Land';

  @override
  String get profileLanguage => 'Sprache';

  @override
  String get settingsStorageDetail => 'API-Schlüssel, aktives Profil';

  @override
  String get allFuels => 'Alle';

  @override
  String get priceAlerts => 'Preisalarme';

  @override
  String get noPriceAlerts => 'Keine Preisalarme';

  @override
  String get noPriceAlertsHint =>
      'Erstellen Sie einen Alarm auf der Detailseite einer Tankstelle.';

  @override
  String alertDeleted(String name) {
    return 'Alarm \"$name\" gelöscht';
  }

  @override
  String get createAlert => 'Preisalarm erstellen';

  @override
  String currentPrice(String price) {
    return 'Aktueller Preis: $price';
  }

  @override
  String get targetPrice => 'Zielpreis (EUR)';

  @override
  String get enterPrice => 'Bitte einen Preis eingeben';

  @override
  String get invalidPrice => 'Ungültiger Preis';

  @override
  String get priceTooHigh => 'Preis zu hoch';

  @override
  String get create => 'Erstellen';

  @override
  String get alertCreated => 'Preisalarm erstellt';

  @override
  String get wrongE5Price => 'Falscher Super E5 Preis';

  @override
  String get wrongE10Price => 'Falscher Super E10 Preis';

  @override
  String get wrongDieselPrice => 'Falscher Diesel Preis';

  @override
  String get wrongStatusOpen => 'Als geöffnet angezeigt, aber geschlossen';

  @override
  String get wrongStatusClosed => 'Als geschlossen angezeigt, aber geöffnet';

  @override
  String get searchAlongRouteLabel => 'Entlang der Route';

  @override
  String get searchEvStations => 'Ladestationen suchen';

  @override
  String get allStations => 'Alle Stationen';

  @override
  String get bestStops => 'Beste Stopps';

  @override
  String get openInMaps => 'In Karten öffnen';

  @override
  String get noStationsAlongRoute =>
      'Keine Stationen entlang der Route gefunden';

  @override
  String get evOperational => 'In Betrieb';

  @override
  String get evStatusUnknown => 'Status unbekannt';

  @override
  String evConnectors(int count) {
    return 'Anschlüsse ($count Punkte)';
  }

  @override
  String get evNoConnectors => 'Keine Anschlussdetails verfügbar';

  @override
  String get evUsageCost => 'Nutzungskosten';

  @override
  String get evPricingUnavailable => 'Preisangabe vom Anbieter nicht verfügbar';

  @override
  String get evLastUpdated => 'Zuletzt aktualisiert';

  @override
  String get evUnknown => 'Unbekannt';

  @override
  String get evDataAttribution => 'Daten von OpenChargeMap (Community-basiert)';

  @override
  String get evStatusDisclaimer =>
      'Der Status spiegelt möglicherweise nicht die Echtzeit-Verfügbarkeit wider. Tippen Sie auf Aktualisieren, um die neuesten Daten abzurufen.';

  @override
  String get evNavigateToStation => 'Zur Station navigieren';

  @override
  String get evRefreshStatus => 'Status aktualisieren';

  @override
  String get evStatusUpdated => 'Status aktualisiert';

  @override
  String get evStationNotFound =>
      'Aktualisierung fehlgeschlagen — Station nicht in der Nähe gefunden';

  @override
  String get addedToFavorites => 'Zu Favoriten hinzugefügt';

  @override
  String get removedFromFavorites => 'Aus Favoriten entfernt';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String get currentLocation => 'Aktueller Standort';

  @override
  String get gpsError => 'GPS-Fehler';

  @override
  String get couldNotResolve => 'Start oder Ziel konnte nicht aufgelöst werden';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Ziel';

  @override
  String get cityAddressOrGps => 'Stadt, Adresse oder GPS';

  @override
  String get cityOrAddress => 'Stadt oder Adresse';

  @override
  String get useGps => 'GPS verwenden';

  @override
  String get stop => 'Stopp';

  @override
  String stopN(int n) {
    return 'Stopp $n';
  }

  @override
  String get addStop => 'Stopp hinzufügen';

  @override
  String get searchAlongRoute => 'Entlang der Route suchen';

  @override
  String get cheapest => 'Günstigste';

  @override
  String nStations(int count) {
    return '$count Tankstellen';
  }

  @override
  String nBest(int count) {
    return '$count beste';
  }

  @override
  String get fuelPricesTankerkoenig => 'Kraftstoffpreise (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Erforderlich für die Kraftstoffpreissuche in Deutschland';

  @override
  String get evChargingOpenChargeMap => 'E-Laden (OpenChargeMap)';

  @override
  String get customKey => 'Eigener Schlüssel';

  @override
  String get appDefaultKey => 'Standard-App-Schlüssel';

  @override
  String get optionalOverrideKey =>
      'Optional: den integrierten App-Schlüssel mit Ihrem eigenen überschreiben';

  @override
  String get requiredForEvSearch =>
      'Erforderlich für die Suche nach E-Ladestationen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get fuelPricesApiKey => 'Kraftstoffpreise API-Schlüssel';

  @override
  String get tankerkoenigApiKey => 'Tankerkoenig API-Schlüssel';

  @override
  String get evChargingApiKey => 'E-Laden API-Schlüssel';

  @override
  String get openChargeMapApiKey => 'OpenChargeMap API-Schlüssel';

  @override
  String get routeSegment => 'Routenabschnitt';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Günstigste Station alle $km km entlang der Route anzeigen';
  }

  @override
  String get avoidHighways => 'Autobahnen vermeiden';

  @override
  String get avoidHighwaysDesc =>
      'Routenberechnung vermeidet Mautstraßen und Autobahnen';

  @override
  String get showFuelStations => 'Tankstellen anzeigen';

  @override
  String get showFuelStationsDesc =>
      'Benzin-, Diesel-, LPG-, CNG-Stationen einbeziehen';

  @override
  String get showEvStations => 'E-Ladestationen anzeigen';

  @override
  String get showEvStationsDesc =>
      'Elektrische Ladestationen in Suchergebnissen einbeziehen';

  @override
  String get noStationsAlongThisRoute =>
      'Keine Stationen entlang dieser Route gefunden.';

  @override
  String get fuelCostCalculator => 'Kraftstoffkostenrechner';

  @override
  String get distanceKm => 'Entfernung (km)';

  @override
  String get consumptionL100km => 'Verbrauch (L/100km)';

  @override
  String get fuelPriceEurL => 'Kraftstoffpreis (EUR/L)';

  @override
  String get tripCost => 'Fahrtkosten';

  @override
  String get fuelNeeded => 'Benötigter Kraftstoff';

  @override
  String get totalCost => 'Gesamtkosten';

  @override
  String get enterCalcValues =>
      'Geben Sie Entfernung, Verbrauch und Preis ein, um die Fahrtkosten zu berechnen';

  @override
  String get priceHistory => 'Preisverlauf';

  @override
  String get noPriceHistory => 'Noch kein Preisverlauf';

  @override
  String get noHourlyData => 'Keine Stundendaten';

  @override
  String get noStatistics => 'Keine Statistiken verfügbar';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statAvg => 'Mittel';

  @override
  String get showAllFuelTypes => 'Alle Kraftstoffarten anzeigen';

  @override
  String get connected => 'Verbunden';

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get connectTankSync => 'TankSync verbinden';

  @override
  String get disconnectTankSync => 'TankSync trennen';

  @override
  String get viewMyData => 'Meine Daten anzeigen';

  @override
  String get optionalCloudSync =>
      'Optionale Cloud-Synchronisierung für Alarme, Favoriten und Push-Benachrichtigungen';

  @override
  String get tapToUpdateGps => 'Tippen, um GPS-Position zu aktualisieren';

  @override
  String get gpsAutoUpdateHint =>
      'Die GPS-Position wird automatisch bei der Suche ermittelt. Sie können sie auch hier manuell aktualisieren.';

  @override
  String get clearGpsConfirm =>
      'Gespeicherte GPS-Position löschen? Sie können sie jederzeit erneut aktualisieren.';

  @override
  String get pageNotFound => 'Seite nicht gefunden';

  @override
  String get deleteAllServerData => 'Alle Serverdaten löschen';

  @override
  String get deleteServerDataConfirm => 'Alle Serverdaten löschen?';

  @override
  String get deleteEverything => 'Alles löschen';

  @override
  String get allDataDeleted => 'Alle Serverdaten gelöscht';

  @override
  String get disconnectConfirm => 'TankSync trennen?';

  @override
  String get disconnect => 'Trennen';

  @override
  String get myServerData => 'Meine Serverdaten';

  @override
  String get anonymousUuid => 'Anonyme UUID';

  @override
  String get server => 'Server';

  @override
  String get syncedData => 'Synchronisierte Daten';

  @override
  String get pushTokens => 'Push-Tokens';

  @override
  String get priceReports => 'Preismeldungen';

  @override
  String get totalItems => 'Einträge gesamt';

  @override
  String get estimatedSize => 'Geschätzte Größe';

  @override
  String get viewRawJson => 'Rohdaten als JSON anzeigen';

  @override
  String get exportJson => 'Als JSON exportieren (Zwischenablage)';

  @override
  String get jsonCopied => 'JSON in Zwischenablage kopiert';

  @override
  String get rawDataJson => 'Rohdaten (JSON)';

  @override
  String get close => 'Schließen';

  @override
  String get account => 'Konto';

  @override
  String get continueAsGuest => 'Als Gast fortfahren';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get upgradeToEmail => 'E-Mail-Konto erstellen';

  @override
  String get savedRoutes => 'Gespeicherte Routen';

  @override
  String get noSavedRoutes => 'Keine gespeicherten Routen';

  @override
  String get noSavedRoutesHint =>
      'Suche entlang einer Route und speichere sie fuer schnellen Zugriff.';

  @override
  String get saveRoute => 'Route speichern';

  @override
  String get routeName => 'Routenname';

  @override
  String itineraryDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String loadingRoute(String name) {
    return 'Route wird geladen: $name';
  }

  @override
  String get refreshFailed =>
      'Aktualisierung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get deleteProfileTitle => 'Profil löschen?';

  @override
  String get deleteProfileBody =>
      'Dieses Profil und seine Einstellungen werden unwiderruflich gelöscht.';

  @override
  String get deleteProfileConfirm => 'Profil löschen';

  @override
  String get errorNetwork => 'Netzwerkfehler. Überprüfe deine Verbindung.';

  @override
  String get errorServer => 'Serverfehler. Bitte später erneut versuchen.';

  @override
  String get errorTimeout => 'Zeitüberschreitung. Bitte erneut versuchen.';

  @override
  String get errorNoConnection => 'Keine Internetverbindung.';

  @override
  String get errorApiKey =>
      'Ungültiger API-Schlüssel. Überprüfe deine Einstellungen.';

  @override
  String get errorLocation => 'Standort konnte nicht ermittelt werden.';

  @override
  String get errorNoApiKey =>
      'Kein API-Schlüssel konfiguriert. In Einstellungen hinzufügen.';

  @override
  String get errorAllServicesFailed =>
      'Daten konnten nicht geladen werden. Verbindung prüfen.';

  @override
  String get errorCache =>
      'Lokaler Datenfehler. Cache leeren und erneut versuchen.';

  @override
  String get errorCancelled => 'Anfrage wurde abgebrochen.';

  @override
  String get errorUnknown => 'Ein unerwarteter Fehler ist aufgetreten.';

  @override
  String get onboardingWelcomeHint =>
      'Richten Sie die App in wenigen Schritten ein.';

  @override
  String get onboardingApiKeyDescription =>
      'Registrieren Sie sich für einen kostenlosen API-Schlüssel oder überspringen Sie diesen Schritt für Demo-Daten.';

  @override
  String get onboardingComplete => 'Alles bereit!';

  @override
  String get onboardingCompleteHint =>
      'Sie können diese Einstellungen jederzeit in Ihrem Profil ändern.';

  @override
  String get onboardingBack => 'Zurück';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingFinish => 'Los geht\'s';

  @override
  String crossBorderNearby(String country) {
    return '$country ist in der Nähe';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km bis zur Grenze';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Ø hier: $price EUR ($count Tankstellen)';
  }

  @override
  String get allPricesView => 'Alle Preise';

  @override
  String get compactView => 'Kompakt';

  @override
  String get switchToAllPricesView => 'Zur Alle-Preise-Ansicht wechseln';

  @override
  String get switchToCompactView => 'Zur Kompaktansicht wechseln';

  @override
  String get unavailable => 'k.A.';

  @override
  String get outOfStock => 'Ausverkauft';

  @override
  String get gdprTitle => 'Ihre Privatsphäre';

  @override
  String get gdprSubtitle =>
      'Diese App respektiert Ihre Privatsphäre. Wählen Sie, welche Daten Sie teilen möchten. Sie können diese Einstellungen jederzeit ändern.';

  @override
  String get gdprLocationTitle => 'Standortzugriff';

  @override
  String get gdprLocationDescription =>
      'Ihre Koordinaten werden an die Kraftstoffpreis-API gesendet, um Tankstellen in der Nähe zu finden. Standortdaten werden nie auf einem Server gespeichert und nicht für Tracking verwendet.';

  @override
  String get gdprLocationShort =>
      'Tankstellen in der Nähe über Ihren Standort finden';

  @override
  String get gdprErrorReportingTitle => 'Fehlermeldungen';

  @override
  String get gdprErrorReportingDescription =>
      'Anonyme Absturzberichte helfen, die App zu verbessern. Keine persönlichen Daten enthalten. Berichte werden nur bei Konfiguration über Sentry gesendet.';

  @override
  String get gdprErrorReportingShort =>
      'Anonyme Absturzberichte zur Verbesserung der App senden';

  @override
  String get gdprCloudSyncTitle => 'Cloud-Synchronisierung';

  @override
  String get gdprCloudSyncDescription =>
      'Favoriten und Preisalarme geräteübergreifend über TankSync synchronisieren. Verwendet anonyme Authentifizierung. Ihre Daten werden verschlüsselt übertragen.';

  @override
  String get gdprCloudSyncShort =>
      'Favoriten und Alarme geräteübergreifend synchronisieren';

  @override
  String get gdprLegalBasis =>
      'Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung). Sie können Ihre Einwilligung jederzeit in den Einstellungen widerrufen.';

  @override
  String get gdprAcceptAll => 'Alle akzeptieren';

  @override
  String get gdprAcceptSelected => 'Auswahl akzeptieren';

  @override
  String get gdprSettingsHint =>
      'Sie können Ihre Datenschutzeinstellungen jederzeit ändern.';

  @override
  String get routeSaved => 'Route gespeichert!';

  @override
  String get routeSaveFailed => 'Route konnte nicht gespeichert werden';

  @override
  String get sqlCopied => 'SQL in Zwischenablage kopiert';

  @override
  String get connectionDataCopied => 'Verbindungsdaten kopiert';

  @override
  String get accountDeleted => 'Konto gelöscht. Lokale Daten bleiben erhalten.';

  @override
  String get switchedToAnonymous => 'Zu anonymer Sitzung gewechselt';

  @override
  String failedToSwitch(String error) {
    return 'Wechsel fehlgeschlagen: $error';
  }

  @override
  String get topicUrlCopied => 'Themen-URL kopiert';

  @override
  String get testNotificationSent => 'Testbenachrichtigung gesendet!';

  @override
  String get testNotificationFailed =>
      'Testbenachrichtigung konnte nicht gesendet werden';

  @override
  String get pushUpdateFailed =>
      'Push-Benachrichtigungseinstellung konnte nicht aktualisiert werden';

  @override
  String get connectedAsGuest => 'Als Gast verbunden';

  @override
  String get accountCreated => 'Konto erstellt!';

  @override
  String get signedIn => 'Angemeldet!';

  @override
  String stationHidden(String name) {
    return '$name ausgeblendet';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name aus Favoriten entfernt';
  }

  @override
  String invalidApiKey(String error) {
    return 'Ungültiger API-Schlüssel: $error';
  }

  @override
  String get invalidQrCode => 'Ungültiges QR-Code-Format';

  @override
  String get invalidQrCodeTankSync =>
      'Ungültiger QR-Code — TankSync-Format erwartet';

  @override
  String get tankSyncConnected => 'TankSync verbunden!';

  @override
  String get syncCompleted =>
      'Synchronisierung abgeschlossen — Daten aktualisiert';

  @override
  String get deviceCodeCopied => 'Gerätecode kopiert';

  @override
  String get undo => 'Rückgängig';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Bitte geben Sie eine gültige $length-stellige $label ein';
  }

  @override
  String get freshnessAgo => 'her';

  @override
  String get freshnessStale => 'Veraltet';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Datenaktualität: $age';
  }

  @override
  String get passwordStrengthWeak => 'Schwach';

  @override
  String get passwordStrengthFair => 'Mittel';

  @override
  String get passwordStrengthStrong => 'Stark';

  @override
  String get passwordReqMinLength => 'Mindestens 8 Zeichen';

  @override
  String get passwordReqUppercase => 'Mindestens 1 Großbuchstabe';

  @override
  String get passwordReqLowercase => 'Mindestens 1 Kleinbuchstabe';

  @override
  String get passwordReqDigit => 'Mindestens 1 Zahl';

  @override
  String get passwordReqSpecial => 'Mindestens 1 Sonderzeichen';

  @override
  String get passwordTooWeak => 'Passwort erfüllt nicht alle Anforderungen';

  @override
  String get brandFilterAll => 'Alle';

  @override
  String get brandFilterNoHighway => 'Keine Autobahn';

  @override
  String get swipeTutorialMessage =>
      'Nach rechts wischen zum Navigieren, nach links zum Entfernen';

  @override
  String get swipeTutorialDismiss => 'Verstanden';

  @override
  String get alertStatsActive => 'Aktiv';

  @override
  String get alertStatsToday => 'Heute';

  @override
  String get alertStatsThisWeek => 'Diese Woche';

  @override
  String get privacyDashboardTitle => 'Datenschutz-Dashboard';

  @override
  String get privacyDashboardSubtitle =>
      'Daten anzeigen, exportieren oder löschen';

  @override
  String get privacyDashboardBanner =>
      'Ihre Daten gehören Ihnen. Hier sehen Sie alles, was diese App speichert, und können es exportieren oder löschen.';

  @override
  String get privacyLocalData => 'Daten auf diesem Gerät';

  @override
  String get privacyIgnoredStations => 'Ausgeblendete Stationen';

  @override
  String get privacyRatings => 'Stationsbewertungen';

  @override
  String get privacyPriceHistory => 'Preisverlauf-Stationen';

  @override
  String get privacyProfiles => 'Suchprofile';

  @override
  String get privacyItineraries => 'Gespeicherte Routen';

  @override
  String get privacyCacheEntries => 'Cache-Einträge';

  @override
  String get privacyApiKey => 'API-Schlüssel gespeichert';

  @override
  String get privacyEvApiKey => 'EV-API-Schlüssel gespeichert';

  @override
  String get privacyEstimatedSize => 'Geschätzter Speicherverbrauch';

  @override
  String get privacySyncedData => 'Cloud-Sync (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Cloud-Sync ist deaktiviert. Alle Daten bleiben nur auf diesem Gerät.';

  @override
  String get privacySyncMode => 'Sync-Modus';

  @override
  String get privacySyncUserId => 'Benutzer-ID';

  @override
  String get privacySyncDescription =>
      'Bei aktiviertem Sync werden Favoriten, Alarme, ausgeblendete Stationen und Bewertungen auch auf dem TankSync-Server gespeichert.';

  @override
  String get privacyViewServerData => 'Serverdaten anzeigen';

  @override
  String get privacyExportButton => 'Alle Daten als JSON exportieren';

  @override
  String get privacyExportSuccess => 'Daten in die Zwischenablage exportiert';

  @override
  String get privacyExportCsvButton => 'Alle Daten als CSV exportieren';

  @override
  String get privacyExportCsvSuccess =>
      'CSV-Daten in die Zwischenablage exportiert';

  @override
  String get privacyDeleteButton => 'Alle Daten löschen';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Fehlerprotokoll in Zwischenablage kopieren ($count)';
  }

  @override
  String get privacyDeleteTitle => 'Alle Daten löschen?';

  @override
  String get privacyDeleteBody =>
      'Dies löscht unwiderruflich:\n\n- Alle Favoriten und Stationsdaten\n- Alle Suchprofile\n- Alle Preisalarme\n- Allen Preisverlauf\n- Alle zwischengespeicherten Daten\n- Ihren API-Schlüssel\n- Alle App-Einstellungen\n\nDie App wird auf den Ausgangszustand zurückgesetzt. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get privacyDeleteConfirm => 'Alles löschen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get amenities => 'Ausstattung';

  @override
  String get amenityShop => 'Shop';

  @override
  String get amenityCarWash => 'Waschanlage';

  @override
  String get amenityAirPump => 'Luft';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Essen';

  @override
  String get amenityAtm => 'Geldautomat';

  @override
  String get amenityWifi => 'WLAN';

  @override
  String get amenityEv => 'E-Laden';

  @override
  String get paymentMethods => 'Zahlungsarten';

  @override
  String get paymentMethodCash => 'Bargeld';

  @override
  String get paymentMethodCard => 'Karte';

  @override
  String get paymentMethodContactless => 'Kontaktlos';

  @override
  String get paymentMethodFuelCard => 'Tankkarte';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Mit $app bezahlen';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Verglichen mit dem Durchschnitt deiner letzten 3 Tankungen ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Verbrauch $value L/100 km, $delta gegenüber deinem Durchschnitt';
  }

  @override
  String get drivingMode => 'Fahrmodus';

  @override
  String get drivingExit => 'Beenden';

  @override
  String get drivingNearestStation => 'Nächste';

  @override
  String get drivingTapToUnlock => 'Tippen zum Entsperren';

  @override
  String get drivingSafetyTitle => 'Sicherheitshinweis';

  @override
  String get drivingSafetyMessage =>
      'Bedienen Sie die App nicht während der Fahrt. Halten Sie an einem sicheren Ort an, bevor Sie den Bildschirm bedienen. Der Fahrer ist jederzeit für die sichere Führung des Fahrzeugs verantwortlich.';

  @override
  String get drivingSafetyAccept => 'Verstanden';

  @override
  String get voiceAnnouncementsTitle => 'Sprachansagen';

  @override
  String get voiceAnnouncementsDescription =>
      'Günstige Tankstellen beim Fahren ansagen';

  @override
  String get voiceAnnouncementsEnabled => 'Sprachansagen aktivieren';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Nur unter $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance Kilometer voraus, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Ansage-Radius';

  @override
  String get voiceAnnouncementCooldown => 'Wiederholungsintervall';

  @override
  String get nearestStations => 'Nächste Tankstellen';

  @override
  String get nearestStationsHint =>
      'Die nächstgelegenen Tankstellen über Ihren Standort finden';

  @override
  String get consumptionLogTitle => 'Verbrauch';

  @override
  String get consumptionLogMenuTitle => 'Verbrauchs-Log';

  @override
  String get consumptionLogMenuSubtitle =>
      'Tankvorgänge erfassen und L/100km berechnen';

  @override
  String get consumptionStatsTitle => 'Verbrauchsstatistik';

  @override
  String get addFillUp => 'Tankvorgang hinzufügen';

  @override
  String get noFillUpsTitle => 'Noch keine Tankvorgänge';

  @override
  String get noFillUpsSubtitle =>
      'Erfassen Sie Ihren ersten Tankvorgang, um den Verbrauch zu verfolgen.';

  @override
  String get fillUpDate => 'Datum';

  @override
  String get liters => 'Liter';

  @override
  String get odometerKm => 'Kilometerstand (km)';

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get stationPreFilled => 'Tankstelle vorausgefüllt';

  @override
  String get statAvgConsumption => 'Ø L/100km';

  @override
  String get statAvgCostPerKm => 'Ø Kosten/km';

  @override
  String get statTotalLiters => 'Gesamt Liter';

  @override
  String get statTotalSpent => 'Gesamt ausgegeben';

  @override
  String get statFillUpCount => 'Tankvorgänge';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get fieldInvalidNumber => 'Ungültige Zahl';

  @override
  String get carbonDashboardTitle => 'CO2-Übersicht';

  @override
  String get carbonTabCharts => 'Diagramme';

  @override
  String get carbonTabAchievements => 'Erfolge';

  @override
  String get carbonEmptyTitle => 'Noch keine Daten';

  @override
  String get carbonEmptySubtitle =>
      'Erfasse Tankvorgänge, um deine CO2-Übersicht zu sehen.';

  @override
  String get carbonSummaryTotalCost => 'Gesamtkosten';

  @override
  String get carbonSummaryTotalCo2 => 'CO2 gesamt';

  @override
  String get monthlyCostsTitle => 'Monatliche Kosten';

  @override
  String get monthlyEmissionsTitle => 'Monatliche CO2-Emissionen';

  @override
  String get milestonesTitle => 'Meilensteine';

  @override
  String get milestoneFirstFillUp => 'Erster Tankvorgang erfasst';

  @override
  String get milestoneTenFillUps => '10 Tankvorgänge erfasst';

  @override
  String get milestoneFiftyFillUps => '50 Tankvorgänge erfasst';

  @override
  String get milestoneHundredLiters => '100 L erfasst';

  @override
  String get milestoneThousandLiters => '1000 L erfasst';

  @override
  String get milestoneHundredKgCo2 => '100 kg CO2 erfasst';

  @override
  String get milestoneOneTonneCo2 => '1 Tonne CO2 erfasst';

  @override
  String get milestoneThousandKm => '1000 km gefahren';

  @override
  String get milestoneTenThousandKm => '10.000 km gefahren';

  @override
  String get fuelVsEvTitle => 'Sprit vs. E-Auto';

  @override
  String get fuelVsEvSubtitle => 'CO2-Vergleich für dieselbe gefahrene Strecke';

  @override
  String get fuelVsEvYourFuel => 'Dein Sprit';

  @override
  String get fuelVsEvEquivalent => 'E-Auto (äquivalent)';

  @override
  String get fuelVsEvDistance => 'Strecke';

  @override
  String get fuelVsEvDifference => 'Differenz';

  @override
  String get shareProgress => 'Teilen';

  @override
  String get shareCopied => 'In Zwischenablage kopiert';

  @override
  String shareCo2Message(String kg) {
    return 'Ich habe mit Tankstellen $kg kg CO2 erfasst.';
  }

  @override
  String get vehiclesTitle => 'Meine Fahrzeuge';

  @override
  String get vehiclesMenuTitle => 'Meine Fahrzeuge';

  @override
  String get vehiclesMenuSubtitle => 'Batterie, Anschlüsse, Ladevorlieben';

  @override
  String get vehiclesEmptyMessage =>
      'Fügen Sie Ihr Fahrzeug hinzu, um nach Anschlüssen zu filtern und Ladekosten zu schätzen.';

  @override
  String get vehiclesWizardTitle => 'Meine Fahrzeuge (optional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Fügen Sie Ihr Auto hinzu, um das Verbrauchsprotokoll vorzubelegen und EV-Anschlussfilter zu aktivieren. Sie können diesen Schritt überspringen und Fahrzeuge später hinzufügen.';

  @override
  String get vehiclesWizardNoneYet => 'Noch kein Fahrzeug konfiguriert.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrzeuge',
      one: '1 Fahrzeug',
    );
    return 'Sie haben $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Überspringen, um die Einrichtung abzuschließen — Sie können Fahrzeuge jederzeit in den Einstellungen hinzufügen.';

  @override
  String get fillUpVehicleLabel => 'Fahrzeug';

  @override
  String get fillUpVehicleNone => 'Kein Fahrzeug';

  @override
  String get fillUpVehicleRequired => 'Fahrzeug erforderlich';

  @override
  String get reportScanError => 'Scan-Fehler melden';

  @override
  String get pickStationTitle => 'Tankstelle wählen';

  @override
  String get pickStationHelper =>
      'Tankvorgang von einer bekannten Tankstelle starten — Preise, Marke und Kraftstoff werden automatisch übernommen.';

  @override
  String get pickStationEmpty =>
      'Noch keine Favoriten — fügen Sie welche aus Suche oder Favoriten hinzu, oder überspringen Sie diesen Schritt.';

  @override
  String get pickStationSkip => 'Überspringen — ohne Tankstelle eintragen';

  @override
  String get scanPump => 'Zapfsäule scannen';

  @override
  String get scanPayment => 'Zahlungs-QR scannen';

  @override
  String get qrPaymentBeneficiary => 'Empfänger';

  @override
  String get qrPaymentAmount => 'Betrag';

  @override
  String get qrPaymentEpcTitle => 'SEPA-Überweisung';

  @override
  String get qrPaymentEpcEmpty => 'Keine Felder erkannt';

  @override
  String get qrPaymentOpenInBank => 'In Banking-App öffnen';

  @override
  String get qrPaymentLaunchFailed => 'Keine App kann diesen Code öffnen';

  @override
  String get qrPaymentUnknownTitle => 'Code nicht erkannt';

  @override
  String get qrPaymentCopyRaw => 'Rohtext kopieren';

  @override
  String get qrPaymentCopiedRaw => 'In Zwischenablage kopiert';

  @override
  String get qrPaymentReport => 'Scan melden';

  @override
  String get qrPaymentEpcCopied =>
      'Bankdaten kopiert — in Banking-App einfügen';

  @override
  String get qrScannerGuidance => 'Kamera auf einen QR-Code richten';

  @override
  String get qrScannerPermissionDenied =>
      'Kamerazugriff wird zum Scannen benötigt.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Kamerazugriff wurde verweigert. Einstellungen öffnen, um ihn freizugeben.';

  @override
  String get qrScannerRetryPermission => 'Erneut versuchen';

  @override
  String get qrScannerOpenSettings => 'Einstellungen öffnen';

  @override
  String get qrScannerTimeout =>
      'Kein QR-Code erkannt. Näher herangehen oder erneut versuchen.';

  @override
  String get qrScannerRetry => 'Erneut versuchen';

  @override
  String get torchOn => 'Blitz einschalten';

  @override
  String get torchOff => 'Blitz ausschalten';

  @override
  String get obdNoAdapter => 'Kein OBD2-Adapter in Reichweite';

  @override
  String get obdOdometerUnavailable =>
      'Kilometerstand konnte nicht gelesen werden';

  @override
  String get obdPermissionDenied =>
      'Bluetooth-Berechtigung in den Einstellungen erteilen';

  @override
  String get obdAdapterUnresponsive =>
      'Keine Antwort — Zündung einschalten und neu versuchen';

  @override
  String get obdPickerTitle => 'OBD2-Adapter wählen';

  @override
  String get obdPickerScanning => 'Suche nach Adaptern…';

  @override
  String get obdPickerConnecting => 'Verbinden…';

  @override
  String get themeSettingTitle => 'Design';

  @override
  String get themeModeLight => 'Hell';

  @override
  String get themeModeDark => 'Dunkel';

  @override
  String get themeModeSystem => 'Systemeinstellung';

  @override
  String get tripRecordingTitle => 'Fahrt wird aufgezeichnet';

  @override
  String get tripSummaryTitle => 'Fahrtzusammenfassung';

  @override
  String get tripMetricDistance => 'Strecke';

  @override
  String get tripMetricSpeed => 'Geschwindigkeit';

  @override
  String get tripMetricFuelUsed => 'Verbraucht';

  @override
  String get tripMetricAvgConsumption => 'Ø';

  @override
  String get tripMetricElapsed => 'Dauer';

  @override
  String get tripMetricOdometer => 'Kilometerstand';

  @override
  String get tripStop => 'Aufzeichnung beenden';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Fortsetzen';

  @override
  String get tripBannerRecording => 'Fahrt wird aufgezeichnet';

  @override
  String get tripBannerPaused => 'Fahrt pausiert — zum Fortsetzen tippen';

  @override
  String get navConsumption => 'Verbrauch';

  @override
  String get vehicleBaselineSectionTitle => 'Baseline-Kalibrierung';

  @override
  String get vehicleBaselineEmpty =>
      'Noch keine Messwerte — starte eine OBD2-Fahrt, um das Verbrauchsprofil dieses Fahrzeugs zu lernen.';

  @override
  String get vehicleBaselineProgress =>
      'Anhand der Messwerte aus verschiedenen Fahrsituationen gelernt.';

  @override
  String get vehicleBaselineReset => 'Baseline zurücksetzen';

  @override
  String get vehicleBaselineResetConfirmTitle => 'Baseline zurücksetzen?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Dadurch werden alle gelernten Werte für dieses Fahrzeug verworfen. Bis neue Fahrten die Daten wieder aufbauen, werden die Kaltstart-Standardwerte verwendet.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2-Adapter';

  @override
  String get vehicleAdapterEmpty =>
      'Kein Adapter gekoppelt. Koppeln, damit die App sich beim nächsten Mal automatisch verbindet.';

  @override
  String get vehicleAdapterUnnamed => 'Unbekannter Adapter';

  @override
  String get vehicleAdapterPair => 'Adapter koppeln';

  @override
  String get vehicleAdapterForget => 'Adapter vergessen';

  @override
  String get achievementsTitle => 'Erfolge';

  @override
  String get achievementFirstTrip => 'Erste Fahrt';

  @override
  String get achievementFirstTripDesc => 'Zeichne deine erste OBD2-Fahrt auf.';

  @override
  String get achievementFirstFillUp => 'Erste Tankung';

  @override
  String get achievementFirstFillUpDesc => 'Trage deine erste Tankung ein.';

  @override
  String get achievementTenTrips => '10 Fahrten';

  @override
  String get achievementTenTripsDesc => 'Zeichne 10 OBD2-Fahrten auf.';

  @override
  String get achievementZeroHarsh => 'Ruhiger Fahrer';

  @override
  String get achievementZeroHarshDesc =>
      'Schließe eine Fahrt von mindestens 10 km ohne starkes Bremsen oder Beschleunigen ab.';

  @override
  String get achievementEcoWeek => 'Öko-Woche';

  @override
  String get achievementEcoWeekDesc =>
      'Fahre 7 Tage in Folge mit mindestens einer ruhigen Fahrt pro Tag.';

  @override
  String get achievementPriceWin => 'Preis-Treffer';

  @override
  String get achievementPriceWinDesc =>
      'Trage eine Tankung ein, die den 30-Tage-Durchschnitt der Station um mindestens 5 % schlägt.';

  @override
  String get syncBaselinesToggleTitle => 'Gelernte Fahrzeugprofile teilen';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Pro-Fahrzeug-Verbrauchsbaselines hochladen, damit ein zweites Gerät sie wiederverwenden kann.';

  @override
  String get obd2StatusConnected => 'OBD2-Adapter: verbunden';

  @override
  String get obd2StatusAttempting => 'OBD2-Adapter: verbindet';

  @override
  String get obd2StatusUnreachable => 'OBD2-Adapter: nicht erreichbar';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2-Adapter: Bluetooth-Berechtigung erforderlich';

  @override
  String get obd2StatusConnectedBody => 'Bereit für eine Fahrtaufzeichnung.';

  @override
  String get obd2StatusAttemptingBody =>
      'Verbindung wird im Hintergrund aufgebaut…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter ausser Reichweite oder wird von einer anderen App verwendet.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Bluetooth-Berechtigung in den Systemeinstellungen erteilen, um automatisch neu zu verbinden.';

  @override
  String get obd2StatusNoAdapter => 'Kein Adapter gekoppelt';

  @override
  String get obd2StatusForget => 'Adapter vergessen';

  @override
  String get tripHistoryTitle => 'Fahrtenverlauf';

  @override
  String get tripHistoryEmptyTitle => 'Noch keine Fahrten';

  @override
  String get tripHistoryEmptySubtitle =>
      'OBD2-Adapter anschließen und eine Fahrt aufzeichnen, um deinen Fahrtenverlauf aufzubauen.';

  @override
  String get tripHistoryUnknownDate => 'Unbekanntes Datum';

  @override
  String get situationIdle => 'Leerlauf';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Stadtverkehr';

  @override
  String get situationHighway => 'Autobahn';

  @override
  String get situationDecel => 'Verzögerung';

  @override
  String get situationClimbing => 'Steigung / beladen';

  @override
  String get situationHardAccel => 'Harte Beschl.';

  @override
  String get situationFuelCut => 'Schubabschaltung';

  @override
  String get tripSaveAsFillUp => 'Als Tankfüllung speichern';

  @override
  String get tripDiscard => 'Verwerfen';

  @override
  String obdOdometerRead(int km) {
    return 'Kilometerstand gelesen: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Nicht gesetzt';

  @override
  String get wizardVehicleTapToEdit => 'Zum Bearbeiten tippen';

  @override
  String get wizardVehicleDefaultBadge => 'Standard';

  @override
  String get profileDefaultVehicleLabel => 'Standardfahrzeug (optional)';

  @override
  String get profileDefaultVehicleNone => 'Kein Standard';

  @override
  String get profileFuelFromVehicleHint =>
      'Kraftstoff wird aus dem Standardfahrzeug abgeleitet. Fahrzeug entfernen, um einen Kraftstoff direkt zu wählen.';

  @override
  String get consumptionNoVehicleTitle => 'Fahrzeug zuerst hinzufügen';

  @override
  String get consumptionNoVehicleBody =>
      'Tankvorgänge werden einem Fahrzeug zugeordnet. Fügen Sie Ihr Auto hinzu, um den Verbrauch zu erfassen.';

  @override
  String get vehicleAdd => 'Fahrzeug hinzufügen';

  @override
  String get vehicleAddTitle => 'Fahrzeug hinzufügen';

  @override
  String get vehicleEditTitle => 'Fahrzeug bearbeiten';

  @override
  String get vehicleDeleteTitle => 'Fahrzeug löschen?';

  @override
  String vehicleDeleteMessage(String name) {
    return '„$name“ aus Ihren Profilen entfernen?';
  }

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameHint => 'z. B. Mein Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Verbrenner';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Elektro';

  @override
  String get vehicleEvSectionTitle => 'Elektro';

  @override
  String get vehicleCombustionSectionTitle => 'Verbrenner';

  @override
  String get vehicleBatteryLabel => 'Batteriekapazität (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max. Ladeleistung (kW)';

  @override
  String get vehicleConnectorsLabel => 'Unterstützte Anschlüsse';

  @override
  String get vehicleMinSocLabel => 'Min. SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max. SoC %';

  @override
  String get vehicleTankLabel => 'Tankvolumen (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Bevorzugter Kraftstoff';

  @override
  String get connectorType2 => 'Typ 2';

  @override
  String get connectorCcs => 'CCS';

  @override
  String get connectorChademo => 'CHAdeMO';

  @override
  String get connectorTesla => 'Tesla';

  @override
  String get connectorSchuko => 'Schuko';

  @override
  String get connectorType1 => 'Typ 1';

  @override
  String get connectorThreePin => 'Schuko 3-polig';

  @override
  String get evShowOnMap => 'Ladestationen anzeigen';

  @override
  String get evAvailableOnly => 'Nur verfügbare';

  @override
  String get evMinPower => 'Min. Leistung';

  @override
  String get evMaxPower => 'Max. Leistung';

  @override
  String get evOperator => 'Betreiber';

  @override
  String get evLastUpdate => 'Letzte Aktualisierung';

  @override
  String get evStatusAvailable => 'Verfügbar';

  @override
  String get evStatusOccupied => 'Belegt';

  @override
  String get evStatusOutOfOrder => 'Außer Betrieb';

  @override
  String get openOnlyFilter => 'Nur geöffnete';

  @override
  String get saveAsDefaults => 'Als Standard speichern';

  @override
  String get criteriaSavedToProfile => 'Als Standard gespeichert';

  @override
  String get profileNotFound => 'Kein aktives Profil';

  @override
  String get updatingFavorites => 'Favoriten werden aktualisiert…';

  @override
  String get fetchingLatestPrices => 'Neueste Preise werden geladen';

  @override
  String get noDataAvailable => 'Keine Daten';

  @override
  String get configAndPrivacy => 'Konfiguration & Datenschutz';

  @override
  String get searchToSeeMap =>
      'Suchen Sie, um Tankstellen auf der Karte zu sehen';

  @override
  String get evPowerAny => 'Alle';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profil';

  @override
  String get sectionLocation => 'Standort';

  @override
  String get tooltipBack => 'Zurück';

  @override
  String get tooltipClose => 'Schließen';

  @override
  String get tooltipClearSearch => 'Sucheingabe löschen';

  @override
  String get tooltipUseGps => 'GPS-Standort verwenden';

  @override
  String get tooltipShowPassword => 'Passwort anzeigen';

  @override
  String get tooltipHidePassword => 'Passwort verbergen';

  @override
  String get evConnectorsLabel => 'Verfügbare Steckertypen';

  @override
  String get evConnectorsNone => 'Keine Steckerinformationen';

  @override
  String get switchToEmail => 'Zu E-Mail wechseln';

  @override
  String get switchToEmailSubtitle =>
      'Daten behalten, Anmeldung von anderen Geräten';

  @override
  String get switchToAnonymousAction => 'Zu anonym wechseln';

  @override
  String get switchToAnonymousSubtitle =>
      'Lokale Daten behalten, neue anonyme Sitzung';

  @override
  String get linkDevice => 'Gerät verknüpfen';

  @override
  String get shareDatabase => 'Datenbank teilen';

  @override
  String get disconnectAction => 'Trennen';

  @override
  String get disconnectSubtitle =>
      'Synchronisierung stoppen (lokale Daten bleiben)';

  @override
  String get deleteAccountAction => 'Konto löschen';

  @override
  String get deleteAccountSubtitle => 'Alle Serverdaten dauerhaft entfernen';

  @override
  String get localOnly => 'Nur lokal';

  @override
  String get localOnlySubtitle =>
      'Optional: Favoriten, Alarme und Bewertungen geräteübergreifend synchronisieren';

  @override
  String get setupCloudSync => 'Cloud-Sync einrichten';

  @override
  String get disconnectTitle => 'TankSync trennen?';

  @override
  String get disconnectBody =>
      'Cloud-Synchronisierung wird deaktiviert. Ihre lokalen Daten (Favoriten, Alarme, Verlauf) bleiben auf diesem Gerät erhalten. Serverdaten werden nicht gelöscht.';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountBody =>
      'Alle Ihre Daten werden dauerhaft vom Server gelöscht (Favoriten, Alarme, Bewertungen, Routen). Lokale Daten auf diesem Gerät bleiben erhalten.\n\nDies kann nicht rückgängig gemacht werden.';

  @override
  String get switchToAnonymousTitle => 'Zu anonym wechseln?';

  @override
  String get switchToAnonymousBody =>
      'Sie werden von Ihrem E-Mail-Konto abgemeldet und mit einer neuen anonymen Sitzung fortfahren.\n\nIhre lokalen Daten (Favoriten, Alarme) bleiben auf diesem Gerät und werden mit dem neuen anonymen Konto synchronisiert.';

  @override
  String get switchAction => 'Wechseln';

  @override
  String get helpBannerCriteria =>
      'Ihre Profil-Standardwerte sind vorausgefüllt. Passen Sie die Kriterien unten an, um Ihre Suche zu verfeinern.';

  @override
  String get helpBannerAlerts =>
      'Legen Sie einen Preisgrenzwert für eine Station fest. Sie werden benachrichtigt, wenn die Preise darunter fallen. Prüfungen laufen alle 30 Minuten.';

  @override
  String get helpBannerConsumption =>
      'Erfassen Sie jede Tankfüllung, um Ihren tatsächlichen Verbrauch und CO₂-Fußabdruck zu verfolgen. Wischen Sie nach links, um einen Eintrag zu löschen.';

  @override
  String get helpBannerVehicles =>
      'Fügen Sie Ihre Fahrzeuge hinzu, damit Tankfüllungen und Kraftstoffvorgaben korrekt voreingestellt werden. Das erste Fahrzeug wird zum Standard.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get onboardingPreferencesTitle => 'Ihre Einstellungen';

  @override
  String get onboardingZipHelper =>
      'Wird verwendet, wenn GPS nicht verfügbar ist';

  @override
  String get onboardingRadiusHelper => 'Größerer Radius = mehr Ergebnisse';

  @override
  String get onboardingPrivacy =>
      'Diese Einstellungen werden nur auf Ihrem Gerät gespeichert und niemals geteilt.';

  @override
  String get onboardingLandingTitle => 'Startbildschirm';

  @override
  String get onboardingLandingHint =>
      'Wählen Sie, welcher Bildschirm beim Start der App angezeigt wird.';

  @override
  String get scanReceipt => 'Beleg scannen';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Kraftstoff';

  @override
  String get stationTypeEv => 'Elektro';

  @override
  String get brandFilterHighway => 'Autobahn';

  @override
  String get ratingModeLocal => 'Lokal';

  @override
  String get ratingModePrivate => 'Privat';

  @override
  String get ratingModeShared => 'Geteilt';

  @override
  String get ratingDescLocal => 'Bewertungen nur auf diesem Gerät gespeichert';

  @override
  String get ratingDescPrivate =>
      'Mit Ihrer Datenbank synchronisiert (nicht für andere sichtbar)';

  @override
  String get ratingDescShared => 'Für alle Nutzer Ihrer Datenbank sichtbar';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap-API-Schlüssel nicht konfiguriert. Fügen Sie einen in den Einstellungen hinzu, um Ladestationen zu suchen.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Der Datenanbieter ($host) verwendet ein abgelaufenes oder ungültiges TLS-Zertifikat. Die App kann von dieser Quelle keine Daten laden, bis der Anbieter das Problem behebt. Bitte wenden Sie sich an $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed nicht verfügbar. Verwende $current.';
  }

  @override
  String get errorTitleApiKey => 'API-Schlüssel erforderlich';

  @override
  String get errorTitleLocation => 'Standort nicht verfügbar';

  @override
  String get errorHintNoStations =>
      'Erhöhen Sie den Suchradius oder suchen Sie an einem anderen Ort.';

  @override
  String get errorHintApiKey =>
      'Konfigurieren Sie Ihren API-Schlüssel in den Einstellungen.';

  @override
  String get errorHintConnection =>
      'Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get errorHintRouting =>
      'Routenberechnung fehlgeschlagen. Prüfen Sie Ihre Internetverbindung.';

  @override
  String get errorHintFallback =>
      'Versuchen Sie es erneut oder suchen Sie nach Postleitzahl / Stadt.';

  @override
  String get detailsLabel => 'Details';

  @override
  String get remove => 'Entfernen';

  @override
  String get showKey => 'Schlüssel anzeigen';

  @override
  String get hideKey => 'Schlüssel verbergen';

  @override
  String get syncOptionalTitle => 'TankSync ist optional';

  @override
  String get syncOptionalDescription =>
      'Die App funktioniert auch ohne Cloud-Sync. Mit TankSync synchronisieren Sie Favoriten, Alarme und Bewertungen geräteübergreifend über Supabase (kostenloses Kontingent verfügbar).';

  @override
  String get syncHowToConnectQuestion => 'Wie möchten Sie verbinden?';

  @override
  String get syncCreateOwnTitle => 'Eigene Datenbank erstellen';

  @override
  String get syncCreateOwnSubtitle =>
      'Kostenloses Supabase-Projekt — wir führen Sie Schritt für Schritt';

  @override
  String get syncJoinExistingTitle => 'Vorhandener Datenbank beitreten';

  @override
  String get syncJoinExistingSubtitle =>
      'QR-Code des Datenbank-Besitzers scannen oder Zugangsdaten einfügen';

  @override
  String get syncChooseAccountType => 'Kontotyp wählen';

  @override
  String get syncAccountTypeAnonymous => 'Anonym';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Sofort, ohne E-Mail. Daten sind an dieses Gerät gebunden.';

  @override
  String get syncAccountTypeEmail => 'E-Mail-Konto';

  @override
  String get syncAccountTypeEmailDesc =>
      'Von jedem Gerät anmelden. Daten bei Geräteverlust wiederherstellen.';

  @override
  String get syncHaveAccountSignIn => 'Bereits ein Konto? Anmelden';

  @override
  String get syncCreateNewAccount => 'Neues Konto erstellen';

  @override
  String get syncTestConnection => 'Verbindung testen';

  @override
  String get syncTestingConnection => 'Teste...';

  @override
  String get syncConnectButton => 'Verbinden';

  @override
  String get syncConnectingButton => 'Verbinde...';

  @override
  String get syncDatabaseReady => 'Datenbank bereit!';

  @override
  String get syncDatabaseNeedsSetup => 'Datenbank-Setup erforderlich';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Fehlt';

  @override
  String get syncSqlEditorInstructions =>
      'Kopieren Sie das SQL unten und führen Sie es im Supabase-SQL-Editor aus (Dashboard → SQL-Editor → Neue Abfrage → Einfügen → Ausführen)';

  @override
  String get syncCopySqlButton => 'SQL in Zwischenablage kopieren';

  @override
  String get syncRecheckSchemaButton => 'Schema erneut prüfen';

  @override
  String get syncDoneButton => 'Fertig';

  @override
  String syncSignedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get syncEmailDescription =>
      'Ihre Daten werden geräteübergreifend mit dieser E-Mail synchronisiert.';

  @override
  String get syncSwitchToAnonymousTitle => 'Zu anonym wechseln';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Ohne E-Mail fortfahren, neue anonyme Sitzung';

  @override
  String get syncGuestDescription => 'Anonym, ohne E-Mail.';

  @override
  String get syncOrDivider => 'oder';

  @override
  String get syncHowToSyncQuestion => 'Wie möchten Sie synchronisieren?';

  @override
  String get syncOfflineDescription =>
      'Die App funktioniert vollständig offline. Cloud-Sync ist optional.';

  @override
  String get syncModeCommunityTitle => 'Tankstellen-Gemeinschaft';

  @override
  String get syncModeCommunitySubtitle =>
      'Favoriten & Bewertungen mit allen Nutzern teilen';

  @override
  String get syncModePrivateTitle => 'Private Datenbank';

  @override
  String get syncModePrivateSubtitle =>
      'Eigene Supabase — volle Datenkontrolle';

  @override
  String get syncModeGroupTitle => 'Gruppe beitreten';

  @override
  String get syncModeGroupSubtitle => 'Familien- oder Freundeskreis-Datenbank';

  @override
  String get syncPrivacyShared => 'Geteilt';

  @override
  String get syncPrivacyPrivate => 'Privat';

  @override
  String get syncPrivacyGroup => 'Gruppe';

  @override
  String get syncStayOfflineButton => 'Offline bleiben';

  @override
  String get syncSuccessTitle => 'Erfolgreich verbunden!';

  @override
  String get syncSuccessDescription =>
      'Ihre Daten werden jetzt automatisch synchronisiert.';

  @override
  String get syncWizardTitleConnect => 'TankSync verbinden';

  @override
  String get syncSetupTitleYourDatabase => 'Ihre Datenbank';

  @override
  String get syncSetupTitleJoinGroup => 'Gruppe beitreten';

  @override
  String get syncSetupTitleAccount => 'Ihr Konto';

  @override
  String get syncWizardBack => 'Zurück';

  @override
  String get syncWizardNext => 'Weiter';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Supabase-Projekt erstellen';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Unten auf \"Supabase öffnen\" tippen\n2. Kostenloses Konto erstellen (falls noch nicht vorhanden)\n3. Auf \"New Project\" klicken\n4. Namen und Region wählen\n5. Etwa 2 Minuten warten, bis es bereit ist';

  @override
  String get syncWizardOpenSupabase => 'Supabase öffnen';

  @override
  String get syncWizardEnableAnonTitle => 'Anonyme Anmeldungen aktivieren';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Im Supabase-Dashboard:\n   Authentication → Providers\n2. \"Anonymous Sign-ins\" suchen\n3. Aktivieren\n4. \"Save\" klicken';

  @override
  String get syncWizardOpenAuthSettings => 'Auth-Einstellungen öffnen';

  @override
  String get syncWizardCopyCredentialsTitle => 'Zugangsdaten kopieren';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Zu Settings → API im Dashboard gehen\n2. \"Project URL\" kopieren\n3. Den \"anon public\"-Schlüssel kopieren\n4. Beide unten einfügen';

  @override
  String get syncWizardOpenApiSettings => 'API-Einstellungen öffnen';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase-URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://ihr-projekt.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Bestehender Datenbank beitreten';

  @override
  String get syncWizardScanQrCode => 'QR-Code scannen';

  @override
  String get syncWizardAskOwnerQr =>
      'Bitten Sie den Datenbank-Besitzer, den QR-Code zu zeigen\n(Einstellungen → TankSync → Teilen)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Bitten Sie den Datenbank-Besitzer, den QR-Code zu zeigen';

  @override
  String get syncWizardEnterManuallyTitle => 'Manuell eingeben';

  @override
  String get syncWizardOrEnterManually => 'oder manuell eingeben';

  @override
  String get syncWizardUrlHelperText =>
      'Leerzeichen und Zeilenumbrüche werden automatisch entfernt';

  @override
  String get syncCredentialsPrivateHint =>
      'Geben Sie Ihre Supabase-Zugangsdaten ein. Sie finden diese im Dashboard unter Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Datenbank-URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Zugangsschlüssel';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'E-Mail';

  @override
  String get authPasswordLabel => 'Passwort';

  @override
  String get authConfirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get authPleaseEnterEmail => 'Bitte E-Mail eingeben';

  @override
  String get authInvalidEmail => 'Ungültige E-Mail-Adresse';

  @override
  String get authPasswordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get authConnectAnonymously => 'Anonym verbinden';

  @override
  String get authCreateAccountAndConnect => 'Konto erstellen & verbinden';

  @override
  String get authSignInAndConnect => 'Anmelden & verbinden';

  @override
  String get authAnonymousSegment => 'Anonym';

  @override
  String get authEmailSegment => 'E-Mail';

  @override
  String get authAnonymousDescription =>
      'Sofortiger Zugang, keine E-Mail erforderlich. Daten sind an dieses Gerät gebunden.';

  @override
  String get authEmailDescription =>
      'Anmeldung von jedem Gerät. Daten wiederherstellen, falls Handy verloren geht.';

  @override
  String get authSyncAcrossDevices =>
      'Daten automatisch auf allen Geräten synchronisieren.';

  @override
  String get authNewHereCreateAccount => 'Neu hier? Konto erstellen';

  @override
  String get ntfyCardTitle => 'Push-Benachrichtigungen (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'ntfy.sh-Push aktivieren';

  @override
  String get ntfyEnableSubtitle => 'Preisalarme über ntfy.sh erhalten';

  @override
  String get ntfyTopicUrlLabel => 'Topic-URL';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Topic-URL kopieren';

  @override
  String get ntfySendTestButton => 'Testbenachrichtigung senden';

  @override
  String get ntfyFdroidHint =>
      'Installieren Sie die ntfy-App aus F-Droid, um Push-Benachrichtigungen auf Ihrem Gerät zu empfangen.';

  @override
  String get ntfyConnectFirstHint =>
      'Verbinden Sie zuerst TankSync, um Push-Benachrichtigungen zu aktivieren.';

  @override
  String get linkDeviceScreenTitle => 'Gerät verknüpfen';

  @override
  String get linkDeviceThisDeviceLabel => 'Dieses Gerät';

  @override
  String get linkDeviceShareCodeHint =>
      'Teilen Sie diesen Code mit Ihrem anderen Gerät:';

  @override
  String get linkDeviceNotConnected => 'Nicht verbunden';

  @override
  String get linkDeviceCopyCodeTooltip => 'Code kopieren';

  @override
  String get linkDeviceImportSectionTitle => 'Von anderem Gerät importieren';

  @override
  String get linkDeviceImportDescription =>
      'Geben Sie den Gerätecode Ihres anderen Geräts ein, um dessen Favoriten, Alarme, Fahrzeuge und Tankprotokoll zu importieren. Jedes Gerät behält sein eigenes Profil und seine Voreinstellungen.';

  @override
  String get linkDeviceCodeFieldLabel => 'Gerätecode';

  @override
  String get linkDeviceCodeFieldHint => 'UUID vom anderen Gerät einfügen';

  @override
  String get linkDeviceImportButton => 'Daten importieren';

  @override
  String get linkDeviceHowItWorksTitle => 'So funktioniert es';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Auf Gerät A: Gerätecode oben kopieren\n2. Auf Gerät B: in das Feld \"Gerätecode\" einfügen\n3. \"Daten importieren\" tippen, um Favoriten, Alarme, Fahrzeuge und Tankprotokoll zusammenzuführen\n4. Beide Geräte haben dann alle kombinierten Daten\n\nJedes Gerät behält seine eigene anonyme Identität und sein eigenes Profil (bevorzugter Kraftstoff, Standardfahrzeug, Startbildschirm). Daten werden zusammengeführt, nicht verschoben.';

  @override
  String get vehicleSetActive => 'Aktivieren';

  @override
  String get swipeHide => 'Ausblenden';

  @override
  String get evChargingSection => 'Elektro-Laden';

  @override
  String get fuelStationsSection => 'Tankstellen';

  @override
  String get yourRating => 'Ihre Bewertung';

  @override
  String get noStorageUsed => 'Kein Speicher verwendet';

  @override
  String get aboutReportBug => 'Fehler melden / Funktion vorschlagen';

  @override
  String get aboutSupportProject => 'Dieses Projekt unterstützen';

  @override
  String get aboutSupportDescription =>
      'Diese App ist kostenlos, Open Source und werbefrei. Wenn sie Ihnen gefällt, unterstützen Sie bitte den Entwickler.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Die Kraftstoffpreise in Luxemburg sind staatlich reguliert und landesweit einheitlich.';

  @override
  String get luxembourgFuelUnleaded95 => 'Super bleifrei 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Super bleifrei 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'Autogas';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxemburgs regulierte Preise sind nicht verfügbar.';

  @override
  String get reportIssueTitle => 'Problem melden';

  @override
  String get enterCorrection => 'Bitte Korrektur eingeben';

  @override
  String get reportNoBackendAvailable =>
      'Die Meldung konnte nicht gesendet werden: Für dieses Land ist kein Meldedienst konfiguriert. Aktivieren Sie TankSync in den Einstellungen, um Community-Meldungen zu senden.';

  @override
  String get correctName => 'Korrekter Tankstellenname';

  @override
  String get correctAddress => 'Korrekte Adresse';

  @override
  String get wrongE85Price => 'Falscher E85 Preis';

  @override
  String get wrongE98Price => 'Falscher Super 98 Preis';

  @override
  String get wrongLpgPrice => 'Falscher LPG Preis';

  @override
  String get wrongStationName => 'Falscher Tankstellenname';

  @override
  String get wrongStationAddress => 'Falsche Adresse';

  @override
  String get independentStation => 'Unabhängige Tankstelle';
}
