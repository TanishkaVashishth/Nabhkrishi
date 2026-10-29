/// Single source of truth for every asset path in the app.
/// Never hardcode a path string inside a widget — reference it from here.
class AssetPaths {
  AssetPaths._();

  static const String logo = 'assets/images/nabhkrishi_logo.png';
  static const String splashLottie = 'assets/lottie/splash_growth.json';
}

/// Shared Hero tag constants — must match exactly between the Splash screen
/// and whatever screen the logo animates into (Language Selection).
class HeroTags {
  HeroTags._();

  static const String appLogo = 'nabhkrishi-app-logo';
}
