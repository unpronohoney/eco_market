import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/core/providers/navigation_provider.dart';
import 'package:eco_market/core/providers/reservations_provider.dart';
import 'package:eco_market/features/home/presentation/screens/home_screen.dart';
import 'package:eco_market/features/deals/presentation/screens/deals_screen.dart';
import 'package:eco_market/features/profile/presentation/screens/profile_screen.dart';
import 'package:eco_market/features/reservations/presentation/screens/my_reservations_screen.dart';

/// Main screen with bottom navigation bar and reservations icon
/// Manages tab switching using Riverpod
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  /// Active tab color (green as specified)
  static const Color _activeColor = Color(0xFF4CAF50);
  static const Color _inactiveColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final reservationCount = ref.watch(activeReservationCountProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: currentTab.index,
            children: const [HomeScreen(), DealsScreen(), ProfileScreen()],
          ),

          // Reservations button (top right, floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _ReservationsButton(
              count: reservationCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyReservationsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: NavTab.values.map((tab) {
                final isActive = currentTab == tab;
                return _NavBarItem(
                  tab: tab,
                  isActive: isActive,
                  activeColor: _activeColor,
                  inactiveColor: _inactiveColor,
                  onTap: () {
                    ref.read(currentTabProvider.notifier).state = tab;
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reservations button with badge
class _ReservationsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ReservationsButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.discountRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation bar item widget
class _NavBarItem extends StatelessWidget {
  final NavTab tab;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.tab,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  IconData get _icon {
    switch (tab) {
      case NavTab.map:
        return isActive ? Icons.map : Icons.map_outlined;
      case NavTab.deals:
        return isActive ? Icons.local_offer : Icons.local_offer_outlined;
      case NavTab.profile:
        return isActive ? Icons.person : Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
