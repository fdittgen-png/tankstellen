class AppConstants {
  AppConstants._();

  static const String appName = 'Fuel Prices';
  static const String appVersion = '4.0.0';
  static const String appPackage = 'de.tankstellen.app';

  // Developer / Publisher
  static const String developerName = 'Florian DITTGEN';
  static const String developerEmail = 'fdittgen@gmail.com';
  static const String developerWebsite =
      'https://github.com/fdittgen-png/tankstellen';

  /// Shared User-Agent for all HTTP clients.
  static const String userAgent = '$appPackage/$appVersion';

  static const double defaultSearchRadiusKm = 10.0;
  static const double maxSearchRadiusKm = 25.0;
  static const double minSearchRadiusKm = 1.0;

  static const Duration minAutoRefreshInterval = Duration(minutes: 5);
  static const Duration refreshJitterMax = Duration(seconds: 30);

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = userAgent;

  static const String tankerkoenigAttribution =
      'Daten von Tankerkoenig.de (CC BY 4.0)';
  static const String osmAttribution =
      '\u00a9 OpenStreetMap contributors';

  static const String tankerkoenigRegistrationUrl =
      'https://creativecommons.tankerkoenig.de/';

  static const String privacyPolicyUrl =
      'https://github.com/fdittgen-png/tankstellen/blob/master/PRIVACY.md';

  // Donation links
  static const String paypalUrl = 'https://www.paypal.me/FlorianDITTGEN';
  static const String revolutUrl = 'https://revolut.me/floriamcep';

  // GitHub project
  static const String githubRepoUrl =
      'https://github.com/fdittgen-png/tankstellen';
  static const String githubIssuesUrl =
      'https://github.com/fdittgen-png/tankstellen/issues';

  /// Sentinel value for price sorting when a station has no price for the selected fuel.
  /// Ensures stations without prices sort to the bottom of the list.
  static const double noPriceSentinel = 999.0;
}
