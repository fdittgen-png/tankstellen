class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://creativecommons.tankerkoenig.de/json';

  static const String listEndpoint = '/list.php';
  static const String detailEndpoint = '/detail.php';
  static const String pricesEndpoint = '/prices.php';
  static const String complaintEndpoint = '/complaint.php';

  static const int maxRadiusKm = 25;
  static const int defaultRadiusKm = 10;
  static const int maxPriceQueryIds = 10;
  static const Duration minRefreshInterval = Duration(minutes: 5);

  /// Test coordinates (Berlin city center) used for API key validation.
  /// When validating a Tankerkoenig API key, we make a minimal search
  /// at these coordinates to verify the key works.
  static const double testLatitude = 52.521;
  static const double testLongitude = 13.438;
}
