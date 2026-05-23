import 'package:flutter_test/flutter_test.dart';
import 'package:sewainaja/main.dart';
import 'package:sewainaja/animated_splash_screen.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that AnimatedSplashScreen is displayed.
    expect(find.byType(AnimatedSplashScreen), findsOneWidget);

    // Elapse time for the splash screen sequence so no Timers remain pending
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
