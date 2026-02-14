import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation tab indices
enum NavTab {
  map(0, 'Harita', 'map'),
  deals(1, 'Fırsatlar', 'local_offer'),
  profile(2, 'Profil', 'person');

  final int tabIndex;
  final String label;
  final String iconName;

  const NavTab(this.tabIndex, this.label, this.iconName);
}

/// Provider for the current navigation tab index
final currentTabProvider = StateProvider<NavTab>((ref) {
  return NavTab.map; // Default to Map tab
});

/// Provider to check if we're on Map tab (for bottom sheet handling)
final isMapTabProvider = Provider<bool>((ref) {
  return ref.watch(currentTabProvider) == NavTab.map;
});
