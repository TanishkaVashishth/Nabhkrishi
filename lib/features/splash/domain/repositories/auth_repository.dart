/// Where the splash screen should route to once its animation/check completes.
enum AuthDestination {
  onboarding, // first-time user -> Language Selection (Screen 2)
  login, // returning user, not authenticated -> Login (Screen 3)
  home, // authenticated + profile complete -> Home Dashboard (Screen 9)
}

/// Domain-layer contract. Presentation never talks to SharedPreferences,
/// Firebase Auth, or any concrete storage directly — only to this interface.
/// This is what makes the feature testable and swappable (Clean Architecture).
abstract class AuthRepository {
  Future<AuthDestination> resolveStartDestination();
}
