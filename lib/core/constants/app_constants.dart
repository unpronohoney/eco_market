/// Application-wide constants for EcoMarket
class AppConstants {
  AppConstants._();

  // Default map center - Beşiktaş, Istanbul
  static const double defaultLatitude = 41.0422;
  static const double defaultLongitude = 29.0067;
  static const double defaultZoom = 14.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;

  // Map tile URL (OpenStreetMap)
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // App Info
  static const String appName = 'EcoMarket';
  static const String appTagline = 'Gıda israfını önle, tasarruf et!';

  // Bottom Sheet
  static const double bottomSheetMinHeight = 0.35;
  static const double bottomSheetMaxHeight = 0.85;
  static const double bottomSheetInitialHeight = 0.45;
}
