import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/constants/app_constants.dart';
import 'package:eco_market/data/models/market_model.dart';

/// Map widget using flutter_map (OpenStreetMap)
/// Displays market locations as custom green markers with radius circle
class MarketMap extends StatelessWidget {
  final List<MarketModel> markets;
  final Function(MarketModel) onMarkerTapped;
  final MarketModel? selectedMarket;
  final MapController? mapController;
  final LatLng? userLocation;
  final double searchRadiusKm;

  const MarketMap({
    super.key,
    required this.markets,
    required this.onMarkerTapped,
    this.selectedMarket,
    this.mapController,
    this.userLocation,
    this.searchRadiusKm = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter:
            userLocation ??
            LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
        initialZoom: AppConstants.defaultZoom,
        minZoom: AppConstants.minZoom,
        maxZoom: AppConstants.maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: AppConstants.mapTileUrl,
          userAgentPackageName: 'com.ecomarket.app',
          maxZoom: 19,
        ),

        // Radius Circle Layer
        if (userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: userLocation!,
                radius: searchRadiusKm * 1000, // Convert km to meters
                useRadiusInMeter: true,
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.6),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // Market Markers Layer
        MarkerLayer(
          markers: [
            // User location blue dot
            if (userLocation != null)
              Marker(
                point: userLocation!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            // Market markers
            ...markets.map((market) => _buildMarker(market)),
          ],
        ),
      ],
    );
  }

  /// Build a custom marker for each market
  Marker _buildMarker(MarketModel market) {
    final isSelected = selectedMarket?.id == market.id;

    return Marker(
      point: LatLng(market.latitude, market.longitude),
      width: isSelected ? 65 : 55,
      height: isSelected ? 78 : 68,
      child: GestureDetector(
        onTap: () => onMarkerTapped(market),
        child: _MarkerWidget(market: market, isSelected: isSelected),
      ),
    );
  }
}

/// Custom marker widget with animation
class _MarkerWidget extends StatelessWidget {
  final MarketModel market;
  final bool isSelected;

  const _MarkerWidget({required this.market, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge count pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.markerShadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${market.greenBadgeCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 1),
        // Main marker pin
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 44 : 38,
          height: isSelected ? 44 : 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.primaryGreenLight,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.markerShadow
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              market.imageEmoji,
              style: TextStyle(fontSize: isSelected ? 20 : 17),
            ),
          ),
        ),
        // Triangle pointer
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(
            color: isSelected ? AppColors.primaryGreen : Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Triangle painter for marker pointer
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
