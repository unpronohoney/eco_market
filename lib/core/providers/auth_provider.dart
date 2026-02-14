import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences (only for onboarding state)
class AuthKeys {
  static const String hasSeenOnboarding = 'auth_has_seen_onboarding';
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// User model for the app
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final bool isMarket;
  final int ecoPoints;
  final double totalCo2Saved;
  final double savedMoney;
  final double savedKilo;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
    this.isMarket = false,
    this.ecoPoints = 0,
    this.totalCo2Saved = 0.0,
    this.savedMoney = 0.0,
    this.savedKilo = 0.0,
  });

  factory AppUser.fromFirebaseUser(
    User user, {
    bool isMarket = false,
    int ecoPoints = 0,
    double totalCo2Saved = 0.0,
    double savedMoney = 0.0,
    double savedKilo = 0.0,
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
      isMarket: isMarket,
      ecoPoints: ecoPoints,
      totalCo2Saved: totalCo2Saved,
      savedMoney: savedMoney,
      savedKilo: savedKilo,
    );
  }

  AppUser copyWith({
    bool? isMarket,
    String? displayName,
    int? ecoPoints,
    double? totalCo2Saved,
    double? savedMoney,
    double? savedKilo,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous,
      isMarket: isMarket ?? this.isMarket,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      totalCo2Saved: totalCo2Saved ?? this.totalCo2Saved,
      savedMoney: savedMoney ?? this.savedMoney,
      savedKilo: savedKilo ?? this.savedKilo,
    );
  }
}

/// Auth state model
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool hasSeenOnboarding;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.hasSeenOnboarding = false,
  });

  bool get isLoggedIn => user != null;
  bool get isGuest => user?.isAnonymous ?? false;
  bool get isMarket => user?.isMarket ?? false;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? hasSeenOnboarding,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

/// Auth state notifier with Firebase Auth
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._auth, this._firestore, this._prefs)
    : super(
        AuthState(
          hasSeenOnboarding:
              _prefs.getBool(AuthKeys.hasSeenOnboarding) ?? false,
          isLoading: true,
        ),
      ) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user != null) {
        // Fetch additional user data from Firestore
        final userData = await _fetchUserData(user.uid);
        final isMarket = userData?['isMarket'] ?? false;

        log('UserData: $userData');

        state = state.copyWith(
          user: AppUser.fromFirebaseUser(
            user,
            isMarket: isMarket,
          ).copyWith(displayName: userData?['name'] ?? user.displayName),
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(clearUser: true, isLoading: false);
      }
    });
  }

  /// Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Register a new user with email and password
  Future<String?> register(
    String name,
    String email,
    String password, {
    bool isMarket = false,
    String? marketName,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Store user data in Firestore
      if (credential.user != null) {
        final uid = credential.user!.uid;

        await _firestore.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isMarket': isMarket,
          'ecoPoints': 0,
          'totalCo2Saved': 0.0,
          'savedMoney': 0.0,
        });

        // If market account, also create a market document
        if (isMarket && marketName != null) {
          // Use default Istanbul location if not provided
          final lat = latitude ?? 41.0082;
          final lng = longitude ?? 28.9784;

          await _firestore.collection('markets').doc(uid).set({
            'name': marketName,
            'address': address ?? '',
            'latitude': lat,
            'longitude': lng,
            'imageEmoji': '🏪',
            'rating': 0,
            'ratingCount': 0,
            'productCount': 0,
            'ownerId': uid,
            'ownerName': name,
            'ownerEmail': email,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
        }

        // Manually set user state with correct data (auth listener may fire before Firestore write)
        state = state.copyWith(
          user: AppUser(
            uid: uid,
            email: email,
            displayName: name,
            isAnonymous: false,
            isMarket: isMarket,
            ecoPoints: 0,
            totalCo2Saved: 0.0,
            savedMoney: 0.0,
          ),
        );
      }

      // Mark onboarding as seen
      await _prefs.setBool(AuthKeys.hasSeenOnboarding, true);
      state = state.copyWith(hasSeenOnboarding: true, isLoading: false);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e.code),
      );
      return _mapFirebaseError(e.code);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Bir hata oluştu');
      return 'Bir hata oluştu';
    }
  }

  /// Login with email and password
  Future<String?> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Mark onboarding as seen
      await _prefs.setBool(AuthKeys.hasSeenOnboarding, true);
      state = state.copyWith(hasSeenOnboarding: true, isLoading: false);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e.code),
      );
      return _mapFirebaseError(e.code);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Bir hata oluştu');
      return 'Bir hata oluştu';
    }
  }

  /// Continue as guest (anonymous sign in)
  Future<void> continueAsGuest() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _auth.signInAnonymously();

      // Mark onboarding as seen
      await _prefs.setBool(AuthKeys.hasSeenOnboarding, true);
      state = state.copyWith(hasSeenOnboarding: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Giriş yapılamadı');
    }
  }

  /// Quick login for demo purposes
  Future<void> quickLogin() async {
    await continueAsGuest();
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      state = state.copyWith(clearUser: true);
    } catch (e) {
      // Ignore logout errors
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await _prefs.setBool(AuthKeys.hasSeenOnboarding, true);
    state = state.copyWith(hasSeenOnboarding: true);
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kayıtlı';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter)';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Şifre hatalı';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}

/// Auth provider with Firebase
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(auth, firestore, prefs);
});

/// Convenience providers
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final hasSeenOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).hasSeenOnboarding;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Market account provider - true if user is a business/market
final isMarketProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isMarket;
});
