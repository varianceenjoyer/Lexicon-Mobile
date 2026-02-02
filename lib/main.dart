import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/lexicon_flutter_service.dart';

void main() async {
  // Use multiple logging methods to ensure we see output
  developer.log('main() started', name: 'Lexicon');
  debugPrint('[main] main() function starting');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[main] WidgetsFlutterBinding initialized');

  debugPrint('[main] Starting Lexicon initialization...');

  // Initialize Lexicon native library
  try {
    await LexiconFlutterService.initialize();
    debugPrint('[main] Lexicon initialized successfully, isInitialized=${LexiconFlutterService.isInitialized}');
  } catch (e, stackTrace) {
    debugPrint('[main] Failed to initialize Lexicon: $e');
    debugPrint('[main] Stack trace: $stackTrace');
     // Continue anyway - will fall back to mock service
  }

  runApp(
    const ProviderScope(
      child: LexiconApp(),
    ),
  );
}
