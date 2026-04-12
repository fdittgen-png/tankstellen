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
  String get noFavoritesHint => 'Πατήστε το αστέρι σε ένα βενζινάδικο για να το αποθηκεύσετε στα αγαπημένα.';

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
  String get gpsReason => 'Αποστέλλονται με κάθε αναζήτηση για εύρεση κοντινών σταθμών.';

  @override
  String get postalCodeData => 'Ταχυδρομικός κώδικας';

  @override
  String get postalReason => 'Μετατρέπεται σε συντεταγμένες μέσω υπηρεσίας γεωκωδικοποίησης.';

  @override
  String get mapViewport => 'Προβολή χάρτη';

  @override
  String get mapReason => 'Τα πλακίδια χάρτη φορτώνονται από τον διακομιστή. Δεν μεταδίδονται προσωπικά δεδομένα.';

  @override
  String get apiKeyData => 'Κλειδί API';

  @override
  String get apiKeyReason => 'Το προσωπικό σας κλειδί αποστέλλεται με κάθε αίτημα API. Συνδέεται με το e-mail σας.';

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
  String get privacyBanner => 'Αυτή η εφαρμογή δεν έχει διακομιστή. Όλα τα δεδομένα παραμένουν στη συσκευή σας. Χωρίς αναλύσεις, παρακολούθηση ή διαφημίσεις.';

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
  String get cacheDescription => 'Η προσωρινή μνήμη αποθηκεύει απαντήσεις API για ταχύτερη φόρτωση και πρόσβαση εκτός σύνδεσης.';

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
  String get clearCacheBody => 'Τα αποθηκευμένα αποτελέσματα αναζήτησης και τιμές θα διαγραφούν. Τα προφίλ, αγαπημένα και ρυθμίσεις διατηρούνται.';

  @override
  String get clearCacheButton => 'Εκκαθάριση';

  @override
  String get deleteAllTitle => 'Διαγραφή όλων των δεδομένων;';

  @override
  String get deleteAllBody => 'Αυτό θα διαγράψει μόνιμα όλα τα προφίλ, αγαπημένα, κλειδί API, ρυθμίσεις και προσωρινή μνήμη. Η εφαρμογή θα επαναφερθεί.';

  @override
  String get deleteAllButton => 'Διαγραφή όλων';

  @override
  String get entries => 'εγγραφές';

  @override
  String get cacheEmpty => 'Η προσωρινή μνήμη είναι κενή';

  @override
  String get noStorage => 'Χωρίς χρησιμοποιούμενο χώρο';

  @override
  String get apiKeyNote => 'Δωρεάν εγγραφή. Δεδομένα από κρατικούς φορείς διαφάνειας τιμών.';

  @override
  String get apiKeyFormatError => 'Μη έγκυρη μορφή — αναμενόμενο UUID (8-4-4-4-12)';

  @override
  String get supportProject => 'Υποστηρίξτε αυτό το έργο';

  @override
  String get supportDescription => 'Αυτή η εφαρμογή είναι δωρεάν, ανοιχτού κώδικα και χωρίς διαφημίσεις. Αν τη βρίσκετε χρήσιμη, σκεφτείτε να υποστηρίξετε τον προγραμματιστή.';

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
  String get locationDenied => 'Η άδεια τοποθεσίας απορρίφθηκε. Μπορείτε να αναζητήσετε με Τ.Κ.';

  @override
  String get demoModeBanner => 'Λειτουργία επίδειξης. Ρυθμίστε το κλειδί API στις ρυθμίσεις.';

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
  String get loadingFavorites => 'Φόρτωση αγαπημένων...\nΑναζητήστε πρώτα σταθμούς για αποθήκευση δεδομένων.';

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
  String get autoUpdateDescription => 'Ενημέρωση θέσης GPS πριν από κάθε αναζήτηση';

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
  String get autoSwitchDescription => 'Αυτόματη εναλλαγή προφίλ κατά τη διέλευση συνόρων';

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
  String get noPriceAlertsHint => 'Δημιουργήστε ειδοποίηση από τη σελίδα λεπτομερειών ενός σταθμού.';

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
  String get noStationsAlongRoute => 'Δεν βρέθηκαν σταθμοί κατά μήκος της διαδρομής';

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
  String get evStatusDisclaimer => 'Η κατάσταση μπορεί να μην αντικατοπτρίζει τη διαθεσιμότητα σε πραγματικό χρόνο. Πατήστε ανανέωση για τα τελευταία δεδομένα.';

  @override
  String get evNavigateToStation => 'Πλοήγηση στον σταθμό';

  @override
  String get evRefreshStatus => 'Ανανέωση κατάστασης';

  @override
  String get evStatusUpdated => 'Κατάσταση ενημερώθηκε';

  @override
  String get evStationNotFound => 'Δεν ήταν δυνατή η ανανέωση — ο σταθμός δεν βρέθηκε κοντά';

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
  String get couldNotResolve => 'Δεν ήταν δυνατός ο προσδιορισμός αφετηρίας ή προορισμού';

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
  String get requiredForFuelSearch => 'Απαιτείται για αναζήτηση τιμών καυσίμων στη Γερμανία';

  @override
  String get evChargingOpenChargeMap => 'Φόρτιση EV (OpenChargeMap)';

  @override
  String get customKey => 'Προσαρμοσμένο κλειδί';

  @override
  String get appDefaultKey => 'Προεπιλεγμένο κλειδί εφαρμογής';

  @override
  String get optionalOverrideKey => 'Προαιρετικό: αντικατάσταση του ενσωματωμένου κλειδιού με το δικό σας';

  @override
  String get requiredForEvSearch => 'Απαιτείται για αναζήτηση σταθμών φόρτισης EV';

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
  String get avoidHighwaysDesc => 'Ο υπολογισμός διαδρομής αποφεύγει δρόμους με διόδια και αυτοκινητοδρόμους';

  @override
  String get showFuelStations => 'Εμφάνιση βενζινάδικων';

  @override
  String get showFuelStationsDesc => 'Συμπερίληψη σταθμών βενζίνης, ντίζελ, LPG, CNG';

  @override
  String get showEvStations => 'Εμφάνιση σταθμών φόρτισης';

  @override
  String get showEvStationsDesc => 'Συμπερίληψη ηλεκτρικών σταθμών φόρτισης στα αποτελέσματα';

  @override
  String get noStationsAlongThisRoute => 'Δεν βρέθηκαν σταθμοί κατά μήκος αυτής της διαδρομής.';

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
  String get enterCalcValues => 'Εισάγετε απόσταση, κατανάλωση και τιμή για υπολογισμό κόστους ταξιδιού';

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
  String get optionalCloudSync => 'Προαιρετικός συγχρονισμός cloud για ειδοποιήσεις, αγαπημένα και push ειδοποιήσεις';

  @override
  String get tapToUpdateGps => 'Πατήστε για ενημέρωση θέσης GPS';

  @override
  String get gpsAutoUpdateHint => 'Η θέση GPS αποκτάται αυτόματα κατά την αναζήτηση. Μπορείτε επίσης να την ενημερώσετε χειροκίνητα εδώ.';

  @override
  String get clearGpsConfirm => 'Διαγραφή αποθηκευμένης θέσης GPS; Μπορείτε να την ενημερώσετε ξανά ανά πάσα στιγμή.';

  @override
  String get pageNotFound => 'Η σελίδα δεν βρέθηκε';

  @override
  String get deleteAllServerData => 'Διαγραφή όλων των δεδομένων διακομιστή';

  @override
  String get deleteServerDataConfirm => 'Διαγραφή όλων των δεδομένων διακομιστή;';

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
  String get noSavedRoutesHint => 'Search along a route and save it for quick access later.';

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
  String get deleteProfileBody => 'This profile and its settings will be permanently deleted. This cannot be undone.';

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
  String get errorNoApiKey => 'No API key configured. Go to Settings to add one.';

  @override
  String get errorAllServicesFailed => 'Could not load data. Check your connection and try again.';

  @override
  String get errorCache => 'Local data error. Try clearing the cache.';

  @override
  String get errorCancelled => 'Request was cancelled.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get onboardingWelcomeHint => 'Set up the app in a few quick steps.';

  @override
  String get onboardingApiKeyDescription => 'Register for a free API key, or skip to explore the app with demo data.';

  @override
  String get onboardingComplete => 'All set!';

  @override
  String get onboardingCompleteHint => 'You can change these settings anytime in your profile.';

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
  String get gdprSubtitle => 'This app respects your privacy. Choose which data you want to share. You can change these settings anytime.';

  @override
  String get gdprLocationTitle => 'Location Access';

  @override
  String get gdprLocationDescription => 'Your coordinates are sent to the fuel price API to find nearby stations. Location data is never stored on a server and is not used for tracking.';

  @override
  String get gdprLocationShort => 'Find nearby fuel stations using your location';

  @override
  String get gdprErrorReportingTitle => 'Error Reporting';

  @override
  String get gdprErrorReportingDescription => 'Anonymous crash reports help improve the app. No personal data is included. Reports are sent via Sentry only when configured.';

  @override
  String get gdprErrorReportingShort => 'Send anonymous crash reports to improve the app';

  @override
  String get gdprCloudSyncTitle => 'Cloud Sync';

  @override
  String get gdprCloudSyncDescription => 'Sync favorites and alerts across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.';

  @override
  String get gdprCloudSyncShort => 'Sync favorites and alerts across devices';

  @override
  String get gdprLegalBasis => 'Legal basis: Art. 6(1)(a) GDPR (Consent). You can withdraw consent anytime in Settings.';

  @override
  String get gdprAcceptAll => 'Accept All';

  @override
  String get gdprAcceptSelected => 'Accept Selected';

  @override
  String get gdprSettingsHint => 'You can change your privacy choices at any time.';

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
  String get invalidQrCodeTankSync => 'Invalid QR code — expected TankSync format';

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
  String get swipeTutorialMessage => 'Swipe right to navigate, swipe left to remove';

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
  String get privacyDashboardBanner => 'Your data belongs to you. Here you can see everything this app stores, export it, or delete it.';

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
  String get privacySyncDisabled => 'Cloud sync is disabled. All data stays on this device only.';

  @override
  String get privacySyncMode => 'Sync mode';

  @override
  String get privacySyncUserId => 'User ID';

  @override
  String get privacySyncDescription => 'When sync is enabled, favorites, alerts, ignored stations, and ratings are also stored on the TankSync server.';

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
  String get privacyDeleteTitle => 'Delete all data?';

  @override
  String get privacyDeleteBody => 'This will permanently delete:\n\n- All favorites and station data\n- All search profiles\n- All price alerts\n- All price history\n- All cached data\n- Your API key\n- All app settings\n\nThe app will reset to its initial state. This action cannot be undone.';

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
  String get drivingSafetyMessage => 'Do not operate the app while driving. Pull over to a safe location before interacting with the screen. The driver is responsible for safe operation of the vehicle at all times.';

  @override
  String get drivingSafetyAccept => 'I understand';

  @override
  String get voiceAnnouncementsTitle => 'Voice Announcements';

  @override
  String get voiceAnnouncementsDescription => 'Announce nearby cheap stations while driving';

  @override
  String get voiceAnnouncementsEnabled => 'Enable voice announcements';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Only below $price';
  }

  @override
  String voiceAnnouncementCheapFuel(String station, String distance, String fuelType, String price) {
    return '$station, $distance kilometers ahead, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Announcement radius';

  @override
  String get voiceAnnouncementCooldown => 'Repeat interval';

  @override
  String get nearestStations => 'Kontinoteroi stathmoi';

  @override
  String get nearestStationsHint => 'Vreite tous kontinoterous stathmous me tin trexousa topothesia sas';

  @override
  String get consumptionLogTitle => 'Fuel consumption';

  @override
  String get consumptionLogMenuTitle => 'Consumption log';

  @override
  String get consumptionLogMenuSubtitle => 'Track fill-ups and calculate L/100km';

  @override
  String get consumptionStatsTitle => 'Consumption stats';

  @override
  String get addFillUp => 'Add fill-up';

  @override
  String get noFillUpsTitle => 'No fill-ups yet';

  @override
  String get noFillUpsSubtitle => 'Log your first fill-up to start tracking consumption.';

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
  String get carbonEmptySubtitle => 'Log fill-ups to see your carbon dashboard.';

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
  String get vehiclesMenuSubtitle => 'Battery, connectors, charging preferences';

  @override
  String get vehiclesEmptyMessage => 'Add your car to filter by connector and estimate charging costs.';

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
  String get switchToEmail => 'Switch to email';

  @override
  String get switchToEmailSubtitle => 'Keep data, add sign-in from other devices';

  @override
  String get switchToAnonymousAction => 'Switch to anonymous';

  @override
  String get switchToAnonymousSubtitle => 'Keep local data, use new anonymous session';

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
  String get localOnlySubtitle => 'Optional: sync favorites, alerts, and ratings across devices';

  @override
  String get setupCloudSync => 'Set up cloud sync';

  @override
  String get disconnectTitle => 'Disconnect TankSync?';

  @override
  String get disconnectBody => 'Cloud sync will be disabled. Your local data (favorites, alerts, history) is preserved on this device. Server data is not deleted.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody => 'This permanently deletes all your data from the server (favorites, alerts, ratings, routes). Local data on this device is preserved.\n\nThis cannot be undone.';

  @override
  String get switchToAnonymousTitle => 'Switch to anonymous?';

  @override
  String get switchToAnonymousBody => 'You will be signed out of your email account and continue with a new anonymous session.\n\nYour local data (favorites, alerts) is kept on this device and will be synced to the new anonymous account.';

  @override
  String get switchAction => 'Switch';

  @override
  String get helpBannerCriteria => 'Your profile defaults are pre-filled. Adjust criteria below to refine your search.';

  @override
  String get helpBannerAlerts => 'Set a price threshold for a station. You\'ll be notified when prices drop below it. Checks run every 30 minutes.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get onboardingPreferencesTitle => 'Your preferences';

  @override
  String get onboardingZipHelper => 'Used when GPS is unavailable';

  @override
  String get onboardingRadiusHelper => 'Larger radius = more results';

  @override
  String get onboardingPrivacy => 'These settings are stored only on your device and never shared.';

  @override
  String get onboardingLandingTitle => 'Home screen';

  @override
  String get onboardingLandingHint => 'Choose which screen opens when you launch the app.';

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
}
