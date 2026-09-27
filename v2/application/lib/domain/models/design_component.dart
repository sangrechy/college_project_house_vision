import 'package:flutter/material.dart';

/// Supported customizable structural components.
enum ComponentType {
  window(label: 'Window', icon: Icons.window),
  door(label: 'Door', icon: Icons.door_front_door),
  wall(label: 'Wall', icon: Icons.view_agenda),
  room(label: 'Room', icon: Icons.meeting_room);

  final String label;
  final IconData icon;

  const ComponentType({required this.label, required this.icon});

  static ComponentType fromString(String? value) {
    if (value == null) return ComponentType.window;
    return ComponentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ComponentType.window,
    );
  }
}

/// Represents a dynamic design modification saved by the homeowner or constructor.
@immutable
class DesignComponent {
  final String id;
  final ComponentType type;
  final double position; // Normalized 0.0 -> 1.0
  final double size;     // Normalized 0.0 -> 1.0
  final int colorValue;  // 32-bit ARGB
  final DateTime updatedAt;
  final String updatedByRole;

  const DesignComponent({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.colorValue,
    required this.updatedAt,
    required this.updatedByRole,
  });

  Color get color => Color(colorValue);

  DesignComponent copyWith({
    String? id,
    ComponentType? type,
    double? position,
    double? size,
    int? colorValue,
    DateTime? updatedAt,
    String? updatedByRole,
  }) {
    return DesignComponent(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      colorValue: colorValue ?? this.colorValue,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByRole: updatedByRole ?? this.updatedByRole,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'selectedComponent': type.label,
      'position': position,
      'size': size,
      'color': colorValue,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedByRole,
    };
  }

  factory DesignComponent.fromMap(Map<String, dynamic> map, {String defaultId = 'primary_component'}) {
    DateTime parseDate(dynamic date) {
      if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return DesignComponent(
      id: map['id']?.toString() ?? defaultId,
      type: ComponentType.fromString(map['selectedComponent']?.toString()),
      position: (map['position'] as num?)?.toDouble() ?? 0.5,
      size: (map['size'] as num?)?.toDouble() ?? 0.5,
      colorValue: (map['color'] as num?)?.toInt() ?? 0xFF1E56A0,
      updatedAt: parseDate(map['updatedAt']),
      updatedByRole: map['updatedBy']?.toString() ?? 'Homeowner',
    );
  }

  static DesignComponent initial() {
    return DesignComponent(
      id: 'primary_component',
      type: ComponentType.window,
      position: 0.5,
      size: 0.5,
      colorValue: 0xFF1E56A0,
      updatedAt: DateTime.now(),
      updatedByRole: 'Homeowner',
    );
  }
}
