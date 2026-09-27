import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_vision/data/services/bim_vision_ai_engine.dart';
import 'package:house_vision/domain/models/ml_inspection_model.dart';

void main() {
  group('ML Inspection Model & Engine Tests', () {
    final aiEngine = BimVisionAiEngine();

    test('BimVisionAiEngine presets are fully populated', () {
      expect(BimVisionAiEngine.presets.length, equals(4));
      final windowPreset = BimVisionAiEngine.presets.firstWhere(
        (p) => p.id == 'preset_window_frame',
      );
      expect(windowPreset.baselineAnomalies, isNotEmpty);
      expect(windowPreset.sector, contains('SECTOR 4A'));
    });

    test('Preset analysis produces valid InspectionResult', () async {
      final preset = BimVisionAiEngine.presets[0];
      final result = await aiEngine.analyzePreset(preset);

      expect(result.id, isNotEmpty);
      expect(result.complianceScore, inInclusiveRange(40.0, 100.0));
      expect(result.processingTimeMs, greaterThan(0));
      expect(result.anomalies.length, equals(preset.baselineAnomalies.length));
      expect(result.analyzedPixels, greaterThan(0));
    });

    test('DetectedAnomaly JSON serialization and deserialization', () {
      const anomaly = DetectedAnomaly(
        id: 'anom_test_01',
        type: AnomalyType.windowAlignment,
        label: 'Window Offset',
        description: 'Lintel shifted by 120mm',
        normalizedRect: Rect.fromLTWH(0.2, 0.3, 0.4, 0.5),
        confidence: 0.965,
        severity: AnomalySeverity.high,
        bimDelta: '+120mm',
        recommendation: 'Shim studs',
      );

      final json = anomaly.toJson();
      expect(json['id'], equals('anom_test_01'));
      expect(json['confidence'], equals(0.965));

      final restored = DetectedAnomaly.fromJson(json);
      expect(restored.id, equals(anomaly.id));
      expect(restored.type, equals(AnomalyType.windowAlignment));
      expect(restored.normalizedRect.left, closeTo(0.2, 0.001));
      expect(restored.confidence, closeTo(0.965, 0.001));
      expect(restored.severity, equals(AnomalySeverity.high));
      expect(restored.bimDelta, equals('+120mm'));
    });

    test('Anomaly normalized bounding boxes are within 0.0 and 1.0 unit space', () {
      for (final preset in BimVisionAiEngine.presets) {
        for (final anomaly in preset.baselineAnomalies) {
          final rect = anomaly.normalizedRect;
          expect(rect.left, greaterThanOrEqualTo(0.0));
          expect(rect.top, greaterThanOrEqualTo(0.0));
          expect(rect.right, lessThanOrEqualTo(1.0));
          expect(rect.bottom, lessThanOrEqualTo(1.0));
        }
      }
    });
  });
}
