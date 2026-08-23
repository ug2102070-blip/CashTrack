import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashtrack/presentation/widgets/global_error_boundary.dart';

void main() {
  testWidgets('GlobalErrorWidget renders graceful fallback UI on Flutter error', (tester) async {
    final errorDetails = FlutterErrorDetails(
      exception: Exception('Simulated visual rendering overflow error'),
      library: 'rendering library',
      context: ErrorDescription('while performing layout'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalErrorWidget(details: errorDetails),
      ),
    );

    await tester.pumpAndSettle();

    // Verify error UI elements exist
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Go to Home'), findsOneWidget);
    expect(find.text('Copy Details'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
