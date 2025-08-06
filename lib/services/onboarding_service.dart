
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage the onboarding state of the application.
/// It checks if the user is opening the app for the first time.
class OnboardingService {
  final SharedPreferences _sharedPrefs;
  static const _keyFirstTime = 'isFirstTime';

  OnboardingService({required SharedPreferences sharedPreferences})
      : _sharedPrefs = sharedPreferences;

  /// Checks if it's the first time the user launches the app.
  /// Defaults to `true` if the key is not found.
  bool isFirstTime() {
    return _sharedPrefs.getBool(_keyFirstTime) ?? true;
  }

  /// Marks the onboarding as completed.
  /// This should be called after the user finishes the onboarding flow.
  Future<void> setOnboardingCompleted() async {
    await _sharedPrefs.setBool(_keyFirstTime, false);
  }
}