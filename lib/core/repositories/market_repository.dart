import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_market/data/models/market_model.dart';
import 'package:eco_market/data/models/product_model.dart';
import 'package:eco_market/core/providers/auth_provider.dart';

/// Repository for fetching markets and products from Firestore
class MarketRepository {
  final FirebaseFirestore _firestore;

  MarketRepository(this._firestore);

  /// Get all markets from Firestore (with their products)
  Stream<List<MarketModel>> getMarketsStream() {
    return _firestore.collection('markets').snapshots().asyncMap((
      snapshot,
    ) async {
      final markets = <MarketModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Fetch products for this market
        final productsSnapshot = await _firestore
            .collection('products')
            .where('marketId', isEqualTo: doc.id)
            .get();

        final products = productsSnapshot.docs
            .map((pDoc) => ProductModel.fromFirestore(pDoc))
            .toList();

        markets.add(
          MarketModel(
            id: doc.id,
            name: data['name'] ?? '',
            address: data['address'] ?? '',
            latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            imageEmoji: data['imageEmoji'] ?? '🏪',
            products: products,
            phoneNumber: data['phoneNumber'],
            openingHours: data['openingHours'],
          ),
        );
      }

      return markets;
    });
  }

  /// Get products for a specific market
  Stream<List<ProductModel>> getProductsStream(String marketId) {
    return _firestore
        .collection('products')
        .where('marketId', isEqualTo: marketId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all markets (one-time fetch)
  Future<List<MarketModel>> getMarkets() async {
    final snapshot = await _firestore.collection('markets').get();
    final markets = <MarketModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Fetch products for this market
      final productsSnapshot = await _firestore
          .collection('products')
          .where('marketId', isEqualTo: doc.id)
          .get();

      final products = productsSnapshot.docs
          .map((pDoc) => ProductModel.fromFirestore(pDoc))
          .toList();

      markets.add(
        MarketModel(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          imageEmoji: data['imageEmoji'] ?? '🏪',
          products: products,
          phoneNumber: data['phoneNumber'],
          openingHours: data['openingHours'],
        ),
      );
    }

    return markets;
  }

  /// Reserve a product
  Future<void> reserveProduct({
    required String userId,
    required String productId,
    required String marketId,
    required String marketName,
    required ProductModel product,
  }) async {
    final batch = _firestore.batch();

    // Add reservation to user's subcollection
    final reservationRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('reservations')
        .doc();

    batch.set(reservationRef, {
      'productId': productId,
      'marketId': marketId,
      'marketName': marketName,
      'productName': product.name,
      'productEmoji': product.imageEmoji,
      'originalPrice': product.originalPrice,
      'discountedPrice': product.discountedPrice,
      'reservedAt': FieldValue.serverTimestamp(),
    });

    // Decrement product stock (optional - if stock field exists)
    final productRef = _firestore.collection('products').doc(productId);
    batch.update(productRef, {'stock': FieldValue.increment(-1)});

    await batch.commit();
  }

  /// Get user's reservations
  Stream<List<Map<String, dynamic>>> getUserReservations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reservations')
        .orderBy('reservedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}

/// Provider for MarketRepository
final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MarketRepository(firestore);
});

/// Provider for markets stream
final marketsStreamProvider = StreamProvider<List<MarketModel>>((ref) {
  final repository = ref.watch(marketRepositoryProvider);
  return repository.getMarketsStream();
});

/// Provider for products stream (requires marketId)
final productsStreamProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, marketId) {
      final repository = ref.watch(marketRepositoryProvider);
      return repository.getProductsStream(marketId);
    });
