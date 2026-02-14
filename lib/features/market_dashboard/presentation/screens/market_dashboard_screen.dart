import 'package:eco_market/features/market_dashboard/presentation/screens/help_screen.dart';
import 'package:eco_market/features/market_dashboard/presentation/screens/notification_list_screen.dart';
import 'package:eco_market/features/market_dashboard/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/providers/auth_provider.dart';
import 'package:eco_market/core/providers/reservations_provider.dart';
import 'package:eco_market/data/models/product_model.dart';
import 'package:eco_market/features/market_dashboard/presentation/widgets/add_product_sheet.dart';
import 'package:eco_market/features/main/presentation/screens/main_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Market Dashboard Screen - Store management panel with real-time Firebase integration
class MarketDashboardScreen extends ConsumerStatefulWidget {
  const MarketDashboardScreen({super.key});

  @override
  ConsumerState<MarketDashboardScreen> createState() =>
      _MarketDashboardScreenState();
}

class _MarketDashboardScreenState extends ConsumerState<MarketDashboardScreen> {
  String _marketId = '';
  String _marketName = 'Mağaza Paneli';
  String _marketEmoji = '🏪';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMarketId();
    });
  }

  /// Initialize market ID from current user
  Future<void> _initMarketId() async {
    final currentUser = ref.read(authProvider).user;

    if (currentUser?.isMarket == true && currentUser != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('markets')
            .doc(currentUser.uid)
            .get();

        String fetchedName = 'Mağazam'; // Varsayılan isim

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          fetchedName = data?['name'] as String? ?? 'İsimsiz Market';
        }
        if (mounted) {
          setState(() {
            _marketId = currentUser.uid;
            _marketName = fetchedName;
          });
        }
      } catch (e) {
        print("Market ismi çekilemedi: $e");
      }
    }
  }

  /// Get products stream for real-time updates
  Stream<List<ProductModel>> get _productsStream {
    if (_marketId.isEmpty) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('products')
        .where('marketId', isEqualTo: _marketId)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          // Sort: active first, then by name
          products.sort((a, b) {
            if (a.isActive != b.isActive) {
              return a.isActive ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          });
          return products;
        });
  }

  /// Get completed reservations stream for real-time stats
  Stream<List<Map<String, dynamic>>> get _completedReservationsStream {
    if (_marketId.isEmpty) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('marketId', isEqualTo: _marketId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  /// Calculate weekly chart data from completed reservations
  Map<int, double> _getWeeklyRevenueData(
    List<Map<String, dynamic>> reservations,
  ) {
    final weeklyData = <int, double>{};
    for (int i = 0; i < 7; i++) {
      weeklyData[i] = 0;
    }

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final res in reservations) {
      final completedAt = res['completedAt'];
      if (completedAt == null) continue;

      DateTime date;
      if (completedAt is Timestamp) {
        date = completedAt.toDate();
      } else {
        continue;
      }

      if (date.isAfter(sevenDaysAgo)) {
        final dayIndex = date.weekday - 1; // 0-6 for Mon-Sun
        final price = (res['discountedPrice'] as num?)?.toDouble() ?? 0.0;
        weeklyData[dayIndex] = (weeklyData[dayIndex] ?? 0) + price;
      }
    }

    return weeklyData;
  }

  /// Soft delete product (set isActive to false)
  Future<void> _softDeleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ürünü Arşivle'),
        content: Text(
          '${product.name} ürünü arşive taşınacak. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Arşivle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({'isActive': false});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün arşive taşındı'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Quick stock increment (+1)
  Future<void> _incrementStock(ProductModel product) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .update({'stock': FieldValue.increment(1)});
  }

  /// Toggle product active status
  Future<void> _toggleProductActive(ProductModel product, bool value) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .update({'isActive': value});
  }

  /// Open product form for editing
  void _showProductFormSheet({ProductModel? product}) {
    if (_marketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce market yüklemesini bekleyin'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) =>
          ProductFormSheet(marketId: _marketId, productToEdit: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_marketEmoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _marketName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              currentUser?.displayName ?? 'Yönetici Paneli',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.discountRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationListScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) async {
              switch (value) {
                case 'customer_panel':
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
                case 'help':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                  break;
                case 'logout':
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) Navigator.pop(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'customer_panel',
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Müşteri Paneli',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'settings', child: Text('Ayarlar')),
              const PopupMenuItem(value: 'help', child: Text('Yardım')),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),

      body: StreamBuilder<List<ProductModel>>(
        stream: _productsStream,
        builder: (context, productsSnapshot) {
          final products = productsSnapshot.data ?? [];
          final activeCount = products.where((p) => p.isActive).length;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _completedReservationsStream,
            builder: (context, reservationsSnapshot) {
              final completedReservations = reservationsSnapshot.data ?? [];

              // Calculate real stats
              final totalRevenue = completedReservations.fold<double>(
                0.0,
                (sum, res) =>
                    sum + ((res['discountedPrice'] as num?)?.toDouble() ?? 0.0),
              );
              final soldCount = completedReservations.length;
              final weeklyData = _getWeeklyRevenueData(completedReservations);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Overview with real data
                    _buildStatsOverview(totalRevenue, soldCount, activeCount),
                    const SizedBox(height: 24),

                    // Weekly Performance Chart with real data
                    _buildWeeklyChart(weeklyData),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Active Listings with real-time stream
                    _buildActiveListings(products, activeCount),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(
    double totalRevenue,
    int soldCount,
    int activeCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: '₺${totalRevenue.toStringAsFixed(0)}',
            label: 'Toplam Ciro',
            icon: Icons.account_balance_wallet,
            valueColor: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: '$soldCount',
            label: 'Satılan Ürün',
            icon: Icons.shopping_bag,
            valueColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: '$activeCount',
            label: 'Aktif İlanlar',
            icon: Icons.eco,
            valueColor: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        children: [
          Icon(icon, color: valueColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<int, double> weeklyData) {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final todayIndex = DateTime.now().weekday - 1;

    // Calculate max value for normalization (or 1 if all zeros)
    final maxValue = weeklyData.values.fold<double>(
      1.0,
      (a, b) => a > b ? a : b,
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Haftalık Performans',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isToday = index == todayIndex;
                final value = weeklyData[index] ?? 0.0;
                final normalized = maxValue > 0
                    ? (value / maxValue).clamp(0.05, 1.0)
                    : 0.1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            heightFactor: normalized,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.primaryGreen
                                    : AppColors.primaryGreen.withValues(
                                        alpha: 0.6,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isToday
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.qr_code_scanner,
                label: 'Müşteri QR Kodu Tara',
                color: AppColors.primaryGreen,
                onTap: _showQRScanDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                label: 'Yeni Ürün Ekle',
                color: Colors.orange,
                onTap: () => _showProductFormSheet(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
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
    );
  }

  Widget _buildActiveListings(List<ProductModel> products, int activeCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Yayındaki Ürünler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeCount Aktif',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Henüz ürün yok',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Container(
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
            ),
            child: Column(
              children: products.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final isActive = product.isActive;
                final isLast = index == products.length - 1;

                return Column(
                  children: [
                    Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.orange,
                        child: const Icon(Icons.archive, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _softDeleteProduct(product);
                        return false; // We handle deletion manually
                      },
                      child: InkWell(
                        onTap: () => _showProductFormSheet(product: product),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Product emoji
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primaryGreenLight
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    product.imageEmoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Product info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '₺${product.discountedPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isActive
                                                ? AppColors.primaryGreen
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // STOCK BADGE
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: product.stock > 0
                                                ? AppColors.primaryGreenLight
                                                : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Stok: ${product.stock}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: product.stock > 0
                                                  ? AppColors.primaryGreen
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Quick Stock +1 button
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.primaryGreen,
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _incrementStock(product),
                                tooltip: 'Stok +1',
                              ),
                              const SizedBox(width: 8),
                              // Active toggle
                              Switch(
                                value: isActive,
                                activeThumbColor: AppColors.primaryGreen,
                                onChanged: (value) =>
                                    _toggleProductActive(product, value),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 72),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showQRScanDialog() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QRScanBottomSheet(
        marketId: user.uid,
        onReservationCompleted: (reservation) {
          _showOrderConfirmedDialog(reservation);
        },
      ),
    );
  }

  void _showOrderConfirmedDialog(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'İşlem Başarılı!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                reservation.productName,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Teslim Edildi',
                style: TextStyle(fontSize: 14, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reservation.earnedPoints} Puan Gönderildi! ⭐',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+₺${(reservation.discountedPrice * reservation.quantity).toStringAsFixed(2)} kazandı',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
}

/// Bottom sheet for QR scanning / simulated reservation verification
class _QRScanBottomSheet extends ConsumerStatefulWidget {
  final String marketId;
  final void Function(ReservationModel) onReservationCompleted;

  const _QRScanBottomSheet({
    required this.marketId,
    required this.onReservationCompleted,
  });

  @override
  ConsumerState<_QRScanBottomSheet> createState() => _QRScanBottomSheetState();
}

class _QRScanBottomSheetState extends ConsumerState<_QRScanBottomSheet> {
  bool _isProcessing = false;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Camera layer
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_isProcessing) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleScannedCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),

          // UI Overlay
          Positioned.fill(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Müşteri QR Kodunu Tara',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kodu çerçevenin içine hizalayın',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryGreen, width: 4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (_isProcessing)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      return Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                        size: 32,
                      );
                    },
                  ),
                  onPressed: () => _controller.toggleTorch(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScannedCode(String rawCode) async {
    setState(() => _isProcessing = true);

    try {
      String reservationId = rawCode;

      if (rawCode.contains('id=')) {
        final uri = Uri.parse(rawCode);
        reservationId = uri.queryParameters['id'] ?? rawCode;
      }

      debugPrint("🔍 Scanned ID: $reservationId");

      final error = await ref
          .read(reservationsProvider.notifier)
          .completeReservation(reservationId);

      if (error == null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservationId)
            .get();

        if (!docSnapshot.exists) throw "Rezervasyon bulunamadı";

        final updatedReservation = ReservationModel.fromFirestore(docSnapshot);

        if (!mounted) return;

        Navigator.pop(context);
        widget.onReservationCompleted(updatedReservation);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Satış Doğrulandı! Puanlar Gönderildi.'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw error;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _controller.start();
      });
    }
  }
}
