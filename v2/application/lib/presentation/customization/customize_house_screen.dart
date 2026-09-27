import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hud_telemetry_bar.dart';
import '../../domain/models/design_component.dart';
import '../../domain/repositories/project_repository.dart';
import 'customize_view_model.dart';

class CustomizeHouseScreen extends StatelessWidget {
  const CustomizeHouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CustomizeViewModel(
        projectRepository: ctx.read<ProjectRepository>(),
      ),
      child: const _CustomizeHouseView(),
    );
  }
}

class _CustomizeHouseView extends StatefulWidget {
  const _CustomizeHouseView();

  @override
  State<_CustomizeHouseView> createState() => _CustomizeHouseViewState();
}

class _CustomizeHouseViewState extends State<_CustomizeHouseView> {
  // Architectural Layer visibility
  bool _layerFraming = true;
  bool _layerUtilities = true;
  bool _layerEnvelope = true;

  final Map<int, String> _materialLabels = {
    0xFF64748B: 'Polished Concrete',
    0xFF1E293B: 'Matte Dark Steel',
    0xFFD97706: 'Scandinavian Timber',
    0xFF991B1B: 'Terracotta Brick',
    0xFF06B6D4: 'Electric Cyan Glazing',
    0xFF10B981: 'Green Biophilic Wall',
    0xFFE2E8F0: 'Architectural Off-White',
    0xFF78350F: 'Natural Cedar Shingle',
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomizeViewModel>();

    // Dynamic cost calculation based on selected elements & scale
    final baseCost = 285000;
    final elementDelta = ((vm.position * 8500) + (vm.size * 14200)).round();
    final totalCost = baseCost + elementDelta;

    final selectedMaterialName = _materialLabels[vm.selectedColor.toARGB32()] ?? 'Architectural Custom';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('3D BIM Studio & Customizer'),
        actions: [
          IconButton(
            tooltip: 'Reset BIM Parameters',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              vm.updatePosition(0.5);
              vm.updateSize(0.5);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Top HUD Telemetry
          const HudTelemetryBar(
            siteTag: 'BIM PARAMETRIC TWIN • LOD 400',
            coordinates: '11°01\'24.8"N 76°58\'12.4"E',
            isLiDarActive: true,
          ),
          const SizedBox(height: 12),

          // 3D Canvas with Interactive Markers
          Container(
            height: 380,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderHighlight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const ModelViewer(
                  src: AppStrings.modelHouseGlb,
                  alt: '3D BIM House Model',
                  autoRotate: false,
                  cameraControls: true,
                  backgroundColor: Colors.transparent,
                ),

                // Top Left Layer Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'INTERACTIVE TWIN',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Draggable Interactive Component Marker
                Positioned(
                  left: 24 + (vm.position * 230),
                  top: 130,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final newPos = vm.position + (details.delta.dx / 230);
                      vm.updatePosition(newPos);
                    },
                    child: Container(
                      width: 52 + (vm.size * 42),
                      height: 52 + (vm.size * 42),
                      decoration: BoxDecoration(
                        color: vm.selectedColor.withValues(alpha: 0.25),
                        border: Border.all(
                          color: vm.selectedColor,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: vm.selectedColor.withValues(alpha: 0.45),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          vm.selectedType.icon,
                          color: vm.selectedColor,
                          size: 26 + (vm.size * 12),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Active Material Pill
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderHighlight),
                    ),
                    child: Row(
                      children: [
                        Icon(vm.selectedType.icon, color: vm.selectedColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${vm.selectedType.label}: $selectedMaterialName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'X: ${(vm.position * 100).toInt()}% • Scale: ${(vm.size * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Real-Time Cost & Engineering Budget Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderHighlight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATED BIM COST ESTIMATE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${totalCost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '+${((elementDelta / baseCost) * 100).toStringAsFixed(1)}% VAR',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Architectural Layers Filter
          const Text(
            'Architectural Model Layers',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLayerChip('Structure & Framing', _layerFraming, () {
                setState(() => _layerFraming = !_layerFraming);
              }),
              const SizedBox(width: 8),
              _buildLayerChip('MEP Utilities', _layerUtilities, () {
                setState(() => _layerUtilities = !_layerUtilities);
              }),
              const SizedBox(width: 8),
              _buildLayerChip('Envelope', _layerEnvelope, () {
                setState(() => _layerEnvelope = !_layerEnvelope);
              }),
            ],
          ),

          const SizedBox(height: 20),

          // Component Type Tabs
          const Text(
            'Component Focus',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: ComponentType.values.map((type) {
              final isSelected = vm.selectedType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => vm.selectType(type),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 20,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Fine Adjustment Sliders
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${vm.selectedType.label} Spatial Offset (X)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${(vm.position * 100).round()}%',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                Slider(value: vm.position, onChanged: vm.updatePosition),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${vm.selectedType.label} Scale Factor',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${(vm.size * 100).round()}%',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                Slider(value: vm.size, onChanged: vm.updateSize),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Architectural Material Finish
          const Text(
            'Material & Surface Texture',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.customizerPalette.map((color) {
              final isSelected = vm.selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => vm.selectColor(color),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderHighlight,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Save & Sync Push Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: vm.isSaving
                  ? null
                  : () async {
                      final success = await vm.saveDesign();
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceElevated,
                            content: Row(
                              children: [
                                const Icon(Icons.cloud_done_rounded, color: AppColors.success),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    vm.saveSuccessMessage ?? 'BIM model synced to constructor tablets.',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
              icon: vm.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                vm.isSaving ? 'Pushing BIM Update...' : 'Push BIM Update to Site Tablets',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLayerChip(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
