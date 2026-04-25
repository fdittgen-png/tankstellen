// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Τιμές Καυσίμων';

  @override
  String get search => 'Αναζήτηση';

  @override
  String get favorites => 'Αγαπημένα';

  @override
  String get map => 'Χάρτης';

  @override
  String get profile => 'Προφίλ';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get gpsLocation => 'Τοποθεσία GPS';

  @override
  String get zipCode => 'Ταχυδρομικός κώδικας';

  @override
  String get zipCodeHint => 'π.χ. 10431';

  @override
  String get fuelType => 'Καύσιμο';

  @override
  String get searchRadius => 'Ακτίνα';

  @override
  String get searchNearby => 'Κοντινά βενζινάδικα';

  @override
  String get searchButton => 'Αναζήτηση';

  @override
  String get searchCriteriaTitle => 'Search criteria';

  @override
  String get searchCriteriaOpen => 'Search';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Within $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Tap to start searching';

  @override
  String get noResults => 'Δεν βρέθηκαν βενζινάδικα.';

  @override
  String get startSearch => 'Αναζητήστε για να βρείτε βενζινάδικα.';

  @override
  String get open => 'Ανοιχτό';

  @override
  String get closed => 'Κλειστό';

  @override
  String distance(String distance) {
    return '$distance μακριά';
  }

  @override
  String get price => 'Τιμή';

  @override
  String get prices => 'Τιμές';

  @override
  String get address => 'Διεύθυνση';

  @override
  String get openingHours => 'Ωράριο';

  @override
  String get open24h => 'Ανοιχτό 24 ώρες';

  @override
  String get navigate => 'Πλοήγηση';

  @override
  String get retry => 'Δοκιμάστε ξανά';

  @override
  String get apiKeySetup => 'Κλειδί API';

  @override
  String get apiKeyDescription => 'Εγγραφείτε μία φορά για δωρεάν κλειδί API.';

  @override
  String get apiKeyLabel => 'Κλειδί API';

  @override
  String get register => 'Εγγραφή';

  @override
  String get continueButton => 'Συνέχεια';

  @override
  String get welcome => 'Τιμές Καυσίμων';

  @override
  String get welcomeSubtitle => 'Βρείτε τα φθηνότερα καύσιμα κοντά σας.';

  @override
  String get profileName => 'Όνομα προφίλ';

  @override
  String get preferredFuel => 'Προτιμώμενο καύσιμο';

  @override
  String get defaultRadius => 'Προεπιλεγμένη ακτίνα';

  @override
  String get landingScreen => 'Αρχική οθόνη';

  @override
  String get homeZip => 'Τ.Κ. κατοικίας';

  @override
  String get newProfile => 'Νέο προφίλ';

  @override
  String get editProfile => 'Επεξεργασία προφίλ';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get countryChangeTitle => 'Switch country?';

  @override
  String countryChangeBody(String country) {
    return 'Switching to $country will change:';
  }

  @override
  String get countryChangeCurrency => 'Currency';

  @override
  String get countryChangeDistance => 'Distance';

  @override
  String get countryChangeVolume => 'Volume';

  @override
  String get countryChangePricePerUnit => 'Price format';

  @override
  String get countryChangeNote =>
      'Existing favorites and fill-up logs are not rewritten; only new entries use the new units.';

  @override
  String get countryChangeConfirm => 'Switch';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get activate => 'Ενεργοποίηση';

  @override
  String get configured => 'Ρυθμισμένο';

  @override
  String get notConfigured => 'Μη ρυθμισμένο';

  @override
  String get about => 'Σχετικά';

  @override
  String get openSource => 'Ανοιχτός κώδικας (Άδεια MIT)';

  @override
  String get sourceCode => 'Πηγαίος κώδικας στο GitHub';

  @override
  String get noFavorites => 'Χωρίς αγαπημένα';

  @override
  String get noFavoritesHint =>
      'Πατήστε το αστέρι σε ένα βενζινάδικο για να το αποθηκεύσετε στα αγαπημένα.';

  @override
  String get language => 'Γλώσσα';

  @override
  String get country => 'Χώρα';

  @override
  String get demoMode => 'Λειτουργία επίδειξης — δείγματα δεδομένων.';

  @override
  String get setupLiveData => 'Ρύθμιση για ζωντανά δεδομένα';

  @override
  String get freeNoKey => 'Δωρεάν — δεν χρειάζεται κλειδί';

  @override
  String get apiKeyRequired => 'Απαιτείται κλειδί API';

  @override
  String get skipWithoutKey => 'Συνέχεια χωρίς κλειδί';

  @override
  String get dataTransparency => 'Διαφάνεια δεδομένων';

  @override
  String get storageAndCache => 'Αποθήκευση και προσωρινή μνήμη';

  @override
  String get clearCache => 'Εκκαθάριση προσωρινής μνήμης';

  @override
  String get clearAllData => 'Διαγραφή όλων των δεδομένων';

  @override
  String get errorLog => 'Αρχείο σφαλμάτων';

  @override
  String stationsFound(int count) {
    return 'Βρέθηκαν $count βενζινάδικα';
  }

  @override
  String get whatIsShared => 'Τι κοινοποιείται — και σε ποιον;';

  @override
  String get gpsCoordinates => 'Συντεταγμένες GPS';

  @override
  String get gpsReason =>
      'Αποστέλλονται με κάθε αναζήτηση για εύρεση κοντινών σταθμών.';

  @override
  String get postalCodeData => 'Ταχυδρομικός κώδικας';

  @override
  String get postalReason =>
      'Μετατρέπεται σε συντεταγμένες μέσω υπηρεσίας γεωκωδικοποίησης.';

  @override
  String get mapViewport => 'Προβολή χάρτη';

  @override
  String get mapReason =>
      'Τα πλακίδια χάρτη φορτώνονται από τον διακομιστή. Δεν μεταδίδονται προσωπικά δεδομένα.';

  @override
  String get apiKeyData => 'Κλειδί API';

  @override
  String get apiKeyReason =>
      'Το προσωπικό σας κλειδί αποστέλλεται με κάθε αίτημα API. Συνδέεται με το e-mail σας.';

  @override
  String get notShared => 'ΔΕΝ κοινοποιείται:';

  @override
  String get searchHistory => 'Ιστορικό αναζήτησης';

  @override
  String get favoritesData => 'Αγαπημένα';

  @override
  String get profileNames => 'Ονόματα προφίλ';

  @override
  String get homeZipData => 'Τ.Κ. κατοικίας';

  @override
  String get usageData => 'Δεδομένα χρήσης';

  @override
  String get privacyBanner =>
      'Αυτή η εφαρμογή δεν έχει διακομιστή. Όλα τα δεδομένα παραμένουν στη συσκευή σας. Χωρίς αναλύσεις, παρακολούθηση ή διαφημίσεις.';

  @override
  String get storageUsage => 'Χρήση αποθηκευτικού χώρου σε αυτή τη συσκευή';

  @override
  String get settingsLabel => 'Ρυθμίσεις';

  @override
  String get profilesStored => 'αποθηκευμένα προφίλ';

  @override
  String get stationsMarked => 'σημειωμένοι σταθμοί';

  @override
  String get cachedResponses => 'αποθηκευμένες απαντήσεις';

  @override
  String get total => 'Σύνολο';

  @override
  String get cacheManagement => 'Διαχείριση προσωρινής μνήμης';

  @override
  String get cacheDescription =>
      'Η προσωρινή μνήμη αποθηκεύει απαντήσεις API για ταχύτερη φόρτωση και πρόσβαση εκτός σύνδεσης.';

  @override
  String get stationSearch => 'Αναζήτηση σταθμών';

  @override
  String get stationDetails => 'Λεπτομέρειες σταθμού';

  @override
  String get priceQuery => 'Αίτημα τιμών';

  @override
  String get zipGeocoding => 'Γεωκωδικοποίηση Τ.Κ.';

  @override
  String minutes(int n) {
    return '$n λεπτά';
  }

  @override
  String hours(int n) {
    return '$n ώρες';
  }

  @override
  String get clearCacheTitle => 'Εκκαθάριση προσωρινής μνήμης;';

  @override
  String get clearCacheBody =>
      'Τα αποθηκευμένα αποτελέσματα αναζήτησης και τιμές θα διαγραφούν. Τα προφίλ, αγαπημένα και ρυθμίσεις διατηρούνται.';

  @override
  String get clearCacheButton => 'Εκκαθάριση';

  @override
  String get deleteAllTitle => 'Διαγραφή όλων των δεδομένων;';

  @override
  String get deleteAllBody =>
      'Αυτό θα διαγράψει μόνιμα όλα τα προφίλ, αγαπημένα, κλειδί API, ρυθμίσεις και προσωρινή μνήμη. Η εφαρμογή θα επαναφερθεί.';

  @override
  String get deleteAllButton => 'Διαγραφή όλων';

  @override
  String get entries => 'εγγραφές';

  @override
  String get cacheEmpty => 'Η προσωρινή μνήμη είναι κενή';

  @override
  String get noStorage => 'Χωρίς χρησιμοποιούμενο χώρο';

  @override
  String get apiKeyNote =>
      'Δωρεάν εγγραφή. Δεδομένα από κρατικούς φορείς διαφάνειας τιμών.';

  @override
  String get apiKeyFormatError =>
      'Μη έγκυρη μορφή — αναμενόμενο UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Υποστηρίξτε αυτό το έργο';

  @override
  String get supportDescription =>
      'Αυτή η εφαρμογή είναι δωρεάν, ανοιχτού κώδικα και χωρίς διαφημίσεις. Αν τη βρίσκετε χρήσιμη, σκεφτείτε να υποστηρίξετε τον προγραμματιστή.';

  @override
  String get reportBug => 'Αναφορά σφάλματος / Πρόταση λειτουργίας';

  @override
  String get reportThisIssue => 'Report this issue';

  @override
  String get reportConsentTitle => 'Report to GitHub?';

  @override
  String get reportConsentBody =>
      'This will open a public GitHub issue with the error details below. No GPS coordinates, API keys, or personal data are included.';

  @override
  String get reportConsentConfirm => 'Open GitHub';

  @override
  String get reportConsentCancel => 'Cancel';

  @override
  String get configProfileSection => 'Profile';

  @override
  String get configActiveProfile => 'Active profile';

  @override
  String get configPreferredFuel => 'Preferred fuel';

  @override
  String get configCountry => 'Country';

  @override
  String get configRouteSegment => 'Route segment';

  @override
  String get configApiKeysSection => 'API keys';

  @override
  String get configTankerkoenigKey => 'Tankerkoenig API key';

  @override
  String get configApiKeyConfigured => 'Configured';

  @override
  String get configApiKeyNotSet => 'Not set (demo mode)';

  @override
  String get configApiKeyCommunity => 'Default (community key)';

  @override
  String get searchLocationPlaceholder => 'Address, postal code or city';

  @override
  String get configEvKey => 'EV charging API key';

  @override
  String get configEvKeyCustom => 'Custom key';

  @override
  String get configEvKeyShared => 'Default (shared)';

  @override
  String get configCloudSyncSection => 'Cloud Sync';

  @override
  String get configTankSyncConnected => 'Connected';

  @override
  String get configTankSyncDisabled => 'Disabled';

  @override
  String get configAuthMode => 'Auth mode';

  @override
  String get configAuthEmail => 'Email (persistent)';

  @override
  String get configAuthAnonymous => 'Anonymous (device-only)';

  @override
  String get configDatabase => 'Database';

  @override
  String get configPrivacySummary => 'Privacy summary';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Favorites, alerts, and ignored stations are synced to your private database\n• GPS position and API keys never leave your device\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• All data is stored locally on this device only\n• No data is sent to any server\n• API keys encrypted in device secure storage';

  @override
  String get configAuthNoteEmail => 'Email account enables cross-device access';

  @override
  String get configAuthNoteAnonymous =>
      'Anonymous account — data tied to this device';

  @override
  String get configNone => 'None';

  @override
  String get privacyPolicy => 'Πολιτική Απορρήτου';

  @override
  String get fuels => 'Καύσιμα';

  @override
  String get services => 'Υπηρεσίες';

  @override
  String get zone => 'Ζώνη';

  @override
  String get highway => 'Αυτοκινητόδρομος';

  @override
  String get localStation => 'Τοπικός σταθμός';

  @override
  String get lastUpdate => 'Τελευταία ενημέρωση';

  @override
  String get automate24h => '24ω/24 — Αυτόματο';

  @override
  String get refreshPrices => 'Ανανέωση τιμών';

  @override
  String get station => 'Βενζινάδικο';

  @override
  String get locationDenied =>
      'Η άδεια τοποθεσίας απορρίφθηκε. Μπορείτε να αναζητήσετε με Τ.Κ.';

  @override
  String get demoModeBanner =>
      'Λειτουργία επίδειξης. Ρυθμίστε το κλειδί API στις ρυθμίσεις.';

  @override
  String get sortDistance => 'Απόσταση';

  @override
  String get sortOpen24h => '24h';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceDistance => 'Price/km';

  @override
  String get cheap => 'φθηνό';

  @override
  String get expensive => 'ακριβό';

  @override
  String stationsOnMap(int count) {
    return '$count σταθμοί';
  }

  @override
  String get loadingFavorites =>
      'Φόρτωση αγαπημένων...\nΑναζητήστε πρώτα σταθμούς για αποθήκευση δεδομένων.';

  @override
  String get reportPrice => 'Αναφορά τιμής';

  @override
  String get whatsWrong => 'Τι δεν πάει καλά;';

  @override
  String get correctPrice => 'Σωστή τιμή (π.χ. 1,459)';

  @override
  String get sendReport => 'Αποστολή αναφοράς';

  @override
  String get reportSent => 'Αναφορά εστάλη. Ευχαριστούμε!';

  @override
  String get enterValidPrice => 'Εισάγετε έγκυρη τιμή';

  @override
  String get cacheCleared => 'Η προσωρινή μνήμη εκκαθαρίστηκε.';

  @override
  String get yourPosition => 'Η θέση σας';

  @override
  String get positionUnknown => 'Θέση άγνωστη';

  @override
  String get distancesFromCenter => 'Αποστάσεις από το κέντρο αναζήτησης';

  @override
  String get autoUpdatePosition => 'Αυτόματη ενημέρωση θέσης';

  @override
  String get autoUpdateDescription =>
      'Ενημέρωση θέσης GPS πριν από κάθε αναζήτηση';

  @override
  String get location => 'Τοποθεσία';

  @override
  String get switchProfileTitle => 'Χώρα άλλαξε';

  @override
  String switchProfilePrompt(String country, String profile) {
    return 'Βρίσκεστε τώρα στη χώρα $country. Εναλλαγή στο προφίλ \"$profile\";';
  }

  @override
  String switchedToProfile(String profile, String country) {
    return 'Εναλλαγή στο προφίλ \"$profile\" ($country)';
  }

  @override
  String get noProfileForCountryTitle => 'Κανένα προφίλ για αυτή τη χώρα';

  @override
  String noProfileForCountry(String country) {
    return 'Βρίσκεστε στη χώρα $country, αλλά δεν έχει ρυθμιστεί προφίλ. Δημιουργήστε ένα στις Ρυθμίσεις.';
  }

  @override
  String get autoSwitchProfile => 'Αυτόματη εναλλαγή προφίλ';

  @override
  String get autoSwitchDescription =>
      'Αυτόματη εναλλαγή προφίλ κατά τη διέλευση συνόρων';

  @override
  String get switchProfile => 'Εναλλαγή';

  @override
  String get dismiss => 'Κλείσιμο';

  @override
  String get profileCountry => 'Χώρα';

  @override
  String get profileLanguage => 'Γλώσσα';

  @override
  String get settingsStorageDetail => 'Κλειδί API, ενεργό προφίλ';

  @override
  String get allFuels => 'Όλα';

  @override
  String get priceAlerts => 'Ειδοποιήσεις τιμών';

  @override
  String get noPriceAlerts => 'Χωρίς ειδοποιήσεις τιμών';

  @override
  String get noPriceAlertsHint =>
      'Δημιουργήστε ειδοποίηση από τη σελίδα λεπτομερειών ενός σταθμού.';

  @override
  String alertDeleted(String name) {
    return 'Ειδοποίηση \"$name\" διαγράφηκε';
  }

  @override
  String get createAlert => 'Δημιουργία ειδοποίησης τιμής';

  @override
  String currentPrice(String price) {
    return 'Τρέχουσα τιμή: $price';
  }

  @override
  String get targetPrice => 'Τιμή-στόχος (EUR)';

  @override
  String get enterPrice => 'Εισάγετε μια τιμή';

  @override
  String get invalidPrice => 'Μη έγκυρη τιμή';

  @override
  String get priceTooHigh => 'Η τιμή είναι πολύ υψηλή';

  @override
  String get create => 'Δημιουργία';

  @override
  String get alertCreated => 'Ειδοποίηση τιμής δημιουργήθηκε';

  @override
  String get wrongE5Price => 'Λανθασμένη τιμή Super E5';

  @override
  String get wrongE10Price => 'Λανθασμένη τιμή Super E10';

  @override
  String get wrongDieselPrice => 'Λανθασμένη τιμή Diesel';

  @override
  String get wrongStatusOpen => 'Εμφανίζεται ανοιχτό, αλλά είναι κλειστό';

  @override
  String get wrongStatusClosed => 'Εμφανίζεται κλειστό, αλλά είναι ανοιχτό';

  @override
  String get searchAlongRouteLabel => 'Κατά μήκος της διαδρομής';

  @override
  String get searchEvStations => 'Αναζήτηση σταθμών φόρτισης';

  @override
  String get allStations => 'Όλοι οι σταθμοί';

  @override
  String get bestStops => 'Καλύτερες στάσεις';

  @override
  String get openInMaps => 'Άνοιγμα στους Χάρτες';

  @override
  String get noStationsAlongRoute =>
      'Δεν βρέθηκαν σταθμοί κατά μήκος της διαδρομής';

  @override
  String get evOperational => 'Σε λειτουργία';

  @override
  String get evStatusUnknown => 'Κατάσταση άγνωστη';

  @override
  String evConnectors(int count) {
    return 'Σύνδεσμοι ($count σημεία)';
  }

  @override
  String get evNoConnectors => 'Δεν υπάρχουν λεπτομέρειες συνδέσμων';

  @override
  String get evUsageCost => 'Κόστος χρήσης';

  @override
  String get evPricingUnavailable => 'Τιμολόγηση μη διαθέσιμη από τον πάροχο';

  @override
  String get evLastUpdated => 'Τελευταία ενημέρωση';

  @override
  String get evUnknown => 'Άγνωστο';

  @override
  String get evDataAttribution => 'Δεδομένα από OpenChargeMap (κοινοτική πηγή)';

  @override
  String get evStatusDisclaimer =>
      'Η κατάσταση μπορεί να μην αντικατοπτρίζει τη διαθεσιμότητα σε πραγματικό χρόνο. Πατήστε ανανέωση για τα τελευταία δεδομένα.';

  @override
  String get evNavigateToStation => 'Πλοήγηση στον σταθμό';

  @override
  String get evRefreshStatus => 'Ανανέωση κατάστασης';

  @override
  String get evStatusUpdated => 'Κατάσταση ενημερώθηκε';

  @override
  String get evStationNotFound =>
      'Δεν ήταν δυνατή η ανανέωση — ο σταθμός δεν βρέθηκε κοντά';

  @override
  String get addedToFavorites => 'Προστέθηκε στα αγαπημένα';

  @override
  String get removedFromFavorites => 'Αφαιρέθηκε από τα αγαπημένα';

  @override
  String get addFavorite => 'Προσθήκη στα αγαπημένα';

  @override
  String get removeFavorite => 'Αφαίρεση από τα αγαπημένα';

  @override
  String get currentLocation => 'Τρέχουσα τοποθεσία';

  @override
  String get gpsError => 'Σφάλμα GPS';

  @override
  String get couldNotResolve =>
      'Δεν ήταν δυνατός ο προσδιορισμός αφετηρίας ή προορισμού';

  @override
  String get start => 'Αφετηρία';

  @override
  String get destination => 'Προορισμός';

  @override
  String get cityAddressOrGps => 'Πόλη, διεύθυνση ή GPS';

  @override
  String get cityOrAddress => 'Πόλη ή διεύθυνση';

  @override
  String get useGps => 'Χρήση GPS';

  @override
  String get stop => 'Στάση';

  @override
  String stopN(int n) {
    return 'Στάση $n';
  }

  @override
  String get addStop => 'Προσθήκη στάσης';

  @override
  String get searchAlongRoute => 'Αναζήτηση κατά μήκος διαδρομής';

  @override
  String get cheapest => 'Φθηνότερο';

  @override
  String nStations(int count) {
    return '$count σταθμοί';
  }

  @override
  String nBest(int count) {
    return '$count καλύτεροι';
  }

  @override
  String get fuelPricesTankerkoenig => 'Τιμές καυσίμων (Tankerkoenig)';

  @override
  String get requiredForFuelSearch =>
      'Απαιτείται για αναζήτηση τιμών καυσίμων στη Γερμανία';

  @override
  String get evChargingOpenChargeMap => 'Φόρτιση EV (OpenChargeMap)';

  @override
  String get customKey => 'Προσαρμοσμένο κλειδί';

  @override
  String get appDefaultKey => 'Προεπιλεγμένο κλειδί εφαρμογής';

  @override
  String get optionalOverrideKey =>
      'Προαιρετικό: αντικατάσταση του ενσωματωμένου κλειδιού με το δικό σας';

  @override
  String get requiredForEvSearch =>
      'Απαιτείται για αναζήτηση σταθμών φόρτισης EV';

  @override
  String get edit => 'Επεξεργασία';

  @override
  String get fuelPricesApiKey => 'Κλειδί API τιμών καυσίμων';

  @override
  String get tankerkoenigApiKey => 'Κλειδί API Tankerkoenig';

  @override
  String get evChargingApiKey => 'Κλειδί API φόρτισης EV';

  @override
  String get openChargeMapApiKey => 'Κλειδί API OpenChargeMap';

  @override
  String get routeSegment => 'Τμήμα διαδρομής';

  @override
  String showCheapestEveryNKm(int km) {
    return 'Εμφάνιση φθηνότερου σταθμού κάθε $km χλμ κατά μήκος της διαδρομής';
  }

  @override
  String get avoidHighways => 'Αποφυγή αυτοκινητοδρόμων';

  @override
  String get avoidHighwaysDesc =>
      'Ο υπολογισμός διαδρομής αποφεύγει δρόμους με διόδια και αυτοκινητοδρόμους';

  @override
  String get showFuelStations => 'Εμφάνιση βενζινάδικων';

  @override
  String get showFuelStationsDesc =>
      'Συμπερίληψη σταθμών βενζίνης, ντίζελ, LPG, CNG';

  @override
  String get showEvStations => 'Εμφάνιση σταθμών φόρτισης';

  @override
  String get showEvStationsDesc =>
      'Συμπερίληψη ηλεκτρικών σταθμών φόρτισης στα αποτελέσματα';

  @override
  String get noStationsAlongThisRoute =>
      'Δεν βρέθηκαν σταθμοί κατά μήκος αυτής της διαδρομής.';

  @override
  String get fuelCostCalculator => 'Υπολογιστής κόστους καυσίμου';

  @override
  String get distanceKm => 'Απόσταση (χλμ)';

  @override
  String get consumptionL100km => 'Κατανάλωση (L/100χλμ)';

  @override
  String get fuelPriceEurL => 'Τιμή καυσίμου (EUR/L)';

  @override
  String get tripCost => 'Κόστος ταξιδιού';

  @override
  String get fuelNeeded => 'Απαιτούμενο καύσιμο';

  @override
  String get totalCost => 'Συνολικό κόστος';

  @override
  String get enterCalcValues =>
      'Εισάγετε απόσταση, κατανάλωση και τιμή για υπολογισμό κόστους ταξιδιού';

  @override
  String get priceHistory => 'Ιστορικό τιμών';

  @override
  String get noPriceHistory => 'Δεν υπάρχει ακόμη ιστορικό τιμών';

  @override
  String get noHourlyData => 'Χωρίς ωριαία δεδομένα';

  @override
  String get noStatistics => 'Δεν υπάρχουν διαθέσιμα στατιστικά';

  @override
  String get statMin => 'Ελάχ';

  @override
  String get statMax => 'Μέγ';

  @override
  String get statAvg => 'Μέσ';

  @override
  String get showAllFuelTypes => 'Εμφάνιση όλων των τύπων καυσίμου';

  @override
  String get connected => 'Συνδεδεμένο';

  @override
  String get notConnected => 'Μη συνδεδεμένο';

  @override
  String get connectTankSync => 'Σύνδεση TankSync';

  @override
  String get disconnectTankSync => 'Αποσύνδεση TankSync';

  @override
  String get viewMyData => 'Προβολή δεδομένων μου';

  @override
  String get optionalCloudSync =>
      'Προαιρετικός συγχρονισμός cloud για ειδοποιήσεις, αγαπημένα και push ειδοποιήσεις';

  @override
  String get tapToUpdateGps => 'Πατήστε για ενημέρωση θέσης GPS';

  @override
  String get gpsAutoUpdateHint =>
      'Η θέση GPS αποκτάται αυτόματα κατά την αναζήτηση. Μπορείτε επίσης να την ενημερώσετε χειροκίνητα εδώ.';

  @override
  String get clearGpsConfirm =>
      'Διαγραφή αποθηκευμένης θέσης GPS; Μπορείτε να την ενημερώσετε ξανά ανά πάσα στιγμή.';

  @override
  String get pageNotFound => 'Η σελίδα δεν βρέθηκε';

  @override
  String get deleteAllServerData => 'Διαγραφή όλων των δεδομένων διακομιστή';

  @override
  String get deleteServerDataConfirm =>
      'Διαγραφή όλων των δεδομένων διακομιστή;';

  @override
  String get deleteEverything => 'Διαγραφή όλων';

  @override
  String get allDataDeleted => 'Όλα τα δεδομένα διακομιστή διαγράφηκαν';

  @override
  String get disconnectConfirm => 'Αποσύνδεση TankSync;';

  @override
  String get disconnect => 'Αποσύνδεση';

  @override
  String get myServerData => 'Τα δεδομένα μου στον διακομιστή';

  @override
  String get anonymousUuid => 'Ανώνυμο UUID';

  @override
  String get server => 'Διακομιστής';

  @override
  String get syncedData => 'Συγχρονισμένα δεδομένα';

  @override
  String get pushTokens => 'Push tokens';

  @override
  String get priceReports => 'Αναφορές τιμών';

  @override
  String get totalItems => 'Σύνολο στοιχείων';

  @override
  String get estimatedSize => 'Εκτιμώμενο μέγεθος';

  @override
  String get viewRawJson => 'Προβολή ακατέργαστων δεδομένων ως JSON';

  @override
  String get exportJson => 'Εξαγωγή ως JSON (πρόχειρο)';

  @override
  String get jsonCopied => 'JSON αντιγράφηκε στο πρόχειρο';

  @override
  String get rawDataJson => 'Ακατέργαστα δεδομένα (JSON)';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get account => 'Account';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get upgradeToEmail => 'Create email account';

  @override
  String get savedRoutes => 'Saved Routes';

  @override
  String get noSavedRoutes => 'No saved routes';

  @override
  String get noSavedRoutesHint =>
      'Search along a route and save it for quick access later.';

  @override
  String get saveRoute => 'Save route';

  @override
  String get routeName => 'Route name';

  @override
  String itineraryDeleted(String name) {
    return '$name deleted';
  }

  @override
  String loadingRoute(String name) {
    return 'Loading route: $name';
  }

  @override
  String get refreshFailed => 'Refresh failed. Please try again.';

  @override
  String get deleteProfileTitle => 'Delete profile?';

  @override
  String get deleteProfileBody =>
      'This profile and its settings will be permanently deleted. This cannot be undone.';

  @override
  String get deleteProfileConfirm => 'Delete profile';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorTimeout => 'Connection timed out. Please try again.';

  @override
  String get errorNoConnection => 'No internet connection.';

  @override
  String get errorApiKey => 'Invalid API key. Check your settings.';

  @override
  String get errorLocation => 'Could not determine your location.';

  @override
  String get errorNoApiKey =>
      'No API key configured. Go to Settings to add one.';

  @override
  String get errorAllServicesFailed =>
      'Could not load data. Check your connection and try again.';

  @override
  String get errorCache => 'Local data error. Try clearing the cache.';

  @override
  String get errorCancelled => 'Request was cancelled.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get onboardingWelcomeHint => 'Set up the app in a few quick steps.';

  @override
  String get onboardingApiKeyDescription =>
      'Register for a free API key, or skip to explore the app with demo data.';

  @override
  String get onboardingComplete => 'All set!';

  @override
  String get onboardingCompleteHint =>
      'You can change these settings anytime in your profile.';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingFinish => 'Get started';

  @override
  String crossBorderNearby(String country) {
    return '$country is nearby';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km to border';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Avg here: $price EUR ($count stations)';
  }

  @override
  String get allPricesView => 'All prices';

  @override
  String get compactView => 'Compact';

  @override
  String get switchToAllPricesView => 'Switch to all-prices view';

  @override
  String get switchToCompactView => 'Switch to compact view';

  @override
  String get unavailable => 'N/A';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get gdprTitle => 'Your Privacy';

  @override
  String get gdprSubtitle =>
      'This app respects your privacy. Choose which data you want to share. You can change these settings anytime.';

  @override
  String get gdprLocationTitle => 'Location Access';

  @override
  String get gdprLocationDescription =>
      'Your coordinates are sent to the fuel price API to find nearby stations. Location data is never stored on a server and is not used for tracking.';

  @override
  String get gdprLocationShort =>
      'Find nearby fuel stations using your location';

  @override
  String get gdprErrorReportingTitle => 'Error Reporting';

  @override
  String get gdprErrorReportingDescription =>
      'Anonymous crash reports help improve the app. No personal data is included. Reports are sent via Sentry only when configured.';

  @override
  String get gdprErrorReportingShort =>
      'Send anonymous crash reports to improve the app';

  @override
  String get gdprCloudSyncTitle => 'Cloud Sync';

  @override
  String get gdprCloudSyncDescription =>
      'Sync favorites and alerts across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.';

  @override
  String get gdprCloudSyncShort => 'Sync favorites and alerts across devices';

  @override
  String get gdprLegalBasis =>
      'Legal basis: Art. 6(1)(a) GDPR (Consent). You can withdraw consent anytime in Settings.';

  @override
  String get gdprAcceptAll => 'Accept All';

  @override
  String get gdprAcceptSelected => 'Accept Selected';

  @override
  String get gdprSettingsHint =>
      'You can change your privacy choices at any time.';

  @override
  String get routeSaved => 'Route saved!';

  @override
  String get routeSaveFailed => 'Failed to save route';

  @override
  String get sqlCopied => 'SQL copied to clipboard';

  @override
  String get connectionDataCopied => 'Connection data copied';

  @override
  String get accountDeleted => 'Account deleted. Local data preserved.';

  @override
  String get switchedToAnonymous => 'Switched to anonymous session';

  @override
  String failedToSwitch(String error) {
    return 'Failed to switch: $error';
  }

  @override
  String get topicUrlCopied => 'Topic URL copied';

  @override
  String get testNotificationSent => 'Test notification sent!';

  @override
  String get testNotificationFailed => 'Failed to send test notification';

  @override
  String get pushUpdateFailed => 'Failed to update push notification setting';

  @override
  String get connectedAsGuest => 'Connected as guest';

  @override
  String get accountCreated => 'Account created!';

  @override
  String get signedIn => 'Signed in!';

  @override
  String stationHidden(String name) {
    return '$name hidden';
  }

  @override
  String removedFromFavoritesName(String name) {
    return '$name removed from favorites';
  }

  @override
  String invalidApiKey(String error) {
    return 'Invalid API key: $error';
  }

  @override
  String get invalidQrCode => 'Invalid QR code format';

  @override
  String get invalidQrCodeTankSync =>
      'Invalid QR code — expected TankSync format';

  @override
  String get tankSyncConnected => 'TankSync connected!';

  @override
  String get syncCompleted => 'Sync completed — data refreshed';

  @override
  String get deviceCodeCopied => 'Device code copied';

  @override
  String get undo => 'Undo';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Please enter a valid $length-digit $label';
  }

  @override
  String get freshnessAgo => 'ago';

  @override
  String get freshnessStale => 'Stale';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Data freshness: $age';
  }

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordReqMinLength => 'At least 8 characters';

  @override
  String get passwordReqUppercase => 'At least 1 uppercase letter';

  @override
  String get passwordReqLowercase => 'At least 1 lowercase letter';

  @override
  String get passwordReqDigit => 'At least 1 number';

  @override
  String get passwordReqSpecial => 'At least 1 special character';

  @override
  String get passwordTooWeak => 'Password does not meet all requirements';

  @override
  String get brandFilterAll => 'All';

  @override
  String get brandFilterNoHighway => 'No highway';

  @override
  String get swipeTutorialMessage =>
      'Swipe right to navigate, swipe left to remove';

  @override
  String get swipeTutorialDismiss => 'Got it';

  @override
  String get alertStatsActive => 'Ενεργές';

  @override
  String get alertStatsToday => 'Σήμερα';

  @override
  String get alertStatsThisWeek => 'Αυτή την εβδομάδα';

  @override
  String get privacyDashboardTitle => 'Privacy Dashboard';

  @override
  String get privacyDashboardSubtitle => 'View, export, or delete your data';

  @override
  String get privacyDashboardBanner =>
      'Your data belongs to you. Here you can see everything this app stores, export it, or delete it.';

  @override
  String get privacyLocalData => 'Data on this device';

  @override
  String get privacyIgnoredStations => 'Ignored stations';

  @override
  String get privacyRatings => 'Station ratings';

  @override
  String get privacyPriceHistory => 'Price history stations';

  @override
  String get privacyProfiles => 'Search profiles';

  @override
  String get privacyItineraries => 'Saved routes';

  @override
  String get privacyCacheEntries => 'Cache entries';

  @override
  String get privacyApiKey => 'API key stored';

  @override
  String get privacyEvApiKey => 'EV API key stored';

  @override
  String get privacyEstimatedSize => 'Estimated storage';

  @override
  String get privacySyncedData => 'Cloud sync (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Cloud sync is disabled. All data stays on this device only.';

  @override
  String get privacySyncMode => 'Sync mode';

  @override
  String get privacySyncUserId => 'User ID';

  @override
  String get privacySyncDescription =>
      'When sync is enabled, favorites, alerts, ignored stations, and ratings are also stored on the TankSync server.';

  @override
  String get privacyViewServerData => 'View server data';

  @override
  String get privacyExportButton => 'Export all data as JSON';

  @override
  String get privacyExportSuccess => 'Data exported to clipboard';

  @override
  String get privacyExportCsvButton => 'Export all data as CSV';

  @override
  String get privacyExportCsvSuccess => 'CSV data exported to clipboard';

  @override
  String get privacyDeleteButton => 'Delete all data';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Copy error log to clipboard ($count)';
  }

  @override
  String get privacyDeleteTitle => 'Delete all data?';

  @override
  String get privacyDeleteBody =>
      'This will permanently delete:\n\n- All favorites and station data\n- All search profiles\n- All price alerts\n- All price history\n- All cached data\n- Your API key\n- All app settings\n\nThe app will reset to its initial state. This action cannot be undone.';

  @override
  String get privacyDeleteConfirm => 'Delete everything';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get amenities => 'Amenities';

  @override
  String get amenityShop => 'Shop';

  @override
  String get amenityCarWash => 'Car Wash';

  @override
  String get amenityAirPump => 'Air';

  @override
  String get amenityToilet => 'WC';

  @override
  String get amenityRestaurant => 'Food';

  @override
  String get amenityAtm => 'ATM';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityEv => 'EV';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodContactless => 'Contactless';

  @override
  String get paymentMethodFuelCard => 'Fuel Card';

  @override
  String get paymentMethodApp => 'App';

  @override
  String payWithApp(String app) {
    return 'Pay with $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Compared to the rolling average over your last 3 fill-ups ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Consumption $value L/100 km, $delta versus your rolling average';
  }

  @override
  String get drivingMode => 'Driving Mode';

  @override
  String get drivingExit => 'Exit';

  @override
  String get drivingNearestStation => 'Nearest';

  @override
  String get drivingTapToUnlock => 'Tap to unlock';

  @override
  String get drivingSafetyTitle => 'Safety Notice';

  @override
  String get drivingSafetyMessage =>
      'Do not operate the app while driving. Pull over to a safe location before interacting with the screen. The driver is responsible for safe operation of the vehicle at all times.';

  @override
  String get drivingSafetyAccept => 'I understand';

  @override
  String get voiceAnnouncementsTitle => 'Voice Announcements';

  @override
  String get voiceAnnouncementsDescription =>
      'Announce nearby cheap stations while driving';

  @override
  String get voiceAnnouncementsEnabled => 'Enable voice announcements';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Only below $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance kilometers ahead, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Announcement radius';

  @override
  String get voiceAnnouncementCooldown => 'Repeat interval';

  @override
  String get nearestStations => 'Kontinoteroi stathmoi';

  @override
  String get nearestStationsHint =>
      'Vreite tous kontinoterous stathmous me tin trexousa topothesia sas';

  @override
  String get consumptionLogTitle => 'Fuel consumption';

  @override
  String get consumptionLogMenuTitle => 'Consumption log';

  @override
  String get consumptionLogMenuSubtitle =>
      'Track fill-ups and calculate L/100km';

  @override
  String get consumptionStatsTitle => 'Consumption stats';

  @override
  String get addFillUp => 'Add fill-up';

  @override
  String get noFillUpsTitle => 'No fill-ups yet';

  @override
  String get noFillUpsSubtitle =>
      'Log your first fill-up to start tracking consumption.';

  @override
  String get fillUpDate => 'Date';

  @override
  String get liters => 'Liters';

  @override
  String get odometerKm => 'Odometer (km)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get stationPreFilled => 'Station pre-filled';

  @override
  String get statAvgConsumption => 'Avg L/100km';

  @override
  String get statAvgCostPerKm => 'Avg cost/km';

  @override
  String get statTotalLiters => 'Total liters';

  @override
  String get statTotalSpent => 'Total spent';

  @override
  String get statFillUpCount => 'Fill-ups';

  @override
  String get fieldRequired => 'Required';

  @override
  String get fieldInvalidNumber => 'Invalid number';

  @override
  String get carbonDashboardTitle => 'Carbon dashboard';

  @override
  String get carbonTabCharts => 'Charts';

  @override
  String get carbonTabAchievements => 'Achievements';

  @override
  String get carbonEmptyTitle => 'No data yet';

  @override
  String get carbonEmptySubtitle =>
      'Log fill-ups to see your carbon dashboard.';

  @override
  String get carbonSummaryTotalCost => 'Total cost';

  @override
  String get carbonSummaryTotalCo2 => 'Total CO2';

  @override
  String get monthlyCostsTitle => 'Monthly costs';

  @override
  String get monthlyEmissionsTitle => 'Monthly CO2 emissions';

  @override
  String get milestonesTitle => 'Milestones';

  @override
  String get milestoneFirstFillUp => 'First fill-up logged';

  @override
  String get milestoneTenFillUps => '10 fill-ups tracked';

  @override
  String get milestoneFiftyFillUps => '50 fill-ups tracked';

  @override
  String get milestoneHundredLiters => '100 L tracked';

  @override
  String get milestoneThousandLiters => '1000 L tracked';

  @override
  String get milestoneHundredKgCo2 => '100 kg CO2 tracked';

  @override
  String get milestoneOneTonneCo2 => '1 tonne CO2 tracked';

  @override
  String get milestoneThousandKm => '1000 km driven';

  @override
  String get milestoneTenThousandKm => '10,000 km driven';

  @override
  String get fuelVsEvTitle => 'Fuel vs EV';

  @override
  String get fuelVsEvSubtitle => 'CO2 comparison for the same distance driven';

  @override
  String get fuelVsEvYourFuel => 'Your fuel';

  @override
  String get fuelVsEvEquivalent => 'Equivalent EV';

  @override
  String get fuelVsEvDistance => 'Distance';

  @override
  String get fuelVsEvDifference => 'Difference';

  @override
  String get shareProgress => 'Share';

  @override
  String get shareCopied => 'Copied to clipboard';

  @override
  String shareCo2Message(String kg) {
    return 'I tracked $kg kg CO2 with Tankstellen.';
  }

  @override
  String get vehiclesTitle => 'My vehicles';

  @override
  String get vehiclesMenuTitle => 'My vehicles';

  @override
  String get vehiclesMenuSubtitle =>
      'Battery, connectors, charging preferences';

  @override
  String get vehiclesEmptyMessage =>
      'Add your car to filter by connector and estimate charging costs.';

  @override
  String get vehiclesWizardTitle => 'My vehicles (optional)';

  @override
  String get vehiclesWizardSubtitle =>
      'Add your car to pre-fill the consumption log and enable EV connector filters. You can skip this and add vehicles later.';

  @override
  String get vehiclesWizardNoneYet => 'No vehicle configured yet.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles',
      one: '1 vehicle',
    );
    return 'You have $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Skip to finish setup — you can add vehicles anytime from Settings.';

  @override
  String get fillUpVehicleLabel => 'Vehicle';

  @override
  String get fillUpVehicleNone => 'No vehicle';

  @override
  String get fillUpVehicleRequired => 'Vehicle is required';

  @override
  String get reportScanError => 'Report scan error';

  @override
  String get pickStationTitle => 'Pick a station';

  @override
  String get pickStationHelper =>
      'Start the fill-up from a known station so prices, brand and fuel type fill themselves in.';

  @override
  String get pickStationEmpty =>
      'No favorite stations yet — add some from Search or Favorites, or skip and fill in manually.';

  @override
  String get pickStationSkip => 'Skip — add without a station';

  @override
  String get scanPump => 'Scan pump';

  @override
  String get scanPayment => 'Scan payment QR';

  @override
  String get qrPaymentBeneficiary => 'Beneficiary';

  @override
  String get qrPaymentAmount => 'Amount';

  @override
  String get qrPaymentEpcTitle => 'SEPA payment';

  @override
  String get qrPaymentEpcEmpty => 'No fields decoded';

  @override
  String get qrPaymentOpenInBank => 'Open in bank app';

  @override
  String get qrPaymentLaunchFailed => 'No app available to open this code';

  @override
  String get qrPaymentUnknownTitle => 'Unrecognised code';

  @override
  String get qrPaymentCopyRaw => 'Copy raw text';

  @override
  String get qrPaymentCopiedRaw => 'Copied to clipboard';

  @override
  String get qrPaymentReport => 'Report this scan';

  @override
  String get qrPaymentEpcCopied =>
      'Bank details copied — paste into your banking app';

  @override
  String get qrScannerGuidance => 'Point the camera at a QR code';

  @override
  String get qrScannerPermissionDenied =>
      'Camera access is needed to scan QR codes.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Camera access was denied. Open settings to grant it.';

  @override
  String get qrScannerRetryPermission => 'Try again';

  @override
  String get qrScannerOpenSettings => 'Open settings';

  @override
  String get qrScannerTimeout =>
      'No QR code detected. Move closer or try again.';

  @override
  String get qrScannerRetry => 'Try again';

  @override
  String get torchOn => 'Turn flash on';

  @override
  String get torchOff => 'Turn flash off';

  @override
  String get obdNoAdapter => 'No OBD2 adapter in range';

  @override
  String get obdOdometerUnavailable => 'Could not read odometer';

  @override
  String get obdPermissionDenied =>
      'Grant Bluetooth permission in system settings';

  @override
  String get obdAdapterUnresponsive =>
      'Adapter didn\'t answer — turn the ignition on and retry';

  @override
  String get obdPickerTitle => 'Pick an OBD2 adapter';

  @override
  String get obdPickerScanning => 'Scanning for adapters…';

  @override
  String get obdPickerConnecting => 'Connecting…';

  @override
  String get themeSettingTitle => 'Theme';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'Follow system';

  @override
  String get tripRecordingTitle => 'Recording trip';

  @override
  String get tripSummaryTitle => 'Trip summary';

  @override
  String get tripMetricDistance => 'Distance';

  @override
  String get tripMetricSpeed => 'Speed';

  @override
  String get tripMetricFuelUsed => 'Fuel used';

  @override
  String get tripMetricAvgConsumption => 'Avg';

  @override
  String get tripMetricElapsed => 'Elapsed';

  @override
  String get tripMetricOdometer => 'Odometer';

  @override
  String get tripStop => 'Stop recording';

  @override
  String get tripPause => 'Pause';

  @override
  String get tripResume => 'Resume';

  @override
  String get tripBannerRecording => 'Recording trip';

  @override
  String get tripBannerPaused => 'Trip paused — tap to resume';

  @override
  String get navConsumption => 'Consumption';

  @override
  String get vehicleBaselineSectionTitle => 'Baseline calibration';

  @override
  String get vehicleBaselineEmpty =>
      'No samples yet — start an OBD2 trip to begin learning this vehicle\'s fuel profile.';

  @override
  String get vehicleBaselineProgress =>
      'Learned from samples across driving situations.';

  @override
  String get vehicleBaselineReset => 'Reset baseline';

  @override
  String get vehicleBaselineResetConfirmTitle => 'Reset baseline?';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'This wipes every learned sample for this vehicle. You\'ll drift back to the cold-start defaults until new trips refill the profile.';

  @override
  String get vehicleAdapterSectionTitle => 'OBD2 adapter';

  @override
  String get vehicleAdapterEmpty =>
      'No adapter paired. Pair one so the app can reconnect automatically next time.';

  @override
  String get vehicleAdapterUnnamed => 'Unknown adapter';

  @override
  String get vehicleAdapterPair => 'Pair adapter';

  @override
  String get vehicleAdapterForget => 'Forget adapter';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFirstTrip => 'First trip';

  @override
  String get achievementFirstTripDesc => 'Record your first OBD2 trip.';

  @override
  String get achievementFirstFillUp => 'First fill-up';

  @override
  String get achievementFirstFillUpDesc => 'Log your first fill-up.';

  @override
  String get achievementTenTrips => '10 trips';

  @override
  String get achievementTenTripsDesc => 'Record 10 OBD2 trips.';

  @override
  String get achievementZeroHarsh => 'Smooth driver';

  @override
  String get achievementZeroHarshDesc =>
      'Complete a trip of 10 km or more with no harsh braking or acceleration.';

  @override
  String get achievementEcoWeek => 'Eco week';

  @override
  String get achievementEcoWeekDesc =>
      'Drive 7 consecutive days with at least one smooth trip each day.';

  @override
  String get achievementPriceWin => 'Price win';

  @override
  String get achievementPriceWinDesc =>
      'Log a fill-up that beats the station\'s 30-day average by 5 % or more.';

  @override
  String get syncBaselinesToggleTitle => 'Share learned vehicle profiles';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Upload per-vehicle consumption baselines so a second device can reuse them.';

  @override
  String get obd2StatusConnected => 'OBD2 adapter: connected';

  @override
  String get obd2StatusAttempting => 'OBD2 adapter: connecting';

  @override
  String get obd2StatusUnreachable => 'OBD2 adapter: unreachable';

  @override
  String get obd2StatusPermissionDenied =>
      'OBD2 adapter: Bluetooth permission needed';

  @override
  String get obd2StatusConnectedBody => 'Ready to record a trip.';

  @override
  String get obd2StatusAttemptingBody => 'Connecting in the background…';

  @override
  String get obd2StatusUnreachableBody =>
      'Adapter out of range or already in use by another app.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Grant Bluetooth permission in system settings to reconnect automatically.';

  @override
  String get obd2StatusNoAdapter => 'No adapter paired';

  @override
  String get obd2StatusForget => 'Forget adapter';

  @override
  String get tripHistoryTitle => 'Trip history';

  @override
  String get tripHistoryEmptyTitle => 'No trips yet';

  @override
  String get tripHistoryEmptySubtitle =>
      'Connect an OBD2 adapter and record a trip to start building your driving history.';

  @override
  String get tripHistoryUnknownDate => 'Unknown date';

  @override
  String get situationIdle => 'Idle';

  @override
  String get situationStopAndGo => 'Stop & go';

  @override
  String get situationUrban => 'Urban';

  @override
  String get situationHighway => 'Highway';

  @override
  String get situationDecel => 'Decelerating';

  @override
  String get situationClimbing => 'Climbing / loaded';

  @override
  String get situationHardAccel => 'Hard accel';

  @override
  String get situationFuelCut => 'Fuel cut — coast';

  @override
  String get tripSaveAsFillUp => 'Save as fill-up';

  @override
  String get tripDiscard => 'Discard';

  @override
  String obdOdometerRead(int km) {
    return 'Odometer read: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Not set';

  @override
  String get wizardVehicleTapToEdit => 'Tap to edit';

  @override
  String get wizardVehicleDefaultBadge => 'Default';

  @override
  String get profileDefaultVehicleLabel => 'Default vehicle (optional)';

  @override
  String get profileDefaultVehicleNone => 'No default';

  @override
  String get profileFuelFromVehicleHint =>
      'Fuel type is derived from your default vehicle. Clear the vehicle to pick a fuel directly.';

  @override
  String get consumptionNoVehicleTitle => 'Add a vehicle first';

  @override
  String get consumptionNoVehicleBody =>
      'Fill-ups are attributed to a vehicle. Add your car to start logging consumption.';

  @override
  String get vehicleAdd => 'Add vehicle';

  @override
  String get vehicleAddTitle => 'Add vehicle';

  @override
  String get vehicleEditTitle => 'Edit vehicle';

  @override
  String get vehicleDeleteTitle => 'Delete vehicle?';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Remove \"$name\" from your profiles?';
  }

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameHint => 'e.g. My Tesla Model 3';

  @override
  String get vehicleTypeCombustion => 'Combustion';

  @override
  String get vehicleTypeHybrid => 'Hybrid';

  @override
  String get vehicleTypeEv => 'Electric';

  @override
  String get vehicleEvSectionTitle => 'Electric';

  @override
  String get vehicleCombustionSectionTitle => 'Combustion';

  @override
  String get vehicleBatteryLabel => 'Battery capacity (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Max charging power (kW)';

  @override
  String get vehicleConnectorsLabel => 'Supported connectors';

  @override
  String get vehicleMinSocLabel => 'Min SoC %';

  @override
  String get vehicleMaxSocLabel => 'Max SoC %';

  @override
  String get vehicleTankLabel => 'Tank capacity (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Preferred fuel';

  @override
  String get connectorType2 => 'Type 2';

  @override
  String get connectorCcs => 'CCS';

  @override
  String get connectorChademo => 'CHAdeMO';

  @override
  String get connectorTesla => 'Tesla';

  @override
  String get connectorSchuko => 'Schuko';

  @override
  String get connectorType1 => 'Type 1';

  @override
  String get connectorThreePin => '3-pin';

  @override
  String get evShowOnMap => 'Show EV stations';

  @override
  String get evAvailableOnly => 'Available only';

  @override
  String get evMinPower => 'Min power';

  @override
  String get evMaxPower => 'Max power';

  @override
  String get evOperator => 'Operator';

  @override
  String get evLastUpdate => 'Last update';

  @override
  String get evStatusAvailable => 'Available';

  @override
  String get evStatusOccupied => 'Occupied';

  @override
  String get evStatusOutOfOrder => 'Out of order';

  @override
  String get openOnlyFilter => 'Open only';

  @override
  String get saveAsDefaults => 'Save as my defaults';

  @override
  String get criteriaSavedToProfile => 'Saved as defaults';

  @override
  String get profileNotFound => 'No active profile';

  @override
  String get updatingFavorites => 'Updating your favorites...';

  @override
  String get fetchingLatestPrices => 'Fetching the latest prices';

  @override
  String get noDataAvailable => 'No data';

  @override
  String get configAndPrivacy => 'Configuration & Privacy';

  @override
  String get searchToSeeMap => 'Search to see stations on the map';

  @override
  String get evPowerAny => 'Any';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Profile';

  @override
  String get sectionLocation => 'Location';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipClose => 'Close';

  @override
  String get tooltipClearSearch => 'Clear search input';

  @override
  String get tooltipUseGps => 'Use GPS location';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get evConnectorsLabel => 'Available connectors';

  @override
  String get evConnectorsNone => 'No connector information';

  @override
  String get switchToEmail => 'Switch to email';

  @override
  String get switchToEmailSubtitle =>
      'Keep data, add sign-in from other devices';

  @override
  String get switchToAnonymousAction => 'Switch to anonymous';

  @override
  String get switchToAnonymousSubtitle =>
      'Keep local data, use new anonymous session';

  @override
  String get linkDevice => 'Link device';

  @override
  String get shareDatabase => 'Share database';

  @override
  String get disconnectAction => 'Disconnect';

  @override
  String get disconnectSubtitle => 'Stop syncing (local data kept)';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Remove all server data permanently';

  @override
  String get localOnly => 'Local only';

  @override
  String get localOnlySubtitle =>
      'Optional: sync favorites, alerts, and ratings across devices';

  @override
  String get setupCloudSync => 'Set up cloud sync';

  @override
  String get disconnectTitle => 'Disconnect TankSync?';

  @override
  String get disconnectBody =>
      'Cloud sync will be disabled. Your local data (favorites, alerts, history) is preserved on this device. Server data is not deleted.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes all your data from the server (favorites, alerts, ratings, routes). Local data on this device is preserved.\n\nThis cannot be undone.';

  @override
  String get switchToAnonymousTitle => 'Switch to anonymous?';

  @override
  String get switchToAnonymousBody =>
      'You will be signed out of your email account and continue with a new anonymous session.\n\nYour local data (favorites, alerts) is kept on this device and will be synced to the new anonymous account.';

  @override
  String get switchAction => 'Switch';

  @override
  String get helpBannerCriteria =>
      'Your profile defaults are pre-filled. Adjust criteria below to refine your search.';

  @override
  String get helpBannerAlerts =>
      'Set a price threshold for a station. You\'ll be notified when prices drop below it. Checks run every 30 minutes.';

  @override
  String get helpBannerConsumption =>
      'Log every fill-up to track your real-world consumption and CO₂ footprint. Swipe left to delete an entry.';

  @override
  String get helpBannerVehicles =>
      'Add your vehicles so fill-ups and fuel preferences default correctly. The first vehicle becomes your default.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get onboardingPreferencesTitle => 'Your preferences';

  @override
  String get onboardingZipHelper => 'Used when GPS is unavailable';

  @override
  String get onboardingRadiusHelper => 'Larger radius = more results';

  @override
  String get onboardingPrivacy =>
      'These settings are stored only on your device and never shared.';

  @override
  String get onboardingLandingTitle => 'Home screen';

  @override
  String get onboardingLandingHint =>
      'Choose which screen opens when you launch the app.';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Fuel';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Highway';

  @override
  String get ratingModeLocal => 'Local';

  @override
  String get ratingModePrivate => 'Private';

  @override
  String get ratingModeShared => 'Shared';

  @override
  String get ratingDescLocal => 'Ratings saved on this device only';

  @override
  String get ratingDescPrivate =>
      'Synced with your database (not visible to others)';

  @override
  String get ratingDescShared => 'Visible to all users of your database';

  @override
  String get errorNoEvApiKey =>
      'OpenChargeMap API key not configured. Add one in Settings to search EV charging stations.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'The data provider ($host) is serving an expired or invalid TLS certificate. The app cannot load data from this source until the provider fixes it. Please contact $host.';
  }

  @override
  String get offlineLabel => 'Offline';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed unavailable. Using $current.';
  }

  @override
  String get errorTitleApiKey => 'API key required';

  @override
  String get errorTitleLocation => 'Location unavailable';

  @override
  String get errorHintNoStations =>
      'Try increasing the search radius or search a different location.';

  @override
  String get errorHintApiKey => 'Configure your API key in Settings.';

  @override
  String get errorHintConnection =>
      'Check your internet connection and try again.';

  @override
  String get errorHintRouting =>
      'Route calculation failed. Check your internet connection and try again.';

  @override
  String get errorHintFallback =>
      'Try again or search by postal code / city name.';

  @override
  String get alertsLoadErrorTitle => 'Couldn\'t load your alerts';

  @override
  String get alertsBackgroundCheckErrorTitle => 'Alert background check failed';

  @override
  String get detailsLabel => 'Details';

  @override
  String get remove => 'Remove';

  @override
  String get showKey => 'Show key';

  @override
  String get hideKey => 'Hide key';

  @override
  String get syncOptionalTitle => 'TankSync is optional';

  @override
  String get syncOptionalDescription =>
      'Your app works fully without cloud sync. TankSync lets you sync favorites, alerts, and ratings across devices using Supabase (free tier available).';

  @override
  String get syncHowToConnectQuestion => 'How would you like to connect?';

  @override
  String get syncCreateOwnTitle => 'Create my own database';

  @override
  String get syncCreateOwnSubtitle =>
      'Free Supabase project — we\'ll guide you step by step';

  @override
  String get syncJoinExistingTitle => 'Join an existing database';

  @override
  String get syncJoinExistingSubtitle =>
      'Scan QR code from the database owner or paste credentials';

  @override
  String get syncChooseAccountType => 'Choose your account type';

  @override
  String get syncAccountTypeAnonymous => 'Anonymous';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Instant, no email needed. Data tied to this device.';

  @override
  String get syncAccountTypeEmail => 'Email Account';

  @override
  String get syncAccountTypeEmailDesc =>
      'Sign in from any device. Recover data if phone is lost.';

  @override
  String get syncHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get syncCreateNewAccount => 'Create new account';

  @override
  String get syncTestConnection => 'Test Connection';

  @override
  String get syncTestingConnection => 'Testing...';

  @override
  String get syncConnectButton => 'Connect';

  @override
  String get syncConnectingButton => 'Connecting...';

  @override
  String get syncDatabaseReady => 'Database ready!';

  @override
  String get syncDatabaseNeedsSetup => 'Database needs setup';

  @override
  String get syncTableStatusOk => 'OK';

  @override
  String get syncTableStatusMissing => 'Missing';

  @override
  String get syncSqlEditorInstructions =>
      'Copy the SQL below and run it in your Supabase SQL Editor (Dashboard → SQL Editor → New Query → Paste → Run)';

  @override
  String get syncCopySqlButton => 'Copy SQL to clipboard';

  @override
  String get syncRecheckSchemaButton => 'Re-check schema';

  @override
  String get syncDoneButton => 'Done';

  @override
  String syncSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get syncEmailDescription =>
      'Your data syncs across all devices with this email.';

  @override
  String get syncSwitchToAnonymousTitle => 'Switch to anonymous';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Continue without email, new anonymous session';

  @override
  String get syncGuestDescription => 'Anonymous, no email needed.';

  @override
  String get syncOrDivider => 'or';

  @override
  String get syncHowToSyncQuestion => 'How would you like to sync?';

  @override
  String get syncOfflineDescription =>
      'Your app works fully offline. Cloud sync is optional.';

  @override
  String get syncModeCommunityTitle => 'Tankstellen Community';

  @override
  String get syncModeCommunitySubtitle =>
      'Share favorites & ratings with all users';

  @override
  String get syncModePrivateTitle => 'Private Database';

  @override
  String get syncModePrivateSubtitle => 'Your own Supabase — full data control';

  @override
  String get syncModeGroupTitle => 'Join a Group';

  @override
  String get syncModeGroupSubtitle => 'Family or friends shared database';

  @override
  String get syncPrivacyShared => 'Shared';

  @override
  String get syncPrivacyPrivate => 'Private';

  @override
  String get syncPrivacyGroup => 'Group';

  @override
  String get syncStayOfflineButton => 'Stay offline';

  @override
  String get syncSuccessTitle => 'Successfully connected!';

  @override
  String get syncSuccessDescription => 'Your data will now sync automatically.';

  @override
  String get syncWizardTitleConnect => 'Connect TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Your database';

  @override
  String get syncSetupTitleJoinGroup => 'Join a group';

  @override
  String get syncSetupTitleAccount => 'Your account';

  @override
  String get syncWizardBack => 'Back';

  @override
  String get syncWizardNext => 'Next';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Create a Supabase project';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Tap \"Open Supabase\" below\n2. Create a free account (if you don\'t have one)\n3. Click \"New Project\"\n4. Choose a name and region\n5. Wait ~2 minutes for it to start';

  @override
  String get syncWizardOpenSupabase => 'Open Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Enable Anonymous Sign-ins';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. In your Supabase dashboard:\n   Authentication → Providers\n2. Find \"Anonymous Sign-ins\"\n3. Toggle it ON\n4. Click \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Open Auth Settings';

  @override
  String get syncWizardCopyCredentialsTitle => 'Copy your credentials';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Go to Settings → API in your dashboard\n2. Copy the \"Project URL\"\n3. Copy the \"anon public\" key\n4. Paste them below';

  @override
  String get syncWizardOpenApiSettings => 'Open API Settings';

  @override
  String get syncWizardSupabaseUrlLabel => 'Supabase URL';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle => 'Join an existing database';

  @override
  String get syncWizardScanQrCode => 'Scan QR Code';

  @override
  String get syncWizardAskOwnerQr =>
      'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Ask the database owner to show their QR code';

  @override
  String get syncWizardEnterManuallyTitle => 'Enter manually';

  @override
  String get syncWizardOrEnterManually => 'or enter manually';

  @override
  String get syncWizardUrlHelperText =>
      'Whitespace and line breaks removed automatically';

  @override
  String get syncCredentialsPrivateHint =>
      'Enter your Supabase project credentials. You can find them in your dashboard under Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'Database URL';

  @override
  String get syncCredentialsAccessKeyLabel => 'Access Key';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPleaseEnterEmail => 'Please enter your email';

  @override
  String get authInvalidEmail => 'Invalid email address';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authConnectAnonymously => 'Connect anonymously';

  @override
  String get authCreateAccountAndConnect => 'Create account & connect';

  @override
  String get authSignInAndConnect => 'Sign in & connect';

  @override
  String get authAnonymousSegment => 'Anonymous';

  @override
  String get authEmailSegment => 'Email';

  @override
  String get authAnonymousDescription =>
      'Instant access, no email needed. Data tied to this device.';

  @override
  String get authEmailDescription =>
      'Sign in from any device. Recover your data if your phone is lost.';

  @override
  String get authSyncAcrossDevices =>
      'Sync data automatically across all your devices.';

  @override
  String get authNewHereCreateAccount => 'New here? Create account';

  @override
  String get ntfyCardTitle => 'Push Notifications (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Enable ntfy.sh push';

  @override
  String get ntfyEnableSubtitle => 'Receive price alerts via ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'Topic URL';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Copy topic URL';

  @override
  String get ntfySendTestButton => 'Send test notification';

  @override
  String get ntfyFdroidHint =>
      'Install the ntfy app from F-Droid to receive push notifications on your device.';

  @override
  String get ntfyConnectFirstHint =>
      'Connect TankSync first to enable push notifications.';

  @override
  String get linkDeviceScreenTitle => 'Link Device';

  @override
  String get linkDeviceThisDeviceLabel => 'This device';

  @override
  String get linkDeviceShareCodeHint =>
      'Share this code with your other device:';

  @override
  String get linkDeviceNotConnected => 'Not connected';

  @override
  String get linkDeviceCopyCodeTooltip => 'Copy code';

  @override
  String get linkDeviceImportSectionTitle => 'Import from another device';

  @override
  String get linkDeviceImportDescription =>
      'Enter the device code from your other device to import its favorites, alerts, vehicles, and consumption log. Each device keeps its own profile and defaults.';

  @override
  String get linkDeviceCodeFieldLabel => 'Device code';

  @override
  String get linkDeviceCodeFieldHint => 'Paste the UUID from other device';

  @override
  String get linkDeviceImportButton => 'Import data';

  @override
  String get linkDeviceHowItWorksTitle => 'How it works';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. On Device A: copy the device code above\n2. On Device B: paste it in the \"Device code\" field\n3. Tap \"Import data\" to merge favorites, alerts, vehicles, and consumption logs\n4. Both devices will have all combined data\n\nEach device keeps its own anonymous identity and its own profile (preferred fuel, default vehicle, landing screen). Data is merged, not moved.';

  @override
  String get vehicleSetActive => 'Set active';

  @override
  String get swipeHide => 'Hide';

  @override
  String get evChargingSection => 'EV Charging';

  @override
  String get fuelStationsSection => 'Fuel Stations';

  @override
  String get yourRating => 'Your rating';

  @override
  String get noStorageUsed => 'No storage used';

  @override
  String get aboutReportBug => 'Report a bug / Suggest a feature';

  @override
  String get aboutSupportProject => 'Support this project';

  @override
  String get aboutSupportDescription =>
      'This app is free, open source, and has no ads. If you find it useful, consider supporting the developer.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Luxembourg fuel prices are government-regulated and uniform nationwide.';

  @override
  String get luxembourgFuelUnleaded95 => 'Unleaded 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Unleaded 98';

  @override
  String get luxembourgFuelDiesel => 'Diesel';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Luxembourg regulated prices are unavailable.';

  @override
  String get reportIssueTitle => 'Report a problem';

  @override
  String get enterCorrection => 'Please enter the correction';

  @override
  String get reportNoBackendAvailable =>
      'The report could not be sent: no reporting service is configured for this country. Enable TankSync in Settings to send community reports.';

  @override
  String get correctName => 'Correct station name';

  @override
  String get correctAddress => 'Correct address';

  @override
  String get wrongE85Price => 'Wrong E85 price';

  @override
  String get wrongE98Price => 'Wrong Super 98 price';

  @override
  String get wrongLpgPrice => 'Wrong LPG price';

  @override
  String get wrongStationName => 'Wrong station name';

  @override
  String get wrongStationAddress => 'Wrong address';

  @override
  String get independentStation => 'Independent station';

  @override
  String get serviceRemindersSection => 'Service reminders';

  @override
  String get serviceRemindersEmpty => 'No reminders yet — pick a preset above.';

  @override
  String get addServiceReminder => 'Add reminder';

  @override
  String get serviceReminderPresetOil => 'Oil (15,000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Oil change';

  @override
  String get serviceReminderPresetTires => 'Tires (20,000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Tires';

  @override
  String get serviceReminderPresetInspection => 'Inspection (30,000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Inspection';

  @override
  String get serviceReminderLabel => 'Label';

  @override
  String get serviceReminderInterval => 'Interval (km)';

  @override
  String get serviceReminderLastService => 'Last service';

  @override
  String get serviceReminderMarkDone => 'Mark as done';

  @override
  String get serviceReminderDueTitle => 'Service due';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return '$label is due — $kmOver km past the interval.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Register at OPINET to get a free API key';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired => 'Register at CNE to get a free API key';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Is this your car?';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders-cyl, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Partial info (offline). You can edit below.';

  @override
  String get vinDecodeError => 'Couldn\'t decode this VIN';

  @override
  String get vinInvalidFormat => 'Invalid VIN format';

  @override
  String get obd2PauseBannerTitle => 'OBD2 connection lost — recording paused';

  @override
  String get obd2PauseBannerResume => 'Resume recording';

  @override
  String get obd2PauseBannerEnd => 'End recording';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Consumption calibration updated for $vehicleName — accuracy improved by $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Reset calibration?';

  @override
  String get veResetConfirmBody =>
      'This will discard the learned per-vehicle calibration and restore the default value (0.85).';

  @override
  String get alertsRadiusSectionTitle => 'Radius alerts';

  @override
  String get alertsRadiusAdd => 'Add radius alert';

  @override
  String get alertsRadiusEmptyTitle => 'No radius alerts yet';

  @override
  String get alertsRadiusEmptyCta => 'Create a radius alert';

  @override
  String get alertsRadiusCreateTitle => 'Create radius alert';

  @override
  String get alertsRadiusLabelHint => 'Label (e.g. Home diesel)';

  @override
  String get alertsRadiusFuelType => 'Fuel type';

  @override
  String get alertsRadiusThreshold => 'Threshold (€/L)';

  @override
  String get alertsRadiusKm => 'Radius (km)';

  @override
  String get alertsRadiusCenterGps => 'Use my location';

  @override
  String get alertsRadiusCenterPostalCode => 'Postal code';

  @override
  String get alertsRadiusSave => 'Save';

  @override
  String get alertsRadiusCancel => 'Cancel';

  @override
  String get alertsRadiusDeleteConfirm => 'Delete radius alert?';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 connected: $adapterName';
  }

  @override
  String velocityAlertTitle(String fuelLabel) {
    return '$fuelLabel dropped at nearby stations';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount stations dropped by up to $maxDropCents¢ in the last hour';
  }

  @override
  String get autoRecordSectionTitle => 'Auto-record';

  @override
  String get autoRecordToggleLabel => 'Auto-record trips';

  @override
  String get autoRecordPhaseStatusBanner =>
      'Auto-record is being rolled out in phases. Turning this on saves your preference, but the background recording flow is still in development — your trips are not yet auto-captured.';

  @override
  String get autoRecordSpeedThresholdLabel => 'Start speed (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Save delay after disconnect (seconds)';

  @override
  String get autoRecordPairedAdapterLabel => 'Paired adapter';

  @override
  String get autoRecordPairedAdapterNone =>
      'No adapter paired. Pair one via the OBD2 onboarding first.';

  @override
  String get autoRecordBackgroundLocationLabel => 'Background location allowed';

  @override
  String get autoRecordBackgroundLocationRequest => 'Request permission';

  @override
  String get autoRecordBadgeClearTooltip => 'Clear counter';

  @override
  String get consumptionTabFuel => 'Fuel';

  @override
  String get consumptionTabCharging => 'Charging';

  @override
  String get noChargingLogsTitle => 'No charging logs yet';

  @override
  String get noChargingLogsSubtitle =>
      'Log your first charging session to start tracking EUR/100 km and kWh/100 km.';

  @override
  String get addChargingLog => 'Log charging';

  @override
  String get addChargingLogTitle => 'Log charging session';

  @override
  String get chargingKwh => 'Energy (kWh)';

  @override
  String get chargingCost => 'Total cost';

  @override
  String get chargingTimeMin => 'Charge time (min)';

  @override
  String get chargingStationName => 'Station (optional)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper => 'Need a previous log to compare';

  @override
  String get chargingLogButtonLabel => 'Log charging';

  @override
  String get chargingCostTrendTitle => 'Charging cost trend';

  @override
  String get chargingEfficiencyTitle => 'Efficiency (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Not enough data yet';

  @override
  String get chargingChartsMonthAxis => 'Month';

  @override
  String get greeceApiProvider => 'Paratiritirio Timon (Greece)';

  @override
  String get greeceCommunityApiNotice =>
      'Powered by the community-maintained fuelpricesgr API';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Romania)';

  @override
  String get romaniaScrapingNotice =>
      'Powered by pretcarburant.ro (Competition Council + ANPC)';

  @override
  String get insightCardTitle => 'Top wasteful behaviours';

  @override
  String get insightEmptyState => 'No notable inefficiencies — keep it up!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Engine over 3000 RPM ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count hard accelerations: wasted $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Idling ($pctTime% of trip): wasted $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% of trip';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String get feedbackConsentTitle => 'Send report to GitHub?';

  @override
  String get feedbackConsentBody =>
      'This creates a public ticket on our GitHub repository with your photo and the OCR text. No personal data (location, account id) is sent. Continue?';

  @override
  String get feedbackConsentContinue => 'Continue';

  @override
  String get feedbackConsentCancel => 'Cancel';

  @override
  String get feedbackConsentLater => 'Later';

  @override
  String get feedbackTokenSectionTitle => 'Bad-scan feedback (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'To automatically open a GitHub ticket from a failed scan, paste a GitHub PAT (`public_repo` scope on the tankstellen repository). Otherwise manual sharing remains available.';

  @override
  String get feedbackTokenStatusSet => 'Token configured';

  @override
  String get feedbackTokenStatusUnset => 'No token';

  @override
  String get feedbackTokenSet => 'Set';

  @override
  String get feedbackTokenClear => 'Clear';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Personal Access Token';

  @override
  String get scanReceiptNoData => 'No receipt data found — try again';

  @override
  String get scanReceiptSuccess =>
      'Receipt scanned — verify values. Tap \"Report scan error\" below if anything is off.';

  @override
  String scanReceiptFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get scanPumpUnreadable => 'Pump display not readable — try again';

  @override
  String get scanPumpSuccess => 'Pump display scanned — verify the values.';

  @override
  String scanPumpFailed(String error) {
    return 'Pump scan failed: $error';
  }

  @override
  String get badScanReportTitle => 'Report a scan error';

  @override
  String get badScanReportTitleReceipt => 'Report a scan error — Receipt';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Report a scan error — Pump display';

  @override
  String get pumpScanFailureTitle => 'Display unreadable';

  @override
  String get pumpScanFailureBody =>
      'The scan couldn\'t read the pump display. What would you like to do?';

  @override
  String get pumpScanFailureCorrectManually => 'Correct manually';

  @override
  String get pumpScanFailureReport => 'Report';

  @override
  String get pumpScanFailureRemove => 'Remove photo';

  @override
  String get badScanReportHint =>
      'We\'ll share the receipt photo and both sets of values so the next build can learn this layout.';

  @override
  String get badScanReportShareAction => 'Share report + photo';

  @override
  String get badScanReportFieldBrandLayout => 'Brand layout';

  @override
  String get badScanReportFieldTotal => 'Total';

  @override
  String get badScanReportFieldPricePerLiter => 'Price/L';

  @override
  String get badScanReportFieldStation => 'Station';

  @override
  String get badScanReportFieldFuel => 'Fuel';

  @override
  String get badScanReportFieldDate => 'Date';

  @override
  String get badScanReportHeaderField => 'Field';

  @override
  String get badScanReportHeaderScanned => 'Scanned';

  @override
  String get badScanReportHeaderYouTyped => 'You typed';

  @override
  String get badScanReportCreateTicket => 'Create issue';

  @override
  String get badScanReportOpenInBrowser => 'Open in browser';

  @override
  String get badScanReportFallbackToShare => 'Submission failed — manual share';

  @override
  String get fillUpSectionWhatTitle => 'What you filled';

  @override
  String get fillUpSectionWhatSubtitle => 'Fuel, amount, price';

  @override
  String get fillUpSectionWhereTitle => 'Where you were';

  @override
  String get fillUpSectionWhereSubtitle => 'Station, odometer, notes';

  @override
  String get fillUpImportFromLabel => 'Import from…';

  @override
  String get fillUpImportSheetTitle => 'Import fill-up data';

  @override
  String get fillUpImportReceiptLabel => 'Receipt';

  @override
  String get fillUpImportReceiptDescription =>
      'Scan a paper receipt with the camera';

  @override
  String get fillUpImportPumpLabel => 'Pump display';

  @override
  String get fillUpImportPumpDescription =>
      'Read Betrag / Preis from the pump LCD';

  @override
  String get fillUpImportObdLabel => 'OBD-II adapter';

  @override
  String get fillUpImportObdDescription =>
      'Read odometer from the OBD-II port over Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Price per liter';

  @override
  String get vehicleHeaderPlateLabel => 'Plate';

  @override
  String get vehicleHeaderUntitled => 'New vehicle';

  @override
  String get vehicleSectionIdentityTitle => 'Identity';

  @override
  String get vehicleSectionIdentitySubtitle => 'Name & VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Drivetrain';

  @override
  String get vehicleSectionDrivetrainSubtitle => 'How this vehicle moves';

  @override
  String get calibrationModeLabel => 'Calibration mode';

  @override
  String get calibrationModeRule => 'Rule-based';

  @override
  String get calibrationModeFuzzy => 'Fuzzy';

  @override
  String get calibrationModeTooltip =>
      'Rule-based assigns each driving sample to exactly one situation. Fuzzy spreads it across all of them by how well each fits — smoother around 60 km/h or changing gradients, but slower to fill all buckets.';

  @override
  String get onboardingObd2StepTitle => 'Connect your OBD2 adapter';

  @override
  String get onboardingObd2StepBody =>
      'Plug your OBD2 adapter into the car\'s port and turn the ignition on. We\'ll read the VIN and fill in engine details for you.';

  @override
  String get onboardingObd2ConnectButton => 'Connect adapter';

  @override
  String get onboardingObd2SkipButton => 'Maybe later';

  @override
  String get onboardingObd2ReadingVin => 'Reading VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Couldn\'t read VIN — enter manually';

  @override
  String get onboardingObd2ConnectFailed =>
      'Couldn\'t connect to the adapter. You can retry or skip.';

  @override
  String get alertsRadiusFrequencyLabel => 'Check frequency';

  @override
  String get alertsRadiusFrequencyDaily => 'Once a day';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Twice a day';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Three times a day';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Four times a day';

  @override
  String get radiusAlertPickOnMap => 'Pick on map';

  @override
  String get radiusAlertMapPickerTitle => 'Pick alert center';

  @override
  String get radiusAlertMapPickerConfirm => 'Confirm';

  @override
  String get radiusAlertMapPickerCancel => 'Cancel';

  @override
  String get radiusAlertMapPickerHint =>
      'Drag the map to position the alert center';

  @override
  String get radiusAlertCenterFromMap => 'Map location';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel near $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'A station is at $price € (target: $threshold €)';
  }

  @override
  String get splashLoadingLabel => 'Loading Tankstellen';

  @override
  String get themeCardTitle => 'Theme';

  @override
  String get themeCardSubtitleSystem => 'System';

  @override
  String get themeCardSubtitleLight => 'Light';

  @override
  String get themeCardSubtitleDark => 'Dark';

  @override
  String get themeSettingsScreenTitle => 'Theme';

  @override
  String get themeSettingsSystemLabel => 'Follow system';

  @override
  String get themeSettingsLightLabel => 'Light';

  @override
  String get themeSettingsDarkLabel => 'Dark';

  @override
  String get themeSettingsSystemDescription =>
      'Match the current device appearance.';

  @override
  String get themeSettingsLightDescription =>
      'Bright backgrounds — best for daytime use.';

  @override
  String get themeSettingsDarkDescription =>
      'Dark backgrounds — easier on the eyes at night and saves battery on OLED screens.';

  @override
  String get trajetsTabLabel => 'Trips';

  @override
  String get trajetsStartRecordingButton => 'Start recording';

  @override
  String get trajetsEmptyStateTitle => 'No trips yet';

  @override
  String get trajetsEmptyStateBody =>
      'Tap Start recording to begin logging your drives.';

  @override
  String trajetsRowDistance(String km) {
    return '$km km';
  }

  @override
  String trajetsRowDuration(String minutes) {
    return '$minutes min';
  }

  @override
  String trajetsRowAvgConsumption(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get trajetDetailSummaryTitle => 'Summary';

  @override
  String get trajetDetailFieldDate => 'Date';

  @override
  String get trajetDetailFieldVehicle => 'Vehicle';

  @override
  String get trajetDetailFieldDistance => 'Distance';

  @override
  String get trajetDetailFieldDuration => 'Duration';

  @override
  String get trajetDetailFieldAvgConsumption => 'Avg consumption';

  @override
  String get trajetDetailFieldFuelUsed => 'Fuel used';

  @override
  String get trajetDetailFieldAvgSpeed => 'Avg speed';

  @override
  String get trajetDetailFieldMaxSpeed => 'Max speed';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Speed (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Fuel rate (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEmpty => 'No samples recorded';

  @override
  String get trajetDetailShareAction => 'Share';

  @override
  String get trajetDetailShareCopied => 'Copied to clipboard';

  @override
  String get trajetDetailDeleteAction => 'Delete';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Delete this trip?';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'This trip will be permanently removed from your history.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Cancel';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Delete';

  @override
  String get tripRecordingPinTooltip =>
      'Pinning keeps the screen on — uses more battery';

  @override
  String get tripRecordingPinSemanticOn => 'Unpin recording form';

  @override
  String get tripRecordingPinSemanticOff => 'Pin recording form';

  @override
  String get vinLabel => 'VIN (optional)';

  @override
  String get vinDecodeTooltip => 'Decode VIN';

  @override
  String get vinConfirmAction => 'Yes, auto-fill';

  @override
  String get vinModifyAction => 'Modify manually';

  @override
  String get veResetAction => 'Reset calibration';

  @override
  String get vinInfoTooltip => 'What is a VIN?';

  @override
  String get vinInfoSectionWhatTitle => 'What is a VIN?';

  @override
  String get vinInfoSectionWhatBody =>
      'The Vehicle Identification Number is a 17-character code unique to your car. It\'s stamped on the chassis and printed on your vehicle registration document.';

  @override
  String get vinInfoSectionWhyTitle => 'Why we ask';

  @override
  String get vinInfoSectionWhyBody =>
      'Decoding the VIN auto-fills engine displacement, cylinder count, model year, primary fuel type, and gross weight — saving you from looking up technical specs manually. The OBD2 fuel-rate calculation uses these values to give you accurate consumption numbers.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Privacy';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Your VIN is stored only locally in the app\'s encrypted storage — it\'s never uploaded to Tankstellen servers. The NHTSA vPIC database is queried with the VIN but returns only anonymous technical specs; NHTSA does not link the VIN to any personal data. Without network, an offline lookup returns manufacturer and country only.';

  @override
  String get vinInfoSectionWhereTitle => 'Where to find it';

  @override
  String get vinInfoSectionWhereBody =>
      'Look through the windshield at the lower-left corner on the driver\'s side, check the driver-side door-frame sticker when the door is open, or read it off your vehicle registration document (card / Carte Grise).';

  @override
  String get vinInfoDismiss => 'Got it';

  @override
  String get vinConfirmPrivacyNote =>
      'We looked up your VIN on NHTSA\'s free vehicle database — nothing sent to Tankstellen servers.';
}
