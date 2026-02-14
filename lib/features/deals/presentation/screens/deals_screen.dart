import 'package:eco_market/features/market_detail/presentation/screens/market_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/repositories/market_repository.dart';
import 'package:eco_market/data/models/market_model.dart';
import 'package:eco_market/data/models/product_model.dart';
import 'package:eco_market/core/widgets/green_badge.dart';
import 'package:eco_market/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:eco_market/features/home/providers/home_provider.dart';

/// Deals List Screen (Tab 2: Fırsatlar)
/// Shows all markets and their Green Badge products in a scrollable list
class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsAsync = ref.watch(marketsStreamProvider);
    final nearbyMarketIds = ref.watch(nearbyMarketIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: marketsAsync.when(
        data: (allMarkets) {
          // Filter to only nearby markets
          final markets = allMarkets
              .where((m) => nearbyMarketIds.contains(m.id))
              .toList();
          return _buildContent(context, ref, markets);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Veriler yüklenemedi'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(marketsStreamProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<MarketModel> markets,
  ) {
    final totalDeals = markets.fold(0, (sum, m) => sum + m.greenBadgeCount);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate the stream to force refresh
        ref.invalidate(marketsStreamProvider);
        // Wait a bit for the new data
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primaryGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  const Text(
                    '🌿 Fırsatlar',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      '$totalDeals',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (markets.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 60,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz market eklenmemiş',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aşağı çekerek yenileyin',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _MarketCard(market: markets[index]);
                }, childCount: markets.length),
              ),
            ),

          // Bottom padding for nav bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

/// Market card widget showing market info and horizontal product list
class _MarketCard extends ConsumerWidget {
  final MarketModel market;

  const _MarketCard({required this.market});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use real-time stream for products
    final productsAsync = ref.watch(productsStreamProvider(market.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market Header
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketDetailScreen(market: market),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Market Emoji Avatar
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
                  const SizedBox(width: 14),

                  // Market Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
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

                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          market.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Products Section with real-time stream
          productsAsync.when(
            data: (allProducts) {
              final greenBadgeProducts = allProducts
                  .where((p) => p.isGreenBadge)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        const Text('🌿', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '${greenBadgeProducts.length} Fırsat Ürünü',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Horizontal Product List
                  if (greenBadgeProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Henüz ürün eklenmemiş',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: greenBadgeProducts.length,
                        itemBuilder: (context, index) {
                          return _ProductChip(
                            product: greenBadgeProducts[index],
                            marketName: market.name,
                            marketId: market.id,
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ürünler yüklenemedi'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact product chip for horizontal scrolling
class _ProductChip extends StatelessWidget {
  final ProductModel product;
  final String marketName;
  final String marketId;

  const _ProductChip({
    required this.product,
    required this.marketName,
    required this.marketId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
              marketName: marketName,
              marketId: marketId,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(product.imageEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),

            // Name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.formattedOriginalPrice,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  product.formattedDiscountedPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Badge
            GreenBadgeCompact(discountRate: product.discountRate),
          ],
        ),
      ),
    );
  }
}
