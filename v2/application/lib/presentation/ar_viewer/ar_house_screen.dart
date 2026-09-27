import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/hud_telemetry_bar.dart';

class ARHouseScreen extends StatefulWidget {
  const ARHouseScreen({super.key});

  @override
  State<ARHouseScreen> createState() => _ARHouseScreenState();
}

class _ARHouseScreenState extends State<ARHouseScreen> with SingleTickerProviderStateMixin {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARNode? _houseNode;

  bool _housePlaced = false;
  bool _isLoading = false;
  bool _isSpatialStudioMode = true; // Default to Spatial Studio for reliable high-fidelity prototype
  String _statusMessage = 'LiDAR Ground Plane Locked • Ready for Site Projection';

  // Interactive 3D Spatial Controls
  double _scaleMultiplier = 1.0; // 1.0 = Tabletop 1:50, 2.0 = Field 1:20, 5.0 = True-Scale 1:1
  double _rotationAngle = 45.0; // Degrees
  final double _elevationHeight = 0.0; // Meters (-1.0m to +3.0m)
  double _sunHour = 14.0; // 14:00 (2 PM sun angle)

  // Virtual Laser Tape Measure state
  bool _tapeMeasureActive = false;
  Offset? _tapePointA;
  Offset? _tapePointB;
  double? _measuredDistanceMeters;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      _isSpatialStudioMode = true;
    }
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;

    sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true,
    );

    objectManager.onInitialize();
    sessionManager.onPlaneOrPointTap = _onPlaneTapped;
  }

  Future<void> _onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    if (_housePlaced || _isLoading || hitTestResults.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Anchoring structural BIM model to physical plane...';
    });

    try {
      final hit = hitTestResults.first;
      final translation = hit.worldTransform.getTranslation();

      final node = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: AppStrings.modelHouseArGlb,
        name: 'HouseVisionModel',
        scale: vector.Vector3(0.05 * _scaleMultiplier, 0.05 * _scaleMultiplier, 0.05 * _scaleMultiplier),
        position: vector.Vector3(translation.x, translation.y + _elevationHeight, translation.z),
        rotation: vector.Vector4(0, 1, 0, _rotationAngle * (pi / 180.0)),
      );

      final added = await _objectManager?.addNode(node);
      if (added == true) {
        _houseNode = node;
        if (mounted) {
          setState(() {
            _housePlaced = true;
            _statusMessage = 'BIM Model Anchored. 3D Spatial Gizmos Active.';
          });
        }
      }
    } catch (e) {
      debugPrint('[ARHouseScreen] Fallback to Spatial Studio: $e');
      if (mounted) {
        setState(() {
          _isSpatialStudioMode = true;
          _statusMessage = 'Physical plane sensor offline. Switched to Spatial AR Studio.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetHouse() async {
    if (_houseNode != null) {
      await _objectManager?.removeNode(_houseNode!);
      _houseNode = null;
    }
    if (mounted) {
      setState(() {
        _housePlaced = false;
        _statusMessage = 'Tap surface plane to re-anchor BIM model.';
      });
    }
  }

  void _handleScreenTap(TapDownDetails details) {
    if (!_tapeMeasureActive) return;

    setState(() {
      if (_tapePointA == null) {
        _tapePointA = details.localPosition;
        _tapePointB = null;
        _measuredDistanceMeters = null;
      } else if (_tapePointB == null) {
        _tapePointB = details.localPosition;
        // Vector distance calculation
        final dx = _tapePointB!.dx - _tapePointA!.dx;
        final dy = _tapePointB!.dy - _tapePointA!.dy;
        final pixelDistance = sqrt(dx * dx + dy * dy);
        // Scale to simulated site meters (approx 40px per meter)
        _measuredDistanceMeters = (pixelDistance / 42.0) * (1.0 / _scaleMultiplier);
      } else {
        // Reset and start new measurement
        _tapePointA = details.localPosition;
        _tapePointB = null;
        _measuredDistanceMeters = null;
      }
    });
  }

  void _resetTapeMeasure() {
    setState(() {
      _tapePointA = null;
      _tapePointB = null;
      _measuredDistanceMeters = null;
    });
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sunAngleRad = ((_sunHour - 6) / 12) * pi;
    final shadowOffsetX = cos(sunAngleRad) * 45;
    final shadowOffsetY = sin(sunAngleRad) * 25;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('AR Site Projector'),
        actions: [
          // Reset Placement
          IconButton(
            tooltip: 'Reset Plane Placement',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetHouse,
          ),
          // Tape measure toggle
          IconButton(
            tooltip: 'Virtual Laser Tape Measure',
            icon: Icon(
              Icons.straighten,
              color: _tapeMeasureActive ? AppColors.accentOrange : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _tapeMeasureActive = !_tapeMeasureActive;
                if (!_tapeMeasureActive) _resetTapeMeasure();
              });
            },
          ),
          // Mode switch
          IconButton(
            tooltip: _isSpatialStudioMode ? 'Switch to Camera AR' : 'Switch to Spatial Studio',
            icon: Icon(
              _isSpatialStudioMode ? Icons.view_in_ar_rounded : Icons.apartment_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() => _isSpatialStudioMode = !_isSpatialStudioMode);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main 3D Viewport
          _isSpatialStudioMode
              ? Stack(
                  children: [
                    // Simulated Architectural Ground Plane Grid
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SpatialGroundGridPainter(
                          rotationDeg: _rotationAngle,
                          shadowOffset: Offset(shadowOffsetX, shadowOffsetY),
                          scaleFactor: _scaleMultiplier,
                        ),
                      ),
                    ),

                    // 3D House Model Renderer
                    const Positioned.fill(
                      child: ModelViewer(
                        src: AppStrings.modelHouseArGlb,
                        alt: 'BIM Spatial Model',
                        autoRotate: false,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ],
                )
              : ARView(
                  onARViewCreated: _onARViewCreated,
                  planeDetectionConfig: PlaneDetectionConfig.horizontal,
                ),

          // Top HUD Telemetry Bar
          const Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: HudTelemetryBar(
              siteTag: 'AR SPATIAL PROJECTOR • BIM LOD 400',
              coordinates: '11°01\'24.8"N 76°58\'12.4"E',
              isLiDarActive: true,
            ),
          ),

          // Status & Tooltip Pill
          Positioned(
            top: 62,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderHighlight),
              ),
              child: Row(
                children: [
                  Icon(
                    _tapeMeasureActive ? Icons.straighten : Icons.grid_4x4_rounded,
                    size: 16,
                    color: _tapeMeasureActive ? AppColors.accentOrange : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tapeMeasureActive
                          ? (_tapePointA == null
                              ? 'Tap Point A to set laser datum'
                              : (_tapePointB == null
                                  ? 'Tap Point B to measure span'
                                  : 'Span: ${_measuredDistanceMeters!.toStringAsFixed(2)}m (${(_measuredDistanceMeters! * 3.28084).toStringAsFixed(1)} ft)'))
                          : _statusMessage,
                      style: TextStyle(
                        color: _tapeMeasureActive ? AppColors.accentOrange : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_tapeMeasureActive && _tapePointA != null)
                    InkWell(
                      onTap: _resetTapeMeasure,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'RESET',
                          style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Virtual Tape Measure Gesture & Laser Painter Overlay
          if (_tapeMeasureActive)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _handleScreenTap,
                child: CustomPaint(
                  painter: _TapeMeasureLaserPainter(
                    pointA: _tapePointA,
                    pointB: _tapePointB,
                    distanceMeters: _measuredDistanceMeters,
                  ),
                ),
              ),
            ),

          // Bottom 3D Spatial Gizmo Controls Dock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderHighlight, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Scale Selector Preset Chips
                  Row(
                    children: [
                      const Text(
                        'SCALE',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      _buildScaleChip('1:100 Tabletop', 0.5),
                      const SizedBox(width: 8),
                      _buildScaleChip('1:50 Model', 1.0),
                      const SizedBox(width: 8),
                      _buildScaleChip('1:20 Site', 2.0),
                      const SizedBox(width: 8),
                      _buildScaleChip('1:1 True', 5.0),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Rotation & Elevation Sliders
                  Row(
                    children: [
                      // Rotation
                      const Icon(Icons.rotate_right_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_rotationAngle.toInt()}°',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _rotationAngle,
                          min: 0,
                          max: 360,
                          onChanged: (val) => setState(() => _rotationAngle = val),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sun Angle (Shadow study)
                      const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.accentOrange),
                      const SizedBox(width: 6),
                      Text(
                        '${_sunHour.toInt()}:00',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _sunHour,
                          min: 7,
                          max: 18,
                          onChanged: (val) => setState(() => _sunHour = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleChip(String label, double scaleVal) {
    final isSelected = (_scaleMultiplier - scaleVal).abs() < 0.1;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _scaleMultiplier = scaleVal),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders the simulated perspective architectural ground grid and shadows.
class _SpatialGroundGridPainter extends CustomPainter {
  final double rotationDeg;
  final Offset shadowOffset;
  final double scaleFactor;

  _SpatialGroundGridPainter({
    required this.rotationDeg,
    required this.shadowOffset,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);

    // Draw simulated shadow footprint
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final shadowRect = Rect.fromCenter(
      center: center + shadowOffset,
      width: 160 * scaleFactor,
      height: 110 * scaleFactor,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // Draw perspective site grid
    final gridPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const lineSpacing = 32.0;
    const gridRadius = 220.0;

    for (double i = -gridRadius; i <= gridRadius; i += lineSpacing) {
      canvas.drawLine(
        Offset(center.dx + i, center.dy - gridRadius * 0.4),
        Offset(center.dx + i * 1.5, center.dy + gridRadius * 0.6),
        gridPaint,
      );
      canvas.drawLine(
        Offset(center.dx - gridRadius * 1.3, center.dy + i * 0.35),
        Offset(center.dx + gridRadius * 1.3, center.dy + i * 0.35),
        gridPaint,
      );
    }

    // Concentric spatial rings
    final ringPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawOval(Rect.fromCenter(center: center, width: 240, height: 110), ringPaint);
    canvas.drawOval(Rect.fromCenter(center: center, width: 380, height: 170), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _SpatialGroundGridPainter oldDelegate) {
    return oldDelegate.rotationDeg != rotationDeg ||
        oldDelegate.shadowOffset != shadowOffset ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}

/// Custom painter for the Virtual Laser Tape Measure.
class _TapeMeasureLaserPainter extends CustomPainter {
  final Offset? pointA;
  final Offset? pointB;
  final double? distanceMeters;

  _TapeMeasureLaserPainter({
    this.pointA,
    this.pointB,
    this.distanceMeters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pointA == null) return;

    final dotPaint = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = AppColors.accentOrange.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw Point A crosshairs
    canvas.drawCircle(pointA!, 5, dotPaint);
    canvas.drawCircle(pointA!, 12, ringPaint);

    if (pointB != null) {
      // Draw Point B crosshairs
      canvas.drawCircle(pointB!, 5, dotPaint);
      canvas.drawCircle(pointB!, 12, ringPaint);

      // Laser line
      final laserPaint = Paint()
        ..color = AppColors.accentOrange
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(pointA!, pointB!, laserPaint);

      // Distance tag pill at line midpoint
      final mid = Offset((pointA!.dx + pointB!.dx) / 2, (pointA!.dy + pointB!.dy) / 2);
      final distText = '${distanceMeters?.toStringAsFixed(2) ?? '0.00'} m';

      final textSpan = TextSpan(
        text: distText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xCCF59E0B),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, mid - Offset(textPainter.width / 2, 14));
    }
  }

  @override
  bool shouldRepaint(covariant _TapeMeasureLaserPainter oldDelegate) {
    return oldDelegate.pointA != pointA ||
        oldDelegate.pointB != pointB ||
        oldDelegate.distanceMeters != distanceMeters;
  }
}
