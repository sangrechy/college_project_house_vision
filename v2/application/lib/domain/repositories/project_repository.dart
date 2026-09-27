import '../models/project_model.dart';
import '../models/design_component.dart';
import '../models/verification_item.dart';

/// Abstract contract for project data access, real-time sync, and design updates.
abstract interface class ProjectRepository {
  /// Stream real-time project overview.
  Stream<ProjectModel> streamProject(String projectId);

  /// Fetch single project snapshot.
  Future<ProjectModel> getProject(String projectId);

  /// Stream live design component updates (bi-directional sync between Homeowner and Constructor).
  Stream<DesignComponent> streamLatestDesign(String projectId);

  /// Persist a modified design component to Firestore and notify all listeners.
  Future<void> updateDesign(String projectId, DesignComponent component);

  /// Retrieve verification and inspection checklist items.
  Future<List<VerificationItem>> getVerificationItems(String projectId);

  /// Update construction progress percentage.
  Future<void> updateProgress(String projectId, double progress);
}
