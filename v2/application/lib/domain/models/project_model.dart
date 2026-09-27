import 'package:flutter/foundation.dart';

/// Represents a construction project tracked inside House Vision.
@immutable
class ProjectModel {
  final String id;
  final String name;
  final String location;
  final double progress; // 0.0 to 1.0
  final String currentStage;
  final String detailedMilestone;
  final DateTime lastUpdated;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.location,
    required this.progress,
    required this.currentStage,
    required this.detailedMilestone,
    required this.lastUpdated,
  });

  int get progressPercent => (progress * 100).round();

  ProjectModel copyWith({
    String? id,
    String? name,
    String? location,
    double? progress,
    String? currentStage,
    String? detailedMilestone,
    DateTime? lastUpdated,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      progress: progress ?? this.progress,
      currentStage: currentStage ?? this.currentStage,
      detailedMilestone: detailedMilestone ?? this.detailedMilestone,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'progress': progress,
      'currentStage': currentStage,
      'detailedMilestone': detailedMilestone,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, {String defaultId = 'dream_home'}) {
    DateTime parseDate(dynamic date) {
      if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ProjectModel(
      id: map['id']?.toString() ?? defaultId,
      name: map['name']?.toString() ?? 'Dream Home',
      location: map['location']?.toString() ?? 'Coimbatore, Tamil Nadu',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.62,
      currentStage: map['currentStage']?.toString() ?? 'Superstructure Framing',
      detailedMilestone: map['detailedMilestone']?.toString() ?? 'Foundation completed • Walls in progress',
      lastUpdated: parseDate(map['lastUpdated']),
    );
  }

  static ProjectModel defaultProject() {
    return ProjectModel(
      id: 'dream_home',
      name: 'Dream Home Residence',
      location: 'Coimbatore, Tamil Nadu',
      progress: 0.62,
      currentStage: 'Superstructure Framing',
      detailedMilestone: 'Foundation completed • Walls in progress',
      lastUpdated: DateTime.now(),
    );
  }
}
