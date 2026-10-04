import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hud_telemetry_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/services/floorplan_3d_extruder.dart';
import '../ar_viewer/ar_house_screen.dart';

/// Preset blueprint layouts for 2D to 3D construction
class FloorplanPreset {
  final String id;
  final String name;
  final String description;
  final String dimensions;
  final int totalSqFt;
  final double defaultWallHeight;
  final List<RoomZone> rooms;

  const FloorplanPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.dimensions,
    required this.totalSqFt,
    required this.defaultWallHeight,
    required this.rooms,
  });
}

class RoomZone {
  final String name;
  final String dims;
  final Rect relativeRect; // Relative coordinates [0.0 - 1.0] on blueprint
  final Color tintColor;
  final int areaSqFt;

  const RoomZone({
    required this.name,
    required this.dims,
    required this.relativeRect,
    required this.tintColor,
    required this.areaSqFt,
  });
}

enum ConstructionStage {
  blueprint2D(0, '2D Blueprint Schematic', 'Architectural dimensioned CAD layout'),
  foundation(1, 'Plinth & Foundation', 'Concrete footings & reinforced slab casting'),
  wallExtrusion(2, 'Wall Extrusion & Framing', 'Load-bearing masonry extruded upward'),
  roofEnvelope(3, 'Roof & Envelope Assembly', 'Timber roof framing and trusses'),
  complete3D(4, 'Complete 3D BIM Twin', 'Finished interactive architectural structure');

  final int step;
  final String title;
  final String subtitle;

  const ConstructionStage(this.step, this.title, this.subtitle);
}

class Floorplan2DTo3DScreen extends StatefulWidget {
  const Floorplan2DTo3DScreen({super.key});

  @override
  State<Floorplan2DTo3DScreen> createState() => _Floorplan2DTo3DScreenState();
}

class _Floorplan2DTo3DScreenState extends State<Floorplan2DTo3DScreen> {
  static final List<FloorplanPreset> _presets = [
    const FloorplanPreset(
      id: 'villa_2bhk',
      name: 'Modern Villa (2BHK)',
      description: 'Open-concept contemporary residence with private master suite',
      dimensions: '36\'0" × 32\'0"',
      totalSqFt: 1152,
      defaultWallHeight: 3.0,
      rooms: [
        RoomZone(
          name: 'Living & Dining',
          dims: '18\' × 14\'',
          relativeRect: Rect.fromLTWH(0.06, 0.08, 0.52, 0.44),
          tintColor: Color(0xFFED8943),
          areaSqFt: 252,
        ),
        RoomZone(
          name: 'Kitchen',
          dims: '12\' × 10\'',
          relativeRect: Rect.fromLTWH(0.62, 0.08, 0.32, 0.32),
          tintColor: Color(0xFF0D9488),
          areaSqFt: 120,
        ),
        RoomZone(
          name: 'Master Suite',
          dims: '14\' × 13\'',
          relativeRect: Rect.fromLTWH(0.06, 0.56, 0.46, 0.38),
          tintColor: Color(0xFF3B82F6),
          areaSqFt: 182,
        ),
        RoomZone(
          name: 'Guest Bedroom',
          dims: '12\' × 11\'',
          relativeRect: Rect.fromLTWH(0.56, 0.56, 0.38, 0.38),
          tintColor: Color(0xFF8B5CF6),
          areaSqFt: 132,
        ),
      ],
    ),
    const FloorplanPreset(
      id: 'cabin_rustic',
      name: 'Rustic Timber Cabin (1BHK)',
      description: 'Compact modular timber cottage with chimney and porch',
      dimensions: '28\'0" × 20\'0"',
      totalSqFt: 560,
      defaultWallHeight: 2.8,
      rooms: [
        RoomZone(
          name: 'Great Room',
          dims: '16\' × 14\'',
          relativeRect: Rect.fromLTWH(0.08, 0.10, 0.54, 0.78),
          tintColor: Color(0xFFD97706),
          areaSqFt: 224,
        ),
        RoomZone(
          name: 'Bunk Room',
          dims: '10\' × 10\'',
          relativeRect: Rect.fromLTWH(0.66, 0.10, 0.26, 0.44),
          tintColor: Color(0xFF10B981),
          areaSqFt: 100,
        ),
        RoomZone(
          name: 'Bath & Storage',
          dims: '10\' × 8\'',
          relativeRect: Rect.fromLTWH(0.66, 0.58, 0.26, 0.30),
          tintColor: Color(0xFF64748B),
          areaSqFt: 80,
        ),
      ],
    ),
  ];

  FloorplanPreset _selectedPreset = _presets[0];
  ConstructionStage _currentStage = ConstructionStage.blueprint2D;
  double _wallHeight = 3.0; // in meters (2.4 to 3.8)
  String _wallMaterial = 'Scandinavian Timber';
  RoomZone? _selectedRoom;
  bool _showDimensions = true;

  // Real 2D to 3D Extrusion State
  Uint8List? _uploadedBlueprintBytes;
  List<DetectedRoom>? _customDetectedRooms;
  bool _isCustomPlan = false;
  String? _extrudedGlbDataUri;
  bool _isExtruding = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _wallMaterials = [
    'Scandinavian Timber',
    'Exposed Red Brick',
    'Cast Concrete',
    'Architectural Stucco',
  ];

  @override
  void initState() {
    super.initState();
    _regenerateGlb();
  }

  List<DetectedRoom> _getActiveRooms() {
    if (_isCustomPlan && _customDetectedRooms != null && _customDetectedRooms!.isNotEmpty) {
      return _customDetectedRooms!;
    }
    return _selectedPreset.rooms.map((r) {
      return DetectedRoom(
        name: r.name,
        x: r.relativeRect.left * 11.0,
        y: r.relativeRect.top * 9.75,
        width: r.relativeRect.width * 11.0,
        length: r.relativeRect.height * 9.75,
        areaSqFt: r.areaSqFt,
      );
    }).toList();
  }

  void _regenerateGlb() {
    try {
      final rooms = _getActiveRooms();
      final glbBytes = Floorplan3dExtruder.generateGlb(
        rooms: rooms,
        wallHeight: _wallHeight,
        wallMaterial: _wallMaterial,
      );
      final base64Str = base64Encode(glbBytes);
      setState(() {
        _extrudedGlbDataUri = 'data:model/gltf-binary;base64,$base64Str';
      });
    } catch (e) {
      debugPrint('[Floorplan2DTo3D] Error generating procedural GLB: $e');
    }
  }

  Future<void> _pickBlueprintImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isExtruding = true);

      final bytes = await picked.readAsBytes();
      final detectedRooms = Floorplan3dExtruder.analyzeFloorplanImage(bytes);

      setState(() {
        _uploadedBlueprintBytes = bytes;
        _customDetectedRooms = detectedRooms;
        _isCustomPlan = true;
        _selectedRoom = null;
        _isExtruding = false;
      });

      _regenerateGlb();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Real 2D→3D Extrusion: Analyzed plan with ${detectedRooms.length} room zones!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[Floorplan2DTo3D] Error processing image: $e');
      if (mounted) {
        setState(() => _isExtruding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process floorplan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('2D Blueprint → 3D Construction'),
        actions: [
          IconButton(
            tooltip: 'Launch Direct in AR',
            icon: const Icon(Icons.view_in_ar_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARHouseScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Top HUD Telemetry
          const HudTelemetryBar(
            siteTag: 'PARAMETRIC 2D-TO-3D CAD ENGINE • LIVE',
            coordinates: '11°01\'24.8"N 76°58\'12.4"E',
            isLiDarActive: true,
          ),
          const SizedBox(height: 12),

          // Blueprint Input Source Card (Camera/Gallery CV scan)
          _buildBlueprintSourceCard(),
          const SizedBox(height: 10),

          // Plan Preset Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presets.map((preset) {
                final isSelected = !_isCustomPlan && preset.id == _selectedPreset.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      preset.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedPreset = preset;
                          _wallHeight = preset.defaultWallHeight;
                          _selectedRoom = null;
                          _isCustomPlan = false;
                        });
                        _regenerateGlb();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Main Viewport (2D Blueprint or 3D Extrusion depending on stage)
          _buildConstructionViewport(),
          const SizedBox(height: 16),

          // Construction Stage Stepper
          _buildStageStepper(),
          const SizedBox(height: 16),

          // Parametric Controls & Material Selection
          _buildParametricControls(),
          const SizedBox(height: 16),

          // Room Inspector & Material Bill of Quantities
          _buildBillOfQuantities(),
          const SizedBox(height: 20),

          // Bottom Action: Direct Spatial AR Launch Button
          _buildArLaunchButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBlueprintSourceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppColors.neumorphicPillShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.document_scanner_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    '2D Blueprint Input (Real-time CV Engine)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (_isCustomPlan)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCustomPlan = false;
                      _uploadedBlueprintBytes = null;
                      _customDetectedRooms = null;
                      _wallHeight = _selectedPreset.defaultWallHeight;
                    });
                    _regenerateGlb();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reset to Preset',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a floorplan drawing or photo of a sketched blueprint. On-device lightweight CV analyzes wall contours and dynamically compiles a 3D BIM glTF mesh.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Upload Blueprint', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  onPressed: _isExtruding ? null : () => _pickBlueprintImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Capture Sketch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  onPressed: _isExtruding ? null : () => _pickBlueprintImage(ImageSource.camera),
                ),
              ),
            ],
          ),
          if (_isCustomPlan) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Custom Plan Active: ${_customDetectedRooms?.length ?? 0} Rooms detected & procedurally extruded to 3D!',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConstructionViewport() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppColors.neumorphicShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_currentStage == ConstructionStage.complete3D)
            // Stage 5: Full 3D BIM House rendered via WebGL
            if (_isExtruding)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Extruding 3D BIM Mesh on Device...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              KeyedSubtree(
                key: ValueKey('glb_${_extrudedGlbDataUri.hashCode}_${_wallHeight.toStringAsFixed(1)}_$_wallMaterial'),
                child: ModelViewer(
                  src: _extrudedGlbDataUri ?? AppStrings.modelHouseArGlb,
                  alt: '3D Extruded Architectural Model',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: AppColors.scaffoldBackground,
                  loading: Loading.eager,
                  reveal: Reveal.auto,
                  shadowIntensity: 0.9,
                  ar: true,
                  arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                ),
              )
          else if (_isCustomPlan && _uploadedBlueprintBytes != null && _currentStage == ConstructionStage.blueprint2D)
            Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _uploadedBlueprintBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Text(
                      '${_customDetectedRooms?.length ?? 0} ROOMS DETECTED',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Stages 1-4: Interactive 2D Schematic / Extrusion Simulation Canvas
            GestureDetector(
              onTapDown: (details) {
                final local = details.localPosition;
                final width = 380.0;
                final height = 380.0;
                final relX = local.dx / width;
                final relY = local.dy / height;

                for (final room in _selectedPreset.rooms) {
                  if (room.relativeRect.contains(Offset(relX, relY))) {
                    setState(() => _selectedRoom = room);
                    return;
                  }
                }
                setState(() => _selectedRoom = null);
              },
              child: CustomPaint(
                size: const Size(double.infinity, 380),
                painter: _BlueprintExtrusionPainter(
                  preset: _selectedPreset,
                  stage: _currentStage,
                  wallHeight: _wallHeight,
                  selectedRoom: _selectedRoom,
                  showDimensions: _showDimensions,
                ),
              ),
            ),

          // Overlay Tag: Current Mode
          Positioned(
            top: 14,
            left: 14,
            child: StatusBadge(
              label: _currentStage.title.toUpperCase(),
              textColor: AppColors.primary,
              backgroundColor: Colors.white,
              icon: _currentStage == ConstructionStage.complete3D
                  ? Icons.view_in_ar_rounded
                  : Icons.architecture_rounded,
            ),
          ),

          // Dimension Toggle Button
          if (_currentStage != ConstructionStage.complete3D)
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                tooltip: 'Toggle Dimensions',
                icon: Icon(
                  Icons.straighten_rounded,
                  color: _showDimensions ? AppColors.accentOrange : AppColors.textSecondary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                ),
                onPressed: () {
                  setState(() => _showDimensions = !_showDimensions);
                },
              ),
            ),

          // Bottom Info Pill
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedPreset.dimensions} • ${_selectedPreset.totalSqFt} sq.ft',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Extrusion: ${_wallHeight.toStringAsFixed(1)}m',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageStepper() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Construction Progression',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Stage ${_currentStage.step + 1} of 5',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _currentStage.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Segmented Progress Bar
          Row(
            children: List.generate(5, (index) {
              final isPassed = index <= _currentStage.step;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStage = ConstructionStage.values[index];
                    });
                  },
                  child: Container(
                    height: 8,
                    margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isPassed ? AppColors.primary : AppColors.border,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Stage Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentStage.step > 0
                      ? () {
                          setState(() {
                            _currentStage = ConstructionStage.values[_currentStage.step - 1];
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous Step'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentStage.step < 4
                      ? () {
                          setState(() {
                            _currentStage = ConstructionStage.values[_currentStage.step + 1];
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(_currentStage.step == 3 ? 'Finalize 3D' : 'Next Stage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParametricControls() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parametric Architectural Controls',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Wall Height Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clear Ceiling Height:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_wallHeight.toStringAsFixed(1)} m (${(_wallHeight * 3.28084).toStringAsFixed(1)} ft)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _wallHeight,
            min: 2.4,
            max: 3.8,
            divisions: 14,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              setState(() => _wallHeight = val);
              _regenerateGlb();
            },
          ),
          const SizedBox(height: 10),

          // Material Finish Chips
          const Text(
            'Wall Construction Material:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wallMaterials.map((mat) {
              final isSelected = mat == _wallMaterial;
              return ChoiceChip(
                label: Text(
                  mat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.accentOrange,
                backgroundColor: AppColors.surface,
                onSelected: (val) {
                  if (val) {
                    setState(() => _wallMaterial = mat);
                    _regenerateGlb();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillOfQuantities() {
    // Estimations based on square footage and wall height
    final concreteCuM = (_selectedPreset.totalSqFt * 0.035).toStringAsFixed(1);
    final rebarTons = (_selectedPreset.totalSqFt * 0.0032).toStringAsFixed(2);
    final timberSqM = (_selectedPreset.totalSqFt * 0.12 * (_wallHeight / 3.0)).toStringAsFixed(0);
    final estimatedCost = (_selectedPreset.totalSqFt * 1650 * (_wallHeight / 3.0)).round();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Material Estimation & BOQ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹ ${(estimatedCost / 100000).toStringAsFixed(2)} Lakhs',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBoqStat('Concrete', '$concreteCuM m³', Icons.foundation_rounded),
              _buildBoqStat('Rebar Steel', '$rebarTons tons', Icons.line_weight_rounded),
              _buildBoqStat('Timber/Framing', '$timberSqM m²', Icons.carpenter_rounded),
            ],
          ),
          if (_selectedRoom != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _selectedRoom!.tintColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected: ${_selectedRoom!.name} (${_selectedRoom!.dims} • ${_selectedRoom!.areaSqFt} sq.ft)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoqStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildArLaunchButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ARHouseScreen(
                    customGlbSrc: _extrudedGlbDataUri,
                    initialPlacementMode: ARPlacementMode.wallBaseAnchor,
                    modelTitle: _isCustomPlan ? 'Custom Extruded 2D→3D' : _selectedPreset.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.vertical_align_bottom_rounded, size: 22),
            label: const Text(
              'MOUNT BASE ON WALL (AR)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ARHouseScreen(
                    customGlbSrc: _extrudedGlbDataUri,
                    initialPlacementMode: ARPlacementMode.floorAnchor,
                    modelTitle: _isCustomPlan ? 'Custom Extruded 2D→3D' : _selectedPreset.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.layers_rounded, size: 20),
            label: const Text(
              'PROJECT ON FLOOR GROUND (AR)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the 2D architectural blueprint and extrusion preview
class _BlueprintExtrusionPainter extends CustomPainter {
  final FloorplanPreset preset;
  final ConstructionStage stage;
  final double wallHeight;
  final RoomZone? selectedRoom;
  final bool showDimensions;

  _BlueprintExtrusionPainter({
    required this.preset,
    required this.stage,
    required this.wallHeight,
    required this.selectedRoom,
    required this.showDimensions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Architectural CAD Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFCAD5E2).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    const gridSize = 24.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Extrusion perspective offset calculation based on stage
    double extrudeDx = 0;
    double extrudeDy = 0;

    if (stage == ConstructionStage.foundation) {
      extrudeDx = 6.0;
      extrudeDy = -8.0;
    } else if (stage == ConstructionStage.wallExtrusion) {
      extrudeDx = 14.0 * (wallHeight / 3.0);
      extrudeDy = -26.0 * (wallHeight / 3.0);
    } else if (stage == ConstructionStage.roofEnvelope) {
      extrudeDx = 22.0 * (wallHeight / 3.0);
      extrudeDy = -42.0 * (wallHeight / 3.0);
    }

    // 3. Draw Room Zones (Flooring & Area Tint)
    for (final room in preset.rooms) {
      final rect = Rect.fromLTWH(
        room.relativeRect.left * size.width,
        room.relativeRect.top * size.height,
        room.relativeRect.width * size.width,
        room.relativeRect.height * size.height,
      );

      final isSelected = selectedRoom?.name == room.name;

      // Fill room zone
      final roomFillPaint = Paint()
        ..color = isSelected
            ? room.tintColor.withValues(alpha: 0.35)
            : room.tintColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, roomFillPaint);

      // Room label & dimensions
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${room.name}\n',
            style: TextStyle(
              color: isSelected ? room.tintColor : const Color(0xFF1E293B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (showDimensions)
            TextSpan(
              text: '${room.dims} (${room.areaSqFt} sq.ft)',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 8);

      textPainter.paint(
        canvas,
        Offset(
          rect.center.dx - (textPainter.width / 2),
          rect.center.dy - (textPainter.height / 2),
        ),
      );
    }

    // 4. Extruded 3D Wall Shadows / Volume (When in wallExtrusion or roofEnvelope stages)
    if (stage == ConstructionStage.wallExtrusion || stage == ConstructionStage.roofEnvelope) {
      final wall3dPaint = Paint()
        ..color = const Color(0xFFED8943).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      for (final room in preset.rooms) {
        final rect = Rect.fromLTWH(
          room.relativeRect.left * size.width,
          room.relativeRect.top * size.height,
          room.relativeRect.width * size.width,
          room.relativeRect.height * size.height,
        );

        // Right side wall polygon
        final rightWall = Path()
          ..moveTo(rect.right, rect.top)
          ..lineTo(rect.right + extrudeDx, rect.top + extrudeDy)
          ..lineTo(rect.right + extrudeDx, rect.bottom + extrudeDy)
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(rightWall, wall3dPaint);

        // Top side wall polygon
        final topWall = Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.left + extrudeDx, rect.top + extrudeDy)
          ..lineTo(rect.right + extrudeDx, rect.top + extrudeDy)
          ..lineTo(rect.right, rect.top)
          ..close();
        canvas.drawPath(topWall, wall3dPaint);
      }
    }

    // 5. Exterior Wall Contours (Load-Bearing Masonry Lines)
    final wallPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final interiorWallPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final room in preset.rooms) {
      final rect = Rect.fromLTWH(
        room.relativeRect.left * size.width,
        room.relativeRect.top * size.height,
        room.relativeRect.width * size.width,
        room.relativeRect.height * size.height,
      );
      canvas.drawRect(rect, interiorWallPaint);
    }

    // Outer bounding perimeter
    double minX = size.width, minY = size.height, maxX = 0, maxY = 0;
    for (final room in preset.rooms) {
      final r = Rect.fromLTWH(
        room.relativeRect.left * size.width,
        room.relativeRect.top * size.height,
        room.relativeRect.width * size.width,
        room.relativeRect.height * size.height,
      );
      minX = min(minX, r.left);
      minY = min(minY, r.top);
      maxX = max(maxX, r.right);
      maxY = max(maxY, r.bottom);
    }
    final outerPerimeter = Rect.fromLTRB(minX, minY, maxX, maxY);
    canvas.drawRect(outerPerimeter, wallPaint);

    // 6. Draw Exterior Dimension Chains
    if (showDimensions) {
      final dimPaint = Paint()
        ..color = const Color(0xFFED8943)
        ..strokeWidth = 1.2;

      // Top Dimension Line
      final topDimY = outerPerimeter.top - 14;
      canvas.drawLine(Offset(outerPerimeter.left, topDimY), Offset(outerPerimeter.right, topDimY), dimPaint);
      canvas.drawLine(Offset(outerPerimeter.left, topDimY - 4), Offset(outerPerimeter.left, topDimY + 4), dimPaint);
      canvas.drawLine(Offset(outerPerimeter.right, topDimY - 4), Offset(outerPerimeter.right, topDimY + 4), dimPaint);

      final widthText = TextPainter(
        text: TextSpan(
          text: preset.dimensions.split('×').first.trim(),
          style: const TextStyle(
            color: Color(0xFFED8943),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      widthText.paint(
        canvas,
        Offset(outerPerimeter.center.dx - (widthText.width / 2), topDimY - 14),
      );

      // Left Dimension Line
      final leftDimX = outerPerimeter.left - 14;
      canvas.drawLine(Offset(leftDimX, outerPerimeter.top), Offset(leftDimX, outerPerimeter.bottom), dimPaint);
      canvas.drawLine(Offset(leftDimX - 4, outerPerimeter.top), Offset(leftDimX + 4, outerPerimeter.top), dimPaint);
      canvas.drawLine(Offset(leftDimX - 4, outerPerimeter.bottom), Offset(leftDimX + 4, outerPerimeter.bottom), dimPaint);

      final heightText = TextPainter(
        text: TextSpan(
          text: preset.dimensions.split('×').last.trim(),
          style: const TextStyle(
            color: Color(0xFFED8943),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      heightText.paint(
        canvas,
        Offset(leftDimX - heightText.width - 4, outerPerimeter.center.dy - (heightText.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintExtrusionPainter oldDelegate) {
    return oldDelegate.preset != preset ||
        oldDelegate.stage != stage ||
        oldDelegate.wallHeight != wallHeight ||
        oldDelegate.selectedRoom != selectedRoom ||
        oldDelegate.showDimensions != showDimensions;
  }
}
