// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Sparkilo';

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
  String get searchCriteriaTitle => 'Κριτήρια αναζήτησης';

  @override
  String get searchCriteriaOpen => 'Αναζήτηση';

  @override
  String searchCriteriaRadiusBadge(String km) {
    return 'Εντός $km km';
  }

  @override
  String get searchCriteriaTapToSearch => 'Πατήστε για αναζήτηση';

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
  String get welcome => 'Sparkilo';

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
  String get countryChangeTitle => 'Αλλαγή χώρας;';

  @override
  String countryChangeBody(String country) {
    return 'Η μετάβαση σε $country θα αλλάξει:';
  }

  @override
  String get countryChangeCurrency => 'Νόμισμα';

  @override
  String get countryChangeDistance => 'Απόσταση';

  @override
  String get countryChangeVolume => 'Όγκος';

  @override
  String get countryChangePricePerUnit => 'Μορφή τιμής';

  @override
  String get countryChangeNote =>
      'Τα υπάρχοντα αγαπημένα και τα αρχεία ανεφοδιασμού δεν επαναγράφονται· μόνο νέες εγγραφές χρησιμοποιούν τις νέες μονάδες.';

  @override
  String get countryChangeConfirm => 'Αλλαγή';

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
  String get reportThisIssue => 'Αναφορά προβλήματος';

  @override
  String get reportAlreadySent => 'Έχετε ήδη αναφέρει αυτό το πρόβλημα.';

  @override
  String get reportConsentTitle => 'Αναφορά στο GitHub;';

  @override
  String get reportConsentBody =>
      'Θα ανοίξει ένα δημόσιο ζήτημα GitHub με τις παρακάτω λεπτομέρειες σφάλματος. Δεν συμπεριλαμβάνονται συντεταγμένες GPS, κλειδιά API ή προσωπικά δεδομένα.';

  @override
  String get reportConsentConfirm => 'Άνοιγμα GitHub';

  @override
  String get reportConsentCancel => 'Ακύρωση';

  @override
  String get configProfileSection => 'Προφίλ';

  @override
  String get configActiveProfile => 'Ενεργό προφίλ';

  @override
  String get configPreferredFuel => 'Προτιμώμενο καύσιμο';

  @override
  String get configCountry => 'Χώρα';

  @override
  String get configRouteSegment => 'Τμήμα διαδρομής';

  @override
  String get configApiKeysSection => 'Κλειδιά API';

  @override
  String get configTankerkoenigKey => 'Κλειδί API Tankerkoenig';

  @override
  String get configApiKeyConfigured => 'Ρυθμισμένο';

  @override
  String get configApiKeyNotSet => 'Μη ορισμένο (λειτουργία επίδειξης)';

  @override
  String get configApiKeyCommunity => 'Προεπιλογή (κοινοτικό κλειδί)';

  @override
  String get searchLocationPlaceholder =>
      'Διεύθυνση, ταχυδρομικός κώδικας ή πόλη';

  @override
  String get configEvKey => 'Κλειδί API φόρτισης EV';

  @override
  String get configEvKeyCustom => 'Προσαρμοσμένο κλειδί';

  @override
  String get configEvKeyShared => 'Προεπιλογή (κοινόχρηστο)';

  @override
  String get configCloudSyncSection => 'Συγχρονισμός Cloud';

  @override
  String get configTankSyncConnected => 'Συνδεδεμένο';

  @override
  String get configTankSyncDisabled => 'Απενεργοποιημένο';

  @override
  String get configAuthMode => 'Τρόπος ταυτοποίησης';

  @override
  String get configAuthEmail => 'Email (μόνιμο)';

  @override
  String get configAuthAnonymous => 'Ανώνυμο (μόνο συσκευή)';

  @override
  String get configDatabase => 'Βάση δεδομένων';

  @override
  String get configPrivacySummary => 'Σύνοψη απορρήτου';

  @override
  String configPrivacySummarySynced(Object authNote) {
    return '• Τα αγαπημένα, οι ειδοποιήσεις και οι αποκρυμμένοι σταθμοί συγχρονίζονται στη δική σας ιδιωτική βάση δεδομένων\n• Η θέση GPS και τα κλειδιά API δεν φεύγουν ποτέ από τη συσκευή σας\n• $authNote';
  }

  @override
  String get configPrivacySummaryLocal =>
      '• Όλα τα δεδομένα αποθηκεύονται τοπικά μόνο σε αυτή τη συσκευή\n• Δεν αποστέλλονται δεδομένα σε κανέναν διακομιστή\n• Τα κλειδιά API κρυπτογραφούνται στην ασφαλή αποθήκευση της συσκευής';

  @override
  String get configAuthNoteEmail =>
      'Ο λογαριασμός email επιτρέπει πρόσβαση από πολλές συσκευές';

  @override
  String get configAuthNoteAnonymous =>
      'Ανώνυμος λογαριασμός — τα δεδομένα συνδέονται με αυτή τη συσκευή';

  @override
  String get configNone => 'Κανένα';

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
  String get demoModeBannerAction => 'Λήψη ζωντανών τιμών';

  @override
  String get sortDistance => 'Απόσταση';

  @override
  String get sortOpen24h => '24ω';

  @override
  String get sortRating => 'Αξιολόγηση';

  @override
  String get sortPriceDistance => 'Τιμή/km';

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
  String get routePlanningSection => 'Σχεδιασμός διαδρομής';

  @override
  String get routeMinSaving => 'Ελάχιστη εξοικονόμηση';

  @override
  String get routeMinSavingOff => 'Ανενεργό';

  @override
  String get routeMinSavingOffCaption =>
      'Εμφάνιση όλων των σταθμών που βρέθηκαν κατά μήκος της διαδρομής';

  @override
  String routeMinSavingCaption(String amount) {
    return 'Μόνο σταθμοί εντός $amount από τον φθηνότερο της διαδρομής';
  }

  @override
  String get routeDetourBudget => 'Μέγιστη παράκαμψη';

  @override
  String routeDetourBudgetCaption(int km) {
    return 'Εμφάνιση σταθμών έως $km χλμ από την άμεση διαδρομή σας';
  }

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
  String get forgetAllSyncedTripsButton =>
      'Διαγραφή όλων των συγχρονισμένων διαδρομών';

  @override
  String get forgetAllSyncedTripsConfirmTitle =>
      'Διαγραφή όλων των συγχρονισμένων διαδρομών;';

  @override
  String get forgetAllSyncedTripsConfirmBody =>
      'Κάθε σύνοψη διαδρομής και αναλυτικά δεδομένα θα αφαιρεθούν από τον διακομιστή. Το τοπικό ιστορικό διαδρομών σε αυτή τη συσκευή δεν θα επηρεαστεί.\n\nΑυτή η ενέργεια δεν μπορεί να αναιρεθεί.';

  @override
  String get forgetAllSyncedTripsConfirmAction => 'Διαγραφή όλων';

  @override
  String get forgetAllSyncedTripsSuccess =>
      'Όλες οι συγχρονισμένες διαδρομές αφαιρέθηκαν από τον διακομιστή';

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
  String get account => 'Λογαριασμός';

  @override
  String get continueAsGuest => 'Συνέχεια ως επισκέπτης';

  @override
  String get createAccount => 'Δημιουργία λογαριασμού';

  @override
  String get signIn => 'Σύνδεση';

  @override
  String get upgradeToEmail => 'Δημιουργία λογαριασμού email';

  @override
  String get savedRoutes => 'Αποθηκευμένες διαδρομές';

  @override
  String get noSavedRoutes => 'Δεν υπάρχουν αποθηκευμένες διαδρομές';

  @override
  String get noSavedRoutesHint =>
      'Αναζητήστε κατά μήκος μιας διαδρομής και αποθηκεύστε την για γρήγορη πρόσβαση αργότερα.';

  @override
  String get saveRoute => 'Αποθήκευση διαδρομής';

  @override
  String get routeName => 'Όνομα διαδρομής';

  @override
  String itineraryDeleted(String name) {
    return 'Το $name διαγράφηκε';
  }

  @override
  String loadingRoute(String name) {
    return 'Φόρτωση διαδρομής: $name';
  }

  @override
  String get refreshFailed => 'Αποτυχία ανανέωσης. Παρακαλώ δοκιμάστε ξανά.';

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
  String get onboardingWelcomeHint =>
      'Ρυθμίστε την εφαρμογή σε μερικά γρήγορα βήματα.';

  @override
  String get onboardingApiKeyDescription =>
      'Εγγραφείτε για δωρεάν κλειδί API ή παραλείψτε για εξερεύνηση με δεδομένα επίδειξης.';

  @override
  String get onboardingComplete => 'Όλα έτοιμα!';

  @override
  String get onboardingCompleteHint =>
      'Μπορείτε να αλλάξετε αυτές τις ρυθμίσεις ανά πάσα στιγμή στο προφίλ σας.';

  @override
  String get onboardingBack => 'Πίσω';

  @override
  String get onboardingNext => 'Επόμενο';

  @override
  String get onboardingSkip => 'Παράλειψη';

  @override
  String get onboardingFinish => 'Ξεκινήστε';

  @override
  String crossBorderNearby(String country) {
    return 'Η $country είναι κοντά';
  }

  @override
  String crossBorderDistance(int km) {
    return '~$km km στα σύνορα';
  }

  @override
  String crossBorderAvgPrice(String price, int count) {
    return 'Μέση τιμή εδώ: $price EUR ($count σταθμοί)';
  }

  @override
  String get allPricesView => 'Όλες οι τιμές';

  @override
  String get compactView => 'Συμπαγής';

  @override
  String get switchToAllPricesView => 'Εναλλαγή στην προβολή όλων των τιμών';

  @override
  String get switchToCompactView => 'Εναλλαγή στη συμπαγή προβολή';

  @override
  String get unavailable => 'Μ/Δ';

  @override
  String get outOfStock => 'Εξαντλημένο';

  @override
  String get gdprTitle => 'Το απόρρητό σας';

  @override
  String get gdprSubtitle =>
      'Αυτή η εφαρμογή σέβεται το απόρρητό σας. Επιλέξτε ποια δεδομένα θέλετε να κοινοποιήσετε. Μπορείτε να αλλάξετε αυτές τις ρυθμίσεις ανά πάσα στιγμή.';

  @override
  String get gdprLocationTitle => 'Πρόσβαση τοποθεσίας';

  @override
  String get gdprLocationDescription =>
      'Οι συντεταγμένες σας αποστέλλονται στο API τιμών καυσίμων για εύρεση κοντινών σταθμών. Τα δεδομένα τοποθεσίας δεν αποθηκεύονται ποτέ σε διακομιστή και δεν χρησιμοποιούνται για παρακολούθηση.';

  @override
  String get gdprLocationShort =>
      'Εύρεση κοντινών σταθμών καυσίμων με βάση την τοποθεσία σας';

  @override
  String get gdprErrorReportingTitle => 'Αναφορά σφαλμάτων';

  @override
  String get gdprErrorReportingDescription =>
      'Ανώνυμες αναφορές σφαλμάτων βοηθούν στη βελτίωση της εφαρμογής. Δεν περιλαμβάνονται προσωπικά δεδομένα. Οι αναφορές αποστέλλονται μέσω Sentry μόνο όταν είναι ρυθμισμένο.';

  @override
  String get gdprErrorReportingShort =>
      'Αποστολή ανώνυμων αναφορών σφαλμάτων για βελτίωση της εφαρμογής';

  @override
  String get gdprCloudSyncTitle => 'Συγχρονισμός Cloud';

  @override
  String get gdprCloudSyncDescription =>
      'Συγχρονισμός αγαπημένων και ειδοποιήσεων σε συσκευές μέσω TankSync. Χρησιμοποιεί ανώνυμη ταυτοποίηση. Τα δεδομένα σας κρυπτογραφούνται κατά τη μεταφορά.';

  @override
  String get gdprCloudSyncShort =>
      'Συγχρονισμός αγαπημένων και ειδοποιήσεων σε συσκευές';

  @override
  String get gdprLegalBasis =>
      'Νομική βάση: Άρθρο 6(1)(α) GDPR (Συγκατάθεση). Μπορείτε να ανακαλέσετε τη συγκατάθεση ανά πάσα στιγμή στις Ρυθμίσεις.';

  @override
  String get gdprAcceptAll => 'Αποδοχή όλων';

  @override
  String get gdprAcceptSelected => 'Αποδοχή επιλεγμένων';

  @override
  String get gdprSettingsHint =>
      'Μπορείτε να αλλάξετε τις επιλογές απορρήτου σας ανά πάσα στιγμή.';

  @override
  String get routeSaved => 'Η διαδρομή αποθηκεύτηκε!';

  @override
  String get routeSaveFailed => 'Αποτυχία αποθήκευσης διαδρομής';

  @override
  String get sqlCopied => 'SQL αντιγράφηκε στο πρόχειρο';

  @override
  String get connectionDataCopied => 'Δεδομένα σύνδεσης αντιγράφηκαν';

  @override
  String get accountDeleted =>
      'Ο λογαριασμός διαγράφηκε. Τα τοπικά δεδομένα διατηρήθηκαν.';

  @override
  String get switchedToAnonymous => 'Μετάβαση σε ανώνυμη σύνδεση';

  @override
  String failedToSwitch(String error) {
    return 'Αποτυχία εναλλαγής: $error';
  }

  @override
  String get topicUrlCopied => 'URL θέματος αντιγράφηκε';

  @override
  String get testNotificationSent => 'Δοκιμαστική ειδοποίηση στάλθηκε!';

  @override
  String get testNotificationFailed =>
      'Αποτυχία αποστολής δοκιμαστικής ειδοποίησης';

  @override
  String get pushUpdateFailed =>
      'Αποτυχία ενημέρωσης ρύθμισης push ειδοποιήσεων';

  @override
  String get connectedAsGuest => 'Συνδεδεμένος ως επισκέπτης';

  @override
  String get accountCreated => 'Ο λογαριασμός δημιουργήθηκε!';

  @override
  String get signedIn => 'Συνδεθήκατε!';

  @override
  String stationHidden(String name) {
    return 'Ο σταθμός $name αποκρύφτηκε';
  }

  @override
  String removedFromFavoritesName(String name) {
    return 'Το $name αφαιρέθηκε από τα αγαπημένα';
  }

  @override
  String invalidApiKey(String error) {
    return 'Μη έγκυρο κλειδί API: $error';
  }

  @override
  String get invalidQrCode => 'Μη έγκυρη μορφή QR κώδικα';

  @override
  String get invalidQrCodeTankSync =>
      'Μη έγκυρος QR κώδικας — αναμενόμενη μορφή TankSync';

  @override
  String get tankSyncConnected => 'TankSync συνδέθηκε!';

  @override
  String get syncCompleted =>
      'Συγχρονισμός ολοκληρώθηκε — τα δεδομένα ανανεώθηκαν';

  @override
  String get deviceCodeCopied => 'Κωδικός συσκευής αντιγράφηκε';

  @override
  String get undo => 'Αναίρεση';

  @override
  String invalidPostalCode(String length, String label) {
    return 'Παρακαλώ εισάγετε έγκυρο $label $length ψηφίων';
  }

  @override
  String get freshnessAgo => 'πριν';

  @override
  String get freshnessStale => 'Παλιό';

  @override
  String freshnessBadgeSemantics(String age) {
    return 'Ανανέωση δεδομένων: $age';
  }

  @override
  String brandLogoLabel(String brand) {
    return 'Λογότυπο $brand';
  }

  @override
  String ratingStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Βαθμολογία $count αστέρια',
      one: 'Βαθμολογία 1 αστέρι',
    );
    return '$_temp0';
  }

  @override
  String get passwordStrengthWeak => 'Αδύναμος';

  @override
  String get passwordStrengthFair => 'Μέτριος';

  @override
  String get passwordStrengthStrong => 'Ισχυρός';

  @override
  String get passwordReqMinLength => 'Τουλάχιστον 8 χαρακτήρες';

  @override
  String get passwordReqUppercase => 'Τουλάχιστον 1 κεφαλαίο γράμμα';

  @override
  String get passwordReqLowercase => 'Τουλάχιστον 1 πεζό γράμμα';

  @override
  String get passwordReqDigit => 'Τουλάχιστον 1 αριθμός';

  @override
  String get passwordReqSpecial => 'Τουλάχιστον 1 ειδικός χαρακτήρας';

  @override
  String get passwordTooWeak => 'Ο κωδικός δεν πληροί όλες τις απαιτήσεις';

  @override
  String get brandFilterAll => 'Όλα';

  @override
  String get brandFilterNoHighway => 'Χωρίς αυτοκινητόδρομο';

  @override
  String get swipeTutorialMessage =>
      'Σύρετε δεξιά για πλοήγηση, σύρετε αριστερά για αφαίρεση';

  @override
  String get swipeTutorialDismiss => 'Κατάλαβα';

  @override
  String get alertStatsActive => 'Ενεργές';

  @override
  String get alertStatsToday => 'Σήμερα';

  @override
  String get alertStatsThisWeek => 'Αυτή την εβδομάδα';

  @override
  String get privacyDashboardTitle => 'Πίνακας ελέγχου απορρήτου';

  @override
  String get privacyDashboardSubtitle =>
      'Προβολή, εξαγωγή ή διαγραφή των δεδομένων σας';

  @override
  String get privacyDashboardBanner =>
      'Τα δεδομένα σας ανήκουν σε εσάς. Εδώ μπορείτε να δείτε όσα αποθηκεύει αυτή η εφαρμογή, να τα εξαγάγετε ή να τα διαγράψετε.';

  @override
  String get privacyLocalData => 'Δεδομένα σε αυτή τη συσκευή';

  @override
  String get privacyIgnoredStations => 'Αποκρυμμένοι σταθμοί';

  @override
  String get privacyRatings => 'Αξιολογήσεις σταθμών';

  @override
  String get privacyPriceHistory => 'Σταθμοί ιστορικού τιμών';

  @override
  String get privacyProfiles => 'Προφίλ αναζήτησης';

  @override
  String get privacyItineraries => 'Αποθηκευμένες διαδρομές';

  @override
  String get privacyCacheEntries => 'Εγγραφές προσωρινής μνήμης';

  @override
  String get privacyApiKey => 'Αποθηκευμένο κλειδί API';

  @override
  String get privacyEvApiKey => 'Αποθηκευμένο κλειδί API EV';

  @override
  String get privacyEstimatedSize => 'Εκτιμώμενος χώρος';

  @override
  String get privacySyncedData => 'Συγχρονισμός cloud (TankSync)';

  @override
  String get privacySyncDisabled =>
      'Ο συγχρονισμός cloud είναι απενεργοποιημένος. Όλα τα δεδομένα παραμένουν μόνο σε αυτή τη συσκευή.';

  @override
  String get privacySyncMode => 'Λειτουργία συγχρονισμού';

  @override
  String get privacySyncUserId => 'ID χρήστη';

  @override
  String get privacySyncDescription =>
      'Όταν ο συγχρονισμός είναι ενεργός, αγαπημένα, ειδοποιήσεις, αποκρυμμένοι σταθμοί και αξιολογήσεις αποθηκεύονται επίσης στον διακομιστή TankSync.';

  @override
  String get privacyViewServerData => 'Προβολή δεδομένων διακομιστή';

  @override
  String get privacyExportButton => 'Εξαγωγή όλων των δεδομένων ως JSON';

  @override
  String get privacyExportSuccess => 'Τα δεδομένα εξήχθησαν στο πρόχειρο';

  @override
  String get privacyExportCsvButton => 'Εξαγωγή όλων των δεδομένων ως CSV';

  @override
  String get privacyExportCsvSuccess =>
      'Τα δεδομένα CSV εξήχθησαν στο πρόχειρο';

  @override
  String get savedToDownloadsFolder => 'Αποθηκεύτηκε στον φάκελο Λήψεις';

  @override
  String get privacyDeleteButton => 'Διαγραφή όλων των δεδομένων';

  @override
  String privacyCopyErrorLog(int count) {
    return 'Αντιγραφή αρχείου καταγραφής σφαλμάτων στο πρόχειρο ($count)';
  }

  @override
  String get privacyClearErrorLog => 'Εκκαθάριση αρχείου σφαλμάτων';

  @override
  String get privacyErrorLogCleared => 'Το αρχείο σφαλμάτων εκκαθαρίστηκε';

  @override
  String get privacyDeleteTitle => 'Διαγραφή όλων των δεδομένων;';

  @override
  String get privacyDeleteBody =>
      'Αυτό θα διαγράψει μόνιμα:\n\n- Όλα τα αγαπημένα και τα δεδομένα σταθμών\n- Όλα τα προφίλ αναζήτησης\n- Όλες τις ειδοποιήσεις τιμών\n- Όλο το ιστορικό τιμών\n- Όλα τα δεδομένα προσωρινής μνήμης\n- Το κλειδί API σας\n- Όλες τις ρυθμίσεις εφαρμογής\n\nΗ εφαρμογή θα επαναφερθεί στην αρχική της κατάσταση. Αυτή η ενέργεια δεν μπορεί να αναιρεθεί.';

  @override
  String get privacyDeleteConfirm => 'Διαγραφή όλων';

  @override
  String get yes => 'Ναι';

  @override
  String get no => 'Όχι';

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
  String get paymentMethods => 'Μέθοδοι πληρωμής';

  @override
  String get paymentMethodCash => 'Μετρητά';

  @override
  String get paymentMethodCard => 'Κάρτα';

  @override
  String get paymentMethodContactless => 'Ανέπαφη';

  @override
  String get paymentMethodFuelCard => 'Κάρτα καυσίμων';

  @override
  String get paymentMethodApp => 'Εφαρμογή';

  @override
  String payWithApp(String app) {
    return 'Πληρωμή με $app';
  }

  @override
  String ecoScoreConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String ecoScoreTooltip(String avg) {
    return 'Σε σύγκριση με τον κυλιόμενο μέσο όρο των τελευταίων 3 ανεφοδιασμών σας ($avg L/100 km).';
  }

  @override
  String ecoScoreSemantics(String value, String delta) {
    return 'Κατανάλωση $value L/100 km, $delta σε σχέση με τον κυλιόμενο μέσο σας';
  }

  @override
  String get drivingMode => 'Λειτουργία οδήγησης';

  @override
  String get drivingExit => 'Έξοδος';

  @override
  String get drivingNearestStation => 'Πλησιέστερος';

  @override
  String get drivingTapToUnlock => 'Πατήστε για ξεκλείδωμα';

  @override
  String get drivingSafetyTitle => 'Ειδοποίηση ασφαλείας';

  @override
  String get drivingSafetyMessage =>
      'Μην χειρίζεστε την εφαρμογή κατά την οδήγηση. Σταματήστε σε ασφαλές σημείο πριν αλληλεπιδράσετε με την οθόνη. Ο οδηγός είναι υπεύθυνος για την ασφαλή λειτουργία του οχήματος ανά πάσα στιγμή.';

  @override
  String get drivingSafetyAccept => 'Κατανοώ';

  @override
  String get voiceAnnouncementsTitle => 'Φωνητικές ανακοινώσεις';

  @override
  String get voiceAnnouncementsDescription =>
      'Ανακοίνωση κοντινών φθηνών σταθμών κατά την οδήγηση';

  @override
  String get voiceAnnouncementsEnabled => 'Ενεργοποίηση φωνητικών ανακοινώσεων';

  @override
  String voiceAnnouncementThreshold(String price) {
    return 'Μόνο κάτω από $price';
  }

  @override
  String voiceAnnouncementCheapFuel(
    String station,
    String distance,
    String fuelType,
    String price,
  ) {
    return '$station, $distance χιλιόμετρα μπροστά, $fuelType $price';
  }

  @override
  String get voiceAnnouncementProximityRadius => 'Ακτίνα ανακοίνωσης';

  @override
  String get voiceAnnouncementCooldown => 'Διάστημα επανάληψης';

  @override
  String get nearestStations => 'Kontinoteroi stathmoi';

  @override
  String get nearestStationsHint =>
      'Vreite tous kontinoterous stathmous me tin trexousa topothesia sas';

  @override
  String get consumptionLogTitle => 'Κατανάλωση καυσίμου';

  @override
  String get consumptionLogMenuTitle => 'Αρχείο κατανάλωσης';

  @override
  String get consumptionLogMenuSubtitle =>
      'Παρακολούθηση ανεφοδιασμών και υπολογισμός L/100km';

  @override
  String get consumptionStatsTitle => 'Στατιστικά κατανάλωσης';

  @override
  String get addFillUp => 'Προσθήκη ανεφοδιασμού';

  @override
  String get noFillUpsTitle => 'Δεν υπάρχουν ανεφοδιασμοί';

  @override
  String get noFillUpsSubtitle =>
      'Καταγράψτε τον πρώτο ανεφοδιασμό για να ξεκινήσετε την παρακολούθηση κατανάλωσης.';

  @override
  String get fillUpDate => 'Ημερομηνία';

  @override
  String get liters => 'Λίτρα';

  @override
  String get odometerKm => 'Χιλιόμετρα (km)';

  @override
  String get notesOptional => 'Σημειώσεις (προαιρετικό)';

  @override
  String get stationPreFilled => 'Σταθμός προεπιλεγμένος';

  @override
  String get statAvgConsumption => 'Μέση L/100km';

  @override
  String get statAvgCostPerKm => 'Μέσο κόστος/km';

  @override
  String get statTotalLiters => 'Συνολικά λίτρα';

  @override
  String get statTotalSpent => 'Συνολικές δαπάνες';

  @override
  String get statFillUpCount => 'Ανεφοδιασμοί';

  @override
  String get fieldRequired => 'Απαιτείται';

  @override
  String get fieldInvalidNumber => 'Μη έγκυρος αριθμός';

  @override
  String get carbonDashboardTitle => 'Πίνακας αποτυπώματος άνθρακα';

  @override
  String get carbonEmptyTitle => 'Δεν υπάρχουν δεδομένα ακόμα';

  @override
  String get carbonEmptySubtitle =>
      'Καταγράψτε ανεφοδιασμούς για να δείτε τον πίνακα αποτυπώματος άνθρακα.';

  @override
  String get carbonSummaryTotalCost => 'Συνολικό κόστος';

  @override
  String get carbonSummaryTotalCo2 => 'Συνολικό CO2';

  @override
  String get monthlyCostsTitle => 'Μηνιαίο κόστος';

  @override
  String get monthlyEmissionsTitle => 'Μηνιαίες εκπομπές CO2';

  @override
  String get vehiclesTitle => 'Τα οχήματά μου';

  @override
  String get vehiclesMenuTitle => 'Τα οχήματά μου';

  @override
  String get vehiclesMenuSubtitle => 'Μπαταρία, βύσματα, προτιμήσεις φόρτισης';

  @override
  String get vehiclesEmptyMessage =>
      'Προσθέστε το αυτοκίνητό σας για φιλτράρισμα κατά βύσμα και εκτίμηση κόστους φόρτισης.';

  @override
  String get vehiclesWizardTitle => 'Τα οχήματά μου (προαιρετικό)';

  @override
  String get vehiclesWizardSubtitle =>
      'Προσθέστε το αυτοκίνητό σας για προεπλήρωση του αρχείου κατανάλωσης και ενεργοποίηση φίλτρων βυσμάτων EV. Μπορείτε να το παραλείψετε και να προσθέσετε οχήματα αργότερα.';

  @override
  String get vehiclesWizardNoneYet => 'Δεν έχει ρυθμιστεί κανένα όχημα ακόμα.';

  @override
  String vehiclesWizardYoursList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count οχήματα',
      one: '1 όχημα',
    );
    return 'Έχετε $_temp0:';
  }

  @override
  String get vehiclesWizardSkipHint =>
      'Παράλειψη για ολοκλήρωση ρύθμισης — μπορείτε να προσθέσετε οχήματα ανά πάσα στιγμή από τις Ρυθμίσεις.';

  @override
  String get fillUpVehicleLabel => 'Όχημα';

  @override
  String get fillUpVehicleNone => 'Χωρίς όχημα';

  @override
  String get fillUpVehicleRequired => 'Το όχημα είναι υποχρεωτικό';

  @override
  String get reportScanError => 'Αναφορά σφάλματος σάρωσης';

  @override
  String get pickStationTitle => 'Επιλογή σταθμού';

  @override
  String get pickStationHelper =>
      'Ξεκινήστε τον ανεφοδιασμό από γνωστό σταθμό για αυτόματη συμπλήρωση τιμών, μάρκας και τύπου καυσίμου.';

  @override
  String get pickStationEmpty =>
      'Δεν υπάρχουν αγαπημένοι σταθμοί ακόμα — προσθέστε μερικούς από Αναζήτηση ή Αγαπημένα, ή παραλείψτε και συμπληρώστε χειροκίνητα.';

  @override
  String get pickStationSkip => 'Παράλειψη — προσθήκη χωρίς σταθμό';

  @override
  String get scanPump => 'Σάρωση αντλίας';

  @override
  String get scanPayment => 'Σάρωση QR πληρωμής';

  @override
  String get qrPaymentBeneficiary => 'Δικαιούχος';

  @override
  String get qrPaymentAmount => 'Ποσό';

  @override
  String get qrPaymentEpcTitle => 'Πληρωμή SEPA';

  @override
  String get qrPaymentEpcEmpty => 'Δεν αποκωδικοποιήθηκαν πεδία';

  @override
  String get qrPaymentOpenInBank => 'Άνοιγμα σε εφαρμογή τράπεζας';

  @override
  String get qrPaymentLaunchFailed =>
      'Δεν υπάρχει εφαρμογή για άνοιγμα αυτού του κώδικα';

  @override
  String get qrPaymentUnknownTitle => 'Μη αναγνωρισμένος κώδικας';

  @override
  String get qrPaymentCopyRaw => 'Αντιγραφή ακατέργαστου κειμένου';

  @override
  String get qrPaymentCopiedRaw => 'Αντιγράφηκε στο πρόχειρο';

  @override
  String get qrPaymentReport => 'Αναφορά αυτής της σάρωσης';

  @override
  String get qrPaymentEpcCopied =>
      'Στοιχεία τράπεζας αντιγράφηκαν — επικολλήστε στην τραπεζική σας εφαρμογή';

  @override
  String get qrScannerGuidance => 'Στρέψτε την κάμερα σε έναν QR κώδικα';

  @override
  String get qrScannerPermissionDenied =>
      'Απαιτείται πρόσβαση στην κάμερα για σάρωση QR κωδίκων.';

  @override
  String get qrScannerPermissionPermanentlyDenied =>
      'Η πρόσβαση στην κάμερα αρνήθηκε. Ανοίξτε τις ρυθμίσεις για να την εκχωρήσετε.';

  @override
  String get qrScannerRetryPermission => 'Δοκιμάστε ξανά';

  @override
  String get qrScannerOpenSettings => 'Άνοιγμα ρυθμίσεων';

  @override
  String get qrScannerTimeout =>
      'Δεν εντοπίστηκε QR κώδικας. Πλησιάστε ή δοκιμάστε ξανά.';

  @override
  String get qrScannerRetry => 'Δοκιμάστε ξανά';

  @override
  String get torchOn => 'Ενεργοποίηση φλας';

  @override
  String get torchOff => 'Απενεργοποίηση φλας';

  @override
  String get obdNoAdapter => 'Δεν βρέθηκε προσαρμογέας OBD2 σε εμβέλεια';

  @override
  String get obdOdometerUnavailable => 'Αδύνατη ανάγνωση χιλιομετρητή';

  @override
  String get obdPermissionDenied =>
      'Εκχωρήστε άδεια Bluetooth στις ρυθμίσεις συστήματος';

  @override
  String get obdAdapterUnresponsive =>
      'Ο προσαρμογέας δεν ανταποκρίθηκε — ανάψτε τη μίζα και δοκιμάστε ξανά';

  @override
  String get obdPickerTitle => 'Επιλογή προσαρμογέα OBD2';

  @override
  String get obdPickerScanning => 'Σάρωση για προσαρμογείς…';

  @override
  String get obdPickerConnecting => 'Σύνδεση…';

  @override
  String get themeSettingTitle => 'Θέμα';

  @override
  String get themeModeLight => 'Φωτεινό';

  @override
  String get themeModeDark => 'Σκοτεινό';

  @override
  String get themeModeSystem => 'Ακολουθεί σύστημα';

  @override
  String get tripRecordingTitle => 'Καταγραφή διαδρομής';

  @override
  String get tripSummaryTitle => 'Σύνοψη διαδρομής';

  @override
  String get tripMetricDistance => 'Απόσταση';

  @override
  String get tripMetricSpeed => 'Ταχύτητα';

  @override
  String get tripMetricFuelUsed => 'Καύσιμο που χρησιμοποιήθηκε';

  @override
  String get tripMetricAvgConsumption => 'Μέση';

  @override
  String get tripMetricElapsed => 'Χρόνος';

  @override
  String get tripMetricOdometer => 'Χιλιόμετρα';

  @override
  String get tripStop => 'Διακοπή καταγραφής';

  @override
  String get tripPause => 'Παύση';

  @override
  String get tripResume => 'Συνέχεια';

  @override
  String get tripBannerRecording => 'Καταγραφή διαδρομής';

  @override
  String get tripBannerPaused => 'Διαδρομή σε παύση — πατήστε για συνέχεια';

  @override
  String get navConsumption => 'Κατανάλωση';

  @override
  String get vehicleBaselineSectionTitle => 'Βαθμονόμηση βάσης';

  @override
  String get vehicleBaselineEmpty =>
      'Δεν υπάρχουν δείγματα ακόμα — ξεκινήστε ένα ταξίδι OBD2 για να αρχίσετε να μαθαίνετε το καυσιμοκατανάλωσης αυτού του οχήματος.';

  @override
  String get vehicleBaselineProgress =>
      'Εκμαθήθηκε από δείγματα σε διαφορετικές οδηγικές καταστάσεις.';

  @override
  String get vehicleBaselineReset => 'Επαναφορά βάσης οδηγικών καταστάσεων';

  @override
  String get vehicleBaselineResetConfirmTitle =>
      'Επαναφορά βάσης οδηγικών καταστάσεων;';

  @override
  String get vehicleBaselineResetConfirmBody =>
      'Αυτό διαγράφει κάθε εκμαθημένο δείγμα για αυτό το όχημα. Θα επιστρέψετε στις προεπιλογές μέχρι νέα ταξίδια να συμπληρώσουν ξανά το προφίλ.';

  @override
  String get vehicleAdapterSectionTitle => 'Προσαρμογέας OBD2';

  @override
  String get vehicleAdapterEmpty =>
      'Δεν έχει συζευχθεί κανένας προσαρμογέας. Συζεύξτε έναν για αυτόματη επανασύνδεση την επόμενη φορά.';

  @override
  String get vehicleAdapterUnnamed => 'Άγνωστος προσαρμογέας';

  @override
  String get vehicleAdapterPair => 'Σύζευξη προσαρμογέα';

  @override
  String get vehicleAdapterForget => 'Αποζεύξη προσαρμογέα';

  @override
  String get achievementsTitle => 'Επιτεύγματα';

  @override
  String get achievementFirstTrip => 'Πρώτο ταξίδι';

  @override
  String get achievementFirstTripDesc => 'Καταγράψτε το πρώτο σας ταξίδι OBD2.';

  @override
  String get achievementFirstFillUp => 'Πρώτος ανεφοδιασμός';

  @override
  String get achievementFirstFillUpDesc =>
      'Καταγράψτε τον πρώτο σας ανεφοδιασμό.';

  @override
  String get achievementTenTrips => '10 ταξίδια';

  @override
  String get achievementTenTripsDesc => 'Καταγράψτε 10 ταξίδια OBD2.';

  @override
  String get achievementZeroHarsh => 'Ομαλός οδηγός';

  @override
  String get achievementZeroHarshDesc =>
      'Ολοκληρώστε ένα ταξίδι 10 km ή περισσότερο χωρίς απότομο φρενάρισμα ή επιτάχυνση.';

  @override
  String get achievementEcoWeek => 'Οικολογική εβδομάδα';

  @override
  String get achievementEcoWeekDesc =>
      'Οδηγήστε 7 συνεχόμενες ημέρες με τουλάχιστον ένα ομαλό ταξίδι κάθε μέρα.';

  @override
  String get achievementPriceWin => 'Καλή τιμή';

  @override
  String get achievementPriceWinDesc =>
      'Καταγράψτε ανεφοδιασμό που υπερβαίνει τον μέσο όρο 30 ημερών του σταθμού κατά 5% ή περισσότερο.';

  @override
  String get syncBaselinesToggleTitle =>
      'Κοινοποίηση εκμαθημένων προφίλ οχημάτων';

  @override
  String get syncBaselinesToggleSubtitle =>
      'Μεταφόρτωση βάσεων κατανάλωσης ανά όχημα ώστε μια δεύτερη συσκευή να μπορεί να τις χρησιμοποιήσει.';

  @override
  String get obd2StatusConnected => 'Προσαρμογέας OBD2: συνδεδεμένος';

  @override
  String get obd2StatusAttempting => 'Προσαρμογέας OBD2: σύνδεση';

  @override
  String get obd2StatusUnreachable => 'Προσαρμογέας OBD2: μη προσβάσιμος';

  @override
  String get obd2StatusPermissionDenied =>
      'Προσαρμογέας OBD2: απαιτείται άδεια Bluetooth';

  @override
  String get obd2StatusConnectedBody => 'Έτοιμος για καταγραφή ταξιδιού.';

  @override
  String get obd2StatusAttemptingBody => 'Σύνδεση στο παρασκήνιο…';

  @override
  String get obd2StatusUnreachableBody =>
      'Ο προσαρμογέας είναι εκτός εμβέλειας ή χρησιμοποιείται ήδη από άλλη εφαρμογή.';

  @override
  String get obd2StatusPermissionDeniedBody =>
      'Εκχωρήστε άδεια Bluetooth στις ρυθμίσεις συστήματος για αυτόματη επανασύνδεση.';

  @override
  String get obd2StatusNoAdapter => 'Δεν έχει συζευχθεί προσαρμογέας';

  @override
  String get obd2StatusForget => 'Αποζεύξη προσαρμογέα';

  @override
  String get tripHistoryTitle => 'Ιστορικό ταξιδιών';

  @override
  String get tripHistoryEmptyTitle => 'Δεν υπάρχουν ταξίδια ακόμα';

  @override
  String get tripHistoryEmptySubtitle =>
      'Συνδέστε έναν προσαρμογέα OBD2 και καταγράψτε ένα ταξίδι για να ξεκινήσετε την ιστορία οδήγησής σας.';

  @override
  String get tripHistoryUnknownDate => 'Άγνωστη ημερομηνία';

  @override
  String get situationIdle => 'Ρελαντί';

  @override
  String get situationStopAndGo => 'Σταμάτημα & εκκίνηση';

  @override
  String get situationUrban => 'Αστικό';

  @override
  String get situationHighway => 'Αυτοκινητόδρομος';

  @override
  String get situationDecel => 'Επιβράδυνση';

  @override
  String get situationClimbing => 'Ανηφόρα / φορτωμένο';

  @override
  String get situationHardAccel => 'Δυνατή επιτάχυνση';

  @override
  String get situationFuelCut => 'Διακοπή καυσίμου — αδράνεια';

  @override
  String get tripSaveAsFillUp => 'Αποθήκευση ως ανεφοδιασμός';

  @override
  String get tripSaveRecording => 'Αποθήκευση ταξιδιού';

  @override
  String get tripDiscard => 'Απόρριψη';

  @override
  String obdOdometerRead(int km) {
    return 'Ανάγνωση χιλιομετρητή: $km km';
  }

  @override
  String get vehicleFuelNotSet => 'Μη ορισμένο';

  @override
  String get wizardVehicleTapToEdit => 'Πατήστε για επεξεργασία';

  @override
  String get wizardVehicleDefaultBadge => 'Προεπιλογή';

  @override
  String get wizardProfileChoiceHint =>
      'Επιλέξτε πώς θέλετε να χρησιμοποιήσετε την εφαρμογή. Μπορείτε να το αλλάξετε αργότερα στις Ρυθμίσεις.';

  @override
  String get wizardProfileChoiceFooter =>
      'Μπορείτε να αλλάξετε την επιλογή σας ανά πάσα στιγμή από Ρυθμίσεις → Λειτουργία χρήσης.';

  @override
  String get wizardProfileBasicName => 'Βασικό';

  @override
  String get wizardProfileBasicDescription =>
      'Φθηνότερα καύσιμα και τιμές φόρτισης EV κοντά σας. Αγαπημένα και ειδοποιήσεις τιμών.';

  @override
  String get wizardProfileMediumName => 'Μεσαίο';

  @override
  String get wizardProfileMediumDescription =>
      'Όλα του Βασικού, συν χειροκίνητη παρακολούθηση ανεφοδιασμών καυσίμου και φόρτισης EV.';

  @override
  String get wizardProfileFullName => 'Πλήρες';

  @override
  String get wizardProfileFullDescription =>
      'Όλα του Μεσαίου, συν αυτόματη καταγραφή ταξιδιών OBD2, βαθμολογίες οδήγησης και κάρτες πιστότητας.';

  @override
  String get wizardProfileCustomName => 'Προσαρμοσμένο';

  @override
  String get wizardProfileCustomDescription =>
      'Ο δικός σας συνδυασμός λειτουργιών. Προσαρμόστε κάθε διακόπτη παρακάτω.';

  @override
  String get useModeSectionHint =>
      'Προσαρμόστε την εφαρμογή στον τρόπο που τη χρησιμοποιείτε. Η επιλογή προεπιλογής ενεργοποιεί το αντίστοιχο σύνολο λειτουργιών.';

  @override
  String get useModeCustomSettingsDescription =>
      'Ο συνδυασμός λειτουργιών σας δεν αντιστοιχεί σε καμία προεπιλογή. Επιλέξτε μία παραπάνω για αντικατάσταση ή συνεχίστε την προσαρμογή.';

  @override
  String useModeSwitchedSnack(String profile) {
    return 'Λειτουργία χρήσης ορίστηκε σε $profile.';
  }

  @override
  String get profileDefaultVehicleLabel => 'Προεπιλεγμένο όχημα (προαιρετικό)';

  @override
  String get profileDefaultVehicleNone => 'Χωρίς προεπιλογή';

  @override
  String get profileFuelFromVehicleHint =>
      'Ο τύπος καυσίμου προκύπτει από το προεπιλεγμένο όχημά σας. Αφαιρέστε το όχημα για άμεση επιλογή καυσίμου.';

  @override
  String get consumptionNoVehicleTitle => 'Προσθέστε πρώτα ένα όχημα';

  @override
  String get consumptionNoVehicleBody =>
      'Οι ανεφοδιασμοί αποδίδονται σε ένα όχημα. Προσθέστε το αυτοκίνητό σας για να ξεκινήσετε την καταγραφή κατανάλωσης.';

  @override
  String get vehicleAdd => 'Προσθήκη οχήματος';

  @override
  String get vehicleAddTitle => 'Προσθήκη οχήματος';

  @override
  String get vehicleEditTitle => 'Επεξεργασία οχήματος';

  @override
  String get vehicleDeleteTitle => 'Διαγραφή οχήματος;';

  @override
  String vehicleDeleteMessage(String name) {
    return 'Αφαίρεση \"$name\" από τα προφίλ σας;';
  }

  @override
  String get vehicleNameLabel => 'Όνομα';

  @override
  String get vehicleNameHint => 'π.χ. Το Tesla μου Model 3';

  @override
  String get vehicleTypeCombustion => 'Εσωτερικής καύσης';

  @override
  String get vehicleTypeHybrid => 'Υβριδικό';

  @override
  String get vehicleTypeEv => 'Ηλεκτρικό';

  @override
  String get vehicleEvSectionTitle => 'Ηλεκτρικό';

  @override
  String get vehicleCombustionSectionTitle => 'Εσωτερικής καύσης';

  @override
  String get vehicleBatteryLabel => 'Χωρητικότητα μπαταρίας (kWh)';

  @override
  String get vehicleMaxChargeLabel => 'Μέγιστη ισχύς φόρτισης (kW)';

  @override
  String get vehicleConnectorsLabel => 'Υποστηριζόμενα βύσματα';

  @override
  String get vehicleMinSocLabel => 'Ελάχιστο SoC %';

  @override
  String get vehicleMaxSocLabel => 'Μέγιστο SoC %';

  @override
  String get vehicleTankLabel => 'Χωρητικότητα ντεπόζιτου (L)';

  @override
  String get vehiclePreferredFuelLabel => 'Προτιμώμενο καύσιμο';

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
  String get connectorThreePin => '3 ακίδων';

  @override
  String get evShowOnMap => 'Εμφάνιση σταθμών EV';

  @override
  String get evAvailableOnly => 'Μόνο διαθέσιμοι';

  @override
  String get evMinPower => 'Ελάχιστη ισχύς';

  @override
  String get evMaxPower => 'Μέγιστη ισχύς';

  @override
  String get evOperator => 'Πάροχος';

  @override
  String get evLastUpdate => 'Τελευταία ενημέρωση';

  @override
  String get evStatusAvailable => 'Διαθέσιμος';

  @override
  String get evStatusOccupied => 'Κατειλημμένος';

  @override
  String get evStatusOutOfOrder => 'Εκτός λειτουργίας';

  @override
  String get openOnlyFilter => 'Μόνο ανοιχτοί';

  @override
  String get saveAsDefaults => 'Αποθήκευση ως προεπιλογές μου';

  @override
  String get criteriaSavedToProfile => 'Αποθηκεύτηκε ως προεπιλογές';

  @override
  String get profileNotFound => 'Δεν υπάρχει ενεργό προφίλ';

  @override
  String get updatingFavorites => 'Ενημέρωση αγαπημένων...';

  @override
  String get fetchingLatestPrices => 'Λήψη τελευταίων τιμών';

  @override
  String get noDataAvailable => 'Δεν υπάρχουν δεδομένα';

  @override
  String get configAndPrivacy => 'Ρυθμίσεις & Απόρρητο';

  @override
  String get searchToSeeMap => 'Αναζητήστε για να δείτε σταθμούς στον χάρτη';

  @override
  String get evPowerAny => 'Οποιαδήποτε';

  @override
  String evPowerKw(int kw) {
    return '$kw kW+';
  }

  @override
  String get sectionProfile => 'Προφίλ';

  @override
  String get sectionLocation => 'Τοποθεσία';

  @override
  String get tooltipBack => 'Πίσω';

  @override
  String get tooltipClose => 'Κλείσιμο';

  @override
  String get tooltipClearSearch => 'Εκκαθάριση αναζήτησης';

  @override
  String get coachingShiftUp => 'Ανέβα σχέση';

  @override
  String get coachingShiftDown => 'Κατέβα σχέση';

  @override
  String get coachingEasePedal => 'Λιγότερο γκάζι';

  @override
  String get tooltipUseGps => 'Χρήση τοποθεσίας GPS';

  @override
  String get tooltipShowPassword => 'Εμφάνιση κωδικού';

  @override
  String get tooltipHidePassword => 'Απόκρυψη κωδικού';

  @override
  String get evConnectorsLabel => 'Διαθέσιμα βύσματα';

  @override
  String get evConnectorsNone => 'Δεν υπάρχουν πληροφορίες βυσμάτων';

  @override
  String get switchToEmail => 'Εναλλαγή σε email';

  @override
  String get switchToEmailSubtitle =>
      'Διατήρηση δεδομένων, σύνδεση από άλλες συσκευές';

  @override
  String get switchToAnonymousAction => 'Εναλλαγή σε ανώνυμο';

  @override
  String get switchToAnonymousSubtitle =>
      'Διατήρηση τοπικών δεδομένων, νέα ανώνυμη σύνδεση';

  @override
  String get linkDevice => 'Σύνδεση συσκευής';

  @override
  String get shareDatabase => 'Κοινοποίηση βάσης δεδομένων';

  @override
  String get disconnectAction => 'Αποσύνδεση';

  @override
  String get disconnectSubtitle =>
      'Διακοπή συγχρονισμού (τα τοπικά δεδομένα διατηρούνται)';

  @override
  String get deleteAccountAction => 'Διαγραφή λογαριασμού';

  @override
  String get deleteAccountSubtitle =>
      'Μόνιμη αφαίρεση όλων των δεδομένων διακομιστή';

  @override
  String get localOnly => 'Μόνο τοπικά';

  @override
  String get localOnlySubtitle =>
      'Προαιρετικό: συγχρονισμός αγαπημένων, ειδοποιήσεων και αξιολογήσεων σε συσκευές';

  @override
  String get setupCloudSync => 'Ρύθμιση συγχρονισμού cloud';

  @override
  String get disconnectTitle => 'Αποσύνδεση TankSync;';

  @override
  String get disconnectBody =>
      'Ο συγχρονισμός cloud θα απενεργοποιηθεί. Τα τοπικά σας δεδομένα (αγαπημένα, ειδοποιήσεις, ιστορικό) διατηρούνται σε αυτή τη συσκευή. Τα δεδομένα διακομιστή δεν διαγράφονται.';

  @override
  String get deleteAccountTitle => 'Διαγραφή λογαριασμού;';

  @override
  String get deleteAccountBody =>
      'Αυτό διαγράφει μόνιμα όλα τα δεδομένα σας από τον διακομιστή (αγαπημένα, ειδοποιήσεις, αξιολογήσεις, διαδρομές). Τα τοπικά δεδομένα σε αυτή τη συσκευή διατηρούνται.\n\nΔεν μπορεί να αναιρεθεί.';

  @override
  String get switchToAnonymousTitle => 'Εναλλαγή σε ανώνυμο;';

  @override
  String get switchToAnonymousBody =>
      'Θα αποσυνδεθείτε από τον λογαριασμό email σας και θα συνεχίσετε με νέα ανώνυμη σύνδεση.\n\nΤα τοπικά σας δεδομένα (αγαπημένα, ειδοποιήσεις) διατηρούνται σε αυτή τη συσκευή και θα συγχρονιστούν στον νέο ανώνυμο λογαριασμό.';

  @override
  String get switchAction => 'Εναλλαγή';

  @override
  String get helpBannerCriteria =>
      'Οι προεπιλογές προφίλ σας έχουν προεπιληρωθεί. Προσαρμόστε τα κριτήρια παρακάτω για βελτίωση της αναζήτησης.';

  @override
  String get helpBannerAlerts =>
      'Ορίστε κατώτατο όριο τιμής για έναν σταθμό. Θα ειδοποιηθείτε όταν οι τιμές πέσουν κάτω από αυτό. Ο έλεγχος γίνεται κάθε 30 λεπτά.';

  @override
  String get helpBannerConsumption =>
      'Καταγράψτε κάθε ανεφοδιασμό για παρακολούθηση πραγματικής κατανάλωσης και αποτυπώματος CO₂. Σύρετε αριστερά για διαγραφή.';

  @override
  String get helpBannerVehicles =>
      'Προσθέστε τα οχήματά σας για σωστή προεπιλογή ανεφοδιασμών και καυσίμων. Το πρώτο όχημα γίνεται η προεπιλογή.';

  @override
  String get syncNow => 'Συγχρονισμός τώρα';

  @override
  String get onboardingPreferencesTitle => 'Οι προτιμήσεις σας';

  @override
  String get onboardingZipHelper =>
      'Χρησιμοποιείται όταν το GPS δεν είναι διαθέσιμο';

  @override
  String get onboardingRadiusHelper =>
      'Μεγαλύτερη ακτίνα = περισσότερα αποτελέσματα';

  @override
  String get onboardingPrivacy =>
      'Αυτές οι ρυθμίσεις αποθηκεύονται μόνο στη συσκευή σας και δεν κοινοποιούνται ποτέ.';

  @override
  String get onboardingLandingTitle => 'Αρχική οθόνη';

  @override
  String get onboardingLandingHint =>
      'Επιλέξτε ποια οθόνη ανοίγει κατά την εκκίνηση της εφαρμογής.';

  @override
  String get iosAutoRecordOnboardingTitle =>
      'Μείνετε εκτός εφαρμογής — αλλά μην την κλείσετε.';

  @override
  String get iosAutoRecordOnboardingBullet1Title =>
      'Ανοίξτε το Sparkilo μία φορά μετά από κάθε επανεκκίνηση.';

  @override
  String get iosAutoRecordOnboardingBullet1Body =>
      'Η Apple εκκινεί το Sparkilo μόνο αφού το έχετε ανοίξει τουλάχιστον μία φορά από τότε που επανεκκινήθηκε το τηλέφωνο. Μετά από αυτό, τα ταξίδια σας καταγράφονται αυτόματα.';

  @override
  String get iosAutoRecordOnboardingBullet2Title =>
      'Μην κλείνετε το Sparkilo από τον διαχειριστή εφαρμογών.';

  @override
  String get iosAutoRecordOnboardingBullet2Body =>
      'Η \"Αναγκαστική έξοδος\" λέει στο iOS να σταματήσει να εκκινεί ξανά την εφαρμογή. Τα ταξίδια σας θα σταματήσουν να καταγράφονται μέχρι να ανοίξετε ξανά το Sparkilo.';

  @override
  String get iosAutoRecordOnboardingBullet3Title =>
      'Όταν το iOS ζητά τοποθεσία \"Πάντα\", παρακαλώ πείτε ναι.';

  @override
  String get iosAutoRecordOnboardingBullet3Body =>
      'Η εφεδρεία που καταγράφει το ταξίδι σας όταν ο προσαρμογέας OBD2 είναι αργός χρειάζεται τοποθεσία παρασκηνίου. Δεν τη μοιραζόμαστε ποτέ.';

  @override
  String get scanReceipt => 'Σάρωση απόδειξης';

  @override
  String get obdConnect => 'OBD-II';

  @override
  String get stationTypeFuel => 'Καύσιμο';

  @override
  String get stationTypeEv => 'EV';

  @override
  String get brandFilterHighway => 'Αυτοκινητόδρομος';

  @override
  String get ratingModeLocal => 'Τοπικό';

  @override
  String get ratingModePrivate => 'Ιδιωτικό';

  @override
  String get ratingModeShared => 'Κοινόχρηστο';

  @override
  String get ratingDescLocal =>
      'Αξιολογήσεις αποθηκευμένες μόνο σε αυτή τη συσκευή';

  @override
  String get ratingDescPrivate =>
      'Συγχρονισμένο με τη βάση δεδομένων σας (δεν φαίνεται σε άλλους)';

  @override
  String get ratingDescShared =>
      'Ορατό σε όλους τους χρήστες της βάσης δεδομένων σας';

  @override
  String get errorNoEvApiKey =>
      'Το κλειδί API OpenChargeMap δεν έχει ρυθμιστεί. Προσθέστε ένα στις Ρυθμίσεις για αναζήτηση σταθμών φόρτισης EV.';

  @override
  String errorUpstreamCertExpired(String host) {
    return 'Ο πάροχος δεδομένων ($host) παρέχει ληγμένο ή μη έγκυρο πιστοποιητικό TLS. Η εφαρμογή δεν μπορεί να φορτώσει δεδομένα από αυτή την πηγή μέχρι ο πάροχος να το διορθώσει. Επικοινωνήστε με τον $host.';
  }

  @override
  String get offlineLabel => 'Εκτός σύνδεσης';

  @override
  String fallbackSummary(String failed, String current) {
    return '$failed μη διαθέσιμο. Χρήση $current.';
  }

  @override
  String get errorTitleApiKey => 'Απαιτείται κλειδί API';

  @override
  String get errorTitleLocation => 'Τοποθεσία μη διαθέσιμη';

  @override
  String get errorHintNoStations =>
      'Δοκιμάστε να αυξήσετε την ακτίνα αναζήτησης ή αναζητήστε διαφορετική τοποθεσία.';

  @override
  String get errorHintApiKey => 'Ρυθμίστε το κλειδί API στις Ρυθμίσεις.';

  @override
  String get errorHintConnection =>
      'Ελέγξτε τη σύνδεση στο διαδίκτυο και δοκιμάστε ξανά.';

  @override
  String get errorHintRouting =>
      'Αποτυχία υπολογισμού διαδρομής. Ελέγξτε τη σύνδεση στο διαδίκτυο και δοκιμάστε ξανά.';

  @override
  String get errorHintFallback =>
      'Δοκιμάστε ξανά ή αναζητήστε με ταχυδρομικό κώδικα / όνομα πόλης.';

  @override
  String get alertsLoadErrorTitle => 'Αδύνατη φόρτωση ειδοποιήσεων';

  @override
  String get alertsBackgroundCheckErrorTitle =>
      'Αποτυχία ελέγχου ειδοποίησης παρασκηνίου';

  @override
  String get detailsLabel => 'Λεπτομέρειες';

  @override
  String get remove => 'Αφαίρεση';

  @override
  String get showKey => 'Εμφάνιση κλειδιού';

  @override
  String get hideKey => 'Απόκρυψη κλειδιού';

  @override
  String get syncOptionalTitle => 'Το TankSync είναι προαιρετικό';

  @override
  String get syncOptionalDescription =>
      'Η εφαρμογή λειτουργεί πλήρως χωρίς συγχρονισμό cloud. Το TankSync σας επιτρέπει να συγχρονίσετε αγαπημένα, ειδοποιήσεις και αξιολογήσεις σε συσκευές μέσω Supabase (διαθέσιμο δωρεάν πλάνο).';

  @override
  String get syncHowToConnectQuestion => 'Πώς θέλετε να συνδεθείτε;';

  @override
  String get syncCreateOwnTitle => 'Δημιουργία δικής μου βάσης δεδομένων';

  @override
  String get syncCreateOwnSubtitle =>
      'Δωρεάν έργο Supabase — θα σας καθοδηγήσουμε βήμα προς βήμα';

  @override
  String get syncJoinExistingTitle => 'Σύνδεση σε υπάρχουσα βάση δεδομένων';

  @override
  String get syncJoinExistingSubtitle =>
      'Σάρωση QR κώδικα από τον ιδιοκτήτη ή επικόλληση διαπιστευτηρίων';

  @override
  String get syncChooseAccountType => 'Επιλέξτε τύπο λογαριασμού';

  @override
  String get syncAccountTypeAnonymous => 'Ανώνυμο';

  @override
  String get syncAccountTypeAnonymousDesc =>
      'Άμεσο, δεν απαιτείται email. Δεδομένα συνδεδεμένα με αυτή τη συσκευή.';

  @override
  String get syncAccountTypeEmail => 'Λογαριασμός Email';

  @override
  String get syncAccountTypeEmailDesc =>
      'Σύνδεση από οποιαδήποτε συσκευή. Ανάκτηση δεδομένων αν χαθεί το τηλέφωνο.';

  @override
  String get syncHaveAccountSignIn => 'Έχετε ήδη λογαριασμό; Συνδεθείτε';

  @override
  String get syncCreateNewAccount => 'Δημιουργία νέου λογαριασμού';

  @override
  String get syncTestConnection => 'Δοκιμή σύνδεσης';

  @override
  String get syncTestingConnection => 'Δοκιμή...';

  @override
  String get syncConnectButton => 'Σύνδεση';

  @override
  String get syncConnectingButton => 'Σύνδεση...';

  @override
  String get syncDatabaseReady => 'Η βάση δεδομένων είναι έτοιμη!';

  @override
  String get syncDatabaseNeedsSetup => 'Η βάση δεδομένων χρειάζεται ρύθμιση';

  @override
  String get syncTableStatusOk => 'ΟΚ';

  @override
  String get syncTableStatusMissing => 'Λείπει';

  @override
  String get syncSqlEditorInstructions =>
      'Αντιγράψτε το SQL παρακάτω και εκτελέστε το στον επεξεργαστή SQL Supabase (Dashboard → SQL Editor → New Query → Επικόλληση → Εκτέλεση)';

  @override
  String get syncCopySqlButton => 'Αντιγραφή SQL στο πρόχειρο';

  @override
  String get syncRecheckSchemaButton => 'Επανέλεγχος σχήματος';

  @override
  String get syncDoneButton => 'Τέλος';

  @override
  String syncSignedInAs(String email) {
    return 'Συνδεδεμένος ως $email';
  }

  @override
  String get syncEmailDescription =>
      'Τα δεδομένα σας συγχρονίζονται σε όλες τις συσκευές με αυτό το email.';

  @override
  String get syncSwitchToAnonymousTitle => 'Εναλλαγή σε ανώνυμο';

  @override
  String get syncSwitchToAnonymousDesc =>
      'Συνέχεια χωρίς email, νέα ανώνυμη σύνδεση';

  @override
  String get syncGuestDescription => 'Ανώνυμο, δεν απαιτείται email.';

  @override
  String get syncOrDivider => 'ή';

  @override
  String get syncHowToSyncQuestion => 'Πώς θέλετε να συγχρονίσετε;';

  @override
  String get syncOfflineDescription =>
      'Η εφαρμογή λειτουργεί πλήρως εκτός σύνδεσης. Ο συγχρονισμός cloud είναι προαιρετικός.';

  @override
  String get syncModeCommunityTitle => 'Κοινότητα Sparkilo';

  @override
  String get syncModeCommunitySubtitle =>
      'Κοινοποίηση αγαπημένων & αξιολογήσεων με όλους τους χρήστες';

  @override
  String get syncModePrivateTitle => 'Ιδιωτική βάση δεδομένων';

  @override
  String get syncModePrivateSubtitle =>
      'Το δικό σας Supabase — πλήρης έλεγχος δεδομένων';

  @override
  String get syncModeGroupTitle => 'Σύνδεση σε ομάδα';

  @override
  String get syncModeGroupSubtitle =>
      'Κοινόχρηστη βάση δεδομένων οικογένειας ή φίλων';

  @override
  String get syncPrivacyShared => 'Κοινόχρηστο';

  @override
  String get syncPrivacyPrivate => 'Ιδιωτικό';

  @override
  String get syncPrivacyGroup => 'Ομάδα';

  @override
  String get syncStayOfflineButton => 'Παραμονή εκτός σύνδεσης';

  @override
  String get syncSuccessTitle => 'Επιτυχής σύνδεση!';

  @override
  String get syncSuccessDescription =>
      'Τα δεδομένα σας θα συγχρονίζονται πλέον αυτόματα.';

  @override
  String get syncWizardTitleConnect => 'Σύνδεση TankSync';

  @override
  String get syncSetupTitleYourDatabase => 'Η βάση δεδομένων σας';

  @override
  String get syncSetupTitleJoinGroup => 'Σύνδεση σε ομάδα';

  @override
  String get syncSetupTitleAccount => 'Ο λογαριασμός σας';

  @override
  String get syncWizardBack => 'Πίσω';

  @override
  String get syncWizardNext => 'Επόμενο';

  @override
  String syncWizardStepOfSteps(int current, int total) {
    return 'Βήμα $current από $total';
  }

  @override
  String get syncWizardCreateSupabaseTitle => 'Δημιουργία έργου Supabase';

  @override
  String get syncWizardCreateSupabaseInstructions =>
      '1. Πατήστε \"Άνοιγμα Supabase\" παρακάτω\n2. Δημιουργήστε δωρεάν λογαριασμό (εάν δεν έχετε)\n3. Κάντε κλικ στο \"New Project\"\n4. Επιλέξτε όνομα και περιοχή\n5. Περιμένετε ~2 λεπτά για εκκίνηση';

  @override
  String get syncWizardOpenSupabase => 'Άνοιγμα Supabase';

  @override
  String get syncWizardEnableAnonTitle => 'Ενεργοποίηση ανώνυμης σύνδεσης';

  @override
  String get syncWizardEnableAnonInstructions =>
      '1. Στον πίνακα ελέγχου Supabase:\n   Authentication → Providers\n2. Βρείτε το \"Anonymous Sign-ins\"\n3. Ενεργοποιήστε το\n4. Κάντε κλικ στο \"Save\"';

  @override
  String get syncWizardOpenAuthSettings => 'Άνοιγμα ρυθμίσεων ταυτοποίησης';

  @override
  String get syncWizardCopyCredentialsTitle => 'Αντιγραφή διαπιστευτηρίων';

  @override
  String get syncWizardCopyCredentialsInstructions =>
      '1. Μεταβείτε στο Settings → API στον πίνακα ελέγχου\n2. Αντιγράψτε το \"Project URL\"\n3. Αντιγράψτε το κλειδί \"anon public\"\n4. Επικολλήστε τα παρακάτω';

  @override
  String get syncWizardOpenApiSettings => 'Άνοιγμα ρυθμίσεων API';

  @override
  String get syncWizardSupabaseUrlLabel => 'URL Supabase';

  @override
  String get syncWizardSupabaseUrlHint => 'https://your-project.supabase.co';

  @override
  String get syncWizardJoinExistingTitle =>
      'Σύνδεση σε υπάρχουσα βάση δεδομένων';

  @override
  String get syncWizardScanQrCode => 'Σάρωση QR κώδικα';

  @override
  String get syncWizardAskOwnerQr =>
      'Ζητήστε από τον ιδιοκτήτη να σας δείξει τον QR κώδικά του\n(Ρυθμίσεις → TankSync → Κοινοποίηση)';

  @override
  String get syncWizardAskOwnerQrShort =>
      'Ζητήστε από τον ιδιοκτήτη να σας δείξει τον QR κώδικά του';

  @override
  String get syncWizardEnterManuallyTitle => 'Χειροκίνητη εισαγωγή';

  @override
  String get syncWizardOrEnterManually => 'ή εισάγετε χειροκίνητα';

  @override
  String get syncWizardUrlHelperText =>
      'Κενά και αλλαγές γραμμής αφαιρούνται αυτόματα';

  @override
  String get syncCredentialsPrivateHint =>
      'Εισάγετε τα διαπιστευτήρια του έργου Supabase. Μπορείτε να τα βρείτε στον πίνακα ελέγχου στο Settings > API.';

  @override
  String get syncCredentialsDatabaseUrlLabel => 'URL βάσης δεδομένων';

  @override
  String get syncCredentialsAccessKeyLabel => 'Κλειδί πρόσβασης';

  @override
  String get syncCredentialsAccessKeyHint => 'eyJhbGciOiJIUzI1NiIs...';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Κωδικός';

  @override
  String get authConfirmPasswordLabel => 'Επιβεβαίωση κωδικού';

  @override
  String get authPleaseEnterEmail => 'Παρακαλώ εισάγετε το email σας';

  @override
  String get authInvalidEmail => 'Μη έγκυρη διεύθυνση email';

  @override
  String get authPasswordsDoNotMatch => 'Οι κωδικοί δεν ταιριάζουν';

  @override
  String get authConnectAnonymously => 'Ανώνυμη σύνδεση';

  @override
  String get authCreateAccountAndConnect => 'Δημιουργία λογαριασμού & σύνδεση';

  @override
  String get authSignInAndConnect => 'Σύνδεση & σύνδεση';

  @override
  String get authAnonymousSegment => 'Ανώνυμο';

  @override
  String get authEmailSegment => 'Email';

  @override
  String get authAnonymousDescription =>
      'Άμεση πρόσβαση, δεν απαιτείται email. Δεδομένα συνδεδεμένα με αυτή τη συσκευή.';

  @override
  String get authEmailDescription =>
      'Σύνδεση από οποιαδήποτε συσκευή. Ανάκτηση δεδομένων αν χαθεί το τηλέφωνο.';

  @override
  String get authSyncAcrossDevices =>
      'Αυτόματος συγχρονισμός δεδομένων σε όλες τις συσκευές σας.';

  @override
  String get authNewHereCreateAccount => 'Νέος χρήστης; Δημιουργία λογαριασμού';

  @override
  String get ntfyCardTitle => 'Push ειδοποιήσεις (ntfy.sh)';

  @override
  String get ntfyEnableTitle => 'Ενεργοποίηση ntfy.sh push';

  @override
  String get ntfyEnableSubtitle => 'Λήψη ειδοποιήσεων τιμών μέσω ntfy.sh';

  @override
  String get ntfyTopicUrlLabel => 'URL θέματος';

  @override
  String get ntfyCopyTopicUrlTooltip => 'Αντιγραφή URL θέματος';

  @override
  String get ntfySendTestButton => 'Αποστολή δοκιμαστικής ειδοποίησης';

  @override
  String get ntfyFdroidHint =>
      'Εγκαταστήστε την εφαρμογή ntfy από το F-Droid για λήψη push ειδοποιήσεων στη συσκευή σας.';

  @override
  String get ntfyConnectFirstHint =>
      'Συνδεθείτε πρώτα στο TankSync για ενεργοποίηση push ειδοποιήσεων.';

  @override
  String get linkDeviceScreenTitle => 'Σύνδεση συσκευής';

  @override
  String get linkDeviceThisDeviceLabel => 'Αυτή η συσκευή';

  @override
  String get linkDeviceShareCodeHint =>
      'Μοιραστείτε αυτόν τον κωδικό με την άλλη συσκευή σας:';

  @override
  String get linkDeviceNotConnected => 'Μη συνδεδεμένο';

  @override
  String get linkDeviceCopyCodeTooltip => 'Αντιγραφή κωδικού';

  @override
  String get linkDeviceImportSectionTitle => 'Εισαγωγή από άλλη συσκευή';

  @override
  String get linkDeviceImportDescription =>
      'Εισάγετε τον κωδικό συσκευής από την άλλη συσκευή σας για εισαγωγή αγαπημένων, ειδοποιήσεων, οχημάτων και αρχείου κατανάλωσης. Κάθε συσκευή διατηρεί το δικό της προφίλ και τις προεπιλογές.';

  @override
  String get linkDeviceCodeFieldLabel => 'Κωδικός συσκευής';

  @override
  String get linkDeviceCodeFieldHint =>
      'Επικολλήστε το UUID από την άλλη συσκευή';

  @override
  String get linkDeviceImportButton => 'Εισαγωγή δεδομένων';

  @override
  String get linkDeviceHowItWorksTitle => 'Πώς λειτουργεί';

  @override
  String get linkDeviceHowItWorksBody =>
      '1. Στη Συσκευή Α: αντιγράψτε τον κωδικό συσκευής παραπάνω\n2. Στη Συσκευή Β: επικολλήστε τον στο πεδίο \"Κωδικός συσκευής\"\n3. Πατήστε \"Εισαγωγή δεδομένων\" για συγχώνευση αγαπημένων, ειδοποιήσεων, οχημάτων και αρχείων κατανάλωσης\n4. Και οι δύο συσκευές θα έχουν όλα τα συνδυασμένα δεδομένα\n\nΚάθε συσκευή διατηρεί τη δική της ανώνυμη ταυτότητα και το δικό της προφίλ (προτιμώμενο καύσιμο, προεπιλεγμένο όχημα, αρχική οθόνη). Τα δεδομένα συγχωνεύονται, δεν μεταφέρονται.';

  @override
  String get vehicleSetActive => 'Ορισμός ως ενεργό';

  @override
  String get swipeHide => 'Απόκρυψη';

  @override
  String get evChargingSection => 'Φόρτιση EV';

  @override
  String get fuelStationsSection => 'Πρατήρια καυσίμων';

  @override
  String get yourRating => 'Η αξιολόγησή σας';

  @override
  String get noStorageUsed => 'Δεν χρησιμοποιείται αποθηκευτικός χώρος';

  @override
  String get aboutReportBug => 'Αναφορά σφάλματος / Πρόταση λειτουργίας';

  @override
  String get aboutSupportProject => 'Υποστήριξη αυτού του έργου';

  @override
  String get aboutSupportDescription =>
      'Αυτή η εφαρμογή είναι δωρεάν, ανοιχτού κώδικα και χωρίς διαφημίσεις. Αν τη βρίσκετε χρήσιμη, σκεφτείτε να υποστηρίξετε τον προγραμματιστή.';

  @override
  String get luxembourgRegulatedPricesNotice =>
      'Οι τιμές καυσίμων στο Λουξεμβούργο είναι κυβερνητικά ρυθμιζόμενες και ομοιόμορφες σε όλη τη χώρα.';

  @override
  String get luxembourgFuelUnleaded95 => 'Αμόλυβδη 95';

  @override
  String get luxembourgFuelUnleaded98 => 'Αμόλυβδη 98';

  @override
  String get luxembourgFuelDiesel => 'Πετρέλαιο';

  @override
  String get luxembourgFuelLpg => 'LPG';

  @override
  String get luxembourgPricesUnavailable =>
      'Οι ρυθμιζόμενες τιμές Λουξεμβούργου δεν είναι διαθέσιμες.';

  @override
  String get reportIssueTitle => 'Αναφορά προβλήματος';

  @override
  String get enterCorrection => 'Παρακαλώ εισάγετε τη διόρθωση';

  @override
  String get reportNoBackendAvailable =>
      'Η αναφορά δεν μπόρεσε να σταλεί: δεν έχει ρυθμιστεί υπηρεσία αναφοράς για αυτή τη χώρα. Ενεργοποιήστε το TankSync στις Ρυθμίσεις για αποστολή αναφορών κοινότητας.';

  @override
  String get correctName => 'Σωστό όνομα σταθμού';

  @override
  String get correctAddress => 'Σωστή διεύθυνση';

  @override
  String get wrongE85Price => 'Λανθασμένη τιμή E85';

  @override
  String get wrongE98Price => 'Λανθασμένη τιμή Super 98';

  @override
  String get wrongLpgPrice => 'Λανθασμένη τιμή LPG';

  @override
  String get wrongStationName => 'Λανθασμένο όνομα σταθμού';

  @override
  String get wrongStationAddress => 'Λανθασμένη διεύθυνση';

  @override
  String get independentStation => 'Ανεξάρτητος σταθμός';

  @override
  String get serviceRemindersSection => 'Υπενθυμίσεις σέρβις';

  @override
  String get serviceRemindersEmpty =>
      'Δεν υπάρχουν υπενθυμίσεις ακόμα — επιλέξτε μια προεπιλογή παραπάνω.';

  @override
  String get addServiceReminder => 'Προσθήκη υπενθύμισης';

  @override
  String get serviceReminderPresetOil => 'Λάδι (15.000 km)';

  @override
  String get serviceReminderPresetOilLabel => 'Αλλαγή λαδιού';

  @override
  String get serviceReminderPresetTires => 'Ελαστικά (20.000 km)';

  @override
  String get serviceReminderPresetTiresLabel => 'Ελαστικά';

  @override
  String get serviceReminderPresetInspection => 'Επιθεώρηση (30.000 km)';

  @override
  String get serviceReminderPresetInspectionLabel => 'Επιθεώρηση';

  @override
  String get serviceReminderLabel => 'Ετικέτα';

  @override
  String get serviceReminderInterval => 'Διάστημα (km)';

  @override
  String get serviceReminderLastService => 'Τελευταίο σέρβις';

  @override
  String get serviceReminderMarkDone => 'Επισήμανση ως ολοκληρωμένο';

  @override
  String get serviceReminderDueTitle => 'Σέρβις σε αναμονή';

  @override
  String serviceReminderDueBody(String label, int kmOver) {
    return 'Το $label είναι σε αναμονή — $kmOver km μετά το διάστημα.';
  }

  @override
  String get southKoreaApiKeyRequired =>
      'Εγγραφείτε στο OPINET για δωρεάν κλειδί API';

  @override
  String get southKoreaApiProvider => 'OPINET (KNOC)';

  @override
  String get chileApiKeyRequired => 'Εγγραφείτε στο CNE για δωρεάν κλειδί API';

  @override
  String get chileApiProvider => 'CNE Bencina en Linea';

  @override
  String get vinConfirmTitle => 'Είναι αυτό το αυτοκίνητό σας;';

  @override
  String vinConfirmBody(
    String year,
    String make,
    String model,
    String displacement,
    String cylinders,
    String fuel,
  ) {
    return '$year $make $model — ${displacement}L, $cylinders κύλινδροι, $fuel';
  }

  @override
  String get vinPartialInfoNote =>
      'Μερικές πληροφορίες (εκτός σύνδεσης). Μπορείτε να επεξεργαστείτε παρακάτω.';

  @override
  String get vinDecodeError => 'Αδύνατη αποκωδικοποίηση αυτού του VIN';

  @override
  String get vinInvalidFormat => 'Μη έγκυρη μορφή VIN';

  @override
  String get obd2PauseBannerTitle =>
      'Η σύνδεση OBD2 χάθηκε — η καταγραφή έχει παυτεί';

  @override
  String get obd2PauseBannerResume => 'Συνέχεια καταγραφής';

  @override
  String get obd2PauseBannerEnd => 'Τέλος καταγραφής';

  @override
  String veCalibratedTitle(String vehicleName, String percent) {
    return 'Βαθμονόμηση κατανάλωσης ενημερώθηκε για $vehicleName — η ακρίβεια βελτιώθηκε κατά $percent%';
  }

  @override
  String get veResetConfirmTitle => 'Επαναφορά ογκομετρικής απόδοσης;';

  @override
  String get veResetConfirmBody =>
      'Αυτό θα απορρίψει την εκμαθημένη ογκομετρική απόδοση (η_v) και θα επαναφέρει την προεπιλεγμένη τιμή (0.85). Οι εκτιμήσεις ροής καυσίμου θα επιστρέψουν στη σταθερά κατασκευαστή μέχρι ο βαθμονομητής να συλλέξει νέα δείγματα.';

  @override
  String get alertsRadiusSectionTitle => 'Ειδοποιήσεις ακτίνας';

  @override
  String get alertsRadiusAdd => 'Προσθήκη ειδοποίησης ακτίνας';

  @override
  String get alertsRadiusEmptyTitle =>
      'Δεν υπάρχουν ειδοποιήσεις ακτίνας ακόμα';

  @override
  String get alertsRadiusEmptyCta => 'Δημιουργία ειδοποίησης ακτίνας';

  @override
  String get alertsRadiusCreateTitle => 'Δημιουργία ειδοποίησης ακτίνας';

  @override
  String get alertsRadiusLabelHint => 'Ετικέτα (π.χ. Diesel σπίτι)';

  @override
  String get alertsRadiusFuelType => 'Τύπος καυσίμου';

  @override
  String get alertsRadiusThreshold => 'Κατώφλι (€/L)';

  @override
  String get alertsRadiusKm => 'Ακτίνα (km)';

  @override
  String get alertsRadiusCenterGps => 'Χρήση τοποθεσίας μου';

  @override
  String get alertsRadiusCenterPostalCode => 'Ταχυδρομικός κώδικας';

  @override
  String get alertsRadiusSave => 'Αποθήκευση';

  @override
  String get alertsRadiusCancel => 'Ακύρωση';

  @override
  String get alertsRadiusDeleteConfirm => 'Διαγραφή ειδοποίησης ακτίνας;';

  @override
  String obd2ConnectedTooltip(String adapterName) {
    return 'OBD2 συνδεδεμένο: $adapterName';
  }

  @override
  String get obd2PairChipTooltip => 'Σύζευξη προσαρμογέα OBD2';

  @override
  String velocityAlertTitle(String fuelLabel) {
    return 'Η τιμή $fuelLabel έπεσε σε κοντινούς σταθμούς';
  }

  @override
  String velocityAlertBody(int stationCount, int maxDropCents) {
    return '$stationCount σταθμοί μείωσαν κατά έως $maxDropCents¢ την τελευταία ώρα';
  }

  @override
  String get fillUpSavedSnackbar => 'Ο ανεφοδιασμός αποθηκεύτηκε';

  @override
  String get radiusAlertsEntryTitle => 'Ειδοποιήσεις ακτίνας & στατιστικά';

  @override
  String get radiusAlertsEntrySubtitle =>
      'Ειδοποίηση όταν πέφτουν οι τιμές κοντά σας';

  @override
  String get notFoundTitle => 'Η σελίδα δεν βρέθηκε';

  @override
  String notFoundBody(String location) {
    return 'Το \"$location\" δεν βρέθηκε.';
  }

  @override
  String get notFoundHomeButton => 'Αρχική';

  @override
  String get consumptionTabHiddenNotice =>
      'Η καρτέλα Κατανάλωσης έχει αποκρυφτεί από τις ρυθμίσεις προφίλ σας.';

  @override
  String get swipeBetweenTabsHint =>
      'Συμβουλή: σύρετε αριστερά ή δεξιά για εναλλαγή μεταξύ καρτελών.';

  @override
  String get discardChangesTitle => 'Απόρριψη αλλαγών;';

  @override
  String get discardChangesBody =>
      'Έχετε αποθηκεύτές αλλαγές. Η έξοδος τώρα θα τις απορρίψει.';

  @override
  String get discardChangesConfirm => 'Απόρριψη';

  @override
  String get discardChangesKeepEditing => 'Συνέχεια επεξεργασίας';

  @override
  String get tankSyncSectionSubtitle =>
      'Συγχρονισμός cloud σε όλες τις συσκευές σας';

  @override
  String get mapUnavailable => 'Ο χάρτης δεν είναι διαθέσιμος';

  @override
  String get routeNameHintExample => 'π.χ. Παρίσι → Λυών';

  @override
  String get priceStatsCurrent => 'Τρέχουσα';

  @override
  String get tankerkoenigApiKeyLabel => 'Κλειδί API Tankerkoenig';

  @override
  String get openChargeMapApiKeyLabel => 'Κλειδί API OpenChargeMap';

  @override
  String get tapToUpdateGpsPosition => 'Πατήστε για ενημέρωση της θέσης GPS';

  @override
  String get nameLabel => 'Όνομα';

  @override
  String get obd2ErrorPermissionDenied =>
      'Απαιτείται άδεια Bluetooth για σύνδεση με προσαρμογέα OBD2.';

  @override
  String get obd2ErrorBluetoothOff =>
      'Ενεργοποιήστε το Bluetooth και δοκιμάστε ξανά.';

  @override
  String get obd2ErrorScanTimeout =>
      'Δεν βρέθηκε προσαρμογέας OBD2 κοντά. Βεβαιωθείτε ότι είναι συνδεδεμένος και ενεργοποιημένος.';

  @override
  String get obd2ErrorAdapterUnresponsive =>
      'Ο προσαρμογέας OBD2 δεν απάντησε. Ανοίξτε το διακόπτη ανάφλεξης και δοκιμάστε ξανά.';

  @override
  String get obd2ErrorProtocolInitFailed =>
      'Ο προσαρμογέας OBD2 έστειλε μη αναγνωρίσιμη απάντηση. Ίσως δεν είναι συμβατός — δοκιμάστε άλλον προσαρμογέα.';

  @override
  String get obd2ErrorDisconnected =>
      'Ο προσαρμογέας OBD2 αποσυνδέθηκε. Συνδεθείτε ξανά και δοκιμάστε πάλι.';

  @override
  String get onboardingExploreDemoData => 'Εξερεύνηση με δοκιμαστικά δεδομένα';

  @override
  String get achievementSmoothDriver => 'Σερί ομαλής οδήγησης';

  @override
  String get achievementSmoothDriverDesc =>
      'Οδηγήστε 5 συνεχόμενα ταξίδια με βαθμολογία ομαλής οδήγησης 80 ή παραπάνω.';

  @override
  String get achievementColdStartAware => 'Συνειδητός ψυχρής εκκίνησης';

  @override
  String get achievementColdStartAwareDesc =>
      'Διατηρήστε το κόστος καυσίμου ψυχρής εκκίνησης ενός ολόκληρου μήνα κάτω από 2% του συνολικού καυσίμου — συνδυάστε σύντομα ταξίδια.';

  @override
  String get achievementHighwayMaster => 'Μάστορας αυτοκινητοδρόμου';

  @override
  String get achievementHighwayMasterDesc =>
      'Ολοκληρώστε ένα ταξίδι 30+ km σε σταθερή ταχύτητα με βαθμολογία ομαλής οδήγησης 90 ή παραπάνω.';

  @override
  String get authErrorNoNetwork =>
      'Δεν υπάρχει σύνδεση δικτύου. Δοκιμάστε αργότερα.';

  @override
  String get authErrorInvalidCredentials =>
      'Μη έγκυρο email ή κωδικός. Ελέγξτε τα διαπιστευτήριά σας.';

  @override
  String get authErrorUserAlreadyExists =>
      'Αυτό το email είναι ήδη εγγεγραμμένο. Δοκιμάστε να συνδεθείτε.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Παρακαλώ ελέγξτε το email σας και επιβεβαιώστε πρώτα τον λογαριασμό σας.';

  @override
  String get authErrorGeneric => 'Αποτυχία σύνδεσης. Παρακαλώ δοκιμάστε ξανά.';

  @override
  String get autoRecordConsentBadgeLabel =>
      'Τοποθεσία παρασκηνίου — μόνο για αυτόματη καταγραφή';

  @override
  String get autoRecordConsentExplanationTitle => 'Σχετικά με αυτή την άδεια';

  @override
  String get autoRecordConsentExplanationBody =>
      'Η αυτόματη καταγραφή χρειάζεται τοποθεσία παρασκηνίου για ανίχνευση εκκίνησης οδήγησης όταν η εφαρμογή είναι κλειστή. Αυτή η άδεια χρησιμοποιείται μόνο για αυτόματη καταγραφή — η αναζήτηση σταθμών και η κεντράρισμα χάρτη χρησιμοποιούν ξεχωριστή άδεια τοποθεσίας προσκηνίου.';

  @override
  String get autoRecordConsentExplanationCloseButton => 'Κατάλαβα';

  @override
  String get autoRecordConsentExplanationTooltip => 'Τι σημαίνει αυτό;';

  @override
  String get autoRecordConsentRevokeAction =>
      'Πατήστε για διαχείριση στις ρυθμίσεις συστήματος';

  @override
  String get autoRecordSectionTitle => 'Αυτόματη καταγραφή';

  @override
  String get autoRecordToggleLabel => 'Αυτόματη καταγραφή ταξιδιών';

  @override
  String get autoRecordStatusActiveLabel =>
      'Η αυτόματη καταγραφή θα ενεργοποιηθεί την επόμενη φορά που θα μπείτε στο αυτοκίνητο.';

  @override
  String get autoRecordStatusNeedsPairingLabel =>
      'Συζεύξτε προσαρμογέα OBD2 για ενεργοποίηση αυτόματης καταγραφής.';

  @override
  String get autoRecordStatusNeedsBackgroundLocationLabel =>
      'Επιτρέψτε την τοποθεσία παρασκηνίου για να συνεχίζει η αυτόματη καταγραφή με σβηστή οθόνη.';

  @override
  String get autoRecordStatusPairAdapterCta => 'Σύζευξη προσαρμογέα';

  @override
  String get autoRecordSpeedThresholdLabel => 'Ταχύτητα εκκίνησης (km/h)';

  @override
  String get autoRecordSaveDelayLabel =>
      'Καθυστέρηση αποθήκευσης μετά την αποσύνδεση (δευτερόλεπτα)';

  @override
  String get autoRecordPairedAdapterLabel => 'Συζευγμένος προσαρμογέας';

  @override
  String get autoRecordPairedAdapterNone =>
      'Δεν έχει συζευχθεί προσαρμογέας. Συζεύξτε έναν πρώτα μέσω του OBD2 onboarding.';

  @override
  String get autoRecordBackgroundLocationLabel =>
      'Τοποθεσία παρασκηνίου επιτρέπεται';

  @override
  String get autoRecordBackgroundLocationRequest => 'Αίτηση άδειας';

  @override
  String get autoRecordBackgroundLocationRationaleTitle =>
      'Γιατί \"Πάντα να επιτρέπεται\";';

  @override
  String get autoRecordBackgroundLocationRationaleBody =>
      'Η αυτόματη καταγραφή μεταδίδει συντεταγμένες GPS από την υπηρεσία OBD-II προσκηνίου ενώ η οθόνη είναι σβηστή, ώστε η διαδρομή ταξιδιού να παραμένει ακριβής. Το Android απαιτεί την επιλογή \"Πάντα να επιτρέπεται\" για να συνεχίζει να λειτουργεί μετά το κλείδωμα της συσκευής.';

  @override
  String get autoRecordBackgroundLocationOpenSettings => 'Άνοιγμα ρυθμίσεων';

  @override
  String get autoRecordBackgroundLocationForegroundDeniedSnackbar =>
      'Απαιτείται άδεια τοποθεσίας';

  @override
  String get autoRecordBackgroundLocationRequestFailedSnackbar =>
      'Αδύνατη αίτηση τοποθεσίας παρασκηνίου';

  @override
  String get autoRecordBadgeClearTooltip => 'Εκκαθάριση μετρητή';

  @override
  String get autoRecordPairAdapterLinkText =>
      'Συζεύξτε έναν προσαρμογέα στην παρακάτω ενότητα για ενεργοποίηση αυτόματης καταγραφής';

  @override
  String get exportBackupTooltip => 'Εξαγωγή αντιγράφου ασφαλείας';

  @override
  String get exportBackupReady =>
      'Αντίγραφο ασφαλείας έτοιμο — επιλέξτε προορισμό';

  @override
  String get exportBackupFailed =>
      'Αποτυχία εξαγωγής αντιγράφου — παρακαλώ δοκιμάστε ξανά';

  @override
  String get brokenMapChipVerifying => 'Επαλήθευση αισθητήρα MAP…';

  @override
  String get brokenMapChipDisclaimer => 'Ύποπτες ενδείξεις MAP';

  @override
  String get brokenMapSnackbarUnreliable =>
      'Ο αισθητήρας MAP διαβάζει εσφαλμένα — οι ενδείξεις καυσίμου μπορεί να είναι 50–80% χαμηλότερες. Δοκιμάστε διαφορετικό προσαρμογέα.';

  @override
  String get brokenMapBannerHardDisable =>
      'Αναξιόπιστος αισθητήρας MAP. Εμφάνιση μέσων ανεφοδιασμού αντί για ζωντανή ροή καυσίμου.';

  @override
  String brokenMapOverlayVerified(String confidence) {
    return 'Αισθητήρας MAP: επαληθευμένος ($confidence)';
  }

  @override
  String brokenMapOverlayUnverified(String confidence) {
    return 'Αισθητήρας MAP: επαλήθευση ($confidence)';
  }

  @override
  String brokenMapOverlaySuspicious(String confidence) {
    return 'Αισθητήρας MAP: ύποπτος ($confidence)';
  }

  @override
  String brokenMapOverlayPosterior(String posterior, String margin) {
    return 'Αισθητήρας MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapOverlayPosteriorVerified(String posterior, String margin) {
    return 'Αισθητήρας MAP: $posterior% ± $margin% (επαληθευμένος)';
  }

  @override
  String get brokenMapDiagnosticsCardTitle => 'Διαγνωστικά αισθητήρα MAP';

  @override
  String brokenMapDiagnosticsBeliefLine(String posterior, String margin) {
    return 'Εμπιστοσύνη βλάβης MAP: $posterior% ± $margin%';
  }

  @override
  String brokenMapDiagnosticsObservationCount(int count) {
    return '$count παρατηρήσεις καταγράφηκαν';
  }

  @override
  String get brokenMapDiagnosticsVerifiedBadge => 'Επαληθευμένα καθαρό';

  @override
  String get brokenMapDiagnosticsBeliefNone =>
      'Ο αισθητήρας MAP αυτού του οχήματος δεν έχει παρατηρηθεί ακόμα.';

  @override
  String get brokenMapDiagnosticsBlocklistHeading =>
      'Αποκλεισμένοι προσαρμογείς';

  @override
  String get brokenMapDiagnosticsBlocklistEmpty =>
      'Δεν υπάρχουν αποκλεισμένοι προσαρμογείς.';

  @override
  String brokenMapDiagnosticsBlocklistEntry(String adapter, String percent) {
    return '$adapter — επισημάνθηκε $percent% βλαβερός';
  }

  @override
  String get brokenMapDiagnosticsClearButton => 'Εκκαθάριση';

  @override
  String get brokenMapRevPromptTitle => 'Ανεβάστε στροφές';

  @override
  String get brokenMapRevPromptBody =>
      'Πατήστε σύντομα το γκάζι για να ελέγξει η εφαρμογή αν ο αισθητήρας MAP ανταποκρίνεται.';

  @override
  String get brokenMapRevPromptConfirm => 'Έγινε — ανέβασα στροφές';

  @override
  String get calibrationAdvancedTitle => 'Σύνθετη βαθμονόμηση';

  @override
  String get calibrationDisplacementLabel => 'Κυβισμός κινητήρα (cc)';

  @override
  String get calibrationVolumetricEfficiencyLabel =>
      'Ογκομετρική απόδοση (η_v)';

  @override
  String get calibrationAfrLabel => 'Αναλογία αέρα-καυσίμου (AFR)';

  @override
  String get calibrationFuelDensityLabel => 'Πυκνότητα καυσίμου (g/L)';

  @override
  String get calibrationSourceDetected => '(ανιχνεύτηκε από VIN)';

  @override
  String calibrationSourceCatalog(String makeModel) {
    return '(κατάλογος: $makeModel)';
  }

  @override
  String get calibrationSourceDefault => '(προεπιλογή)';

  @override
  String get calibrationSourceManual => '(χειροκίνητο)';

  @override
  String get calibrationResetToDetected => 'Επαναφορά σε ανιχνευμένη τιμή';

  @override
  String calibrationLearnerStatusCalibrated(String eta, int samples) {
    return 'η_v: $eta (βαθμονομημένο, $samples δείγματα)';
  }

  @override
  String calibrationLearnerStatusLearning(String eta, int samples) {
    return 'η_v: $eta (εκμάθηση, $samples δείγματα)';
  }

  @override
  String get calibrationLearnerStatusNoSamples =>
      'η_v: 0.85 (προεπιλογή — δεν υπάρχει πλήρης ανεφοδιασμός ακόμα)';

  @override
  String get calibrationResetLearner => 'Επαναφορά εκπαιδευτή';

  @override
  String get calibrationBasisAtkinson => 'Κύκλος Atkinson';

  @override
  String get calibrationBasisVnt => 'VNT diesel + DI';

  @override
  String get calibrationBasisTurboDi => 'Υπερτροφοδοτούμενο + DI';

  @override
  String get calibrationBasisTurbo => 'Υπερτροφοδοτούμενο';

  @override
  String get calibrationBasisNaDi => 'Φυσικής αναπνοής + DI';

  @override
  String calibrationSourceCatalogWithBasis(String makeModel, String basis) {
    return '(κατάλογος: $makeModel — προεπιλογή $basis)';
  }

  @override
  String catalogReresolveSnackbarMessage(String makeModel) {
    return 'Το $makeModel σας επισημαίνεται ως diesel αλλά αντιστοιχεί σε καταχώρηση βενζίνης. Πατήστε για ενημέρωση.';
  }

  @override
  String get catalogReresolveSnackbarAction => 'Ενημέρωση';

  @override
  String get consumptionTabFuel => 'Καύσιμο';

  @override
  String get consumptionTabCharging => 'Φόρτιση';

  @override
  String get noChargingLogsTitle => 'Δεν υπάρχουν αρχεία φόρτισης ακόμα';

  @override
  String get noChargingLogsSubtitle =>
      'Καταγράψτε την πρώτη σας συνεδρία φόρτισης για παρακολούθηση EUR/100 km και kWh/100 km.';

  @override
  String get addChargingLog => 'Καταγραφή φόρτισης';

  @override
  String get addChargingLogTitle => 'Καταγραφή συνεδρίας φόρτισης';

  @override
  String get chargingKwh => 'Ενέργεια (kWh)';

  @override
  String get chargingCost => 'Συνολικό κόστος';

  @override
  String get chargingTimeMin => 'Χρόνος φόρτισης (λεπτά)';

  @override
  String get chargingStationName => 'Σταθμός (προαιρετικό)';

  @override
  String chargingEurPer100km(String value) {
    return '$value EUR / 100 km';
  }

  @override
  String chargingKwhPer100km(String value) {
    return '$value kWh / 100 km';
  }

  @override
  String get chargingDerivedHelper =>
      'Απαιτείται προηγούμενη εγγραφή για σύγκριση';

  @override
  String get chargingLogButtonLabel => 'Καταγραφή φόρτισης';

  @override
  String get chargingCostTrendTitle => 'Τάση κόστους φόρτισης';

  @override
  String get chargingEfficiencyTitle => 'Απόδοση (kWh/100 km)';

  @override
  String get chargingChartsEmpty => 'Δεν υπάρχουν αρκετά δεδομένα ακόμα';

  @override
  String get chargingChartsMonthAxis => 'Μήνας';

  @override
  String get gdprCommunityWaitTimeTitle => 'Χρόνοι αναμονής κοινότητας';

  @override
  String get gdprCommunityWaitTimeShort =>
      'Ανώνυμη κοινοποίηση χρόνων αναμονής στον σταθμό';

  @override
  String get gdprCommunityWaitTimeDescription =>
      'Ανώνυμη κοινοποίηση της άφιξης και αναχώρησής σας από σταθμό καυσίμων για εμφάνιση τυπικών χρόνων αναμονής. Δεν μεταφορτώνονται συντεταγμένες τοποθεσίας — μόνο το αναγνωριστικό σταθμού.';

  @override
  String get consoFeatureGroupTitle => 'Κατανάλωση';

  @override
  String get consoFeatureGroupDescription =>
      'Παρακολουθήστε την κατανάλωση — χειροκίνητοι ανεφοδιασμοί ή αυτόματη καταγραφή ταξιδιών OBD2.';

  @override
  String get consoModeOff => 'Ανενεργό';

  @override
  String get consoModeFuel => 'Καύσιμο';

  @override
  String get consoModeFuelAndTrips => 'Καύσιμο + Ταξίδια';

  @override
  String get consoModeOffDescription =>
      'Χωρίς καρτέλα Κατανάλωσης και χωρίς ενότητα ρυθμίσεων Κατανάλωσης.';

  @override
  String get consoModeFuelDescription =>
      'Μόνο χειροκίνητοι ανεφοδιασμοί. Χρήσιμο χωρίς προσαρμογέα OBD2.';

  @override
  String get consoModeFuelAndTripsDescription =>
      'Προσθέτει αυτόματη καταγραφή ταξιδιών OBD2. Απαιτεί συζευγμένο προσαρμογέα.';

  @override
  String get consoSubsectionVehicles => 'Τα οχήματά μου';

  @override
  String get consoSubsectionTrajets => 'Ταξίδια (OBD2)';

  @override
  String get consoSubsectionToggles => 'Οδήγηση';

  @override
  String consumptionStatsOpenWindowBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count μερικοί ανεφοδιασμοί σε αναμονή — δεν περιλαμβάνονται στον μέσο',
      one: '1 μερικός ανεφοδιασμός σε αναμονή — δεν περιλαμβάνεται στον μέσο',
    );
    return '$_temp0';
  }

  @override
  String consumptionStatsCorrectionShareHint(int percent) {
    return '$percent% καυσίμου από αυτόματες διορθώσεις — ελέγξτε τις εγγραφές';
  }

  @override
  String get fillUpCorrectionLabel =>
      'Αυτόματη διόρθωση — πατήστε για επεξεργασία';

  @override
  String get fillUpCorrectionEditTitle => 'Επεξεργασία αυτόματης διόρθωσης';

  @override
  String get fillUpCorrectionEditExplainer =>
      'Αυτή η εγγραφή δημιουργήθηκε αυτόματα για κάλυψη της διαφοράς μεταξύ καταγεγραμμένων ταξιδιών και αντλημένου καυσίμου. Προσαρμόστε τις τιμές αν γνωρίζετε τα ακριβή στοιχεία.';

  @override
  String get fillUpCorrectionDelete => 'Διαγραφή διόρθωσης';

  @override
  String get fillUpCorrectionStation => 'Όνομα σταθμού (προαιρετικό)';

  @override
  String get greeceApiProvider => 'Παρατηρητήριο Τιμών (Ελλάδα)';

  @override
  String get greeceCommunityApiNotice =>
      'Τροφοδοτείται από το API fuelpricesgr που συντηρεί η κοινότητα';

  @override
  String get romaniaApiProvider => 'Monitorul Prețurilor (Ρουμανία)';

  @override
  String get romaniaScrapingNotice =>
      'Τροφοδοτείται από το pretcarburant.ro (Συμβούλιο Ανταγωνισμού + ANPC)';

  @override
  String crossBorderCheaper(String country, String km, String price) {
    return 'Σταθμοί $country $km km μακριά — $price€/L φθηνότεροι';
  }

  @override
  String get crossBorderTapToSwitch => 'Πατήστε για εναλλαγή χώρας';

  @override
  String get crossBorderDismissTooltip => 'Απόρριψη';

  @override
  String get insightCardTitle => 'Πιο σπάταλες συμπεριφορές';

  @override
  String get insightEmptyState =>
      'Δεν υπάρχουν αξιοσημείωτες ανεπάρκειες — συνεχίστε έτσι!';

  @override
  String insightHighRpm(String pctTime, String liters) {
    return 'Κινητήρας πάνω από 3000 RPM ($pctTime% ταξιδιού): σπατάλη $liters L';
  }

  @override
  String insightHardAccel(String count, String liters) {
    return '$count δυνατές επιταχύνσεις: σπατάλη $liters L';
  }

  @override
  String insightIdling(String pctTime, String liters) {
    return 'Ρελαντί ($pctTime% ταξιδιού): σπατάλη $liters L';
  }

  @override
  String insightSubtitlePctOfTrip(String pctTime) {
    return '$pctTime% ταξιδιού';
  }

  @override
  String insightTrailingLitersWasted(String liters) {
    return '+$liters L';
  }

  @override
  String insightLowGear(String minutes) {
    return 'Βαριά φόρτωση σε χαμηλή ταχύτητα ($minutes λεπτά)';
  }

  @override
  String get drivingScoreCardTitle => 'Βαθμολογία οδήγησης';

  @override
  String get drivingScoreCardOutOf => '/100';

  @override
  String get drivingScoreCardSubtitle =>
      'Σύνθετη βαθμολογία από ρελαντί, δυνατές επιταχύνσεις, δυνατό φρενάρισμα και χρόνο υψηλών στροφών. Η σύγκριση \"καλύτερος από X% των προηγούμενων ταξιδιών\" θα έρθει σε επόμενη ενημέρωση.';

  @override
  String drivingScoreCardSemanticsLabel(String score) {
    return 'Βαθμολογία οδήγησης $score από 100';
  }

  @override
  String get drivingScorePenaltyIdling => 'Ρελαντί';

  @override
  String get drivingScorePenaltyHardAccel => 'Δυνατές επιταχύνσεις';

  @override
  String get drivingScorePenaltyHardBrake => 'Δυνατό φρενάρισμα';

  @override
  String get drivingScorePenaltyHighRpm => 'Υψηλές στροφές';

  @override
  String get drivingScorePenaltyFullThrottle => 'Πλήρες γκάζι';

  @override
  String get ecoRouteOption => 'Οικονομικό';

  @override
  String ecoRouteSavings(String liters) {
    return '≈ $liters L εξοικονόμηση';
  }

  @override
  String get ecoRouteHint =>
      'Πιο έξυπνη οδήγηση — προτιμά σταθερό αυτοκινητόδρομο αντί για λαβυρινθώδεις συντομεύσεις.';

  @override
  String get favoritesShareAction => 'Κοινοποίηση';

  @override
  String favoritesShareSubject(String date) {
    return 'Sparkilo — αγαπημένα στις $date';
  }

  @override
  String get favoritesShareError => 'Αδύνατη δημιουργία εικόνας κοινοποίησης';

  @override
  String get featureManagementSectionTitle => 'Διαχείριση λειτουργιών';

  @override
  String get featureManagementSectionSubtitle =>
      'Ενεργοποίηση ή απενεργοποίηση μεμονωμένων λειτουργιών. Ορισμένες λειτουργίες εξαρτώνται από άλλες — οι διακόπτες είναι απενεργοποιημένοι μέχρι να πληρούνται οι προαπαιτούμενες.';

  @override
  String get featureLabel_obd2TripRecording => 'Καταγραφή ταξιδιών OBD2';

  @override
  String get featureDescription_obd2TripRecording =>
      'Αυτόματη καταγραφή ταξιδιών μέσω OBD2.';

  @override
  String get featureLabel_gamification => 'Gamification';

  @override
  String get featureDescription_gamification =>
      'Βαθμολογίες οδήγησης και εξαργυρωμένα σήματα.';

  @override
  String get featureLabel_hapticEcoCoach => 'Απτικός οδηγός eco';

  @override
  String get featureDescription_hapticEcoCoach =>
      'Απτική ανατροφοδότηση σε πραγματικό χρόνο κατά τη διάρκεια ταξιδιού.';

  @override
  String get featureLabel_tankSync => 'TankSync';

  @override
  String get featureDescription_tankSync =>
      'Συγχρονισμός μεταξύ συσκευών μέσω Supabase.';

  @override
  String get featureLabel_consumptionAnalytics => 'Ανάλυση κατανάλωσης';

  @override
  String get featureDescription_consumptionAnalytics =>
      'Καρτέλα ανάλυσης ανεφοδιασμών και ταξιδιών.';

  @override
  String get featureLabel_baselineSync => 'Συγχρονισμός βάσης';

  @override
  String get featureDescription_baselineSync =>
      'Συγχρονισμός βάσεων οδήγησης μέσω TankSync.';

  @override
  String get featureLabel_unifiedSearchResults =>
      'Ενοποιημένα αποτελέσματα αναζήτησης';

  @override
  String get featureDescription_unifiedSearchResults =>
      'Ενιαία λίστα αποτελεσμάτων που συνδυάζει σταθμούς καυσίμων και EV.';

  @override
  String get featureLabel_priceAlerts => 'Ειδοποιήσεις τιμών';

  @override
  String get featureDescription_priceAlerts =>
      'Ειδοποιήσεις πτώσης τιμής βάσει κατωφλίου.';

  @override
  String get featureLabel_priceHistory => 'Ιστορικό τιμών';

  @override
  String get featureDescription_priceHistory =>
      'Γραφήματα τιμών 30 ημερών στις λεπτομέρειες σταθμού.';

  @override
  String get featureLabel_routePlanning => 'Σχεδιασμός διαδρομής';

  @override
  String get featureDescription_routePlanning =>
      'Φθηνότερη στάση κατά μήκος της διαδρομής σας.';

  @override
  String get featureLabel_evCharging => 'Φόρτιση EV';

  @override
  String get featureDescription_evCharging =>
      'Σταθμοί φόρτισης μέσω OpenChargeMap.';

  @override
  String get featureLabel_glideCoach => 'Οδηγός glide';

  @override
  String get featureDescription_glideCoach =>
      'Καθοδήγηση hypermiling με σήματα κυκλοφορίας OSM.';

  @override
  String get featureLabel_gpsTripPath => 'Διαδρομή GPS ταξιδιού';

  @override
  String get featureDescription_gpsTripPath =>
      'Αποθήκευση δειγμάτων διαδρομής GPS μαζί με κάθε ταξίδι.';

  @override
  String get featureLabel_autoRecord => 'Αυτόματη καταγραφή';

  @override
  String get featureDescription_autoRecord =>
      'Αυτόματη έναρξη ταξιδιού όταν ο προσαρμογέας OBD2 συνδέεται σε κινούμενο όχημα.';

  @override
  String get featureLabel_showFuel => 'Εμφάνιση σταθμών καυσίμων';

  @override
  String get featureDescription_showFuel =>
      'Εμφάνιση αποτελεσμάτων σταθμών βενζίνης/diesel στην αναζήτηση και τον χάρτη.';

  @override
  String get featureLabel_showElectric => 'Εμφάνιση σταθμών φόρτισης';

  @override
  String get featureDescription_showElectric =>
      'Εμφάνιση σταθμών φόρτισης EV στην αναζήτηση και τον χάρτη.';

  @override
  String get featureLabel_showConsumptionTab => 'Καρτέλα κατανάλωσης';

  @override
  String get featureDescription_showConsumptionTab =>
      'Εμφάνιση καρτέλας ανάλυσης κατανάλωσης στην κάτω πλοήγηση.';

  @override
  String get featureBlockedEnable_gamification =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureBlockedEnable_hapticEcoCoach =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureBlockedEnable_consumptionAnalytics =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureBlockedEnable_baselineSync =>
      'Ενεργοποιήστε πρώτα το TankSync';

  @override
  String get featureBlockedEnable_glideCoach =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureBlockedEnable_gpsTripPath =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureBlockedEnable_autoRecord =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureBlockedEnable_showFuel =>
      'Δεν πληρούνται οι προαπαιτούμενες';

  @override
  String get featureBlockedEnable_showElectric =>
      'Δεν πληρούνται οι προαπαιτούμενες';

  @override
  String get featureBlockedEnable_showConsumptionTab =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureLabel_tflitePricePrediction => 'Πρόβλεψη τιμής TFLite';

  @override
  String get featureDescription_tflitePricePrediction =>
      'Μοντέλο πρόβλεψης τιμών στη συσκευή — η εκτέλεση γίνεται τοπικά· χαρακτηριστικά και προβλέψεις δεν φεύγουν ποτέ από τη συσκευή.';

  @override
  String get featureBlockedEnable_tflitePricePrediction =>
      'Ενεργοποιήστε πρώτα το ιστορικό τιμών';

  @override
  String get featureLabel_fuelCalculator => 'Αριθμομηχανή καυσίμου';

  @override
  String get featureDescription_fuelCalculator =>
      'Αριθμομηχανή κόστους καυσίμου από τα αποτελέσματα αναζήτησης.';

  @override
  String get featureLabel_carbonDashboard => 'Πίνακας αποτυπώματος άνθρακα';

  @override
  String get featureDescription_carbonDashboard =>
      'Πίνακας αποτυπώματος CO2 από την καρτέλα Κατανάλωσης.';

  @override
  String get featureLabel_experimentalOemPids => 'Πειραματικά OEM PIDs';

  @override
  String get featureDescription_experimentalOemPids =>
      'Ανάγνωση ακριβών λίτρων ντεπόζιτου μέσω PIDs κατασκευαστή σε υποστηριζόμενους προσαρμογείς.';

  @override
  String get featureBlockedEnable_experimentalOemPids =>
      'Ενεργοποιήστε πρώτα την καταγραφή ταξιδιών OBD2';

  @override
  String get featureLabel_paymentQrScan => 'Σάρωση QR πληρωμής';

  @override
  String get featureDescription_paymentQrScan =>
      'Αναγνώστης QR για πληρωμή στην οθόνη λεπτομερειών σταθμού.';

  @override
  String get featureLabel_communityPriceReports => 'Αναφορές τιμών κοινότητας';

  @override
  String get featureDescription_communityPriceReports =>
      'Αναφορά τιμής σταθμού από την οθόνη λεπτομερειών.';

  @override
  String get feedbackConsentTitle => 'Αποστολή αναφοράς στο GitHub;';

  @override
  String get feedbackConsentBody =>
      'Αυτό δημιουργεί δημόσιο ticket στο αποθετήριο GitHub μας με τη φωτογραφία και το κείμενο OCR. Δεν αποστέλλονται προσωπικά δεδομένα (τοποθεσία, αναγνωριστικό λογαριασμού). Συνέχεια;';

  @override
  String get feedbackConsentContinue => 'Συνέχεια';

  @override
  String get feedbackConsentCancel => 'Ακύρωση';

  @override
  String get feedbackConsentLater => 'Αργότερα';

  @override
  String get feedbackTokenSectionTitle => 'Σχόλια κακής σάρωσης (GitHub)';

  @override
  String get feedbackTokenDescription =>
      'Για αυτόματο άνοιγμα GitHub ticket από αποτυχημένη σάρωση, επικολλήστε GitHub PAT (εύρος `public_repo` στο αποθετήριο tankstellen). Αλλιώς παραμένει διαθέσιμη η χειροκίνητη κοινοποίηση.';

  @override
  String get feedbackTokenStatusSet => 'Token ρυθμισμένο';

  @override
  String get feedbackTokenStatusUnset => 'Χωρίς token';

  @override
  String get feedbackTokenSet => 'Ορισμός';

  @override
  String get feedbackTokenClear => 'Εκκαθάριση';

  @override
  String get feedbackTokenDialogTitle => 'GitHub PAT';

  @override
  String get feedbackTokenFieldLabel => 'Προσωπικό κλειδί πρόσβασης';

  @override
  String get fillUpReconciliationVerifiedBadgeLabel =>
      'Επαληθευμένο από προσαρμογέα';

  @override
  String get fillUpReconciliationVarianceDialogTitle =>
      'Δεν ταιριάζει με την ανάγνωση προσαρμογέα';

  @override
  String fillUpReconciliationVarianceDialogBody(String userL, String adapterL) {
    return 'Η εγγραφή σας: $userL L. Ο προσαρμογέας λέει: $adapterL L (διαφορά από δείγμα πριν/μετά στάθμης καυσίμου). Χρήση τιμής προσαρμογέα;';
  }

  @override
  String get fillUpReconciliationVarianceDialogKeepMine =>
      'Διατήρηση εγγραφής μου';

  @override
  String get fillUpReconciliationVarianceDialogUseAdapter =>
      'Χρήση τιμής προσαρμογέα';

  @override
  String get scanReceiptNoData =>
      'Δεν βρέθηκαν δεδομένα απόδειξης — δοκιμάστε ξανά';

  @override
  String get scanReceiptSuccess =>
      'Η απόδειξη σαρώθηκε — επαληθεύστε τις τιμές. Πατήστε «Αναφορά σφάλματος σάρωσης» παρακάτω αν κάτι είναι λάθος.';

  @override
  String scanReceiptFailed(String error) {
    return 'Αποτυχία σάρωσης: $error';
  }

  @override
  String get scanPumpUnreadable =>
      'Η οθόνη αντλίας δεν είναι αναγνώσιμη — δοκιμάστε ξανά';

  @override
  String get scanPumpSuccess =>
      'Η οθόνη αντλίας σαρώθηκε — επαληθεύστε τις τιμές.';

  @override
  String scanPumpFailed(String error) {
    return 'Αποτυχία σάρωσης αντλίας: $error';
  }

  @override
  String get badScanReportTitle => 'Αναφορά σφάλματος σάρωσης';

  @override
  String get badScanReportTitleReceipt =>
      'Αναφορά σφάλματος σάρωσης — Απόδειξη';

  @override
  String get badScanReportTitlePumpDisplay =>
      'Αναφορά σφάλματος σάρωσης — Οθόνη αντλίας';

  @override
  String get pumpScanFailureTitle => 'Μη αναγνώσιμη οθόνη';

  @override
  String get pumpScanFailureBody =>
      'Η σάρωση δεν μπόρεσε να διαβάσει την οθόνη αντλίας. Τι θέλετε να κάνετε;';

  @override
  String get pumpScanFailureCorrectManually => 'Χειροκίνητη διόρθωση';

  @override
  String get pumpScanFailureReport => 'Αναφορά';

  @override
  String get pumpScanFailureRemove => 'Αφαίρεση φωτογραφίας';

  @override
  String get badScanReportHint =>
      'Θα μοιραστούμε τη φωτογραφία απόδειξης και και τα δύο σύνολα τιμών ώστε η επόμενη έκδοση να μάθει αυτή τη διάταξη.';

  @override
  String get badScanReportShareAction => 'Κοινοποίηση αναφοράς + φωτογραφίας';

  @override
  String get badScanReportFieldBrandLayout => 'Διάταξη μάρκας';

  @override
  String get badScanReportFieldTotal => 'Σύνολο';

  @override
  String get badScanReportFieldPricePerLiter => 'Τιμή/L';

  @override
  String get badScanReportFieldStation => 'Σταθμός';

  @override
  String get badScanReportFieldFuel => 'Καύσιμο';

  @override
  String get badScanReportFieldDate => 'Ημερομηνία';

  @override
  String get badScanReportHeaderField => 'Πεδίο';

  @override
  String get badScanReportHeaderScanned => 'Σαρωμένο';

  @override
  String get badScanReportHeaderYouTyped => 'Εισαγάγατε';

  @override
  String get badScanReportCreateTicket => 'Δημιουργία ζητήματος';

  @override
  String get badScanReportOpenInBrowser => 'Άνοιγμα στον περιηγητή';

  @override
  String get badScanReportFallbackToShare =>
      'Αποτυχία υποβολής — χειροκίνητη κοινοποίηση';

  @override
  String get pumpCameraHint =>
      'Ευθυγραμμίστε τους τρεις αριθμούς της οθόνης της αντλίας μέσα στο πλαίσιο';

  @override
  String get pumpCameraCapture => 'Λήψη';

  @override
  String get pumpCameraPermissionDenied =>
      'Απαιτείται πρόσβαση στην κάμερα για τη σάρωση της οθόνης της αντλίας. Ενεργοποιήστε την στις ρυθμίσεις της συσκευής.';

  @override
  String get pumpCameraError =>
      'Η κάμερα δεν μπόρεσε να ξεκινήσει. Δοκιμάστε ξανά ή εισαγάγετε τις τιμές χειροκίνητα.';

  @override
  String get fillUpSectionWhatTitle => 'Τι ανεφοδιαστήκατε';

  @override
  String get fillUpSectionWhatSubtitle => 'Καύσιμο, ποσότητα, τιμή';

  @override
  String get fillUpSectionWhereTitle => 'Πού βρισκόσαστε';

  @override
  String get fillUpSectionWhereSubtitle => 'Σταθμός, χιλιόμετρα, σημειώσεις';

  @override
  String get fillUpImportFromLabel => 'Εισαγωγή από…';

  @override
  String get fillUpImportSheetTitle => 'Εισαγωγή δεδομένων ανεφοδιασμού';

  @override
  String get fillUpImportReceiptLabel => 'Απόδειξη';

  @override
  String get fillUpImportReceiptDescription =>
      'Σάρωση χάρτινης απόδειξης με κάμερα';

  @override
  String get fillUpImportPumpLabel => 'Οθόνη αντλίας';

  @override
  String get fillUpImportPumpDescription =>
      'Ανάγνωση Betrag / Preis από την οθόνη LCD αντλίας';

  @override
  String get fillUpImportObdLabel => 'Προσαρμογέας OBD-II';

  @override
  String get fillUpImportObdDescription =>
      'Ανάγνωση χιλιομετρητή από τη θύρα OBD-II μέσω Bluetooth';

  @override
  String get fillUpPricePerLiterLabel => 'Τιμή ανά λίτρο';

  @override
  String get vehicleHeaderPlateLabel => 'Πινακίδα';

  @override
  String get vehicleHeaderUntitled => 'Νέο όχημα';

  @override
  String get vehicleSectionIdentityTitle => 'Ταυτότητα';

  @override
  String get vehicleSectionIdentitySubtitle => 'Όνομα & VIN';

  @override
  String get vehicleSectionDrivetrainTitle => 'Κινητήρας';

  @override
  String get vehicleSectionDrivetrainSubtitle =>
      'Τρόπος κίνησης αυτού του οχήματος';

  @override
  String get calibrationModeLabel => 'Λειτουργία βαθμονόμησης';

  @override
  String get calibrationModeRule => 'Βάσει κανόνων';

  @override
  String get calibrationModeFuzzy => 'Ασαφής';

  @override
  String get calibrationModeTooltip =>
      'Η βαθμονόμηση βάσει κανόνων αντιστοιχεί κάθε δείγμα οδήγησης σε μία ακριβώς κατάσταση. Η ασαφής το κατανέμει σε όλες ανάλογα με την καταλληλότητα — πιο ομαλό γύρω στα 60 km/h ή σε μεταβαλλόμενες κλίσεις, αλλά πιο αργό να γεμίσει όλα τα κουβάδια.';

  @override
  String get profileGamificationToggleTitle =>
      'Εμφάνιση επιτευγμάτων & βαθμολογιών';

  @override
  String get profileGamificationToggleSubtitle =>
      'Όταν είναι ανενεργό, σήματα, βαθμολογίες και εικονίδια τροπαίων αποκρύπτονται από ολόκληρη την εφαρμογή.';

  @override
  String get gpsDiagnosticsTitle => 'Διαγνωστικά δειγματοληψίας GPS';

  @override
  String gpsDiagnosticsHeader(String count, String span, int gaps) {
    String _temp0 = intl.Intl.pluralLogic(
      gaps,
      locale: localeName,
      other: '$gaps κενά',
      one: '1 κενό',
      zero: 'χωρίς κενά',
    );
    return '$count δείγματα · $span · $_temp0';
  }

  @override
  String gpsDiagnosticsCadence(int ms) {
    return 'Διάμεσο διάστημα: $ms ms';
  }

  @override
  String get gpsDiagnosticsExplain =>
      'Καταγράφηκε κατά τη διάρκεια εγγραφής για επαλήθευση ρυθμού GPS κατά την αδρανοποίηση τηλεφώνου.';

  @override
  String get hapticEcoCoachSectionTitle => 'Οδήγηση';

  @override
  String get hapticEcoCoachSettingTitle => 'Eco coaching σε πραγματικό χρόνο';

  @override
  String get hapticEcoCoachSettingSubtitle =>
      'Ήπια απτική + συμβουλή οθόνης όταν πατάτε γκάζι στη ζώνη κρουαζιέρας';

  @override
  String get hapticEcoCoachSnackBarMessage =>
      'Ελαφρύτερο γκάζι — η αδράνεια εξοικονομεί περισσότερα';

  @override
  String get anonKeyLabel => 'Κλειδί Anon';

  @override
  String get anonKeyHideTooltip => 'Απόκρυψη κλειδιού';

  @override
  String get anonKeyShowTooltip => 'Εμφάνιση κλειδιού για επαλήθευση';

  @override
  String anonKeyTooLong(int length) {
    return 'Το κλειδί είναι πολύ μεγάλο ($length χαρακτήρες) — ελέγξτε για επιπλέον κείμενο';
  }

  @override
  String anonKeyLooksCorrect(int length) {
    return 'Το κλειδί φαίνεται σωστό ($length χαρακτήρες)';
  }

  @override
  String get anonKeyShouldBeJwt =>
      'Το κλειδί πρέπει να είναι JWT (header.payload.signature)';

  @override
  String anonKeyMayBeTruncated(int length) {
    return 'Το κλειδί μπορεί να είναι κομμένο ($length από ~208 αναμενόμενους χαρακτήρες)';
  }

  @override
  String get anonKeyExceedsMax => 'Το κλειδί υπερβαίνει το μέγιστο μήκος';

  @override
  String get qrShareTitle => 'Κοινοποίηση βάσης δεδομένων σας';

  @override
  String get qrShareSubtitle =>
      'Άλλοι μπορούν να σαρώσουν αυτόν τον QR κώδικα για σύνδεση';

  @override
  String get qrShareCopyAsText => 'Αντιγραφή ως κείμενο';

  @override
  String get authInfoTitle => 'Γιατί να δημιουργήσω λογαριασμό;';

  @override
  String get authInfoBenefit1 =>
      '• Συγχρονισμός αγαπημένων, ειδοποιήσεων και αποθηκευμένων διαδρομών σε συσκευές';

  @override
  String get authInfoBenefit2 =>
      '• Προετοιμάστε διαδρομή στο τηλέφωνό σας, χρησιμοποιήστε την στο αυτοκίνητο';

  @override
  String get authInfoBenefit3 => '• Δεν κοινοποιούνται δεδομένα σε τρίτους';

  @override
  String get authInfoBenefit4 =>
      '• Μπορείτε να διαγράψετε τον λογαριασμό σας ανά πάσα στιγμή';

  @override
  String get privacyLocalDataEmpty =>
      'Τίποτα αποθηκευμένο ακόμα. Προσθέστε ένα αγαπημένο ή ορίστε ειδοποίηση τιμής για εμφάνιση εγγραφών εδώ.';

  @override
  String get privacyHideEmptyRows => 'Απόκρυψη κενών γραμμών';

  @override
  String privacyShowEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εμφάνιση $count κενών γραμμών',
      one: 'Εμφάνιση $count κενής γραμμής',
    );
    return '$_temp0';
  }

  @override
  String get apiKeySetupTitle => 'Ρύθμιση κλειδιού API (προαιρετικό)';

  @override
  String get apiKeySetupDescription =>
      'Εγγραφείτε για δωρεάν κλειδί API ή παραλείψτε για εξερεύνηση με δεδομένα επίδειξης.';

  @override
  String apiKeyRegistrationButton(String provider) {
    return 'Εγγραφή $provider';
  }

  @override
  String apiKeyTerms(String provider) {
    return 'Εισάγοντας κλειδί API αποδέχεστε τους όρους του $provider. Απαγορεύεται η αναδιανομή δεδομένων.';
  }

  @override
  String get calculatorDistanceHint => 'π.χ. 150';

  @override
  String get calculatorConsumptionHint => 'π.χ. 7.0';

  @override
  String get calculatorPriceHint => 'π.χ. 1.899';

  @override
  String get routeStrategyLabel => 'Στρατηγική:';

  @override
  String get routeStrategyUniform => 'Ομοιόμορφη';

  @override
  String get routeStrategyBalanced => 'Ισορροπημένη';

  @override
  String get glideCoachBetaTitle => 'Οδηγός glide beta (πειραματικό)';

  @override
  String get glideCoachBetaSubtitle =>
      'Ήπια απτική κατά την επιβράδυνση μπροστά σε κόκκινο φανάρι. Ανενεργό εξ ορισμού — κίνδυνος απόσπασης προσοχής.';

  @override
  String get consentSyncTripsTitle => 'Συγχρονισμός καταγεγραμμένων ταξιδιών';

  @override
  String get consentSyncTripsSubtitle =>
      'Δημιουργία αντιγράφων ταξιδιών OBD2 + GPS στο TankSync. Μεταξύ συσκευών, προαιρετικό.';

  @override
  String get consentSyncTripsDisabledHint =>
      'Ενεργοποιήστε τον Συγχρονισμό Cloud παραπάνω για δημιουργία αντιγράφων ταξιδιών.';

  @override
  String get consentSyncTripsNeedsEmailHint =>
      'Συνδεθείτε με λογαριασμό email για συγχρονισμό διαδρομών μεταξύ συσκευών.';

  @override
  String get consentHideDetails => 'Απόκρυψη λεπτομερειών';

  @override
  String get consentShowDetails => 'Εμφάνιση λεπτομερειών';

  @override
  String get dialogOk => 'ΟΚ';

  @override
  String get invalidLinkTitle => 'Μη έγκυρος σύνδεσμος';

  @override
  String invalidLinkBody(String path) {
    return 'Ο σύνδεσμος \"$path\" δεν είναι έγκυρος.';
  }

  @override
  String get home => 'Αρχική';

  @override
  String get loyaltySettingsTitle => 'Κάρτες καυσίμων';

  @override
  String get loyaltySettingsSubtitle =>
      'Εφαρμογή έκπτωσης πιστότητας στις εμφανιζόμενες τιμές';

  @override
  String get loyaltyMenuTitle => 'Κάρτες καυσίμων';

  @override
  String get loyaltyMenuSubtitle =>
      'Εφαρμογή εκπτώσεων ανά λίτρο από Total, Aral, Shell, …';

  @override
  String get loyaltyAddCard => 'Προσθήκη κάρτας';

  @override
  String get loyaltyAddCardSheetTitle => 'Προσθήκη κάρτας καυσίμων';

  @override
  String get loyaltyBrandLabel => 'Μάρκα';

  @override
  String get loyaltyCardLabelLabel => 'Ετικέτα (προαιρετικό)';

  @override
  String get loyaltyDiscountLabel => 'Έκπτωση (ανά λίτρο)';

  @override
  String get loyaltyDiscountInvalid => 'Εισάγετε θετικό αριθμό';

  @override
  String get loyaltyDeleteConfirmTitle => 'Διαγραφή κάρτας;';

  @override
  String get loyaltyDeleteConfirmBody =>
      'Αυτή η κάρτα θα σταματήσει να εφαρμόζει την έκπτωσή της.';

  @override
  String get loyaltyEmptyTitle => 'Δεν υπάρχουν κάρτες καυσίμων ακόμα';

  @override
  String get loyaltyEmptyBody =>
      'Προσθέστε κάρτα για αυτόματη εφαρμογή έκπτωσης ανά λίτρο στους αντίστοιχους σταθμούς.';

  @override
  String get loyaltyBadgePrefix => '−';

  @override
  String get maintenanceSignalIdleRpmCreepTitle =>
      'Ανίχνευση αύξησης ρελαντί RPM';

  @override
  String maintenanceSignalIdleRpmCreepBody(String percent, int tripCount) {
    return 'Οι στροφές ρελαντί έχουν αυξηθεί κατά $percent% στα τελευταία $tripCount ταξίδια. Πιθανό πρώιμο σημάδι βουλωμένου φίλτρου αέρα ή μετατόπισης αισθητήρα.';
  }

  @override
  String get maintenanceSignalMafDeviationTitle =>
      'Πιθανός περιορισμός εισαγωγής';

  @override
  String maintenanceSignalMafDeviationBody(String percent, int tripCount) {
    return 'Η ροή καυσίμου κρουαζιέρας έχει μειωθεί κατά $percent% στα τελευταία $tripCount ταξίδια. Πιθανό σημάδι βουλωμένου φίλτρου αέρα ή περιορισμένης εισαγωγής — αξίζει έλεγχο.';
  }

  @override
  String get maintenanceActionDismiss => 'Απόρριψη';

  @override
  String get maintenanceActionSnooze => 'Αναβολή 30 ημέρες';

  @override
  String get consumptionMonthlyInsightsTitle => 'Αυτός ο μήνας vs προηγούμενος';

  @override
  String get consumptionMonthlyTripsLabel => 'Ταξίδια';

  @override
  String get consumptionMonthlyDriveTimeLabel => 'Χρόνος οδήγησης';

  @override
  String get consumptionMonthlyDistanceLabel => 'Απόσταση';

  @override
  String get consumptionMonthlyAvgConsumptionLabel => 'Μέση κατανάλωση';

  @override
  String get consumptionMonthlyComparisonNotReliable =>
      'Απαιτούνται τουλάχιστον 3 ταξίδια ανά μήνα για σύγκριση';

  @override
  String get obd2CapabilitySectionTitle => 'Δυνατότητες προσαρμογέα';

  @override
  String get obd2CapabilityStandardOnly => 'Τυπικό';

  @override
  String get obd2CapabilityOemPids => 'OEM PIDs';

  @override
  String get obd2CapabilityFullCan => 'Full CAN';

  @override
  String get obd2CapabilityUpgradeHintStandard =>
      'Για ακριβή λίτρα-στο-ντεπόζιτο σε Peugeot/Citroën, η εφαρμογή υποστηρίζει OBDLink MX+/LX/CX (τσιπ STN).';

  @override
  String get obd2DebugOverlayEnabledSnack =>
      'Διαγνωστική επικάλυψη OBD2 ενεργοποιήθηκε';

  @override
  String get obd2DebugOverlayDisabledSnack =>
      'Διαγνωστική επικάλυψη OBD2 απενεργοποιήθηκε';

  @override
  String get obd2DebugOverlayClearButton => 'Εκκαθάριση';

  @override
  String get obd2DebugOverlayCloseButton => 'Κλείσιμο';

  @override
  String get obd2DebugOverlayTitle => 'Ίχνη OBD2';

  @override
  String get obd2DiagnosticShareLabel => 'Κοινοποίηση διαγνωστικού αρχείου';

  @override
  String get obd2DebugLoggingTitle => 'Καταγραφή εντοπισμού σφαλμάτων OBD2';

  @override
  String get obd2DebugLoggingSubtitle =>
      'Καταγράψτε κάθε συνεδρία OBD2 — σύνδεση, χειραψία, κενά δεδομένων και επανασυνδέσεις — σε ένα εξαγώγιμο αρχείο καταγραφής XML. Απενεργοποιημένο από προεπιλογή.';

  @override
  String get obd2DebugSessionShareLabel =>
      'Κοινή χρήση αρχείου καταγραφής συνεδρίας OBD2';

  @override
  String obd2PickerPinnedFallback(String adapterName) {
    return 'Δεν ήταν δυνατή η επαφή με \'$adapterName\' — επιλέξτε άλλον προσαρμογέα';
  }

  @override
  String get onboardingObd2StepTitle => 'Σύνδεση προσαρμογέα OBD2';

  @override
  String get onboardingObd2StepBody =>
      'Συνδέστε τον προσαρμογέα OBD2 στη θύρα του αυτοκινήτου και ανάψτε τη μίζα. Θα διαβάσουμε το VIN και θα συμπληρώσουμε τα στοιχεία κινητήρα για εσάς.';

  @override
  String get onboardingObd2ConnectButton => 'Σύνδεση προσαρμογέα';

  @override
  String get onboardingObd2SkipButton => 'Ίσως αργότερα';

  @override
  String get onboardingObd2ReadingVin => 'Ανάγνωση VIN…';

  @override
  String get onboardingObd2VinReadFailed =>
      'Αδύνατη ανάγνωση VIN — εισάγετε χειροκίνητα';

  @override
  String get onboardingObd2ConnectFailed =>
      'Αδύνατη σύνδεση με τον προσαρμογέα. Μπορείτε να δοκιμάσετε ξανά ή να παραλείψετε.';

  @override
  String get onboardingPickUseMode =>
      'Επιλέξτε λειτουργία χρήσης για συνέχεια.';

  @override
  String get alertsRadiusFrequencyLabel => 'Συχνότητα ελέγχου';

  @override
  String get alertsRadiusFrequencyDaily => 'Μία φορά την ημέρα';

  @override
  String get alertsRadiusFrequencyTwiceDaily => 'Δύο φορές την ημέρα';

  @override
  String get alertsRadiusFrequencyThriceDaily => 'Τρεις φορές την ημέρα';

  @override
  String get alertsRadiusFrequencyFourTimesDaily => 'Τέσσερις φορές την ημέρα';

  @override
  String get radiusAlertPickOnMap => 'Επιλογή στον χάρτη';

  @override
  String get radiusAlertMapPickerTitle => 'Επιλογή κέντρου ειδοποίησης';

  @override
  String get radiusAlertMapPickerConfirm => 'Επιβεβαίωση';

  @override
  String get radiusAlertMapPickerCancel => 'Ακύρωση';

  @override
  String get radiusAlertMapPickerHint =>
      'Σύρετε τον χάρτη για τοποθέτηση κέντρου ειδοποίησης';

  @override
  String get radiusAlertCenterFromMap => 'Τοποθεσία χάρτη';

  @override
  String radiusAlertNotificationTitle(String fuelLabel, String label) {
    return '$fuelLabel κοντά στο $label';
  }

  @override
  String radiusAlertNotificationBody(String price, String threshold) {
    return 'Ένας σταθμός έχει $price € (στόχος: $threshold €)';
  }

  @override
  String get refuelUnitPerLiter => '/L';

  @override
  String get refuelUnitPerKwh => '/kWh';

  @override
  String get refuelUnitPerSession => '/συνεδρία';

  @override
  String get speedConsumptionCardTitle => 'Κατανάλωση ανά ταχύτητα';

  @override
  String get speedBandIdleJam => 'Ρελαντί / μποτιλιάρισμα';

  @override
  String get speedBandUrban => 'Αστικό (10–50)';

  @override
  String get speedBandSuburban => 'Προαστιακό (50–80)';

  @override
  String get speedBandRural => 'Επαρχιακό (80–100)';

  @override
  String get speedBandMotorwaySlow => 'Οικονομική κρουαζιέρα (100–115)';

  @override
  String get speedBandMotorway => 'Αυτοκινητόδρομος (115–130)';

  @override
  String get speedBandMotorwayFast => 'Γρήγορος αυτοκινητόδρομος (130+)';

  @override
  String get speedConsumptionInsufficientData =>
      'Καταγράψτε 30+ λεπτά ταξιδιών με τον προσαρμογέα OBD2 για ξεκλείδωμα της ανάλυσης ταχύτητας/κατανάλωσης.';

  @override
  String speedConsumptionTimeShare(int percent) {
    return '$percent % οδήγησης';
  }

  @override
  String get speedConsumptionNeedMoreData => 'Απαιτούνται περισσότερα δεδομένα';

  @override
  String get splashLoadingLabel => 'Φόρτωση Sparkilo';

  @override
  String get tankLevelTitle => 'Στάθμη ντεπόζιτου';

  @override
  String tankLevelLitersFormat(String litres) {
    return '$litres L';
  }

  @override
  String tankLevelRangeFormat(String kilometres) {
    return '≈ $kilometres km αυτονομία';
  }

  @override
  String tankLevelLastFillUpFormat(String date, String count) {
    return 'Τελευταίος ανεφοδιασμός: $date · $count ταξίδι(α) από τότε';
  }

  @override
  String get tankLevelMethodObd2 => 'Μέτρηση OBD2';

  @override
  String get tankLevelMethodDistanceFallback => 'εκτίμηση βάσει απόστασης';

  @override
  String get tankLevelMethodMixed => 'μεικτή μέτρηση';

  @override
  String get tankLevelEmptyNoFillUp =>
      'Καταγράψτε ανεφοδιασμό για εμφάνιση στάθμης ντεπόζιτου';

  @override
  String get tankLevelDetailSheetTitle =>
      'Ταξίδια από τον τελευταίο ανεφοδιασμό';

  @override
  String get addFillUpIsFullTankLabel => 'Πλήρες ντεπόζιτο';

  @override
  String get addFillUpIsFullTankSubtitle =>
      'Το ντεπόζιτο γέμισε ως επάνω — αποεπιλέξτε αν ήταν μερικός ανεφοδιασμός';

  @override
  String get themeCardTitle => 'Θέμα';

  @override
  String get themeCardSubtitleSystem => 'Σύστημα';

  @override
  String get themeCardSubtitleLight => 'Φωτεινό';

  @override
  String get themeCardSubtitleDark => 'Σκοτεινό';

  @override
  String get themeSettingsScreenTitle => 'Θέμα';

  @override
  String get themeSettingsSystemLabel => 'Ακολουθεί σύστημα';

  @override
  String get themeSettingsLightLabel => 'Φωτεινό';

  @override
  String get themeSettingsDarkLabel => 'Σκοτεινό';

  @override
  String get themeSettingsSystemDescription =>
      'Αντιστοιχεί στην τρέχουσα εμφάνιση συσκευής.';

  @override
  String get themeSettingsLightDescription =>
      'Φωτεινά φόντα — ιδανικό για χρήση κατά τη διάρκεια της ημέρας.';

  @override
  String get themeSettingsDarkDescription =>
      'Σκοτεινά φόντα — πιο ευχάριστο για τα μάτια τη νύχτα και εξοικονομεί μπαταρία σε οθόνες OLED.';

  @override
  String get themeSettingsEcoLabel => 'Eco';

  @override
  String get themeSettingsEcoDescription =>
      'Η χαρακτηριστική πράσινη εμφάνιση της εφαρμογής — φωτεινή και ευανάγνωστη, με απαλά πρασινωπά φόντα.';

  @override
  String get throttleRpmHistogramTitle => 'Πώς χρησιμοποιήσατε τον κινητήρα';

  @override
  String get throttleRpmHistogramThrottleSection => 'Θέση γκαζιού';

  @override
  String get throttleRpmHistogramRpmSection => 'RPM κινητήρα';

  @override
  String get throttleRpmHistogramThrottleCoast => 'Αδράνεια (0–25%)';

  @override
  String get throttleRpmHistogramThrottleLight => 'Ελαφρύ (25–50%)';

  @override
  String get throttleRpmHistogramThrottleFirm => 'Μέτριο (50–75%)';

  @override
  String get throttleRpmHistogramThrottleWide => 'Πλήρες (75–100%)';

  @override
  String get throttleRpmHistogramRpmIdle => 'Ρελαντί (≤900)';

  @override
  String get throttleRpmHistogramRpmCruise => 'Κρουαζιέρα (901–2000)';

  @override
  String get throttleRpmHistogramRpmSpirited => 'Δυναμικό (2001–3000)';

  @override
  String get throttleRpmHistogramRpmHard => 'Σκληρό (>3000)';

  @override
  String get throttleRpmHistogramEmpty =>
      'Δεν υπάρχουν δείγματα γκαζιού ή RPM σε αυτό το ταξίδι.';

  @override
  String throttleRpmHistogramBarShare(String pct) {
    return '$pct%';
  }

  @override
  String get trajetsTabLabel => 'Ταξίδια';

  @override
  String get trajetsStartRecordingButton => 'Έναρξη καταγραφής';

  @override
  String get trajetsResumeRecordingButton => 'Συνέχεια καταγραφής';

  @override
  String get tripStartProgressConnectingAdapter =>
      'Σύνδεση σε προσαρμογέα OBD2…';

  @override
  String get tripStartProgressReadingVehicleData =>
      'Ανάγνωση δεδομένων οχήματος…';

  @override
  String get tripStartProgressStartingRecording => 'Έναρξη καταγραφής…';

  @override
  String get trajetsEmptyStateTitle => 'Δεν υπάρχουν ταξίδια ακόμα';

  @override
  String get trajetsEmptyStateBody =>
      'Πατήστε Έναρξη καταγραφής για να ξεκινήσετε την καταγραφή των οδηγήσεών σας.';

  @override
  String trajetsRowDistance(String km) {
    return '$km km';
  }

  @override
  String trajetsRowDuration(String minutes) {
    return '$minutes λεπτά';
  }

  @override
  String trajetsRowAvgConsumption(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get trajetDetailSummaryTitle => 'Σύνοψη';

  @override
  String get trajetDetailFieldDate => 'Ημερομηνία';

  @override
  String get trajetDetailFieldVehicle => 'Όχημα';

  @override
  String get trajetDetailFieldAdapter => 'Προσαρμογέας OBD2';

  @override
  String get trajetDetailFieldDistance => 'Απόσταση';

  @override
  String get trajetDetailFieldDuration => 'Διάρκεια';

  @override
  String get trajetDetailFieldAvgConsumption => 'Μέση κατανάλωση';

  @override
  String get trajetDetailFieldFuelUsed => 'Καύσιμο που χρησιμοποιήθηκε';

  @override
  String get trajetDetailFieldFuelCost => 'Κόστος καυσίμου';

  @override
  String get trajetDetailFieldAvgSpeed => 'Μέση ταχύτητα';

  @override
  String get trajetDetailFieldMaxSpeed => 'Μέγιστη ταχύτητα';

  @override
  String get trajetDetailFieldValueUnknown => '—';

  @override
  String get trajetDetailChartSpeed => 'Ταχύτητα (km/h)';

  @override
  String get trajetDetailChartFuelRate => 'Ροή καυσίμου (L/h)';

  @override
  String get trajetDetailChartRpm => 'RPM';

  @override
  String get trajetDetailChartEngineLoad => 'Φόρτωση κινητήρα (%)';

  @override
  String get trajetDetailChartsSection => 'Γραφήματα';

  @override
  String get trajetsRowColdStartChip => 'Ψυχρή εκκίνηση';

  @override
  String get trajetsRowColdStartTooltip =>
      'Ο κινητήρας δεν έφτασε σε θερμοκρασία λειτουργίας κατά τη διάρκεια αυτού του ταξιδιού — η κατανάλωση καυσίμου ήταν υψηλότερη από το συνηθισμένο.';

  @override
  String get trajetDetailChartEmpty => 'Δεν καταγράφηκαν δείγματα';

  @override
  String get trajetDetailShareAction => 'Κοινοποίηση';

  @override
  String trajetDetailShareSubject(String date) {
    return 'Sparkilo — ταξίδι στις $date';
  }

  @override
  String get trajetDetailShareError =>
      'Αδύνατη δημιουργία εικόνας κοινοποίησης';

  @override
  String get trajetDetailDeleteAction => 'Διαγραφή';

  @override
  String get trajetDetailDeleteConfirmTitle => 'Διαγραφή αυτού του ταξιδιού;';

  @override
  String get trajetDetailDeleteConfirmBody =>
      'Αυτό το ταξίδι θα αφαιρεθεί μόνιμα από το ιστορικό σας.';

  @override
  String get trajetDetailDeleteConfirmCancel => 'Ακύρωση';

  @override
  String get trajetDetailDeleteConfirmConfirm => 'Διαγραφή';

  @override
  String get tripRecordingObd2NotResponding =>
      'Ο προσαρμογέας OBD2 είναι συνδεδεμένος αλλά δεν επιστρέφει δεδομένα. Δοκιμάστε διαφορετικό προσαρμογέα ή ελέγξτε το πρωτόκολλο διαγνωστικού του οχήματος.';

  @override
  String get tripLengthCardTitle => 'Κατανάλωση ανά μήκος ταξιδιού';

  @override
  String get tripLengthBucketShort => 'Σύντομο (<5 km)';

  @override
  String get tripLengthBucketMedium => 'Μεσαίο (5–25 km)';

  @override
  String get tripLengthBucketLong => 'Μεγάλο (>25 km)';

  @override
  String get tripLengthBucketNeedMoreData => 'Απαιτούνται περισσότερα δεδομένα';

  @override
  String tripLengthBucketTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ταξίδια',
      one: '1 ταξίδι',
      zero: 'κανένα ταξίδι',
    );
    return '$_temp0';
  }

  @override
  String get tripPathCardTitle => 'Διαδρομή ταξιδιού';

  @override
  String get tripPathCardSubtitle => 'Διαδρομή καταγεγραμμένη με GPS';

  @override
  String get tripPathLegendTitle => 'Κατανάλωση';

  @override
  String get tripPathLegendEfficient => 'Αποδοτική (< 6 L/100km)';

  @override
  String get tripPathLegendBorderline => 'Οριακή (6–10 L/100km)';

  @override
  String get tripPathLegendWasteful => 'Σπάταλη (≥ 10 L/100km)';

  @override
  String get tripRecordingPinTooltip =>
      'Η καρφίτσωση κρατά την οθόνη αναμμένη — χρησιμοποιεί περισσότερη μπαταρία';

  @override
  String get tripRecordingPinSemanticOn => 'Αποκαρφίτσωση φόρμας καταγραφής';

  @override
  String get tripRecordingPinSemanticOff => 'Καρφίτσωση φόρμας καταγραφής';

  @override
  String get tripRecordingPinHelpTooltip => 'Τι κάνει η καρφίτσωση;';

  @override
  String get tripRecordingPinHelpTitle => 'Σχετικά με την καρφίτσωση';

  @override
  String get tripRecordingPinHelpBody =>
      'Η καρφίτσωση κρατά την οθόνη αναμμένη και αποκρύπτει τις γραμμές συστήματος ώστε η φόρμα να παραμένει αναγνώσιμη σε βάση ταμπλό. Πατήστε ξανά για απελευθέρωση. Απελευθερώνεται αυτόματα όταν σταματά το ταξίδι.';

  @override
  String get tripRecordingResumeHintMessage =>
      'Η καταγραφή συνεχίζεται στο παρασκήνιο. Πατήστε το κόκκινο banner στην κορυφή οποιασδήποτε οθόνης για επιστροφή.';

  @override
  String get tripBannerOpenFromConsumptionTab =>
      'Ανοίξτε το ενεργό ταξίδι από την καρτέλα Κατανάλωση';

  @override
  String get tripRecordingUnpinnedWarning =>
      'Καρφιτσώστε την οθόνη για να διατηρείτε το GPS ενεργό κατά τη διάρκεια του ταξιδιού — Το Android μπορεί να περιορίσει το GPS κατά την αδρανοποίηση.';

  @override
  String get tripRecordingMinimiseTooltip => 'Σμίκρυνση σε πλωτό πλακίδιο';

  @override
  String get unifiedFilterFuel => 'Καύσιμο';

  @override
  String get unifiedFilterEv => 'EV';

  @override
  String get unifiedFilterBoth => 'Και τα δύο';

  @override
  String get unifiedNoResultsForFilter =>
      'Δεν υπάρχουν αποτελέσματα για αυτό το φίλτρο';

  @override
  String get searchFailedSnackbar =>
      'Αποτυχία αναζήτησης — παρακαλώ δοκιμάστε ξανά';

  @override
  String get vinLabel => 'VIN (προαιρετικό)';

  @override
  String get vinDecodeTooltip => 'Αποκωδικοποίηση VIN';

  @override
  String get vinConfirmAction => 'Ναι, αυτόματη συμπλήρωση';

  @override
  String get vinModifyAction => 'Χειροκίνητη τροποποίηση';

  @override
  String get veResetAction => 'Επαναφορά ογκομετρικής απόδοσης';

  @override
  String get vehicleReadVinFromCarButton => 'Ανάγνωση VIN από αυτοκίνητο';

  @override
  String get vehicleReadVinFromCarTooltip =>
      'Ανάγνωση VIN από συζευγμένο προσαρμογέα OBD2';

  @override
  String get vehicleReadVinFailedUnsupportedSnackbar =>
      'VIN μη διαθέσιμο (Mode 09 PID 02 δεν υποστηρίζεται σε οχήματα πριν το 2005)';

  @override
  String get vehicleReadVinFailedGenericSnackbar =>
      'Αποτυχία ανάγνωσης VIN — παρακαλώ εισάγετε χειροκίνητα';

  @override
  String get vehicleReadVinNoAdapterHint =>
      'Συζεύξτε πρώτα έναν προσαρμογέα OBD2 για αυτόματη ανάγνωση VIN';

  @override
  String get pickerButtonLabel => 'Επιλογή από κατάλογο';

  @override
  String get pickerSearchHint => 'Αναζήτηση μάρκας ή μοντέλου';

  @override
  String get pickerHelpText => 'Προεπλήρωση από 50+ υποστηριζόμενα οχήματα';

  @override
  String get pickerEmptyResults => 'Δεν βρέθηκαν αποτελέσματα';

  @override
  String get pickerCancel => 'Ακύρωση';

  @override
  String get pickerLoading => 'Φόρτωση καταλόγου…';

  @override
  String get vinInfoTooltip => 'Τι είναι το VIN;';

  @override
  String get vinInfoSectionWhatTitle => 'Τι είναι το VIN;';

  @override
  String get vinInfoSectionWhatBody =>
      'Ο Αριθμός Αναγνώρισης Οχήματος είναι ένας κωδικός 17 χαρακτήρων μοναδικός για το αυτοκίνητό σας. Είναι σφραγισμένος στο πλαίσιο και τυπωμένος στην άδεια κυκλοφορίας σας.';

  @override
  String get vinInfoSectionWhyTitle => 'Γιατί το ζητάμε';

  @override
  String get vinInfoSectionWhyBody =>
      'Η αποκωδικοποίηση του VIN προσυμπληρώνει αυτόματα κυβισμό κινητήρα, αριθμό κυλίνδρων, έτος κατασκευής, κύριο τύπο καυσίμου και μικτό βάρος — εξοικονομώντας σας την αναζήτηση τεχνικών χαρακτηριστικών. Ο υπολογισμός ροής καυσίμου OBD2 χρησιμοποιεί αυτές τις τιμές για ακριβή αριθμό κατανάλωσης.';

  @override
  String get vinInfoSectionPrivacyTitle => 'Απόρρητο';

  @override
  String get vinInfoSectionPrivacyBody =>
      'Το VIN σας αποθηκεύεται μόνο τοπικά στην κρυπτογραφημένη αποθήκευση της εφαρμογής — δεν μεταφορτώνεται ποτέ στους διακομιστές Sparkilo. Η βάση δεδομένων NHTSA vPIC υποβάλλεται σε ερώτημα με το VIN αλλά επιστρέφει μόνο ανώνυμες τεχνικές προδιαγραφές· η NHTSA δεν συνδέει το VIN με προσωπικά δεδομένα. Χωρίς δίκτυο, η αναζήτηση εκτός σύνδεσης επιστρέφει μόνο κατασκευαστή και χώρα.';

  @override
  String get vinInfoSectionWhereTitle => 'Πού να το βρείτε';

  @override
  String get vinInfoSectionWhereBody =>
      'Κοιτάξτε μέσα από το παρμπρίζ στην κάτω αριστερή γωνία στην πλευρά του οδηγού, ελέγξτε το αυτοκόλλητο στο πλαίσιο της πόρτας οδηγού όταν είναι ανοιχτή, ή διαβάστε το από την άδεια κυκλοφορίας σας.';

  @override
  String get vinInfoDismiss => 'Κατάλαβα';

  @override
  String get vinConfirmPrivacyNote =>
      'Αναζητήσαμε το VIN σας στη δωρεάν βάση δεδομένων οχημάτων της NHTSA — τίποτα δεν στάλθηκε στους διακομιστές Sparkilo.';

  @override
  String get gdprVinOnlineDecodeTitle => 'Αποκωδικοποίηση VIN online';

  @override
  String get gdprVinOnlineDecodeShort =>
      'Αποκωδικοποίηση VIN μέσω της δωρεάν δημόσιας υπηρεσίας NHTSA';

  @override
  String get gdprVinOnlineDecodeDescription =>
      'Όταν συζεύγνυτε έναν προσαρμογέα, το VIN του οχήματός σας διαβάζεται τοπικά για αναγνώριση του αυτοκινήτου. Ενεργοποιώντας αυτό αποστέλλεται το 17-χαρακτηρο VIN στη δωρεάν υπηρεσία vPIC της NHTSA για αναζήτηση πρόσθετων στοιχείων (μοντέλο, κυβισμός, τύπος καυσίμου). Το VIN είναι τα μόνα δεδομένα που αποστέλλονται — καμία άλλη πληροφορία δεν φεύγει από τη συσκευή σας.';

  @override
  String get vehicleDetectedFromVinBadge => '(ανιχνεύτηκε)';

  @override
  String vehicleDetectedFromVinSnackbar(String summary) {
    return 'Ανιχνεύτηκε από VIN: $summary. Εφαρμογή;';
  }

  @override
  String get vehicleDetectedFromVinApply => 'Εφαρμογή';

  @override
  String waitTimeHint(int minutes) {
    return '~$minutes λεπτά αναμονή';
  }

  @override
  String get waitTimeTrackStart => 'Παρακολούθηση αναμονής μου';

  @override
  String get waitTimeTrackEnd => 'Φεύγω';

  @override
  String waitTimeElapsedShort(int minutes) {
    return '$minutes λεπτά μέχρι τώρα';
  }

  @override
  String get widgetHelpSectionTitle => 'Widget αρχικής οθόνης';

  @override
  String get widgetHelpIntro =>
      'Προσθέστε το widget SparKilo στην αρχική οθόνη σας για εμφάνιση τιμών καυσίμων και φόρτισης με μια ματιά.';

  @override
  String get widgetHelpAdd =>
      'Προσθέστε το από τον επιλογέα widget του launcher — πατήστε παρατεταμένα σε κενή περιοχή της αρχικής οθόνης, επιλέξτε Widget και βρείτε το SparKilo.';

  @override
  String get widgetHelpTap =>
      'Πατήστε σταθμό στο widget για άνοιγμά του στην εφαρμογή. Πατήστε το εικονίδιο ανανέωσης για ενημέρωση τιμών.';

  @override
  String get widgetHelpConfigure =>
      'Στο Android, πατήστε παρατεταμένα το widget και επιλέξτε Επαναρύθμιση για αλλαγή προφίλ, χρώματος και περιεχομένου.';

  @override
  String get widgetVariantDefault => 'Μόνο τρέχουσα τιμή';

  @override
  String get widgetVariantPredictive =>
      'Προβλεπτικό: καλύτερη στιγμή για ανεφοδιασμό';

  @override
  String get widgetPredictiveNowPrefix => 'τώρα';
}
