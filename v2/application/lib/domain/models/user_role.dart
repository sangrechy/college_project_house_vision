/// Supported actor roles in House Vision.
enum UserRole {
  homeowner(
    label: 'Homeowner',
    description: 'Explore 3D floor plans, customize finishes, and monitor build milestones.',
  ),
  constructor(
    label: 'Constructor',
    description: 'Verify field measurements, review homeowner design changes, and manage reality checks.',
  );

  final String label;
  final String description;

  const UserRole({required this.label, required this.description});
}
