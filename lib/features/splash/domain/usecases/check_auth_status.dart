import '../repositories/auth_repository.dart';

/// A use case is a single, named unit of business logic. The presentation
/// layer calls `CheckAuthStatus()` — it has no idea whether that resolves
/// via SharedPreferences, secure storage, or a token refresh call.
class CheckAuthStatus {
  final AuthRepository _repository;

  const CheckAuthStatus(this._repository);

  Future<AuthDestination> call() {
    return _repository.resolveStartDestination();
  }
}
