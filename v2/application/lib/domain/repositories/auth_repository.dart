import '../models/user_role.dart';

/// Abstract contract for authentication and role management.
abstract interface class AuthRepository {
  /// Stream of currently authenticated user role (or null if unauthenticated).
  Stream<UserRole?> get userRoleStream;

  /// Get current role synchronously.
  UserRole? get currentRole;

  /// Sign in with email, password, and designated role.
  Future<void> signIn({
    required String email,
    required String password,
    required UserRole role,
  });

  /// Set the active role directly (for fast persona switching).
  Future<void> selectRole(UserRole role);

  /// Sign out.
  Future<void> signOut();
}
