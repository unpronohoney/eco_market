import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_market/app.dart';
import 'package:eco_market/core/providers/auth_provider.dart';

/// Application entry point
/// Wraps the app with ProviderScope for Riverpod state management
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize SharedPreferences (for onboarding state only)
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override the shared preferences provider
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EcoMarketApp(),
    ),
  );
}
