import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status.dart';

enum SplashStatus { loading, ready }

/// Thin presentation-layer controller. Holds no Flutter widgets — only
/// state — so it can be unit-tested without pumping a widget tree.
class SplashController extends ChangeNotifier {
  final CheckAuthStatus _checkAuthStatus;

  /// Minimum time the splash stays on screen even if the auth check
  /// resolves instantly — prevents an ugly "flash" for users on fast
  /// connections. Apple/Google both do this deliberately.
  static const Duration minimumDisplayDuration = Duration(milliseconds: 1800);

  SplashStatus status = SplashStatus.loading;
  AuthDestination? destination;

  SplashController(this._checkAuthStatus);

  Future<void> resolve() async {
    final stopwatch = Stopwatch()..start();

    final result = await _checkAuthStatus();

    final elapsed = stopwatch.elapsed;
    final remaining = minimumDisplayDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    destination = result;
    status = SplashStatus.ready;
    notifyListeners();
  }
}
