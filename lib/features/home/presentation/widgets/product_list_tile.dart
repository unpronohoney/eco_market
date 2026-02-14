import 'package:flutter/material.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/data/models/product_model.dart';
import 'package:eco_market/core/widgets/green_badge.dart';

/// Product list tile widget for the bottom sheet
/// Displays product with image, name, prices, and Green Badge
class ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
  });

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
            color: product.isGreenBadge
                ? AppColors.primaryGreen.withValues(alpha: 0.2)
                : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Product Emoji/Image
            Container(
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
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
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
                  const SizedBox(height: 4),

                  // Description
                  if (product.description != null)
                    Text(
                      product.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),

                  // Prices Row
                  Row(
                    children: [
                      // Original Price (strikethrough)
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
                      // Discounted Price
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
            if (product.isGreenBadge) ...[
              const SizedBox(width: 8),
              GreenBadgeCompact(discountRate: product.discountRate),
            ],
          ],
        ),
      ),
    );
  }
}
