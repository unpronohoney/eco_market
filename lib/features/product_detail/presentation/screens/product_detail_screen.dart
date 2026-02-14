import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/providers/auth_provider.dart';
import 'package:eco_market/core/providers/reservations_provider.dart';
import 'package:eco_market/data/models/product_model.dart';
import 'package:eco_market/core/widgets/green_badge.dart';
import 'dart:async';

/// Product Detail Screen with countdown timer and reserve action
class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final String marketName;
  final String marketId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.marketName,
    required this.marketId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final expiry = widget.product.expiryDate;
    if (expiry.isAfter(now)) {
      _timeRemaining = expiry.difference(now);
    } else {
      _timeRemaining = Duration.zero;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get _isUrgent => _timeRemaining.inHours < 1;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isReserved = ref.watch(
      reservationsProvider.select(
        (list) =>
            list.any((r) => r.productId == widget.product.id && r.isActive),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.marketName,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Hero Product Image
                  Hero(
                    tag: 'product_${widget.product.id}',
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.product.imageEmoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Product Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (widget.product.description != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        widget.product.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Countdown Timer Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: _isUrgent
                                  ? AppColors.discountRed
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Son Kullanma:',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isUrgent
                                    ? AppColors.discountRed
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_timeRemaining),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: _isUrgent
                                ? AppColors.discountRed
                                : AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (_isUrgent)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.discountRed.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '⚡ Acele et!',
                              style: TextStyle(
                                color: AppColors.discountRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Price Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Original Price
                        Text(
                          widget.product.formattedOriginalPrice,
                          style: const TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        // Discounted Price
                        Text(
                          widget.product.formattedDiscountedPrice,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Badge
                        GreenBadge(
                          discountRate: widget.product.discountRate,
                          isLastDay: widget.product.isExpiringToday,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector + Stock Info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Stock indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stokta Kalan:',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.product.stock > 0
                                    ? AppColors.primaryGreenLight
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.product.stock > 0
                                    ? '${widget.product.stock} adet'
                                    : 'Tükendi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.product.stock > 0
                                      ? AppColors.primaryGreen
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.product.stock > 0) ...[
                          const SizedBox(height: 16),
                          // Quantity row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Minus
                              Material(
                                color: _quantity > 1
                                    ? AppColors.primaryGreenLight
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      Icons.remove,
                                      color: _quantity > 1
                                          ? AppColors.primaryGreen
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              // Count
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '$_quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              // Plus
                              Material(
                                color: _quantity < widget.product.stock
                                    ? AppColors.primaryGreenLight
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _quantity < widget.product.stock
                                      ? () => setState(() => _quantity++)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      Icons.add,
                                      color: _quantity < widget.product.stock
                                          ? AppColors.primaryGreen
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Dynamic totals
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '₺${(widget.product.savings * _quantity).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const Text(
                                    'Kazanç',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${widget.product.points * _quantity}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const Text(
                                    'Puan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${(widget.product.co2Saved * _quantity).toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const Text(
                                    'CO₂ Tasarruf',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 120), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),

      // Reserve FAB
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 60,
        child: FloatingActionButton.extended(
          onPressed: (isReserved || widget.product.stock == 0)
              ? null
              : isLoggedIn
              ? () => _showReserveDialog(context)
              : () => _showLoginRequiredDialog(context),
          backgroundColor: (isReserved || widget.product.stock == 0)
              ? AppColors.textSecondary
              : isLoggedIn
              ? AppColors.primaryGreen
              : Colors.orange,
          elevation: (isReserved || widget.product.stock == 0) ? 0 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReserved
                    ? Icons.check_circle
                    : widget.product.stock == 0
                    ? Icons.remove_shopping_cart
                    : isLoggedIn
                    ? Icons.bookmark_add
                    : Icons.lock_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isReserved
                    ? 'AYIRTILDI'
                    : widget.product.stock == 0
                    ? 'TÜKENDİ'
                    : isLoggedIn
                    ? 'AYIRT ($_quantity ADET) - ₺${(widget.product.discountedPrice * _quantity).toStringAsFixed(0)}'
                    : 'GİRİŞ YAP VE AYIRT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showReserveDialog(BuildContext context) async {
    // Reserve product using transaction with quantity
    final error = await ref
        .read(reservationsProvider.notifier)
        .reserveProduct(
          product: widget.product,
          marketName: widget.marketName,
          marketId: widget.marketId,
          quantity: _quantity,
        );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Ürün Ayırtıldı! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                '${widget.product.name} başarıyla ayırtıldı.\nKasada QR kodunu gösterin.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Giriş Yapmanız Gerekiyor',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            const Text(
              'Ürün ayırtmak için hesabınıza giriş yapın.\nÜcretsiz üye olun ve avantajlardan yararlanın!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Quick login for demo
                  await ref.read(authProvider.notifier).quickLogin();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Giriş yapıldı! Artık ayırtabilirsiniz.'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Giriş Yap / Üye Ol',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Daha Sonra',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
