import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_market/core/providers/auth_provider.dart';

/// Review model
class ReviewModel {
  final String id;
  final String marketId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.marketId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      marketId: data['marketId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Kullanıcı',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'marketId': marketId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} dk önce';
      }
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

/// Reviews notifier
class ReviewsNotifier extends StateNotifier<List<ReviewModel>> {
  final FirebaseFirestore _firestore;
  final AppUser? _user;

  ReviewsNotifier(this._firestore, this._user) : super([]);

  /// Submit a review and update market rating
  Future<String?> submitReview({
    required String marketId,
    required double rating,
    required String comment,
  }) async {
    if (_user == null) return 'Giriş yapmalısınız';
    if (rating < 1 || rating > 5) return 'Geçersiz puan';

    try {
      await _firestore.runTransaction((transaction) async {
        final marketRef = _firestore.collection('markets').doc(marketId);
        final marketDoc = await transaction.get(marketRef);

        if (!marketDoc.exists) {
          throw Exception('Market bulunamadı');
        }

        final marketData = marketDoc.data()!;
        final currentRating = (marketData['rating'] as num?)?.toDouble() ?? 5.0;
        final ratingCount = (marketData['ratingCount'] as int?) ?? 0;

        // Calculate new average rating
        final newRatingCount = ratingCount + 1;
        final newRating =
            ((currentRating * ratingCount) + rating) / newRatingCount;

        // Update market rating
        transaction.update(marketRef, {
          'rating': newRating,
          'ratingCount': newRatingCount,
        });

        // Create review document
        final reviewRef = _firestore.collection('reviews').doc();
        transaction.set(reviewRef, {
          'marketId': marketId,
          'userId': _user.uid,
          'userName': _user.displayName ?? 'Kullanıcı',
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Load reviews for a specific market
  Future<void> loadMarketReviews(String marketId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('marketId', isEqualTo: marketId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      state = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      state = [];
    }
  }

  /// Get stream of reviews for a market
  Stream<List<ReviewModel>> marketReviewsStream(String marketId) {
    return _firestore
        .collection('reviews')
        .where('marketId', isEqualTo: marketId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Check if user has already reviewed a market
  Future<bool> hasUserReviewed(String marketId) async {
    if (_user == null) return false;

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('marketId', isEqualTo: marketId)
          .where('userId', isEqualTo: _user.uid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Delete a review and update market rating
  Future<String?> deleteReview({
    required String reviewId,
    required String marketId,
    required double reviewRating,
  }) async {
    if (_user == null) return 'Giriş yapmalısınız';

    try {
      await _firestore.runTransaction((transaction) async {
        final marketRef = _firestore.collection('markets').doc(marketId);
        final marketDoc = await transaction.get(marketRef);

        if (!marketDoc.exists) {
          throw Exception('Market bulunamadı');
        }

        final marketData = marketDoc.data()!;
        final currentRating = (marketData['rating'] as num?)?.toDouble() ?? 5.0;
        final ratingCount = (marketData['ratingCount'] as int?) ?? 1;

        // Recalculate rating after removing this review
        if (ratingCount > 1) {
          final newRatingCount = ratingCount - 1;
          final newRating =
              ((currentRating * ratingCount) - reviewRating) / newRatingCount;
          transaction.update(marketRef, {
            'rating': newRating,
            'ratingCount': newRatingCount,
          });
        } else {
          // No reviews left, reset to default
          transaction.update(marketRef, {'rating': 5.0, 'ratingCount': 0});
        }

        // Delete the review
        final reviewRef = _firestore.collection('reviews').doc(reviewId);
        transaction.delete(reviewRef);
      });

      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

/// Reviews provider
final reviewsProvider =
    StateNotifierProvider<ReviewsNotifier, List<ReviewModel>>((ref) {
      final firestore = ref.watch(firestoreProvider);
      final user = ref.watch(currentUserProvider);
      return ReviewsNotifier(firestore, user);
    });

/// Stream provider for market reviews (handles missing index gracefully)
final marketReviewsStreamProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, marketId) {
      final firestore = ref.watch(firestoreProvider);

      // Try to get reviews without ordering (more reliable if index not set up)
      return firestore
          .collection('reviews')
          .where('marketId', isEqualTo: marketId)
          .snapshots()
          .map((snapshot) {
            final reviews = snapshot.docs
                .map((doc) => ReviewModel.fromFirestore(doc))
                .toList();
            // Sort locally instead
            reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return reviews;
          })
          .handleError((error) {
            debugPrint('Reviews stream error: $error');
            return <ReviewModel>[];
          });
    });
