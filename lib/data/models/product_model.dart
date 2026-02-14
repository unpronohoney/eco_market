import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model representing food items with expiry information
/// Contains fields for pricing, discount, stock, and Green Badge eligibility
class ProductModel {
  final String id;
  final String name;
  final double originalPrice;
  final double discountedPrice;
  final int discountRate;
  final bool isGreenBadge;
  final DateTime expiryDate;
  final String imageEmoji;
  final String? description;
  final int stock;
  final double weight;
  final String category;
  final double co2Saved;
  final int points;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountRate,
    required this.isGreenBadge,
    required this.expiryDate,
    required this.imageEmoji,
    this.description,
    this.stock = 0,
    this.weight = 100,
    this.category = 'other',
    this.co2Saved = 0.5,
    this.points = 10,
    this.isActive = true,
  });

  /// Factory constructor for creating from Firestore document
  /// Handles null values safely with sensible defaults
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble() ?? 0.0,
      discountRate: (data['discountRate'] as num?)?.toInt() ?? 0,
      isGreenBadge: data['isGreenBadge'] as bool? ?? false,
      expiryDate:
          (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageEmoji: data['imageEmoji'] as String? ?? '🍞',
      description: data['description'] as String?,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 100,
      category: data['category'] as String? ?? 'other',
      co2Saved: (data['co2Saved'] as num?)?.toDouble() ?? 0.5,
      points: (data['points'] as num?)?.toInt() ?? 10,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Check if product expires today
  bool get isExpiringToday {
    final now = DateTime.now();
    return expiryDate.year == now.year &&
        expiryDate.month == now.month &&
        expiryDate.day == now.day;
  }

  /// Check if product expires within 24 hours
  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inHours <= 24 && difference.inHours >= 0;
  }

  /// Get savings amount
  double get savings => originalPrice - discountedPrice;

  /// Format price with Turkish Lira symbol
  String get formattedOriginalPrice => '₺${originalPrice.toStringAsFixed(0)}';
  String get formattedDiscountedPrice =>
      '₺${discountedPrice.toStringAsFixed(0)}';

  /// Get badge text based on discount and expiry
  String get badgeText {
    if (isExpiringToday) {
      return 'Bugün Son Gün!';
    }
    return '%$discountRate İndirim';
  }

  /// Create a copy with modified fields
  ProductModel copyWith({
    String? id,
    String? name,
    double? originalPrice,
    double? discountedPrice,
    int? discountRate,
    bool? isGreenBadge,
    DateTime? expiryDate,
    String? imageEmoji,
    String? description,
    int? stock,
    double? weight,
    String? category,
    double? co2Saved,
    int? points,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountRate: discountRate ?? this.discountRate,
      isGreenBadge: isGreenBadge ?? this.isGreenBadge,
      expiryDate: expiryDate ?? this.expiryDate,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
      category: category ?? this.category,
      co2Saved: co2Saved ?? this.co2Saved,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
    );
  }
}
