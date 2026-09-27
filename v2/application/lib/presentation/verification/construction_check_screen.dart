import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../domain/models/verification_item.dart';

class ConstructionCheckScreen extends StatefulWidget {
  const ConstructionCheckScreen({super.key});

  @override
  State<ConstructionCheckScreen> createState() => _ConstructionCheckScreenState();
}

class _ConstructionCheckScreenState extends State<ConstructionCheckScreen> {
  final List<VerificationItem> _items = VerificationItem.sampleChecklist();

  void _triggerScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Site camera scanning initialized. Align viewport with ground marks.'),
      ),
    );
  }

  void _uploadVerification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inspection photos and LiDAR telemetry uploaded to cloud repository.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Field Inspection Checklist'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Milestone Verification',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check structural elements on site against architectural parameters.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Scanning Action Banner
          CustomCard(
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
            borderColor: AppColors.primary.withValues(alpha: 0.2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Site Photogrammetry',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Capture field photos to auto-align BIM geometry.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Verification Item Cards
          ..._items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(item.status.icon, color: item.status.color, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(
                            label: item.status.label.toUpperCase(),
                            textColor: item.status.color,
                            backgroundColor: item.status.color.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (item.recommendation != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.recommendation!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 20),

          // Action Buttons
          ElevatedButton.icon(
            onPressed: _triggerScan,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan Field Construction'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _uploadVerification,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Sync Checklist to Cloud'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
