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
  String get supportProject => 'Dieses Projekt unterstützen';

  @override
  String get supportDescription =>
      'Diese App ist kostenlos, Open Source und ohne Werbung. Wenn Sie sie nützlich finden, unterstützen Sie den Entwickler.';

  @override
  String get reportBug => 'Fehler melden / Funktion vorschlagen';

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
}
