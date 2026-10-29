import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete implementation. Swap this file alone if you move from
/// SharedPreferences to secure storage or a remote session check —
/// nothing above this layer needs to change.
class AuthRepositoryImpl implements AuthRepository {
  static const _kOnboardingCompleteKey = 'onboarding_complete';
  static const _kAuthTokenKey = 'auth_token';
  static const _kProfileCompleteKey = 'profile_complete';

  @override
  Future<AuthDestination> resolveStartDestination() async {
    final prefs = await SharedPreferences.getInstance();

    final onboardingComplete = prefs.getBool(_kOnboardingCompleteKey) ?? false;
    if (!onboardingComplete) {
      return AuthDestination.onboarding;
    }

    final token = prefs.getString(_kAuthTokenKey);
    final profileComplete = prefs.getBool(_kProfileCompleteKey) ?? false;

    if (token != null && token.isNotEmpty && profileComplete) {
      return AuthDestination.home;
    }

    return AuthDestination.login;
  }
}
