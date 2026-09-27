import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hud_telemetry_bar.dart';
import '../../data/services/bim_vision_ai_engine.dart';
import '../../domain/models/ml_inspection_model.dart';

class RealityVerificationScreen extends StatefulWidget {
  const RealityVerificationScreen({super.key});

  @override
  State<RealityVerificationScreen> createState() => _RealityVerificationScreenState();
}

class _RealityVerificationScreenState extends State<RealityVerificationScreen>
    with SingleTickerProviderStateMixin {
  final BimVisionAiEngine _aiEngine = BimVisionAiEngine();
  final ImagePicker _picker = ImagePicker();

  SiteInspectionPreset _selectedPreset = BimVisionAiEngine.presets[0];
  InspectionResult? _inspectionResult;
  bool _isAnalyzing = false;
  Uint8List? _customImageBytes;

  // Split-Curtain divider position (0.0 = all Reality, 1.0 = all BIM)
  double _curtainSplit = 0.52;

  // Scanning laser animation
  late final AnimationController _scanAnimController;
  late final Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );

    // Run initial analysis with first preset
    _runAnalysisForPreset(_selectedPreset);
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysisForPreset(SiteInspectionPreset preset) async {
    setState(() {
      _selectedPreset = preset;
      _customImageBytes = null;
      _isAnalyzing = true;
    });
    _scanAnimController.repeat(reverse: true);

    final result = await _aiEngine.analyzePreset(preset);

    if (mounted) {
      _scanAnimController.stop();
      _scanAnimController.reset();
      setState(() {
        _inspectionResult = result;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _customImageBytes = bytes;
        _isAnalyzing = true;
      });
      _scanAnimController.repeat(reverse: true);

      final result = await _aiEngine.analyzeImageBytes(bytes, siteName: file.name);

      if (mounted) {
        _scanAnimController.stop();
        _scanAnimController.reset();
        setState(() {
          _inspectionResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('[AI Vision Lab] Error picking image: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  void _showCertificateDialog() {
    final result = _inspectionResult;
    if (result == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderHighlight, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(
              result.isApproved ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: result.isApproved ? AppColors.success : AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'BIM Verification Audit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit ID: ${result.id}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildAuditRow('Compliance Index', '${result.complianceScore.toStringAsFixed(1)}%'),
                  const Divider(height: 14),
                  _buildAuditRow('Neural Engine Latency', '${result.processingTimeMs} ms'),
                  const Divider(height: 14),
                  _buildAuditRow('Total Discrepancies', '${result.anomalies.length} items'),
                  const Divider(height: 14),
                  _buildAuditRow('LOD Tolerance Standard', 'ACI 117-10 / BIM 400'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              result.summaryNotes,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Export PDF & Broadcast'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.surfaceElevated,
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Signed BIM report dispatched to Site Team.', style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _inspectionResult;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('AI Vision Lab & Split-Curtain'),
        actions: [
          IconButton(
            tooltip: 'Live Site Camera',
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          IconButton(
            tooltip: 'Import Site Photo',
            icon: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            tooltip: 'Verification Audit Certificate',
            icon: const Icon(Icons.verified_outlined, color: AppColors.accentOrange),
            onPressed: _showCertificateDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Top HUD Telemetry
          HudTelemetryBar(
            siteTag: _selectedPreset.sector,
            coordinates: '11°01\'24.8"N 76°58\'12.4"E',
            isLiDarActive: true,
          ),
          const SizedBox(height: 14),

          // Preset Scenarios Carousel
          const Text(
            'FIELD TELEMETRY SCENARIOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: BimVisionAiEngine.presets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, index) {
                final preset = BimVisionAiEngine.presets[index];
                final isSelected = _selectedPreset.id == preset.id && _customImageBytes == null;
                return InkWell(
                  onTap: () => _runAnalysisForPreset(preset),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          preset.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Split Curtain Reality Comparison Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              final canvasWidth = constraints.maxWidth;
              const canvasHeight = 310.0;
              final splitX = canvasWidth * _curtainSplit;

              return Container(
                height: canvasHeight,
                width: canvasWidth,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderHighlight, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Layer 1: Planned 3D BIM Wireframe (Left layer)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF0F172A),
                        child: CustomPaint(
                          painter: _BimWireframePainter(preset: _selectedPreset),
                        ),
                      ),
                    ),

                    // Layer 2: Actual Construction Reality (Right layer clipped by Split-Curtain)
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _SplitCurtainClipper(splitX: splitX),
                        child: Container(
                          color: const Color(0xFF1E293B),
                          child: _customImageBytes != null
                              ? Image.memory(
                                  _customImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : CustomPaint(
                                  painter: _RealitySitePainter(preset: _selectedPreset),
                                ),
                        ),
                      ),
                    ),

                    // Layer 3: Computer Vision Bounding Box Overlay
                    if (result != null && !_isAnalyzing)
                      ...result.anomalies.map((anomaly) {
                        final rect = anomaly.normalizedRect;
                        final boxLeft = rect.left * canvasWidth;
                        final boxTop = rect.top * canvasHeight;
                        final boxWidth = rect.width * canvasWidth;
                        final boxHeight = rect.height * canvasHeight;

                        final isCritical = anomaly.severity == AnomalySeverity.critical;
                        final boxColor = isCritical ? AppColors.error : AppColors.accentOrange;

                        return Positioned(
                          left: boxLeft,
                          top: boxTop,
                          width: boxWidth,
                          height: boxHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: boxColor, width: 2.2),
                              borderRadius: BorderRadius.circular(6),
                              color: boxColor.withValues(alpha: 0.12),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Floating confidence pill
                                Positioned(
                                  top: -24,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: boxColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${anomaly.label} • ${(anomaly.confidence * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    // Layer 4: Scanning Laser Beam Animation
                    if (_isAnalyzing)
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, _) {
                          final laserY = _scanAnimation.value * canvasHeight;
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: laserY,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Layer 5: Interactive Split-Curtain Divider Handle
                    Positioned(
                      left: splitX - 18,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _curtainSplit = (_curtainSplit + (details.delta.dx / canvasWidth)).clamp(0.08, 0.92);
                          });
                        },
                        child: SizedBox(
                          width: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Vertical line
                              Container(
                                width: 2.5,
                                color: AppColors.primary,
                              ),
                              // Circular grab knob
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.compare_arrows_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Split Legend Badges
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'BIM SPEC ${(_curtainSplit * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'SITE REALITY ${((1 - _curtainSplit) * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ML Compliance Score Indicator Card
          if (result != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: result.isApproved ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (result.isApproved ? AppColors.success : AppColors.error).withValues(alpha: 0.14),
                      border: Border.all(
                        color: result.isApproved ? AppColors.success : AppColors.error,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${result.complianceScore.toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: result.isApproved ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              result.isApproved ? 'COMPLIANT WITH BIM LOD 400' : 'CRITICAL VARIANCE DETECTED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: result.isApproved ? AppColors.success : AppColors.error,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.summaryNotes,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Detected Structural Discrepancies List
          const Text(
            'Detected Structural Anomalies',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (result != null)
            ...result.anomalies.map(
              (anomaly) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            anomaly.severity == AnomalySeverity.critical
                                ? Icons.warning_rounded
                                : Icons.report_problem_outlined,
                            size: 20,
                            color: anomaly.severity == AnomalySeverity.critical
                                ? AppColors.error
                                : AppColors.accentOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              anomaly.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(anomaly.confidence * 100).toStringAsFixed(1)}% CONF',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        anomaly.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.architecture_rounded, size: 14, color: AppColors.accentOrange),
                            const SizedBox(width: 6),
                            Text(
                              'BIM Offset: ${anomaly.bimDelta}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentOrange,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Remedy: ${anomaly.recommendation}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Export & Broadcast Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showCertificateDialog,
              icon: const Icon(Icons.verified_rounded),
              label: const Text('Generate BIM Verification Certificate'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Custom clipper that only shows the portion to the right of splitX.
class _SplitCurtainClipper extends CustomClipper<Rect> {
  final double splitX;

  _SplitCurtainClipper({required this.splitX});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(splitX, 0, size.width - splitX, size.height);
  }

  @override
  bool shouldReclip(covariant _SplitCurtainClipper oldClipper) {
    return oldClipper.splitX != splitX;
  }
}

/// Custom painter for the planned 3D BIM Wireframe side.
class _BimWireframePainter extends CustomPainter {
  final SiteInspectionPreset preset;

  _BimWireframePainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Technical coordinate grid
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // BIM structural vector wireframe
    final vectorPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.45;
    final cy = size.height * 0.50;

    // Wall frame polygon
    final wallPath = Path()
      ..moveTo(cx - 100, cy - 80)
      ..lineTo(cx + 100, cy - 80)
      ..lineTo(cx + 100, cy + 90)
      ..lineTo(cx - 100, cy + 90)
      ..close();
    canvas.drawPath(wallPath, vectorPaint);

    // Window opening rectangle in BIM
    final windowRect = Rect.fromCenter(center: Offset(cx, cy - 10), width: 90, height: 75);
    canvas.drawRect(windowRect, vectorPaint);

    // Dimension cross lines
    final dimPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(cx - 45, cy - 60), Offset(cx + 45, cy - 60), dimPaint);
  }

  @override
  bool shouldRepaint(covariant _BimWireframePainter oldDelegate) => false;
}

/// Custom painter for the simulated site construction field capture.
class _RealitySitePainter extends CustomPainter {
  final SiteInspectionPreset preset;

  _RealitySitePainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    // Concrete / site masonry texture background
    final bgPaint = Paint()..color = const Color(0xFF273244);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final masonryPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.5;

    // Draw masonry mortar courses
    for (double y = 20; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), masonryPaint);
    }

    // Concrete rough opening with visible offset (shifted right or tilted)
    final cx = size.width * 0.45;
    final cy = size.height * 0.50;

    final actualOpeningPaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;

    // Displaced window opening representing real field condition (+35px offset)
    final actualRect = Rect.fromCenter(center: Offset(cx + 35, cy - 10), width: 95, height: 78);
    canvas.drawRect(actualRect, actualOpeningPaint);

    final timberStudPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.7)
      ..strokeWidth = 3.0;

    // Framing studs around opening
    canvas.drawLine(Offset(actualRect.left, actualRect.top - 20), Offset(actualRect.left, actualRect.bottom + 20), timberStudPaint);
    canvas.drawLine(Offset(actualRect.right, actualRect.top - 20), Offset(actualRect.right, actualRect.bottom + 20), timberStudPaint);
  }

  @override
  bool shouldRepaint(covariant _RealitySitePainter oldDelegate) => false;
}
