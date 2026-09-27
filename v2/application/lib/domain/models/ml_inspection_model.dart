import 'dart:ui';

/// Types of structural anomalies detected by the BIM Vision AI Engine.
enum AnomalyType {
  windowAlignment,
  wallPlumbDeviation,
  concreteMicrocrack,
  rebarGridVariance,
}

/// Severity classification based on engineering building codes.
enum AnomalySeverity {
  low,
  medium,
  high,
  critical,
}

/// Represents a detected structural anomaly with normalized coordinates.
class DetectedAnomaly {
  final String id;
  final AnomalyType type;
  final String label;
  final String description;
  final Rect normalizedRect; // [0.0 - 1.0] relative to image dimensions
  final double confidence; // e.g. 0.962 (96.2%)
  final AnomalySeverity severity;
  final String bimDelta; // e.g. "+120mm horizontal displacement"
  final String recommendation;

  const DetectedAnomaly({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    required this.normalizedRect,
    required this.confidence,
    required this.severity,
    required this.bimDelta,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'description': description,
        'rect': {
          'left': normalizedRect.left,
          'top': normalizedRect.top,
          'width': normalizedRect.width,
          'height': normalizedRect.height,
        },
        'confidence': confidence,
        'severity': severity.name,
        'bimDelta': bimDelta,
        'recommendation': recommendation,
      };

  factory DetectedAnomaly.fromJson(Map<String, dynamic> json) {
    final rectMap = json['rect'] as Map<String, dynamic>;
    return DetectedAnomaly(
      id: json['id'] as String,
      type: AnomalyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnomalyType.windowAlignment,
      ),
      label: json['label'] as String,
      description: json['description'] as String,
      normalizedRect: Rect.fromLTWH(
        (rectMap['left'] as num).toDouble(),
        (rectMap['top'] as num).toDouble(),
        (rectMap['width'] as num).toDouble(),
        (rectMap['height'] as num).toDouble(),
      ),
      confidence: (json['confidence'] as num).toDouble(),
      severity: AnomalySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AnomalySeverity.medium,
      ),
      bimDelta: json['bimDelta'] as String,
      recommendation: json['recommendation'] as String,
    );
  }
}

/// Full structural inspection report emitted by the vision engine.
class InspectionResult {
  final String id;
  final DateTime timestamp;
  final String siteName;
  final double complianceScore; // e.g. 91.4%
  final int processingTimeMs;
  final List<DetectedAnomaly> anomalies;
  final String summaryNotes;
  final int analyzedPixels;

  const InspectionResult({
    required this.id,
    required this.timestamp,
    required this.siteName,
    required this.complianceScore,
    required this.processingTimeMs,
    required this.anomalies,
    required this.summaryNotes,
    required this.analyzedPixels,
  });

  bool get isApproved => complianceScore >= 85.0 && anomalies.every((a) => a.severity != AnomalySeverity.critical);

  int get criticalCount => anomalies.where((a) => a.severity == AnomalySeverity.critical).length;
  int get warningCount => anomalies.where((a) => a.severity == AnomalySeverity.medium || a.severity == AnomalySeverity.high).length;
}

/// Pre-configured site test telemetry scenarios for instant verification.
class SiteInspectionPreset {
  final String id;
  final String title;
  final String subtitle;
  final String sector;
  final String simulatedImagePath;
  final List<DetectedAnomaly> baselineAnomalies;

  const SiteInspectionPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sector,
    required this.simulatedImagePath,
    required this.baselineAnomalies,
  });
}
