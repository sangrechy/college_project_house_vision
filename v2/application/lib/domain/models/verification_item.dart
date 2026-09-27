import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum VerificationStatus {
  matched(label: 'Matched', icon: Icons.check_circle, color: AppColors.success),
  mismatch(label: 'Mismatch', icon: Icons.warning_rounded, color: AppColors.error),
  pending(label: 'Pending', icon: Icons.access_time_filled, color: AppColors.warning);

  final String label;
  final IconData icon;
  final Color color;

  const VerificationStatus({required this.label, required this.icon, required this.color});
}

/// Represents an inspected building element during reality check.
@immutable
class VerificationItem {
  final String id;
  final String title;
  final String description;
  final VerificationStatus status;
  final String? recommendation;

  const VerificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.recommendation,
  });

  static List<VerificationItem> sampleChecklist() {
    return const [
      VerificationItem(
        id: 'chk_wall_align',
        title: 'Wall Alignment',
        description: 'Perimeter masonry matches BIM coordinate grid (±3mm tolerance).',
        status: VerificationStatus.matched,
      ),
      VerificationItem(
        id: 'chk_window_pos',
        title: 'Window Opening',
        description: 'Rough opening for North bay window overlaps internal shear wall offset.',
        status: VerificationStatus.mismatch,
        recommendation: 'Pause lintel casting and verify before continuing framing.',
      ),
      VerificationItem(
        id: 'chk_door_pos',
        title: 'Door Jamb Clearance',
        description: 'Front entry double door rough clearance verified to 96" height.',
        status: VerificationStatus.matched,
      ),
      VerificationItem(
        id: 'chk_column_pos',
        title: 'Column Reinforcement',
        description: 'C3 structural column vertical rebars verified against structural drawings.',
        status: VerificationStatus.matched,
      ),
    ];
  }
}
