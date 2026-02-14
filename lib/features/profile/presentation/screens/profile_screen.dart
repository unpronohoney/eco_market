import 'dart:developer';

import 'package:eco_market/core/providers/reservations_provider.dart';
import 'package:eco_market/features/auth/presentation/screens/login_screen.dart';
import 'package:eco_market/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/providers/auth_provider.dart';
import 'package:eco_market/features/auth/presentation/screens/welcome_screen.dart';
import 'package:eco_market/features/market_dashboard/presentation/screens/market_dashboard_screen.dart';
import 'package:eco_market/features/profile/presentation/screens/customer_settings_screen.dart';
import 'package:eco_market/features/profile/presentation/screens/customer_help_screen.dart';

/// Profile Screen (Tab 3: Profil)
/// Guest mode profile with login incentive and impact dashboard
/// Supports mock login for demo purposes

final userDocProvider = StreamProvider.family<Map<String, dynamic>?, String>((
  ref,
  uid,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data());
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar & Info (Guest or Logged In)
                  isLoggedIn ? _buildLoggedInHeader(ref) : _buildGuestHeader(),

                  const SizedBox(height: 24),

                  // Login Button (only when guest)
                  if (!isLoggedIn) _buildLoginButton(context, ref),

                  if (!isLoggedIn) const SizedBox(height: 32),

                  // Impact Dashboard Section
                  _buildImpactSection(isLoggedIn, ref),

                  const SizedBox(height: 24),

                  // Features Teaser (only when guest)
                  if (!isLoggedIn) _buildFeatureTeaser(context),

                  const SizedBox(height: 32),

                  // Market Dashboard Button (only for market accounts)
                  if (ref.watch(isMarketProvider))
                    _buildMarketDashboardButton(context),

                  if (ref.watch(isMarketProvider)) const SizedBox(height: 16),

                  const SizedBox(height: 100), // Bottom padding for nav bar
                ],
              ),
            ),

            // Menu button (only when logged in)
            if (isLoggedIn)
              Positioned(
                top: 70,
                right: 16,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'market_panel':
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MarketDashboardScreen(),
                            ),
                            (route) => false,
                          );
                          break;
                        case 'settings':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerSettingsScreen(),
                            ),
                          );
                          break;
                        case 'help':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerHelpScreen(),
                            ),
                          );
                          break;
                        case 'logout':
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WelcomeScreen(),
                              ),
                              (route) => false,
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (ref.watch(isMarketProvider))
                        const PopupMenuItem(
                          value: 'market_panel',
                          child: Row(
                            children: [
                              Icon(
                                Icons.store_outlined,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Mağaza Paneli',
                                style: TextStyle(color: AppColors.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Ayarlar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Yardım'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: AppColors.discountRed,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Çıkış Yap',
                              style: TextStyle(color: AppColors.discountRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketDashboardButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketDashboardScreen()),
          );
        },
        icon: const Icon(Icons.store, color: AppColors.primaryGreen),
        label: const Text(
          'Mağaza Paneline Geç',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHeader() {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryGreenLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.person_outline,
              size: 48,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Guest Label
        const Text(
          'Misafir Kullanıcı',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '👋 Hoş geldiniz!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInHeader(WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userName = currentUser?.displayName ?? 'Kullanıcı';
    final initials = userName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Column(
      children: [
        // Avatar with user initials
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.greenGradient,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGreen, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // User Name
        Text(
          userName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 16, color: AppColors.primaryGreen),
              SizedBox(width: 4),
              Text(
                'Eko Kahraman',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WelcomeScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Giriş Yap / Kayıt Ol',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImpactSection(bool isLoggedIn, WidgetRef ref) {
    // Get user data from Firestore
    final user = ref.watch(authProvider).user;

    // Default values
    double savedMoney = 0;
    double totalCo2Saved = 0;
    double savedKilo = 0;
    int ecoPoints = 0;
    int completedOrders = 0;

    if (isLoggedIn && user != null) {
      // Stream user document for real-time updates
      // user.uid bilgisini dışarıdan alabilmek için .family kullanıyoruz
      final userDocAsync = ref.watch(userDocProvider(user.uid));
      userDocAsync.whenData((data) {
        if (data != null) {
          savedMoney = (data['savedMoney'] as num?)?.toDouble() ?? 0;
          totalCo2Saved = (data['totalCo2Saved'] as num?)?.toDouble() ?? 0;
          ecoPoints = (data['ecoPoints'] as num?)?.toInt() ?? 0;
          savedKilo = (data['savedKilo'] as num?)?.toDouble() ?? 0;
        }
      });

      // Also count completed reservations
      final reservations = ref.watch(reservationsProvider);
      completedOrders = reservations
          .where((r) => r.status == ReservationStatus.completed)
          .length;

      // Get real values from userDocAsync
      final userData = userDocAsync.valueOrNull;
      if (userData != null) {
        savedMoney = (userData['savedMoney'] as num?)?.toDouble() ?? 0;
        totalCo2Saved = (userData['totalCo2Saved'] as num?)?.toDouble() ?? 0;
        ecoPoints = (userData['ecoPoints'] as num?)?.toInt() ?? 0;
        savedKilo = (userData['savedKilo'] as num?)?.toDouble() ?? 0;
      }
      log('UserData: $userData');
      log('UserData: $userDocAsync');
      log('Completed Orders: $completedOrders');
      log('Eco Points: ${userDocAsync.whenData((data) => data?['ecoPoints'])}');
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🌍', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etki Panosu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isLoggedIn
                          ? 'Harika gidiyorsun! 🎉'
                          : 'Giriş yaparak etkini takip et!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Eco Points badge
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$ecoPoints',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Impact Stats (Real from Firestore)
          Row(
            children: [
              Expanded(
                child: _ImpactCard(
                  emoji: '🥗',
                  title: 'Kurtarılan Gıda',
                  value: isLoggedIn
                      ? '${savedKilo.toStringAsFixed(3)} kg'
                      : '0 kg',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactCard(
                  emoji: '💰',
                  title: 'Tasarruf',
                  value: isLoggedIn
                      ? '₺${savedMoney.toStringAsFixed(1)}'
                      : '₺0',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ImpactCard(
                  emoji: '🌱',
                  title: 'CO₂ Engellenen',
                  value: isLoggedIn
                      ? '${totalCo2Saved.toStringAsFixed(1)} kg'
                      : '0 kg',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactCard(
                  emoji: '🛒',
                  title: 'Sipariş',
                  value: isLoggedIn ? '$completedOrders' : '0',
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTeaser(BuildContext context) {
    return InkWell(
      onTap: () => _showSignUpBenefits(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreenLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Üye olarak daha fazlasını keşfet!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Favoriler, özel teklifler ve daha fazlası',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignUpBenefits(BuildContext context) {
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
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Title
            const Text(
              'EcoMarket Ailesine Katıl! 🚀',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Benefits List
            _BenefitTile(
              emoji: '🔔',
              title: 'Bildirimler',
              subtitle: 'Fırsatları ilk sen duy.',
              color: Colors.orange,
            ),
            _BenefitTile(
              emoji: '🎫',
              title: 'Rezervasyon',
              subtitle: 'Ürününü gitmeden ayırt.',
              color: AppColors.primaryGreen,
            ),
            _BenefitTile(
              emoji: '🌱',
              title: 'İstatistik',
              subtitle: 'Karbon tasarrufunu takip et.',
              color: const Color(0xFF10B981),
            ),
            _BenefitTile(
              emoji: '💬',
              title: 'Topluluk',
              subtitle: 'Yorum yap ve puan ver.',
              color: const Color(0xFF6366F1),
            ),

            const SizedBox(height: 24),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Hemen Ücretsiz Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Action
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Zaten hesabım var? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'Giriş Yap',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Individual impact stat card
class _ImpactCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final Color color;

  const _ImpactCard({
    required this.emoji,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Benefit tile for signup modal
class _BenefitTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _BenefitTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
