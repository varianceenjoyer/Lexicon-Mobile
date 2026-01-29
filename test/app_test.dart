import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon_mobile/app.dart';

void main() {
  group('LexiconApp', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: LexiconApp(),
        ),
      );

      // App should render
      expect(find.byType(LexiconApp), findsOneWidget);
    });
  });
}
