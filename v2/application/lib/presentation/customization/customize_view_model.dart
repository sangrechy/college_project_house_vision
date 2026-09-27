import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/design_component.dart';
import '../../domain/repositories/project_repository.dart';

class CustomizeViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;

  ComponentType _selectedType = ComponentType.window;
  double _position = 0.5;
  double _size = 0.5;
  Color _selectedColor = const Color(0xFF1E56A0);
  bool _isSaving = false;
  String? _saveSuccessMessage;

  CustomizeViewModel({required this._projectRepository}) {
    _loadInitial();
  }

  ComponentType get selectedType => _selectedType;
  double get position => _position;
  double get size => _size;
  Color get selectedColor => _selectedColor;
  bool get isSaving => _isSaving;
  String? get saveSuccessMessage => _saveSuccessMessage;

  void _loadInitial() {
    _projectRepository.streamLatestDesign(AppStrings.defaultProjectId).take(1).listen((d) {
      _selectedType = d.type;
      _position = d.position;
      _size = d.size;
      _selectedColor = d.color;
      notifyListeners();
    });
  }

  void selectType(ComponentType type) {
    _selectedType = type;
    notifyListeners();
  }

  void updatePosition(double newPos) {
    _position = newPos.clamp(0.0, 1.0);
    notifyListeners();
  }

  void updateSize(double newSize) {
    _size = newSize.clamp(0.1, 1.0);
    notifyListeners();
  }

  void selectColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  Future<bool> saveDesign({String updatedByRole = 'Homeowner'}) async {
    _isSaving = true;
    _saveSuccessMessage = null;
    notifyListeners();

    final component = DesignComponent(
      id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      position: _position,
      size: _size,
      colorValue: _selectedColor.toARGB32(),
      updatedAt: DateTime.now(),
      updatedByRole: updatedByRole,
    );

    try {
      await _projectRepository.updateDesign(AppStrings.defaultProjectId, component);
      _saveSuccessMessage = '${_selectedType.label} design saved & synced with constructor';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
