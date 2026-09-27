import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/design_component.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/verification_item.dart';
import '../../domain/repositories/project_repository.dart';
import '../services/firebase_service.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final AppFirebaseService _firebaseService;

  // In-memory single sources of truth with instant broadcast streams
  ProjectModel _cachedProject = ProjectModel.defaultProject();
  DesignComponent _cachedDesign = DesignComponent.initial();

  final _projectController = StreamController<ProjectModel>.broadcast();
  final _designController = StreamController<DesignComponent>.broadcast();

  StreamSubscription? _remoteSubscription;

  ProjectRepositoryImpl({AppFirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? AppFirebaseService() {
    _initRemoteSync('dream_home');
  }

  void _initRemoteSync(String projectId) {
    final remoteStream = _firebaseService.projectSnapshotStream(projectId);
    if (remoteStream != null) {
      _remoteSubscription = remoteStream.listen(
        (docSnapshot) {
          if (docSnapshot.exists && docSnapshot.data() != null) {
            final data = docSnapshot.data()!;
            _cachedProject = ProjectModel.fromMap(data, defaultId: projectId);
            _cachedDesign = DesignComponent.fromMap(data);

            _projectController.add(_cachedProject);
            _designController.add(_cachedDesign);
            debugPrint('[ProjectRepository] Received remote Firestore update: ${_cachedDesign.type.label} @ ${_cachedDesign.position}');
          }
        },
        onError: (err) {
          debugPrint('[ProjectRepository] Remote stream warning (fallback to local state): $err');
        },
      );
    }
  }

  @override
  Stream<ProjectModel> streamProject(String projectId) async* {
    yield _cachedProject;
    yield* _projectController.stream;
  }

  @override
  Future<ProjectModel> getProject(String projectId) async {
    final remoteData = await _firebaseService.getProjectData(projectId);
    if (remoteData != null) {
      _cachedProject = ProjectModel.fromMap(remoteData, defaultId: projectId);
    }
    return _cachedProject;
  }

  @override
  Stream<DesignComponent> streamLatestDesign(String projectId) async* {
    yield _cachedDesign;
    yield* _designController.stream;
  }

  @override
  Future<void> updateDesign(String projectId, DesignComponent component) async {
    _cachedDesign = component;
    _designController.add(_cachedDesign);

    // Save to Firestore
    final data = component.toMap();
    final success = await _firebaseService.setProjectData(projectId, data);
    debugPrint('[ProjectRepository] updateDesign synced to Firestore: $success');
  }

  @override
  Future<List<VerificationItem>> getVerificationItems(String projectId) async {
    return VerificationItem.sampleChecklist();
  }

  @override
  Future<void> updateProgress(String projectId, double progress) async {
    _cachedProject = _cachedProject.copyWith(progress: progress);
    _projectController.add(_cachedProject);

    await _firebaseService.setProjectData(projectId, {
      'progress': progress,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  void dispose() {
    _remoteSubscription?.cancel();
    _projectController.close();
    _designController.close();
  }
}
