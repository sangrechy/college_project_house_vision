import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/hud_telemetry_bar.dart';

enum ARModelTarget {
  bimHouse,
  neferGuide,
}

class ARHouseScreen extends StatefulWidget {
  const ARHouseScreen({super.key});

  @override
  State<ARHouseScreen> createState() => _ARHouseScreenState();
}

class _ARHouseScreenState extends State<ARHouseScreen> with SingleTickerProviderStateMixin {
  // Camera & Background Viewport
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _cameraError = false;
  String _cameraErrorMsg = '';

  // Mode: CAM AR (Live optical background) vs STUDIO (Architectural dark grid)
  bool _isCameraMode = false; // Default to STUDIO for guaranteed rendering across Web/Desktop/Mobile

  // Real-time Hardware & Simulated Sensor Telemetry
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _simulatedSensorTimer;

  double _accelX = 0, _accelY = 0, _accelZ = 9.8;
  double _magX = 0, _magY = 1, _magZ = 0;
  double _pitchDeg = 0.0;
  double _rollDeg = 0.0;
  double _headingDeg = 342.0;
  String _cardinalDirection = 'NW';
  DateTime _lastSensorUpdate = DateTime.now();

  // Model & AR Spatial State
  ARModelTarget _selectedModel = ARModelTarget.neferGuide;
  double _scaleMultiplier = 1.0;
  double _rotationAngle = 45.0; // 0 to 360 deg
  double _sunHour = 14.0; // 7:00 to 18:00
  String _statusMessage = 'Spatial 3D Studio Active • 1:1 Human Avatar (1.65m)';

  // Virtual Laser Tape Measure
  bool _tapeMeasureActive = false;
  Offset? _tapePointA;
  Offset? _tapePointB;
  double? _measuredDistanceMeters;

  @override
  void initState() {
    super.initState();
    _initSensors();
    // Only attempt camera init if supported platform or user toggles CAM AR
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _cameraErrorMsg = 'No camera sensor detected.';
            _isCameraMode = false;
          });
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _isCameraMode = true;
        _statusMessage = 'Live Camera Feed Active • 1:1 Human Scale Anchor';
      });
    } catch (e) {
      debugPrint('[ARHouseScreen] Camera init fallback: $e');
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMsg = 'Camera unavailable: $e';
          _isCameraMode = false;
          _statusMessage = 'Operating in High-Precision Spatial Studio Mode.';
        });
      }
    }
  }

  void _initSensors() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        _accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
          (event) {
            _accelX = event.x;
            _accelY = event.y;
            _accelZ = event.z;
            _processSensors();
          },
          onError: (_) => _startSimulatedSensors(),
        );

        _magSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
          (event) {
            _magX = event.x;
            _magY = event.y;
            _magZ = event.z;
            _processSensors();
          },
          onError: (_) {},
        );

        _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
          (_) {},
          onError: (_) {},
        );
      } catch (_) {
        _startSimulatedSensors();
      }
    } else {
      _startSimulatedSensors();
    }
  }

  void _startSimulatedSensors() {
    _simulatedSensorTimer?.cancel();
    _simulatedSensorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _headingDeg = (338 + (DateTime.now().second % 10)).toDouble();
          _cardinalDirection = _getCardinal(_headingDeg);
        });
      }
    });
  }

  void _processSensors() {
    final now = DateTime.now();
    if (now.difference(_lastSensorUpdate).inMilliseconds < 33) return; // 30Hz throttle
    _lastSensorUpdate = now;

    final pitchRad = atan2(-_accelX, sqrt(_accelY * _accelY + _accelZ * _accelZ));
    final rollRad = atan2(_accelY, _accelZ);

    final pitch = pitchRad * (180.0 / pi);
    final roll = rollRad * (180.0 / pi);

    final cosPitch = cos(pitchRad);
    final sinPitch = sin(pitchRad);
    final cosRoll = cos(rollRad);
    final sinRoll = sin(rollRad);

    final xh = _magX * cosPitch + _magZ * sinPitch;
    final yh = _magX * sinRoll * sinPitch + _magY * cosRoll - _magZ * sinRoll * cosPitch;

    var rawHeading = atan2(-yh, xh) * (180.0 / pi);
    if (rawHeading < 0) rawHeading += 360.0;

    var diff = rawHeading - _headingDeg;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final smoothedHeading = (_headingDeg + 0.15 * diff + 360) % 360;

    final cardinal = _getCardinal(smoothedHeading);

    if (mounted) {
      setState(() {
        _pitchDeg = pitch;
        _rollDeg = roll;
        _headingDeg = smoothedHeading;
        _cardinalDirection = cardinal;
      });
    }
  }

  String _getCardinal(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SW';
    if (degrees >= 247.5 && degrees < 292.5) return 'W';
    return 'NW';
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
        final dx = _tapePointB!.dx - _tapePointA!.dx;
        final dy = _tapePointB!.dy - _tapePointA!.dy;
        final pixelDistance = sqrt(dx * dx + dy * dy);
        final pxPerMeter = _selectedModel == ARModelTarget.neferGuide ? 160.0 : 42.0;
        _measuredDistanceMeters = (pixelDistance / pxPerMeter) * (1.0 / _scaleMultiplier);
      } else {
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

  void _resetPlacement() {
    setState(() {
      _rotationAngle = 45.0;
      _scaleMultiplier = 1.0;
      _sunHour = 14.0;
      _resetTapeMeasure();
      _statusMessage = _selectedModel == ARModelTarget.neferGuide
          ? 'Nefer AI Assistant reset to 1:1 Human Scale (1.65m).'
          : 'BIM Model reset to default spatial datum.';
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _gyroSub?.cancel();
    _simulatedSensorTimer?.cancel();
    _cameraController?.dispose();
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
          IconButton(
            tooltip: 'Reset Spatial Placement',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetPlacement,
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (!_isCameraMode && _cameraController == null && !_cameraError) {
                  _initCamera();
                }
                setState(() => _isCameraMode = !_isCameraMode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isCameraMode ? AppColors.primary : AppColors.accentOrange).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isCameraMode ? AppColors.primary : AppColors.accentOrange,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCameraMode ? Icons.camera_alt_rounded : Icons.apartment_rounded,
                      size: 16,
                      color: _isCameraMode ? AppColors.primary : AppColors.accentOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isCameraMode ? 'CAM AR' : 'STUDIO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isCameraMode ? AppColors.primary : AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Layer 1: Live Optical Camera (CAM AR Mode) or Dark Studio Grid
          if (_isCameraMode && _isCameraReady && _cameraController != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final camera = _cameraController!;
                  if (!camera.value.isInitialized) return const SizedBox.shrink();

                  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                  final previewRatio = isLandscape ? camera.value.aspectRatio : (1 / camera.value.aspectRatio);
                  final screenRatio = constraints.maxWidth / constraints.maxHeight;

                  final scale = previewRatio > screenRatio
                      ? (previewRatio / screenRatio)
                      : (screenRatio / previewRatio);

                  return ClipRect(
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: CameraPreview(camera),
                      ),
                    ),
                  );
                },
              ),
            )
          else if (_isCameraMode && !_isCameraReady)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 14),
                      Text(
                        _cameraError ? _cameraErrorMsg : 'STARTING OPTICAL AR CAMERA...',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // STUDIO Mode: High-Precision Architectural Perspective Grid
            Positioned.fill(
              child: CustomPaint(
                painter: _SpatialGroundGridPainter(
                  rotationDeg: _rotationAngle,
                  shadowOffset: Offset(shadowOffsetX, shadowOffsetY),
                  scaleFactor: _scaleMultiplier,
                ),
              ),
            ),

          // Background Layer 2: Simulated Holographic Ground Anchor in CAM AR mode
          if (_isCameraMode)
            Positioned.fill(
              child: CustomPaint(
                painter: _CamFloorAnchorPainter(
                  pitch: _pitchDeg,
                  roll: _rollDeg,
                  scale: _scaleMultiplier,
                ),
              ),
            ),

          // Layer 3: Interactive 3D Model Viewport (Transparent in CAM AR, Solid Canvas in STUDIO)
          Positioned.fill(
            child: KeyedSubtree(
              key: ValueKey('${_selectedModel.name}_$_scaleMultiplier'),
              child: ModelViewer(
                src: _selectedModel == ARModelTarget.neferGuide
                    ? AppStrings.modelNeferGlb
                    : AppStrings.modelHouseArGlb,
                alt: _selectedModel == ARModelTarget.neferGuide
                    ? 'Nefer • AI Site Assistant & BIM Guide'
                    : 'BIM Spatial Model',
                autoRotate: false,
                cameraControls: true,
                backgroundColor: _isCameraMode ? Colors.transparent : AppColors.scaffoldBackground,
                loading: Loading.eager,
                reveal: Reveal.auto,
                scale: '$_scaleMultiplier $_scaleMultiplier $_scaleMultiplier',
                shadowIntensity: 1.0,
                ar: true,
                arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                arScale: ArScale.auto,
                arPlacement: ArPlacement.floor,
                innerModelViewerHtml: '''
                  <button slot="ar-button" id="ar-button" style="position: absolute; bottom: 190px; right: 20px; background: linear-gradient(135deg, #FF7A30, #ED8943); color: #fff; border: none; padding: 12px 20px; border-radius: 26px; font-weight: 800; font-size: 13px; letter-spacing: 0.5px; box-shadow: 0 4px 18px rgba(237,137,67,0.55); display: flex; align-items: center; gap: 8px; cursor: pointer; z-index: 99999;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3 4c0-1.1.9-2 2-2h4v2H5v4H3V4zm0 16c0 1.1.9 2 2 2h4v-2H5v-4H3v4zm16 2c1.1 0 2-.9 2-2v-4h-2v4h-4v2h4zm2-18c0-1.1-.9-2-2-2h-4v2h4v4h2V4zm-9 4l5 3v6l-5 3-5-3v-6l5-3z"/></svg>
                    VIEW IN ROOM (AR)
                  </button>
                ''',
              ),
            ),
          ),

          // Layer 4: Top HUD Telemetry Bar (Live Compass, Cardinal & LiDAR)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: HudTelemetryBar(
              siteTag: _selectedModel == ARModelTarget.neferGuide
                  ? 'NEFER AI GUIDE • SPATIAL HUMAN ANCHOR'
                  : 'AR SPATIAL PROJECTOR • BIM LOD 400',
              coordinates: '11°01\'24.8"N 76°58\'12.4"E',
              isLiDarActive: true,
              headingDegrees: _headingDeg.round(),
              cardinalDirection: _cardinalDirection,
            ),
          ),

          // Layer 5: Dual Model Selector (Nefer AI Guide vs BIM House)
          Positioned(
            top: 64,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppColors.neumorphicPillShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModelTab(
                      title: 'Nefer (AI Guide)',
                      subtitle: 'Smooth PBR • 512px Face (5.3MB)',
                      icon: Icons.person_rounded,
                      isSelected: _selectedModel == ARModelTarget.neferGuide,
                      onTap: () {
                        setState(() {
                          _selectedModel = ARModelTarget.neferGuide;
                          _scaleMultiplier = 1.0;
                          _statusMessage = 'Nefer AI Assistant anchored at 1:1 Human Scale (1.65m)';
                          _resetTapeMeasure();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildModelTab(
                      title: 'BIM House (Site)',
                      subtitle: 'Single Mesh Twin (971KB)',
                      icon: Icons.apartment_rounded,
                      isSelected: _selectedModel == ARModelTarget.bimHouse,
                      onTap: () {
                        setState(() {
                          _selectedModel = ARModelTarget.bimHouse;
                          _scaleMultiplier = 1.0;
                          _statusMessage = 'Architectural BIM Model loaded (1:50 Site Scale)';
                          _resetTapeMeasure();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer 6: Status & Attitude Telemetry Pill
          Positioned(
            top: 122,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppColors.neumorphicPillShadow,
              ),
              child: Row(
                children: [
                  Icon(
                    _tapeMeasureActive ? Icons.straighten : Icons.sensors_rounded,
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
                          : '$_statusMessage • Tilt: ${_pitchDeg.round()}°',
                      style: TextStyle(
                        color: _tapeMeasureActive ? AppColors.accentOrange : AppColors.textPrimary,
                        fontSize: 11.5,
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

          // Layer 7: Virtual Tape Measure Interactive Gesture & Canvas Overlay
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

          // Layer 8: Bottom 3D Spatial Gizmo Controls Dock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppColors.neumorphicShadow,
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
                      if (_selectedModel == ARModelTarget.neferGuide) ...[
                        _buildScaleChip('1:10 Desk', 0.1),
                        const SizedBox(width: 8),
                        _buildScaleChip('1:5 Mini', 0.2),
                        const SizedBox(width: 8),
                        _buildScaleChip('1:2 Half', 0.5),
                        const SizedBox(width: 8),
                        _buildScaleChip('1:1 Human', 1.0),
                      ] else ...[
                        _buildScaleChip('1:100 Tabletop', 0.5),
                        const SizedBox(width: 8),
                        _buildScaleChip('1:50 Model', 1.0),
                        const SizedBox(width: 8),
                        _buildScaleChip('1:20 Site', 2.0),
                        const SizedBox(width: 8),
                        _buildScaleChip('1:1 True', 5.0),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Rotation & Sun/Shadow Sliders
                  Row(
                    children: [
                      const Icon(Icons.rotate_right_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_rotationAngle.toInt()}°',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
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
                      const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.accentOrange),
                      const SizedBox(width: 6),
                      Text(
                        '${_sunHour.toInt()}:00',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
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
    final isSelected = (_scaleMultiplier - scaleVal).abs() < 0.05;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _scaleMultiplier = scaleVal),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : AppColors.neumorphicPillShadow,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected ? AppColors.neumorphicPillShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Holographic floor anchor painter for CAM AR mode
class _CamFloorAnchorPainter extends CustomPainter {
  final double pitch;
  final double roll;
  final double scale;

  _CamFloorAnchorPainter({
    required this.pitch,
    required this.roll,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);

    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: 260 * scale.clamp(0.4, 2.0), height: 90 * scale.clamp(0.4, 2.0)),
      glowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 260 * scale.clamp(0.4, 2.0), height: 90 * scale.clamp(0.4, 2.0)),
      ringPaint,
    );

    final innerRingPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: 140 * scale.clamp(0.4, 2.0), height: 50 * scale.clamp(0.4, 2.0)),
      innerRingPaint,
    );

    final crossPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx - 18, center.dy), Offset(center.dx + 18, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx, center.dy + 10), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _CamFloorAnchorPainter oldDelegate) {
    return oldDelegate.pitch != pitch || oldDelegate.roll != roll || oldDelegate.scale != scale;
  }
}

/// Perspective architectural ground grid and shadow footprint for STUDIO Mode
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

    final shadowPaint = Paint()
      ..color = const Color(0xFFA6B4C8).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final shadowRect = Rect.fromCenter(
      center: center + shadowOffset,
      width: 160 * scaleFactor,
      height: 110 * scaleFactor,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.20)
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

    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
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

/// Virtual Laser Tape Measure Canvas Painter
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

    canvas.drawCircle(pointA!, 5, dotPaint);
    canvas.drawCircle(pointA!, 12, ringPaint);

    if (pointB != null) {
      canvas.drawCircle(pointB!, 5, dotPaint);
      canvas.drawCircle(pointB!, 12, ringPaint);

      final laserPaint = Paint()
        ..color = AppColors.accentOrange
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(pointA!, pointB!, laserPaint);

      final mid = Offset((pointA!.dx + pointB!.dx) / 2, (pointA!.dy + pointB!.dy) / 2);
      final distText = '${distanceMeters?.toStringAsFixed(2) ?? "0.00"} m';

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
