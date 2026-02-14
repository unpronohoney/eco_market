import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_market/data/models/product_model.dart';
import 'package:eco_market/core/providers/auth_provider.dart';

/// Reservation status enum
enum ReservationStatus { active, completed, cancelled }

/// Model for a reservation with QR code and status
class ReservationModel {
  final String id;
  final String userId;
  final String marketId;
  final String marketName;
  final String productId;
  final String productName;
  final String productEmoji;
  final double originalPrice;
  final double discountedPrice;
  final int discountRate;
  final double co2Saved;
  final String qrCode;
  final double savedKilo;
  final ReservationStatus status;
  final DateTime reservedAt;
  final int earnedPoints;
  final int quantity;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.marketId,
    required this.marketName,
    required this.productId,
    required this.productName,
    required this.productEmoji,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountRate,
    required this.co2Saved,
    required this.savedKilo,
    required this.qrCode,
    required this.status,
    required this.reservedAt,
    required this.earnedPoints,
    required this.quantity,
  });

  /// Generate a unique QR code
  static String generateQrCode() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999).toString().padLeft(6, '0');
    return 'ECO-$timestamp-$randomPart';
  }

  /// Create from Firestore document
  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      marketId: data['marketId'] ?? '',
      marketName: data['marketName'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productEmoji: data['productEmoji'] ?? '🍞',
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble() ?? 0.0,
      discountRate: data['discountRate'] ?? 0,
      co2Saved: (data['co2Saved'] as num?)?.toDouble() ?? 0.0,
      qrCode: data['qrCode'] ?? '',
      savedKilo: ((data['savedKilo'] as num?)?.toDouble() ?? 0.0) / 1000,
      status: _parseStatus(data['status']),
      reservedAt:
          (data['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      earnedPoints: data['earnedPoints'] ?? 50,
      quantity: data['quantity'] ?? 1,
    );
  }

  static ReservationStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.active;
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'marketId': marketId,
      'marketName': marketName,
      'productId': productId,
      'productName': productName,
      'productEmoji': productEmoji,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountRate': discountRate,
      'co2Saved': co2Saved,
      'qrCode': qrCode,
      'savedKilo': savedKilo,
      'status': status.name,
      'reservedAt': FieldValue.serverTimestamp(),
      'earnedPoints': earnedPoints,
      'quantity': quantity,
    };
  }

  /// Get formatted reservation time
  String get formattedTime {
    final hour = reservedAt.hour.toString().padLeft(2, '0');
    final minute = reservedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Check if reservation is active
  bool get isActive => status == ReservationStatus.active;
}

/// Notifier for managing reservations with Firestore transactions
class ReservationsNotifier extends StateNotifier<List<ReservationModel>> {
  final FirebaseFirestore _firestore;
  final String? _userId;

  ReservationsNotifier(this._firestore, this._userId) : super([]) {
    if (_userId != null) {
      _loadReservations();
    }
  }

  /// Load user's reservations from Firestore
  Future<void> _loadReservations() async {
    if (_userId == null) {
      debugPrint('ReservationsNotifier: No user ID, skipping load');
      return;
    }

    debugPrint('ReservationsNotifier: Loading reservations for user $_userId');

    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: _userId)
          .orderBy('reservedAt', descending: true)
          .get();

      debugPrint(
        'ReservationsNotifier: Found ${snapshot.docs.length} reservations',
      );

      state = snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('ReservationsNotifier: Error loading reservations: $e');
      // Try without ordering (index may not exist)
      try {
        final snapshot = await _firestore
            .collection('reservations')
            .where('userId', isEqualTo: _userId)
            .get();

        debugPrint(
          'ReservationsNotifier: Fallback found ${snapshot.docs.length} reservations',
        );

        final reservations = snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList();
        // Sort locally
        reservations.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));
        state = reservations;
      } catch (e2) {
        debugPrint('ReservationsNotifier: Fallback also failed: $e2');
      }
    }
  }

  /// Public method to reload reservations (for pull-to-refresh)
  Future<void> reload() => _loadReservations();

  /// Reserve a product with transaction (atomic stock decrement)
  Future<String?> reserveProduct({
    required ProductModel product,
    required String marketId,
    required String marketName,
    int quantity = 1,
  }) async {
    if (_userId == null) return 'Giriş yapmalısınız';

    try {
      final productRef = _firestore.collection('products').doc(product.id);

      await _firestore.runTransaction((transaction) async {
        // Get current product state
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception('Ürün bulunamadı');
        }

        final productData = productDoc.data()!;
        final currentStock = productData['stock'] as int? ?? 0;

        if (currentStock < quantity) {
          throw Exception('Yeterli stok yok (kalan: $currentStock)');
        }

        // Decrement stock by quantity
        final newStock = currentStock - quantity;
        transaction.update(productRef, {
          'stock': newStock,
          'isActive': newStock > 0,
        });

        // Create reservation
        final qrCode = ReservationModel.generateQrCode();
        final unitCo2 = (productData['co2Saved'] as num?)?.toDouble() ?? 0.5;
        final reservationRef = _firestore.collection('reservations').doc();
        final unitWeight =
            ((productData['weight'] as num?)?.toDouble() ?? 0.0) / 1000;
        final unitPoints = (productData['points'] as int?) ?? 50;

        final reservationData = {
          'userId': _userId,
          'marketId': marketId,
          'marketName': marketName,
          'productId': product.id,
          'productName': product.name,
          'productEmoji': product.imageEmoji,
          'originalPrice': product.originalPrice,
          'discountedPrice': product.discountedPrice,
          'discountRate': product.discountRate,
          'quantity': quantity,
          'co2Saved': unitCo2 * quantity,
          'savedKilo': unitWeight * quantity,
          'qrCode': qrCode,
          'status': 'active',
          'reservedAt': FieldValue.serverTimestamp(),
          'earnedPoints': unitPoints * quantity,
        };

        transaction.set(reservationRef, reservationData);
      });

      // Reload reservations
      await _loadReservations();
      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Complete a reservation (called by market owner after QR scan)
  Future<String?> completeReservation(String reservationId) async {
    try {
      final reservationRef = _firestore
          .collection('reservations')
          .doc(reservationId);

      await _firestore.runTransaction((transaction) async {
        final reservationDoc = await transaction.get(reservationRef);

        if (!reservationDoc.exists) {
          throw Exception('Rezervasyon bulunamadı');
        }

        final data = reservationDoc.data()!;
        if (data['status'] != 'active') {
          throw Exception('Bu rezervasyon zaten işlendi');
        }

        final userId = data['userId'] as String;
        final co2Saved = (data['co2Saved'] as num?)?.toDouble() ?? 0.5;
        final earnedPoints = data['earnedPoints'] as int? ?? 50;
        final savedMoney =
            (data['originalPrice'] as num).toDouble() -
            (data['discountedPrice'] as num).toDouble();
        final savedKilo = ((data['savedKilo'] as num?)?.toDouble() ?? 0);

        // Update reservation status
        transaction.update(reservationRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Update user stats (gamification)
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'ecoPoints': FieldValue.increment(earnedPoints),
          'totalCo2Saved': FieldValue.increment(co2Saved),
          'savedMoney': FieldValue.increment(savedMoney),
          'savedKilo': FieldValue.increment(savedKilo),
        });
      });

      await _loadReservations();
      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Cancel a reservation and restore stock
  Future<String?> cancelReservation(String reservationId) async {
    if (_userId == null) return 'Giriş yapmalısınız';

    try {
      final reservationRef = _firestore
          .collection('reservations')
          .doc(reservationId);

      await _firestore.runTransaction((transaction) async {
        final reservationDoc = await transaction.get(reservationRef);

        if (!reservationDoc.exists) {
          throw Exception('Rezervasyon bulunamadı');
        }

        final data = reservationDoc.data()!;
        if (data['status'] != 'active') {
          throw Exception('Bu rezervasyon iptal edilemez');
        }

        final productId = data['productId'] as String;
        final productRef = _firestore.collection('products').doc(productId);

        // Restore stock
        transaction.update(productRef, {
          'stock': FieldValue.increment(1),
          'isActive': true,
        });

        // Update reservation status
        transaction.update(reservationRef, {'status': 'cancelled'});
      });

      await _loadReservations();
      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Get reservations for a specific market (for market owners)
  Future<List<ReservationModel>> getMarketReservations(String marketId) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('marketId', isEqualTo: marketId)
          .where('status', isEqualTo: 'active')
          .orderBy('reservedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Find reservation by QR code
  Future<ReservationModel?> findByQrCode(String qrCode) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReservationModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }
}

/// Main reservations provider
final reservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<ReservationModel>>((ref) {
      final firestore = ref.watch(firestoreProvider);
      final user = ref.watch(currentUserProvider);
      return ReservationsNotifier(firestore, user?.uid);
    });

/// Active reservation count provider
final activeReservationCountProvider = Provider<int>((ref) {
  return ref
      .watch(reservationsProvider)
      .where((r) => r.status == ReservationStatus.active)
      .length;
});

/// Reservation count provider
final reservationCountProvider = Provider<int>((ref) {
  return ref.watch(reservationsProvider).length;
});

/// Stream provider for market's active reservations (for QR verification)
final marketActiveReservationsStreamProvider =
    StreamProvider.family<List<ReservationModel>, String>((ref, marketId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('reservations')
          .where('marketId', isEqualTo: marketId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
            final reservations = snapshot.docs
                .map((doc) => ReservationModel.fromFirestore(doc))
                .toList();
            // Sort by reservation time (newest first)
            reservations.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));
            return reservations;
          });
    });

/// Stream provider for a single reservation (for real-time status updates)
final singleReservationStreamProvider =
    StreamProvider.family<ReservationModel?, String>((ref, reservationId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('reservations')
          .doc(reservationId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return ReservationModel.fromFirestore(doc);
          });
    });
