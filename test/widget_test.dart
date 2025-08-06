
// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:sentia_flow/main.dart';
import 'package:sentia_flow/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // This is the main test group for our widget tests.
  testWidgets('App starts and shows initial loading screen', (WidgetTester tester) async {
    // --- SETUP ---
    // For tests, we need to provide a fake (mock) implementation
    // of SharedPreferences. We initialize it with an empty map.
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    final onboardingService = OnboardingService(sharedPreferences: sharedPreferences);

    // --- EXECUTION ---
    // Build our app and trigger a frame.
    // CORRECTION: We now pass the required 'onboardingService' parameter.
    await tester.pumpWidget(MyApp(onboardingService: onboardingService));

    // --- VERIFICATION ---
    // Since it's the first time running (based on our mock SharedPreferences),
    // the app should show the OnboardingScreen.
    // We can verify this by looking for a unique text from that screen.
    expect(find.text('Welcome to SentiaFlow'), findsOneWidget);

    // The old counter test is removed as it's no longer relevant.
  });
}
