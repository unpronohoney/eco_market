import 'package:eco_market/data/models/product_model.dart';

/// Market model representing bakeries/stores with location data
/// Contains list of products available at this market
class MarketModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String imageEmoji;
  final List<ProductModel> products;
  final String? phoneNumber;
  final String? openingHours;

  const MarketModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.imageEmoji,
    required this.products,
    this.phoneNumber,
    this.openingHours,
  });

  /// Count of products with Green Badge
  int get greenBadgeCount => products.where((p) => p.isGreenBadge).length;

  /// Get only Green Badge products
  List<ProductModel> get greenBadgeProducts =>
      products.where((p) => p.isGreenBadge).toList();

  /// Check if market has any discounted products
  bool get hasDiscountedProducts => products.any((p) => p.isGreenBadge);

  /// Get total savings available at this market
  double get totalSavings =>
      products.fold(0.0, (sum, p) => sum + (p.originalPrice - p.discountedPrice));

  /// Format rating as string with star
  String get formattedRating => '⭐ ${rating.toStringAsFixed(1)}';

  /// Create a copy with modified fields
  MarketModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    String? imageEmoji,
    List<ProductModel>? products,
    String? phoneNumber,
    String? openingHours,
  }) {
    return MarketModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      products: products ?? this.products,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      openingHours: openingHours ?? this.openingHours,
    );
  }
}
