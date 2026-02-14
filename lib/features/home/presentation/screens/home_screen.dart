import 'package:eco_market/core/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/constants/app_constants.dart';
import 'package:eco_market/core/repositories/market_repository.dart';
import 'package:eco_market/data/models/market_model.dart';
import 'package:eco_market/features/home/providers/home_provider.dart';
import 'package:eco_market/features/home/presentation/widgets/market_map.dart';
import 'package:eco_market/features/market_detail/presentation/screens/market_detail_screen.dart';
import 'package:eco_market/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:eco_market/core/widgets/green_badge.dart';

/// Main Home Screen with full-screen map and interactive markers
/// Shows market locations and opens draggable bottom sheet on marker tap
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Request GPS and save user location
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 5),
        );
        if (mounted) {
          ref.read(userLocationProvider.notifier).state = LatLng(
            position.latitude,
            position.longitude,
          );
        }
      }
    } catch (_) {
      // Keep default Istanbul location on timeout or error
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyMarkets = ref.watch(nearbyMarketsProvider);
    final selectedMarket = ref.watch(selectedMarketProvider);
    final totalDeals = ref.watch(totalDealsProvider);
    final userLocation = ref.watch(userLocationProvider);
    final searchRadius = ref.watch(searchRadiusProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Map
          MarketMap(
            markets: nearbyMarkets,
            selectedMarket: selectedMarket,
            mapController: _mapController,
            onMarkerTapped: (market) => _onMarkerTapped(context, market),
            userLocation: userLocation,
            searchRadiusKm: searchRadius,
          ),

          // Top Overlay: App Branding, Deals Count & Radius Slider
          _buildTopOverlay(totalDeals),

          // Zoom Controls (bottom-right)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // My Location
                FloatingActionButton(
                  heroTag: 'location',
                  mini: false,
                  onPressed: _centerOnUserLocation,
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(
                    Icons.my_location,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                // Zoom In
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom + 1).clamp(
                        AppConstants.minZoom,
                        AppConstants.maxZoom,
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.add, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                // Zoom Out
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom - 1).clamp(
                        AppConstants.minZoom,
                        AppConstants.maxZoom,
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.remove, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(int totalDeals) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // App Logo/Name
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'EcoMarket',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Deals Count Badge + Refresh Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Refresh Button
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  child: InkWell(
                    onTap: () {
                      ref.invalidate(marketsStreamProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veriler yenileniyor...'),
                          duration: Duration(seconds: 1),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Deals Count Badge
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  child: InkWell(
                    onTap: () => ref.read(currentTabProvider.notifier).state =
                        NavTab.deals,

                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreenLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_offer,
                              size: 14,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$totalDeals Fırsat',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Radius Slider
            _buildRadiusSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSlider() {
    final radius = ref.watch(searchRadiusProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.primaryGreen, size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primaryGreen,
                inactiveTrackColor: AppColors.primaryGreenLight,
                thumbColor: AppColors.primaryGreen,
                overlayColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                valueIndicatorColor: AppColors.primaryGreen,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: radius,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${radius.toInt()} km',
                onChanged: (value) {
                  ref.read(searchRadiusProvider.notifier).state = value;
                },
              ),
            ),
          ),
          Text(
            '${radius.toInt()} km',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _onMarkerTapped(BuildContext context, MarketModel market) {
    ref.read(selectedMarketProvider.notifier).state = market;

    // Animate map to the selected marker
    _mapController.move(LatLng(market.latitude, market.longitude), 15.0);

    // Show draggable bottom sheet
    _showMarketBottomSheet(context, market);
  }

  void _showMarketBottomSheet(BuildContext context, MarketModel market) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => _DraggableMarketSheet(
        market: market,
        onClose: () {
          Navigator.pop(context);
          ref.read(selectedMarketProvider.notifier).state = null;
        },
        onMarketTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketDetailScreen(market: market),
            ),
          );
        },
        onProductTap: (product) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: product,
                marketName: market.name,
                marketId: market.id,
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      ref.read(selectedMarketProvider.notifier).state = null;
    });
  }

  void _centerOnUserLocation() {
    final userLocation = ref.read(userLocationProvider);
    if (userLocation != null) {
      _mapController.move(userLocation, 14.0);
    } else {
      _mapController.move(
        LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
        AppConstants.defaultZoom,
      );
    }
  }
}

/// Draggable bottom sheet for market details
class _DraggableMarketSheet extends StatelessWidget {
  final MarketModel market;
  final VoidCallback onClose;
  final VoidCallback onMarketTap;
  final Function(dynamic) onProductTap;

  const _DraggableMarketSheet({
    required this.market,
    required this.onClose,
    required this.onMarketTap,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final greenBadgeProducts = market.greenBadgeProducts;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Drag Handle + Market Header (all draggable)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Market Header
                    _buildMarketHeader(context),
                    const Divider(height: 1),
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '🌿',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Fırsat Ürünleri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${greenBadgeProducts.length} Ürün',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Products List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = greenBadgeProducts[index];
                    return _ProductListTile(
                      product: product,
                      onTap: () => onProductTap(product),
                    );
                  }, childCount: greenBadgeProducts.length),
                ),
              ),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketHeader(BuildContext context) {
    return InkWell(
      onTap: onMarketTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Market Emoji
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  market.imageEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Market Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          market.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          market.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rating Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    market.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Product list tile for bottom sheet
class _ProductListTile extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _ProductListTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Product Emoji/Image with Hero
            Hero(
              tag: 'product_${product.id}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    product.imageEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        product.formattedOriginalPrice,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.formattedDiscountedPrice,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Green Badge
            GreenBadgeCompact(discountRate: product.discountRate),
          ],
        ),
      ),
    );
  }
}
