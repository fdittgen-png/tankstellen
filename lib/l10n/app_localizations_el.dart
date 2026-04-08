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
}
