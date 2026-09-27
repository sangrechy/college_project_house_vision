import 'package:flutter_test/flutter_test.dart';
import 'package:house_vision/domain/models/design_component.dart';
import 'package:house_vision/domain/models/project_model.dart';
import 'package:house_vision/domain/models/verification_item.dart';

void main() {
  group('DesignComponent Model Tests', () {
    test('initial values and copyWith works', () {
      final initial = DesignComponent.initial();
      expect(initial.type, equals(ComponentType.window));
      expect(initial.position, equals(0.5));

      final updated = initial.copyWith(
        type: ComponentType.door,
        position: 0.8,
      );
      expect(updated.type, equals(ComponentType.door));
      expect(updated.position, equals(0.8));
      expect(updated.size, equals(initial.size));
    });

    test('serialization to and from map', () {
      final comp = DesignComponent(
        id: 'comp_1',
        type: ComponentType.wall,
        position: 0.75,
        size: 0.6,
        colorValue: 0xFF00A896,
        updatedAt: DateTime(2026, 9, 15),
        updatedByRole: 'Constructor',
      );

      final map = comp.toMap();
      expect(map['selectedComponent'], equals('Wall'));
      expect(map['position'], equals(0.75));

      final restored = DesignComponent.fromMap(map);
      expect(restored.type, equals(ComponentType.wall));
      expect(restored.position, equals(0.75));
      expect(restored.size, equals(0.6));
      expect(restored.colorValue, equals(0xFF00A896));
    });
  });

  group('ProjectModel Tests', () {
    test('default project values and percentage computation', () {
      final project = ProjectModel.defaultProject();
      expect(project.id, equals('dream_home'));
      expect(project.progress, equals(0.62));
      expect(project.progressPercent, equals(62));
    });

    test('copyWith updates progress correctly', () {
      final project = ProjectModel.defaultProject();
      final updated = project.copyWith(progress: 0.85);
      expect(updated.progressPercent, equals(85));
    });
  });

  group('VerificationItem Tests', () {
    test('sample checklist has valid items', () {
      final items = VerificationItem.sampleChecklist();
      expect(items.length, greaterThanOrEqualTo(4));
      expect(items.any((i) => i.status == VerificationStatus.mismatch), isTrue);
    });
  });
}
