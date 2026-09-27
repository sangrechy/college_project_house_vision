import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/status_badge.dart';

class House3DViewerScreen extends StatefulWidget {
  const House3DViewerScreen({super.key});

  @override
  State<House3DViewerScreen> createState() => _House3DViewerScreenState();
}

class _House3DViewerScreenState extends State<House3DViewerScreen> {
  bool _autoRotate = true;
  String _currentOrbit = '45deg 65deg 105%';

  void _setOrbit(String orbit) {
    setState(() {
      _currentOrbit = orbit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('3D Architectural Model'),
        actions: [
          IconButton(
            tooltip: _autoRotate ? 'Pause Rotation' : 'Auto Rotate',
            icon: Icon(
              _autoRotate ? Icons.pause_circle_outline : Icons.play_circle_outline,
            ),
            onPressed: () {
              setState(() => _autoRotate = !_autoRotate);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'BIM Architectural Twin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Interactive 3D geometry rendered via WebGL. Pinch to zoom, drag to orbit.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          // 3D Canvas
          Container(
            height: 420,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                ModelViewer(
                  src: AppStrings.modelHouseGlb,
                  alt: '3D House Model',
                  autoRotate: _autoRotate,
                  cameraControls: true,
                  cameraOrbit: _currentOrbit,
                  backgroundColor: Colors.transparent,
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: StatusBadge(
                    label: '3D GLB ASSET',
                    textColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    icon: Icons.threed_rotation_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Camera Presets
          const Text(
            'Perspective Presets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setOrbit('0deg 75deg 105%'),
                  child: const Text('Front'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setOrbit('45deg 55deg 110%'),
                  child: const Text('Isometric'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setOrbit('0deg 10deg 120%'),
                  child: const Text('Top / Roof'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setOrbit('180deg 75deg 105%'),
                  child: const Text('Rear'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Gesture Guide Cards
          const Row(
            children: [
              Expanded(
                child: _GuideTile(
                  icon: Icons.touch_app_rounded,
                  title: 'Single Finger',
                  subtitle: 'Orbit / Rotate',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _GuideTile(
                  icon: Icons.pinch_rounded,
                  title: 'Two Fingers',
                  subtitle: 'Pinch to Zoom',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _GuideTile(
                  icon: Icons.pan_tool_alt_rounded,
                  title: 'Two Fingers',
                  subtitle: 'Pan Camera',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuideTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
