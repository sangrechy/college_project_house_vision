/// Centralized application strings and asset references.
abstract final class AppStrings {
  static const String appName = 'House Vision';
  static const String appTagline = 'Visualize • Build • Monitor';
  static const String defaultProjectId = 'dream_home';
  static const String defaultProjectName = 'Dream Home Residence';
  static const String defaultProjectLocation = 'Coimbatore, Tamil Nadu';

  // Asset Paths
  static const String modelHouseGlb = 'assets/models/house.glb';
  static const String modelHouseArGlb = 'assets/models/house_ar.glb';
  static const String modelHousePng = 'assets/models/house.png';

  // Firestore Collections
  static const String colProjects = 'projects';
  static const String colUsers = 'users';
  static const String colDesignUpdates = 'design_updates';
  static const String colVerifications = 'verifications';
}
