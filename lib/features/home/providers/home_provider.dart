import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:eco_market/data/models/market_model.dart';
import 'package:eco_market/core/repositories/market_repository.dart';

/// Provider for all available markets from Firestore
final marketsProvider = Provider<List<MarketModel>>((ref) {
  final marketsAsync = ref.watch(marketsStreamProvider);
  return marketsAsync.when(
    data: (markets) => markets,
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Search radius in km (default: 5 km)
final searchRadiusProvider = StateProvider<double>((ref) => 5.0);

/// User's current location (defaults to Istanbul center if GPS unavailable)
final userLocationProvider = StateProvider<LatLng?>((ref) {
  return const LatLng(41.0082, 28.9784); // Istanbul default
});

/// Nearby markets filtered by distance from user location
final nearbyMarketsProvider = Provider<List<MarketModel>>((ref) {
  final allMarkets = ref.watch(marketsProvider);
  final userLocation = ref.watch(userLocationProvider);
  final radiusKm = ref.watch(searchRadiusProvider);

  if (userLocation == null) return allMarkets;

  final radiusMeters = radiusKm * 1000;

  // Calculate distance for each market and filter
  final marketsWithDistance = <MapEntry<MarketModel, double>>[];

  for (final market in allMarkets) {
    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      market.latitude,
      market.longitude,
    );
    if (distance <= radiusMeters) {
      marketsWithDistance.add(MapEntry(market, distance));
    }
  }

  // Sort by distance (closest first)
  marketsWithDistance.sort((a, b) => a.value.compareTo(b.value));

  return marketsWithDistance.map((e) => e.key).toList();
});

/// Provider for the currently selected market
final selectedMarketProvider = StateProvider<MarketModel?>((ref) {
  return null;
});

/// Provider to track if bottom sheet is open
final isBottomSheetVisibleProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for map zoom level
final mapZoomProvider = StateProvider<double>((ref) {
  return 14.0;
});

/// Derived provider: Nearby markets with Green Badge products
final marketsWithDealsProvider = Provider<List<MarketModel>>((ref) {
  final markets = ref.watch(nearbyMarketsProvider);
  return markets.where((m) => m.hasDiscountedProducts).toList();
});

/// Derived provider: Total number of deals in nearby markets
final totalDealsProvider = Provider<int>((ref) {
  final markets = ref.watch(nearbyMarketsProvider);
  return markets.fold(0, (sum, m) => sum + m.greenBadgeCount);
});

/// Set of nearby market IDs (for filtering products in Deals screen)
final nearbyMarketIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(nearbyMarketsProvider).map((m) => m.id).toSet();
});
