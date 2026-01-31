import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/lexicon_flutter_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Lexicon native library
  try {
    await LexiconFlutterService.initialize();
    debugPrint('Lexicon initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Lexicon: $e');
    // Continue anyway - will fall back to mock service
  }

  runApp(
    const ProviderScope(
      child: LexiconApp(),
    ),
  );
}
