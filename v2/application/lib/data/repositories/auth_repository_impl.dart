import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/firebase_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppFirebaseService _firebaseService;
  final _roleController = StreamController<UserRole?>.broadcast();
  UserRole? _currentRole;

  AuthRepositoryImpl({AppFirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? AppFirebaseService();

  @override
  Stream<UserRole?> get userRoleStream => _roleController.stream;

  @override
  UserRole? get currentRole => _currentRole;

  @override
  Future<void> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Attempt Firebase Auth sign-in if connected
    final auth = _firebaseService.auth;
    if (auth != null && email.isNotEmpty && password.isNotEmpty) {
      try {
        await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      } catch (e) {
        debugPrint('[AuthRepository] Firebase auth notice (proceeding in offline/demo mode): $e');
      }
    }

    _currentRole = role;
    _roleController.add(_currentRole);
  }

  @override
  Future<void> selectRole(UserRole role) async {
    _currentRole = role;
    _roleController.add(_currentRole);
  }

  @override
  Future<void> signOut() async {
    final auth = _firebaseService.auth;
    if (auth != null) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
    _currentRole = null;
    _roleController.add(null);
  }

  void dispose() {
    _roleController.close();
  }
}
