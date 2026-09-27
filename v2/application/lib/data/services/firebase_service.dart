import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_strings.dart';

/// Low-level service wrapper for Firebase services with safety guards.
class AppFirebaseService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  AppFirebaseService({
    this._firestore,
    this._auth,
  });

  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get firestore {
    if (!isFirebaseAvailable) return null;
    try {
      return _firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[FirebaseService] Firestore unavailable: $e');
      return null;
    }
  }

  FirebaseAuth? get auth {
    if (!isFirebaseAvailable) return null;
    try {
      return _auth ?? FirebaseAuth.instance;
    } catch (e) {
      debugPrint('[FirebaseService] Auth unavailable: $e');
      return null;
    }
  }

  /// Live stream for a project document.
  Stream<DocumentSnapshot<Map<String, dynamic>>>? projectSnapshotStream(String projectId) {
    final db = firestore;
    if (db == null) return null;
    try {
      return db.collection(AppStrings.colProjects).doc(projectId).snapshots();
    } catch (e) {
      debugPrint('[FirebaseService] Failed to stream project: $e');
      return null;
    }
  }

  /// Write design update to project document.
  Future<bool> setProjectData(String projectId, Map<String, dynamic> data, {bool merge = true}) async {
    final db = firestore;
    if (db == null) return false;
    try {
      await db.collection(AppStrings.colProjects).doc(projectId).set(data, SetOptions(merge: merge));
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Firestore write failed: $e');
      return false;
    }
  }

  /// Fetch project data once.
  Future<Map<String, dynamic>?> getProjectData(String projectId) async {
    final db = firestore;
    if (db == null) return null;
    try {
      final doc = await db.collection(AppStrings.colProjects).doc(projectId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('[FirebaseService] Firestore read failed: $e');
      return null;
    }
  }
}
