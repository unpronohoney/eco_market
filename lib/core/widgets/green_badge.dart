import 'package:flutter/material.dart';
import 'package:eco_market/core/constants/app_colors.dart';

/// Green Badge widget for displaying discount/expiry information
/// Used on products nearing expiry date to highlight savings
class GreenBadge extends StatelessWidget {
  final int discountRate;
  final bool isLastDay;

  const GreenBadge({
    super.key,
    required this.discountRate,
    this.isLastDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.markerShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            isLastDay ? 'Son Gün!' : '%$discountRate',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of GreenBadge for list items
class GreenBadgeCompact extends StatelessWidget {
  final int discountRate;

  const GreenBadgeCompact({super.key, required this.discountRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '%$discountRate İndirim',
        style: const TextStyle(
          color: AppColors.primaryGreenDark,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
